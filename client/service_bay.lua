LS_Trucking = LS_Trucking or {}

local ServiceBay = {}
local ctx = {}
local uiOpen = false
local activeVehicle = 0
local activeVehicleData = nil
local originalProps = nil
local serviceCam = nil
local camAngle = 0.0
local camDistance = 5.8
local camHeight = 1.65
local textVisible = false
local serviceBlip = nil

local MOD_TYPES = {
    engine = 11,
    brakes = 12,
    transmission = 13,
    suspension = 15,
    armor = 16
}

local MOD_LABELS = {
    engine = 'Engine',
    transmission = 'Transmission',
    brakes = 'Brakes',
    suspension = 'Suspension',
    armor = 'Armor'
}

local MOD_ICONS = {
    engine = 'fa-gears',
    transmission = 'fa-sliders',
    brakes = 'fa-circle-stop',
    suspension = 'fa-car-side',
    armor = 'fa-shield-halved',
    turbo = 'fa-wind',
    tires = 'fa-ring'
}

local function Cfg()
    return Config.ServiceBay or {}
end

local function Notify(message, notifyType)
    if ctx.Notify then ctx.Notify(message, notifyType or 'inform') end
end

local function SetKeepInput(enabled)
    if ctx.SetKeepInput then
        ctx.SetKeepInput(enabled == true)
    elseif SetNuiFocusKeepInput then
        SetNuiFocusKeepInput(enabled == true)
    end
end

local function GetConfigCoords3(coords)
    if not coords then return nil end
    if coords.x and coords.y and coords.z then return vector3(coords.x + 0.0, coords.y + 0.0, coords.z + 0.0) end
    return nil
end

local function GetServiceBayCoords()
    local cfg = Cfg()
    return GetConfigCoords3(cfg.coords) or GetConfigCoords3(Config.Depot and (Config.Depot.vehicleReturn or Config.Depot.terminal))
end

local function GetServicePrices()
    local prices = Cfg().Prices or {}
    return prices.Service or {}
end

local function GetUpgradePrices()
    local prices = Cfg().Prices or {}
    return prices.Upgrades or {}
end

local function GetTurboStages()
    local stages = {}
    local configured = Cfg().TurboStages

    if type(configured) == 'table' then
        for _, stage in ipairs(configured) do
            local level = math.floor(tonumber(stage.level) or 0)
            if level > 0 then
                stages[#stages + 1] = {
                    level = level,
                    label = stage.label or ('Stage %s Turbo'):format(level),
                    price = math.max(0, math.floor(tonumber(stage.price) or 0)),
                    power = tonumber(stage.power) or 0.0,
                    torque = tonumber(stage.torque) or 1.0,
                    description = stage.description or ''
                }
            end
        end
    end

    if #stages == 0 then
        local prices = GetUpgradePrices()
        stages[#stages + 1] = {
            level = 1,
            label = 'Stage 1 Turbo',
            price = math.max(0, math.floor(tonumber(prices.turbo) or 0)),
            power = 0.0,
            torque = 1.0,
            description = 'Compressor plumbing and safe boost control.'
        }
    end

    table.sort(stages, function(a, b) return (a.level or 0) < (b.level or 0) end)
    return stages
end

local function GetTurboStageConfig(level)
    level = math.floor(tonumber(level) or 0)
    if level <= 0 then return nil end
    for _, stage in ipairs(GetTurboStages()) do
        if tonumber(stage.level) == level then return stage end
    end
    return nil
end

local function GetAppearancePrices()
    local prices = Cfg().Prices or {}
    return prices.Appearance or {}
end

local function GetDescription(key, level)
    local descriptions = Cfg().Descriptions or {}
    local value = descriptions[key]
    if type(value) == 'table' then
        return value[math.max(1, tonumber(level) or 1)] or value[#value] or ''
    end
    return value or ''
end

local function GetServiceDescription(key, fallback)
    local descriptions = Cfg().Descriptions or {}
    local serviceDescriptions = descriptions.service or {}
    return serviceDescriptions[key] or fallback or ''
end

local function GetStateBag(vehicle)
    if not vehicle or vehicle == 0 or not Entity then return nil end
    local ok, entity = pcall(Entity, vehicle)
    if not ok or not entity then return nil end
    return entity.state
end

local function SetVehicleServiceValue(vehicle, key, value)
    local state = GetStateBag(vehicle)
    if state and state.set then state:set(key, value, true) end
end

local function GetVehicleServiceValue(vehicle, key, fallback)
    local state = GetStateBag(vehicle)
    local value = state and state[key] or nil
    if value == nil then return fallback end
    return value
end

local function GetVehicleTurboStage(vehicle)
    if ctx.GetTurboStage then
        return math.max(0, math.floor(tonumber(ctx.GetTurboStage(vehicle)) or 0))
    end

    local stage = tonumber(GetVehicleServiceValue(vehicle, 'lsfcTurboStage', nil))
    if stage ~= nil then return math.max(0, math.floor(stage)) end
    return IsToggleModOn(vehicle, 18) and 1 or 0
end

local function ApplyTurboStage(vehicle, stage)
    stage = math.max(0, math.floor(tonumber(stage) or 0))

    if ctx.ApplyTurboStage then
        ctx.ApplyTurboStage(vehicle, stage)
        return
    end

    SetVehicleModKit(vehicle, 0)
    ToggleVehicleMod(vehicle, 18, stage > 0)
    SetVehicleServiceValue(vehicle, 'lsfcTurboInstalled', stage > 0)
    SetVehicleServiceValue(vehicle, 'lsfcTurboStage', stage)
end

local function GetFuel(vehicle)
    if Config.GetVehicleFuel then
        local value = Config.GetVehicleFuel(vehicle)
        if value ~= nil then return value end
    end
    return GetVehicleFuelLevel(vehicle)
end

local function SetFuel(vehicle, fuel)
    fuel = math.max(0.0, math.min(100.0, tonumber(fuel) or 100.0))
    if ctx.SetFuel then ctx.SetFuel(vehicle, fuel) else SetVehicleFuelLevel(vehicle, fuel) end
end

local function FixVehicleBodyDamage(vehicle, preserveMechanical)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return end

    local engineHealth, tankHealth, fuel, wasDriveable
    if preserveMechanical then
        engineHealth = GetVehicleEngineHealth(vehicle)
        tankHealth = GetVehiclePetrolTankHealth(vehicle)
        fuel = GetFuel(vehicle)
        wasDriveable = IsVehicleDriveable(vehicle, false)
    end

    SetVehicleFixed(vehicle)
    SetVehicleDeformationFixed(vehicle)
    SetVehicleBodyHealth(vehicle, 1000.0)
    SetVehicleDirtLevel(vehicle, 0.0)

    for windowIndex = 0, 7 do
        FixVehicleWindow(vehicle, windowIndex)
    end

    for doorIndex = 0, 7 do
        SetVehicleDoorShut(vehicle, doorIndex, false)
    end

    if preserveMechanical then
        SetVehicleEngineHealth(vehicle, engineHealth or 1000.0)
        SetVehiclePetrolTankHealth(vehicle, tankHealth or 1000.0)
        SetFuel(vehicle, fuel or 100.0)
        SetVehicleUndriveable(vehicle, wasDriveable == false)
    end
end

local function GetMileage(vehicle)
    local state = ctx.BuildCurrentVehicleState and ctx.BuildCurrentVehicleState() or nil
    return math.max(0.0, tonumber(state and state.mileage) or 0.0)
end

local function GetVehicleLabel(vehicleData)
    vehicleData = vehicleData or {}
    return vehicleData.vehicleLabel or vehicleData.label or vehicleData.vehicle_label or vehicleData.model or 'LSFC Vehicle'
end

local function BuildVehicleMeta(vehicle, source, record)
    record = record or {}
    return {
        source = source,
        id = record.id,
        type = record.type,
        index = record.index or record.vehicleIndex or record.vehicle_index or 1,
        label = GetVehicleLabel(record),
        plate = GetVehicleNumberPlateText(vehicle)
    }
end

local function ResolveServiceVehicle()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle == 0 or not DoesEntityExist(vehicle) then
        Notify('Pull an LSFC garage or private fleet vehicle into the service bay.', 'error')
        return nil
    end

    if GetPedInVehicleSeat(vehicle, -1) ~= ped then
        Notify('Use the service bay from the driver seat.', 'error')
        return nil
    end

    local spawned = ctx.GetSpawnedVehicle and ctx.GetSpawnedVehicle() or 0
    if spawned == 0 or not DoesEntityExist(spawned) or spawned ~= vehicle then
        Notify('Only your active LSFC garage or private fleet vehicle can use this bay.', 'error')
        return nil
    end

    local contractor = ctx.GetContractorVehicle and ctx.GetContractorVehicle() or nil
    if contractor then return vehicle, 'contractor', contractor end

    local garage = ctx.GetGarageVehicle and ctx.GetGarageVehicle() or nil
    if garage then return vehicle, 'garage', garage end

    Notify('Service bay work is limited to garage fleet and private fleet vehicles.', 'error')
    return nil
end
local function BuildInstalledList(vehicle)
    SetVehicleModKit(vehicle, 0)
    local installed = {}
    for key, modType in pairs(MOD_TYPES) do
        local current = GetVehicleMod(vehicle, modType)
        installed[#installed + 1] = {
            label = MOD_LABELS[key] or key,
            value = current >= 0 and ('Stage %s'):format(current + 1) or 'Stock'
        }
    end
    local turboStage = GetVehicleTurboStage(vehicle)
    local turboCfg = GetTurboStageConfig(turboStage)
    installed[#installed + 1] = { label = 'Turbo', value = turboStage > 0 and (turboCfg and turboCfg.label or ('Stage %s Turbo'):format(turboStage)) or 'Stock' }
    local tiresCanBurst = GetVehicleTyresCanBurst(vehicle)
    installed[#installed + 1] = { label = 'Tires', value = tiresCanBurst and 'Standard' or 'Reinforced' }
    return installed
end

local function BuildModOption(vehicle, key, modType)
    local max = GetNumVehicleMods(vehicle, modType)
    if not max or max <= 0 then return nil end

    local current = GetVehicleMod(vehicle, modType)
    local currentLevel = current >= 0 and current + 1 or 0
    local prices = GetUpgradePrices()
    local priceCfg = prices[key] or {}
    local levels = {}

    for level = 1, max do
        levels[#levels + 1] = {
            level = level,
            label = ('Stage %s'):format(level),
            description = GetDescription(key, level),
            price = math.max(0, math.floor((tonumber(priceCfg.base) or 0) + ((level - 1) * (tonumber(priceCfg.step) or 0))))
        }
    end

    return {
        kind = 'upgrade',
        key = key,
        label = MOD_LABELS[key] or key,
        icon = MOD_ICONS[key] or 'fa-wrench',
        current = currentLevel,
        currentLabel = currentLevel > 0 and ('Stage %s'):format(currentLevel) or 'Stock',
        levels = levels,
        removable = currentLevel > 0
    }
end

local function BuildUpgradeOptions(vehicle)
    SetVehicleModKit(vehicle, 0)
    local options = {}
    for _, key in ipairs({ 'engine', 'transmission', 'brakes', 'suspension', 'armor' }) do
        local option = BuildModOption(vehicle, key, MOD_TYPES[key])
        if option then options[#options + 1] = option end
    end

    local currentTurboStage = GetVehicleTurboStage(vehicle)
    local currentTurboCfg = GetTurboStageConfig(currentTurboStage)
    local turboLevels = {}
    for _, stage in ipairs(GetTurboStages()) do
        if tonumber(stage.level) > currentTurboStage then
            turboLevels[#turboLevels + 1] = {
                level = stage.level,
                label = stage.label or ('Stage %s Turbo'):format(stage.level),
                description = stage.description ~= '' and stage.description or GetDescription('turbo', stage.level),
                price = math.max(0, math.floor(tonumber(stage.price) or 0)),
                power = tonumber(stage.power) or 0.0,
                torque = tonumber(stage.torque) or 1.0
            }
        end
    end

    options[#options + 1] = {
        kind = 'upgrade',
        key = 'turbo',
        label = 'Turbo',
        icon = MOD_ICONS.turbo,
        current = currentTurboStage,
        currentLabel = currentTurboStage > 0 and (currentTurboCfg and currentTurboCfg.label or ('Stage %s Turbo'):format(currentTurboStage)) or 'Stock',
        removable = currentTurboStage > 0,
        levels = turboLevels
    }

    local reinforcedTires = not GetVehicleTyresCanBurst(vehicle)
    options[#options + 1] = {
        kind = 'upgrade',
        key = 'tires',
        label = 'Commercial Tires',
        icon = MOD_ICONS.tires,
        current = reinforcedTires and 1 or 0,
        currentLabel = reinforcedTires and 'Reinforced' or 'Standard',
        removable = reinforcedTires,
        levels = reinforcedTires and {} or {{ level = 1, label = 'Reinforced Tires', description = GetDescription('tires'), price = math.max(0, tonumber(GetUpgradePrices().tires) or 0) }}
    }

    return options
end

local function BuildServiceOptions(vehicle)
    local prices = GetServicePrices()
    return {
        {
            kind = 'service',
            key = 'drivetrain',
            label = 'Drivetrain Repair',
            icon = 'fa-gears',
            price = math.max(0, tonumber(prices.drivetrain) or 0),
            description = GetServiceDescription('drivetrain', 'ECU fault clear and fluid check.')
        },
        {
            kind = 'service',
            key = 'body',
            label = 'Body Repair',
            icon = 'fa-car-burst',
            price = math.max(0, tonumber(prices.body) or 0),
            description = GetServiceDescription('body', 'Panel repair and finish cleanup.')
        },
        {
            kind = 'service',
            key = 'full',
            label = 'Full Service',
            icon = 'fa-clipboard-check',
            price = math.max(0, tonumber(prices.full) or 0),
            description = GetServiceDescription('full', 'Drivetrain check, body repair, and service log update.')
        }
    }
end

local function BuildAppearanceOptions(vehicle)
    SetVehicleModKit(vehicle, 0)
    local appearancePrices = GetAppearancePrices()
    local options = {}
    local liveryPrice = math.max(0, tonumber(appearancePrices.livery) or 0)
    local nativeCount = GetVehicleLiveryCount(vehicle)
    local modCount = GetNumVehicleMods(vehicle, 48)

    if nativeCount and nativeCount > 0 then
        local currentLivery = GetVehicleLivery(vehicle)
        local levels = {}
        for i = 0, nativeCount - 1 do
            levels[#levels + 1] = { level = i, label = ('Livery %s'):format(i + 1), price = liveryPrice, mode = 'native' }
        end
        options[#options + 1] = {
            kind = 'appearance',
            key = 'livery',
            label = 'Embedded Liveries',
            icon = 'fa-brush',
            current = currentLivery,
            currentLabel = currentLivery and currentLivery >= 0 and ('Livery %s'):format(currentLivery + 1) or 'Stock',
            levels = levels
        }
    elseif modCount and modCount > 0 then
        local currentLivery = GetVehicleMod(vehicle, 48)
        local levels = {}
        for i = 0, modCount - 1 do
            levels[#levels + 1] = { level = i, label = ('Livery %s'):format(i + 1), price = liveryPrice, mode = 'mod' }
        end
        options[#options + 1] = {
            kind = 'appearance',
            key = 'livery',
            label = 'Mod Part Liveries',
            icon = 'fa-brush',
            current = currentLivery,
            currentLabel = currentLivery and currentLivery >= 0 and ('Livery %s'):format(currentLivery + 1) or 'Stock',
            levels = levels
        }
    end

    local extras = {}
    for extraId = 0, 20 do
        if DoesExtraExist(vehicle, extraId) then
            local enabled = IsVehicleExtraTurnedOn(vehicle, extraId)
            extras[#extras + 1] = {
                kind = 'appearance',
                key = 'extra',
                extraId = extraId,
                label = ('Extra %s'):format(extraId),
                icon = 'fa-puzzle-piece',
                enabled = enabled,
                target = not enabled,
                price = math.max(0, tonumber(appearancePrices.extra) or 0),
                description = enabled and 'Remove this mounted extra.' or 'Install this mounted extra.'
            }
        end
    end

    return options, extras
end

local function BuildPayload(access)
    local vehicle = activeVehicle
    local state = ctx.BuildCurrentVehicleState and ctx.BuildCurrentVehicleState() or {}
    local props = ctx.GetVehicleProps and ctx.GetVehicleProps(vehicle) or {}
    local mileage = GetMileage(vehicle)
    local lastServiceMileage = tonumber(props.lsfcLastServiceMileage) or tonumber(GetVehicleServiceValue(vehicle, 'lsfcLastServiceMileage', 0.0)) or 0.0
    local appearanceOptions, extraOptions = BuildAppearanceOptions(vehicle)

    return {
        locale = Config.Locale or 'en',
        config = {
            locale = Config.Locale or 'en'
        },
        vehicle = {
            label = activeVehicleData and activeVehicleData.label or 'LSFC Vehicle',
            plate = GetVehicleNumberPlateText(vehicle),
            source = activeVehicleData and activeVehicleData.source or 'garage'
        },
        state = {
            engineHealth = GetVehicleEngineHealth(vehicle),
            bodyHealth = GetVehicleBodyHealth(vehicle),
            fuel = GetFuel(vehicle),
            mileage = mileage,
            lastServiceMileage = lastServiceMileage,
            milesSinceService = math.max(0.0, mileage - lastServiceMileage)
        },
        invoice = {
            discountPercent = tonumber(access and access.discountPercent) or 0,
            paymentLabel = access and access.paymentLabel or (Config.PayToBank and 'Bank Account' or 'Cash Account'),
            paymentMethod = access and access.paymentMethod or (Config.PayToBank and 'bank' or 'cash')
        },
        installed = BuildInstalledList(vehicle),
        serviceOptions = BuildServiceOptions(vehicle),
        upgradeOptions = BuildUpgradeOptions(vehicle),
        appearanceOptions = appearanceOptions,
        extraOptions = extraOptions
    }
end
local function ApplyItem(vehicle, item, paid)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) or type(item) ~= 'table' then return end
    SetVehicleModKit(vehicle, 0)

    if item.kind == 'upgrade' then
        local key = tostring(item.key or '')
        local target = tonumber(item.target) or tonumber(item.level) or 1
        local remove = item.remove == true or target <= 0

        if key == 'turbo' then
            ApplyTurboStage(vehicle, remove and 0 or target)
        elseif key == 'tires' then
            SetVehicleTyresCanBurst(vehicle, remove)
            SetVehicleServiceValue(vehicle, 'lsfcTyresCanBurst', not remove)
        elseif MOD_TYPES[key] then
            SetVehicleMod(vehicle, MOD_TYPES[key], remove and -1 or math.max(0, target - 1), false)
        end
        return
    end

    if item.kind == 'appearance' then
        local key = tostring(item.key or '')
        if key == 'livery' then
            local target = tonumber(item.target)
            if target ~= nil then
                if item.mode == 'mod' then
                    SetVehicleMod(vehicle, 48, target, false)
                else
                    SetVehicleLivery(vehicle, target)
                end
            end
        elseif key == 'extra' then
            local extraId = tonumber(item.extraId)
            if extraId and DoesExtraExist(vehicle, extraId) then
                SetVehicleExtra(vehicle, extraId, item.target == true and 0 or 1)
            end
        end
        return
    end

    if paid and item.kind == 'service' then
        local key = tostring(item.key or '')
        local repairsDrivetrain = key == 'drivetrain' or key == 'full'
        local repairsBody = key == 'body' or key == 'full'

        if repairsDrivetrain then
            SetVehicleEngineHealth(vehicle, 1000.0)
            SetVehiclePetrolTankHealth(vehicle, 1000.0)
            SetVehicleUndriveable(vehicle, false)
        end
        if repairsBody then
            FixVehicleBodyDamage(vehicle, not repairsDrivetrain)
        end
        SetVehicleServiceValue(vehicle, 'lsfcLastServiceMileage', GetMileage(vehicle))
    end
end

local function RestoreOriginalProps()
    if activeVehicle ~= 0 and DoesEntityExist(activeVehicle) and originalProps and ctx.ApplyVehicleProps then
        ctx.ApplyVehicleProps(activeVehicle, originalProps)
        if originalProps.lsfcLastServiceMileage ~= nil then
            SetVehicleServiceValue(activeVehicle, 'lsfcLastServiceMileage', tonumber(originalProps.lsfcLastServiceMileage) or 0.0)
        end
        if originalProps.tyresCanBurst ~= nil then
            SetVehicleTyresCanBurst(activeVehicle, originalProps.tyresCanBurst == true)
            SetVehicleServiceValue(activeVehicle, 'lsfcTyresCanBurst', originalProps.tyresCanBurst == true)
        end
        if originalProps.lsfcTurboStage ~= nil or originalProps.turbo ~= nil then
            ApplyTurboStage(activeVehicle, tonumber(originalProps.lsfcTurboStage) or (originalProps.turbo == true and 1 or 0))
        end
    end
end

local function ApplyCart(cart, paid)
    if activeVehicle == 0 or not DoesEntityExist(activeVehicle) then return end
    for _, item in ipairs(cart or {}) do
        ApplyItem(activeVehicle, item, paid == true)
    end
end

local function PreviewCart(cart)
    RestoreOriginalProps()
    ApplyCart(cart, false)
end


local function SetServiceBayHoodOpen(open)
    if activeVehicle == 0 or not DoesEntityExist(activeVehicle) then return end
    if open then
        SetVehicleDoorOpen(activeVehicle, 4, false, false)
    else
        SetVehicleDoorShut(activeVehicle, 4, false)
    end
end

local function HasMechanicalWork(cart)
    for _, item in ipairs(cart or {}) do
        local kind = tostring(item.kind or '')
        if kind == 'service' or kind == 'upgrade' then return true end
    end
    return false
end

local function GetInstallLabel(item, index, total)
    item = item or {}
    local kind = tostring(item.kind or '')
    local label = tostring(item.label or 'Service bay item')
    local detail = tostring(item.detail or '')
    local verb = 'Installing'

    if kind == 'service' then
        verb = 'Servicing'
    elseif kind == 'appearance' and item.key == 'livery' then
        verb = 'Applying'
    elseif item.remove == true or tonumber(item.target) == 0 then
        verb = 'Removing'
    elseif kind == 'appearance' and item.key == 'extra' and item.target == false then
        verb = 'Removing'
    end

    if detail ~= '' and detail ~= 'nil' then
        return ('%s %s - %s (%s/%s)'):format(verb, label, detail, index, total)
    end

    return ('%s %s (%s/%s)'):format(verb, label, index, total)
end

local function GetInstallDuration(item)
    local progress = Cfg().InstallProgress or {}
    local kind = tostring(item and item.kind or '')
    return math.max(250, tonumber(progress[kind]) or tonumber(progress.duration) or 1000)
end

local function RunInstallProgress(cart)
    cart = cart or {}
    local total = #cart
    if total <= 0 then return true end

    local progress = Cfg().InstallProgress or {}
    local openedHood = HasMechanicalWork(cart)
    if openedHood then
        SetServiceBayHoodOpen(true)
        Wait(250)
    end

    for index, item in ipairs(cart) do
        if activeVehicle == 0 or not DoesEntityExist(activeVehicle) or not uiOpen then
            if openedHood then SetServiceBayHoodOpen(false) end
            SendNUIMessage({ action = 'serviceBayInstallProgress', phase = 'clear' })
            return false, T('service.vehicle_unavailable')
        end

        local kind = tostring(item.kind or '')
        if kind == 'service' or kind == 'upgrade' then SetServiceBayHoodOpen(true) end

        local duration = GetInstallDuration(item)
        local label = GetInstallLabel(item, index, total)
        SendNUIMessage({
            action = 'serviceBayInstallProgress',
            phase = 'start',
            label = label,
            detail = 'Technician work in progress',
            index = index,
            total = total,
            duration = duration
        })

        local start = GetGameTimer()
        while GetGameTimer() - start < duration do
            Wait(50)
            if activeVehicle == 0 or not DoesEntityExist(activeVehicle) or not uiOpen then
                if openedHood then SetServiceBayHoodOpen(false) end
                SendNUIMessage({ action = 'serviceBayInstallProgress', phase = 'clear' })
                return false, T('service.work_order_canceled')
            end
        end

        SendNUIMessage({
            action = 'serviceBayInstallProgress',
            phase = 'complete',
            label = label,
            detail = 'Item installed',
            index = index,
            total = total,
            percent = 100
        })

        if ctx.PlayUISound then ctx.PlayUISound(progress.sound or 'impact') end
        Wait(150)
    end

    if openedHood then SetServiceBayHoodOpen(false) end
    SendNUIMessage({
        action = 'serviceBayInstallProgress',
        phase = 'saving',
        label = 'Finalizing invoice and saving vehicle state',
        detail = 'Applying service bay records',
        index = total,
        total = total,
        percent = 100
    })
    return true
end
local function StartCamera(vehicle)

    if serviceCam then return end
    local coords = GetEntityCoords(vehicle)
    camAngle = GetEntityHeading(vehicle) + 145.0
    camDistance = 5.8
    camHeight = 1.65
    serviceCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamFov(serviceCam, 48.0)
    RenderScriptCams(true, true, 350, true, true)

    CreateThread(function()
        while uiOpen and serviceCam do
            Wait(0)
            DisableAllControlActions(0)
            DisableAllControlActions(1)
            DisableAllControlActions(2)

            if IsDisabledControlPressed(0, 24) or IsControlPressed(0, 24) then
                camAngle = camAngle - (GetDisabledControlNormal(0, 1) * 6.0)
                camHeight = math.max(0.35, math.min(3.5, camHeight + (GetDisabledControlNormal(0, 2) * 2.5)))
            end

            if IsDisabledControlPressed(0, 14) or IsControlPressed(0, 14) or IsDisabledControlPressed(0, 242) then
                camDistance = math.min(9.0, camDistance + 0.08)
            elseif IsDisabledControlPressed(0, 15) or IsControlPressed(0, 15) or IsDisabledControlPressed(0, 241) then
                camDistance = math.max(2.6, camDistance - 0.08)
            end

            if activeVehicle ~= 0 and DoesEntityExist(activeVehicle) then
                coords = GetEntityCoords(activeVehicle)
                local rad = math.rad(camAngle)
                local camX = coords.x + (math.cos(rad) * camDistance)
                local camY = coords.y + (math.sin(rad) * camDistance)
                local camZ = coords.z + camHeight
                SetCamCoord(serviceCam, camX, camY, camZ)
                PointCamAtEntity(serviceCam, activeVehicle, 0.0, 0.0, 0.65, true)
            end
        end
    end)
end

local function StopCamera()
    if not serviceCam then return end
    RenderScriptCams(false, true, 250, true, true)
    DestroyCam(serviceCam, false)
    serviceCam = nil
end

local function CloseServiceBay(restore)
    if restore ~= false then RestoreOriginalProps() end
    uiOpen = false
    activeVehicle = 0
    activeVehicleData = nil
    originalProps = nil
    SendNUIMessage({ action = 'serviceBayClose' })
    SetNuiFocus(false, false)
    SetKeepInput(false)
    StopCamera()
end

local function Checkout(cart, paymentMethod)
    cart = cart or {}
    if activeVehicle == 0 or not DoesEntityExist(activeVehicle) or not activeVehicleData then
        return { success = false, message = T('service.vehicle_unavailable') }
    end

    local installed, installMessage = RunInstallProgress(cart)
    if not installed then
        Notify(installMessage or T('service.work_order_canceled'), 'error')
        return { success = false, message = installMessage or T('service.work_order_canceled') }
    end

    local purchase = lib.callback.await('ls_trucking:server:purchaseServiceBayCart', false, {
        vehicle = activeVehicleData,
        cart = cart,
        paymentMethod = paymentMethod
    })

    if not purchase or not purchase.success then
        Notify(purchase and purchase.message or 'Service bay invoice could not be paid.', 'error')
        return purchase or { success = false }
    end

    RestoreOriginalProps()
    ApplyCart(cart or {}, true)

    local props = ctx.GetVehicleProps and ctx.GetVehicleProps(activeVehicle) or {}
    props.lsfcLastServiceMileage = tonumber(GetVehicleServiceValue(activeVehicle, 'lsfcLastServiceMileage', props.lsfcLastServiceMileage or 0.0)) or 0.0
    props.tyresCanBurst = GetVehicleTyresCanBurst(activeVehicle)
    props.lsfcTurboStage = GetVehicleTurboStage(activeVehicle)
    props.turbo = props.lsfcTurboStage > 0 or IsToggleModOn(activeVehicle, 18)
    props.toggles = props.toggles or {}
    props.toggles['18'] = props.turbo == true

    local state = ctx.BuildCurrentVehicleState and ctx.BuildCurrentVehicleState() or {}
    local save = lib.callback.await('ls_trucking:server:saveServiceBayVehicle', false, {
        vehicle = activeVehicleData,
        props = props,
        fuel = state.fuel or GetFuel(activeVehicle),
        engineHealth = GetVehicleEngineHealth(activeVehicle),
        bodyHealth = GetVehicleBodyHealth(activeVehicle),
        mileage = state.mileage or GetMileage(activeVehicle)
    })

    if not save or not save.success then
        Notify(save and save.message or 'Service bay work was applied but could not be saved.', 'error')
        return save or { success = false }
    end

    Notify(purchase.message or 'Service bay work order complete.', 'success')
    if ctx.PlayUISound then ctx.PlayUISound('confirm') end
    CloseServiceBay(false)
    return { success = true, invoice = purchase.invoice }
end
local function OpenServiceBay()
    if uiOpen then return end
    local cfg = Cfg()
    if cfg.Enabled == false then
        Notify('LSFC service bay is disabled.', 'error')
        return
    end

    local vehicle, source, record = ResolveServiceVehicle()
    if not vehicle then return end

    local meta = BuildVehicleMeta(vehicle, source, record)
    local access = lib.callback.await('ls_trucking:server:getServiceBayAccess', false, meta)
    if not access or not access.success then
        Notify(access and access.message or 'Service bay access denied.', 'error')
        return
    end

    activeVehicle = vehicle
    activeVehicleData = meta
    originalProps = ctx.GetVehicleProps and ctx.GetVehicleProps(vehicle) or {}
    originalProps.lsfcLastServiceMileage = tonumber(GetVehicleServiceValue(vehicle, 'lsfcLastServiceMileage', originalProps.lsfcLastServiceMileage or 0.0)) or 0.0
    originalProps.tyresCanBurst = GetVehicleTyresCanBurst(vehicle)
    originalProps.lsfcTurboStage = tonumber(originalProps.lsfcTurboStage) or GetVehicleTurboStage(vehicle)

    local payload = BuildPayload(access)
    uiOpen = true
    SetNuiFocus(true, true)
    SetKeepInput(true)
    SendNUIMessage({ action = 'serviceBayOpen', data = payload })
    StartCamera(vehicle)
    if ctx.PlayUISound then ctx.PlayUISound('click') end
end

local function SetTextVisible(visible)
    if visible == textVisible then return end
    textVisible = visible

    if lib and lib.showTextUI and lib.hideTextUI then
        if visible then
            lib.showTextUI(Cfg().Text or '[E] Open LSFC Service Bay', { icon = 'screwdriver-wrench' })
        else
            lib.hideTextUI()
        end
    end
end

local function DrawHelpText(text)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(text or '[E] Open LSFC Service Bay')
    EndTextCommandDisplayHelp(0, false, true, 1)
end

local function DrawServiceMarker(coords)
    local marker = Cfg().Marker or {}
    local size = marker.size or vector3(6.0, 6.0, 0.25)
    local color = marker.color or { r = 245, g = 190, b = 40, a = 110 }
    DrawMarker(
        tonumber(marker.type) or 1,
        coords.x, coords.y, coords.z + (tonumber(marker.zOffset) or -0.95),
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        size.x or 6.0, size.y or 6.0, size.z or 0.25,
        color.r or 245, color.g or 190, color.b or 40, color.a or 110,
        false, false, 2, false, nil, nil, false
    )
end

local function CreateServiceBlip()
    local cfg = Cfg()
    local blipCfg = cfg.Blip or {}
    if blipCfg.enabled == false or serviceBlip then return end

    local coords = GetServiceBayCoords()
    if not coords then return end
    serviceBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(serviceBlip, tonumber(blipCfg.sprite) or 446)
    SetBlipDisplay(serviceBlip, 4)
    SetBlipScale(serviceBlip, tonumber(blipCfg.scale) or 0.55)
    SetBlipColour(serviceBlip, tonumber(blipCfg.color) or 5)
    SetBlipAsShortRange(serviceBlip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(blipCfg.label or 'LSFC Service Bay')
    EndTextCommandSetBlipName(serviceBlip)
end

CreateThread(function()
    Wait(1000)
    CreateServiceBlip()

    while true do
        local sleep = 1000
        local cfg = Cfg()
        local coords = cfg.Enabled ~= false and GetServiceBayCoords() or nil

        if coords then
            local ped = PlayerPedId()
            local playerCoords = GetEntityCoords(ped)
            local dist = #(playerCoords - coords)
            local drawDistance = tonumber(cfg.drawDistance) or 65.0
            local radius = tonumber(cfg.radius) or 7.5

            if dist <= drawDistance then
                sleep = 0
                DrawServiceMarker(coords)

                if dist <= radius and IsPedInAnyVehicle(ped, false) and not uiOpen then
                    if lib and lib.showTextUI then
                        SetTextVisible(true)
                    else
                        DrawHelpText(cfg.Text or '[E] Open LSFC Service Bay')
                    end

                    if IsControlJustReleased(0, 38) then
                        OpenServiceBay()
                    end
                else
                    SetTextVisible(false)
                end
            else
                SetTextVisible(false)
            end
        else
            SetTextVisible(false)
        end

        Wait(sleep)
    end
end)

RegisterCommand(Cfg().Command or 'lsservice', function()
    OpenServiceBay()
end, false)

RegisterNUICallback('serviceBayPreview', function(data, cb)
    PreviewCart(data and data.cart or {})
    cb({ success = true })
end)

RegisterNUICallback('serviceBayCheckout', function(data, cb)
    data = data or {}
    local result = Checkout(data.cart or {}, data.paymentMethod)
    cb(result or { success = false })
end)

RegisterNUICallback('serviceBayClose', function(data, cb)
    CloseServiceBay(not data or data.restore ~= false)
    cb({ success = true })
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    SetTextVisible(false)
    if uiOpen then CloseServiceBay(true) end
    if serviceBlip then RemoveBlip(serviceBlip) serviceBlip = nil end
end)

function ServiceBay.ConfigureClient(context)
    ctx = context or {}
end

LS_Trucking.ServiceBay = ServiceBay
