local activeContract = nil
local reusableVehicle = nil
local activeBlip = nil
local spawnedVehicle = nil
local spawnedTrailer = nil
local spawnedTrailerStartBody = 1000.0
local carryingProp = nil
local carryingCargo = false
local garageVehicle = nil
local miniUIVisible = true
local dispatchPed = nil
local spawnedPeds = {}
local zones = {}
local vehicleTargetAdded = false
local trailerTargetAdded = false

local tabletOpen = false
local tabletProp = nil

local lastRouteSummary = nil
local currentDriverInfo = nil

local function GetClientTimestamp()
    local function pad(number)
        number = tonumber(number) or 0
        return number < 10 and ('0' .. number) or tostring(number)
    end

    if GetLocalTime then
        local ok, year, month, a, b, c, d, e = pcall(GetLocalTime)

        if ok and tonumber(year) and tonumber(month) then
            -- Some FiveM builds return: year, month, dayOfWeek, day, hour, minute, second
            if tonumber(e) then
                local day = tonumber(b) or 1
                local hour = tonumber(c) or 0
                local minute = tonumber(d) or 0
                return ('%04d-%s-%s %s:%s'):format(tonumber(year), pad(month), pad(day), pad(hour), pad(minute))
            end

            -- Other builds may return: year, month, day, hour, minute, second
            if tonumber(d) then
                local day = tonumber(a) or 1
                local hour = tonumber(b) or 0
                local minute = tonumber(c) or 0
                return ('%04d-%s-%s %s:%s'):format(tonumber(year), pad(month), pad(day), pad(hour), pad(minute))
            end
        end
    end

    return 'Current Session'
end


local function LoadLastRouteSummary()
    local raw = GetResourceKvpString('ls_trucking_last_route_summary')

    if raw and raw ~= '' then
        local ok, decoded = pcall(json.decode, raw)

        if ok and type(decoded) == 'table' then
            lastRouteSummary = decoded
        end
    end
end

LoadLastRouteSummary()

local function SaveLastRouteSummary(data)
    if not data or type(data) ~= 'table' then return end

    lastRouteSummary = data
    SetResourceKvp('ls_trucking_last_route_summary', json.encode(data))

    SendNUIMessage({
        action = 'updateLastRouteSummary',
        summary = lastRouteSummary
    })
end

local function PlayUISound(soundType)
    SendNUIMessage({ action = 'playSound', sound = soundType or 'click' })
end

local function StopTabletAnim()
    tabletOpen = false

    local ped = PlayerPedId()
    ClearPedSecondaryTask(ped)

    if tabletProp and DoesEntityExist(tabletProp) then
        DeleteEntity(tabletProp)
    end

    tabletProp = nil
end

local function StartTabletAnim()
    StopTabletAnim()

    tabletOpen = true

    local ped = PlayerPedId()
    local dict = 'amb@code_human_in_bus_passenger_idles@female@tablet@base'
    local anim = 'base'
    local model = `prop_cs_tablet`

    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(0) end

    RequestModel(model)
    while not HasModelLoaded(model) do Wait(0) end

    local coords = GetEntityCoords(ped)
    tabletProp = CreateObject(model, coords.x, coords.y, coords.z, true, true, false)

    AttachEntityToEntity(
        tabletProp,
        ped,
        GetPedBoneIndex(ped, 28422),
        -0.025, 0.005, -0.065,
        10.0, 160.0, 0.0,
        true, true, false, true, 1, true
    )

    TaskPlayAnim(ped, dict, anim, 3.0, 3.0, -1, 49, 0, false, false, false)
    SetModelAsNoLongerNeeded(model)
end

CreateThread(function()
    while true do
        if tabletOpen then
            local ped = PlayerPedId()

            if not IsEntityPlayingAnim(ped, 'amb@code_human_in_bus_passenger_idles@female@tablet@base', 'base', 3) then
                TaskPlayAnim(ped, 'amb@code_human_in_bus_passenger_idles@female@tablet@base', 'base', 3.0, 3.0, -1, 49, 0, false, false, false)
            end

            Wait(1500)
        else
            Wait(1000)
        end
    end
end)

local function Notify(message, notifyType)
    notifyType = notifyType or 'inform'

    if notifyType == 'warning' or notifyType == 'error' then
        PlayUISound('alert')
    end

    if Config.Notifications and Config.Notifications.Enabled == false then
        return
    end

    lib.notify({
        title = (Config.Notifications and Config.Notifications.Title) or 'Los Santos Freight Co.',
        description = message,
        type = notifyType,
        duration = (Config.Notifications and Config.Notifications.Duration) or Config.NotificationDuration or 8500
    })
end

RegisterNetEvent('ls_trucking:client:notify', function(message, notifyType) Notify(message, notifyType) end)

local freightDialogPromise = nil

local function ShowFreightDialog(header, lines, closeLabel)
    if type(lines) == 'table' then
        lines = table.concat(lines, '\n')
    end

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'showFreightDialog',
        mode = 'info',
        header = header or 'Los Santos Freight Co.',
        content = lines or '',
        closeLabel = closeLabel or 'Close'
    })
end

local function ShowFreightConfirm(header, lines, confirmLabel, cancelLabel)
    if type(lines) == 'table' then
        lines = table.concat(lines, '\n')
    end

    if freightDialogPromise then
        freightDialogPromise:resolve({ confirmed = false })
        freightDialogPromise = nil
    end

    local p = promise.new()
    freightDialogPromise = p

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'showFreightDialog',
        mode = 'confirm',
        header = header or 'Los Santos Freight Co.',
        content = lines or '',
        confirmLabel = confirmLabel or 'Confirm',
        cancelLabel = cancelLabel or 'Cancel'
    })

    local result = Citizen.Await(p)
    return result and result.confirmed == true
end

local function ShowFreightCancelDialog(repLoss, reasons)
    if freightDialogPromise then
        freightDialogPromise:resolve({ confirmed = false })
        freightDialogPromise = nil
    end

    local p = promise.new()
    freightDialogPromise = p

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'showFreightCancelDialog',
        header = 'Cancel Freight Route',
        repLoss = repLoss or 0,
        reasons = reasons or {}
    })

    local result = Citizen.Await(p)

    if result and result.confirmed and result.reason then
        return result.reason
    end

    return nil
end


local function LoadModel(model)
    local hash = type(model) == 'number' and model or joaat(model)
    if not IsModelInCdimage(hash) then Notify(('Model does not exist: %s'):format(tostring(model)), 'error') return nil end
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(10) end
    return hash
end

local function ApplyExtras(vehicle, extras)
    if not vehicle or vehicle == 0 or not extras then return end
    for extraId, enabled in pairs(extras) do
        extraId = tonumber(extraId)
        if extraId and DoesExtraExist(vehicle, extraId) then SetVehicleExtra(vehicle, extraId, enabled and 0 or 1) end
    end
end

local function SetVehicleOptions(vehicle, options, isTrailer)
    if not vehicle or vehicle == 0 or not options then return end
    SetVehicleModKit(vehicle, 0)
    if isTrailer then
        if options.trailerLivery ~= nil then SetVehicleLivery(vehicle, options.trailerLivery) end
        ApplyExtras(vehicle, options.trailerExtras)
    else
        if options.livery ~= nil then SetVehicleLivery(vehicle, options.livery) end
        if options.truckLivery ~= nil then SetVehicleLivery(vehicle, options.truckLivery) end
        ApplyExtras(vehicle, options.extras or options.truckExtras)
    end
    SetVehicleDirtLevel(vehicle, 0.0)
end

local function SetFuel(vehicle, fuel)
    if not vehicle or vehicle == 0 then return end
    if Config.SetVehicleFuel then
        Config.SetVehicleFuel(vehicle, fuel or 100)
        return
    end
    SetVehicleFuelLevel(vehicle, (fuel or 100) + 0.0)
end

local function GiveKeys(vehicle)
    if not vehicle or vehicle == 0 then return end
    local plate = GetVehicleNumberPlateText(vehicle)
    if Config.GiveVehicleKeys then
        Config.GiveVehicleKeys(vehicle, plate)
        return
    end
end

local function GetVehicleProps(vehicle)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return {} end
    SetVehicleModKit(vehicle, 0)
    local color1, color2 = GetVehicleColours(vehicle)
    local pearl, wheel = GetVehicleExtraColours(vehicle)
    local nr, ng, nb = GetVehicleNeonLightsColour(vehicle)
    local sr, sg, sb = GetVehicleTyreSmokeColor(vehicle)
    local props = {
        model = GetEntityModel(vehicle),
        plate = GetVehicleNumberPlateText(vehicle),
        dirtLevel = GetVehicleDirtLevel(vehicle),
        bodyHealth = GetVehicleBodyHealth(vehicle),
        engineHealth = GetVehicleEngineHealth(vehicle),
        tankHealth = GetVehiclePetrolTankHealth(vehicle),
        fuelLevel = GetVehicleFuelLevel(vehicle),
        colors = { color1, color2 },
        extraColors = { pearl, wheel },
        dashboardColor = GetVehicleDashboardColour(vehicle),
        interiorColor = GetVehicleInteriorColour(vehicle),
        windowTint = GetVehicleWindowTint(vehicle),
        livery = GetVehicleLivery(vehicle),
        wheelType = GetVehicleWheelType(vehicle),
        tyreSmokeColor = { sr, sg, sb },
        neonEnabled = { IsVehicleNeonLightEnabled(vehicle, 0), IsVehicleNeonLightEnabled(vehicle, 1), IsVehicleNeonLightEnabled(vehicle, 2), IsVehicleNeonLightEnabled(vehicle, 3) },
        neonColor = { nr, ng, nb },
        mods = {}, toggles = {}, extras = {}
    }
    for i = 0, 49 do props.mods[tostring(i)] = GetVehicleMod(vehicle, i) end
    props.toggles['18'] = IsToggleModOn(vehicle, 18)
    props.toggles['20'] = IsToggleModOn(vehicle, 20)
    props.toggles['22'] = IsToggleModOn(vehicle, 22)
    for i = 0, 20 do if DoesExtraExist(vehicle, i) then props.extras[tostring(i)] = IsVehicleExtraTurnedOn(vehicle, i) end end
    return props
end

local function ApplyVehicleProps(vehicle, props)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) or not props then return end
    if type(props) == 'string' and props ~= '' then props = json.decode(props) end
    if not props or type(props) ~= 'table' then return end
    SetVehicleModKit(vehicle, 0)
    if props.plate then SetVehicleNumberPlateText(vehicle, props.plate) end
    if props.colors then SetVehicleColours(vehicle, props.colors[1] or 0, props.colors[2] or 0) end
    if props.extraColors then SetVehicleExtraColours(vehicle, props.extraColors[1] or 0, props.extraColors[2] or 0) end
    if props.dashboardColor then SetVehicleDashboardColour(vehicle, props.dashboardColor) end
    if props.interiorColor then SetVehicleInteriorColour(vehicle, props.interiorColor) end
    if props.windowTint then SetVehicleWindowTint(vehicle, props.windowTint) end
    if props.wheelType then SetVehicleWheelType(vehicle, props.wheelType) end
    if props.mods then for modType, modIndex in pairs(props.mods) do SetVehicleMod(vehicle, tonumber(modType), tonumber(modIndex), false) end end
    if props.toggles then for modType, enabled in pairs(props.toggles) do ToggleVehicleMod(vehicle, tonumber(modType), enabled == true) end end
    if props.extras then for extraId, enabled in pairs(props.extras) do extraId = tonumber(extraId) if extraId and DoesExtraExist(vehicle, extraId) then SetVehicleExtra(vehicle, extraId, enabled and 0 or 1) end end end
    if props.livery and props.livery >= 0 then SetVehicleLivery(vehicle, props.livery) end
    if props.neonEnabled then for i = 0, 3 do SetVehicleNeonLightEnabled(vehicle, i, props.neonEnabled[i + 1] == true) end end
    if props.neonColor then SetVehicleNeonLightsColour(vehicle, props.neonColor[1] or 255, props.neonColor[2] or 255, props.neonColor[3] or 255) end
    if props.tyreSmokeColor then SetVehicleTyreSmokeColor(vehicle, props.tyreSmokeColor[1] or 255, props.tyreSmokeColor[2] or 255, props.tyreSmokeColor[3] or 255) end
    SetVehicleDirtLevel(vehicle, props.dirtLevel or 0.0)
    SetVehicleBodyHealth(vehicle, props.bodyHealth or 1000.0)
    SetVehicleEngineHealth(vehicle, props.engineHealth or 1000.0)
    SetVehiclePetrolTankHealth(vehicle, props.tankHealth or 1000.0)
end

local function GetJobVehiclePlate()
    if not spawnedVehicle or not DoesEntityExist(spawnedVehicle) then return nil end
    return GetVehicleNumberPlateText(spawnedVehicle)
end


local function GetStreetAddressFromCoords(coords)
    if not coords then return nil end

    local x, y, z = coords.x, coords.y, coords.z
    if not x or not y or not z then return nil end

    local streetHash, crossingHash = GetStreetNameAtCoord(x, y, z)
    local street = streetHash and streetHash ~= 0 and GetStreetNameFromHashKey(streetHash) or nil
    local crossing = crossingHash and crossingHash ~= 0 and GetStreetNameFromHashKey(crossingHash) or nil

    if street and street ~= '' and crossing and crossing ~= '' then
        return ('%s / %s'):format(street, crossing)
    end

    if street and street ~= '' then
        return street
    end

    return nil
end

local function SetActiveDestination(label, coords)
    if not activeContract then return end

    activeContract.destination = label or 'N/A'
    activeContract.destinationAddress = GetStreetAddressFromCoords(coords)
end

local function GetBlipStyle(blipType)
    local blips = Config.Blips or {}
    local key = 'Default'

    if blipType == 'pickup' then key = 'Pickup' end
    if blipType == 'package' then key = 'PackageDelivery' end
    if blipType == 'crate' then key = 'CrateDelivery' end
    if blipType == 'trailer' then key = 'TrailerDelivery' end
    if blipType == 'receiver' then key = 'Receiver' end
    if blipType == 'return' then key = 'ReturnVehicle' end

    return blips[key] or blips.Default or { sprite = 1, color = 5, scale = 0.85 }
end

local function CreateRouteBlip(coords, label, blipType)
    if activeBlip then RemoveBlip(activeBlip) activeBlip = nil end
    if not coords then return end

    local style = GetBlipStyle(blipType)
    activeBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(activeBlip, style.sprite or 1)
    SetBlipScale(activeBlip, style.scale or 0.85)
    SetBlipColour(activeBlip, style.color or 5)
    SetBlipAsShortRange(activeBlip, false)

    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(label or 'Trucking Route')
    EndTextCommandSetBlipName(activeBlip)

    if activeContract and label then
        activeContract.destinationAddress = GetStreetAddressFromCoords(coords)
    end

    PlayUISound('destination')
end

local function GetCargoDeliveryBlipType(contractType)
    if contractType == 'boxtruck' then return 'crate' end
    if contractType == 'trailer' then return 'trailer' end
    return 'package'
end

local function ClearRouteBlip() if activeBlip then RemoveBlip(activeBlip) activeBlip = nil end end

local function Progress(label, duration, anim, prop)
    return lib.progressBar({
        duration = duration,
        label = label,
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true
        },
        anim = anim,
        prop = prop
    })
end

local function GetCargoConfigForContract(contractType, cargoTypeOverride)
    if cargoTypeOverride and Config.CargoTypes and Config.CargoTypes[cargoTypeOverride] then
        return Config.CargoTypes[cargoTypeOverride]
    end

    if activeContract and activeContract.currentCarryCargoType and Config.CargoTypes and Config.CargoTypes[activeContract.currentCarryCargoType] then
        return Config.CargoTypes[activeContract.currentCarryCargoType]
    end

    if activeContract and activeContract.cargoConfig then
        return activeContract.cargoConfig
    end

    local cargoType = activeContract and activeContract.cargoType or (Config.DefaultCargoType and Config.DefaultCargoType[contractType])

    if cargoType and Config.CargoTypes and Config.CargoTypes[cargoType] then
        return Config.CargoTypes[cargoType]
    end

    return Config.CargoItems and Config.CargoItems[contractType]
end

local function CarryCargoProp(contractType, cargoTypeOverride)
    local cargo = GetCargoConfigForContract(contractType, cargoTypeOverride)
    if not cargo then return end
    local ped = PlayerPedId()
    lib.requestAnimDict('anim@heists@box_carry@')
    TaskPlayAnim(ped, 'anim@heists@box_carry@', 'idle', 8.0, 8.0, -1, 49, 0, false, false, false)
    local prop = CreateObject(cargo.prop, 0.0, 0.0, 0.0, true, true, false)
    local o = cargo.carryOffset
    AttachEntityToEntity(prop, ped, GetPedBoneIndex(ped, o.bone), o.pos.x, o.pos.y, o.pos.z, o.rot.x, o.rot.y, o.rot.z, true, true, false, true, 1, true)
    carryingProp = prop
    carryingCargo = true
end

local function DeleteCarryProp()
    ClearPedTasks(PlayerPedId())
    if carryingProp and DoesEntityExist(carryingProp) then DeleteEntity(carryingProp) end
    carryingProp = nil
    carryingCargo = false
    if activeContract then activeContract.currentCarryCargoType = nil end
end

CreateThread(function()
    while true do
        Wait(1000)

        if carryingCargo and carryingProp and DoesEntityExist(carryingProp) then
            local ped = PlayerPedId()

            if not IsEntityPlayingAnim(ped, 'anim@heists@box_carry@', 'idle', 3) then
                lib.requestAnimDict('anim@heists@box_carry@')
                TaskPlayAnim(ped, 'anim@heists@box_carry@', 'idle', 8.0, 8.0, -1, 49, 0, false, false, false)
            end
        end
    end
end)

local function GetTargetSystem()
    local configured = Config.TargetSystem or (Config.Target and Config.Target.System) or 'auto'

    if configured == 'ox' or configured == 'ox_target' then
        return 'ox'
    end

    if configured == 'qb' or configured == 'qb-target' then
        return 'qb'
    end

    if GetResourceState('ox_target') == 'started' then
        return 'ox'
    end

    if GetResourceState('qb-target') == 'started' then
        return 'qb'
    end

    return 'ox'
end

local function ConvertTargetIcon(icon)
    icon = tostring(icon or 'circle')

    if GetTargetSystem() == 'qb' then
        icon = icon:gsub('fa%-solid%s+', '')
        icon = icon:gsub('fa%-regular%s+', '')
        icon = icon:gsub('fa%-brands%s+', '')
        icon = icon:gsub('fas%s+', '')
        icon = icon:gsub('far%s+', '')
        icon = icon:gsub('fab%s+', '')
        icon = icon:gsub('fa%-', '')
    end

    return icon
end

local function ConvertTargetOptions(options)
    local converted = {}

    for _, option in ipairs(options or {}) do
        local originalCanInteract = option.canInteract
        local originalOnSelect = option.onSelect

        converted[#converted + 1] = {
            name = option.name,
            label = option.label,
            icon = ConvertTargetIcon(option.icon),
            distance = option.distance,
            canInteract = originalCanInteract and function(entity, distance, data)
                local coords = nil

                if type(data) == 'vector3' then
                    coords = data
                elseif type(data) == 'table' and data.coords then
                    coords = data.coords
                else
                    coords = GetEntityCoords(PlayerPedId())
                end

                return originalCanInteract(entity, distance, coords)
            end or nil,
            onSelect = originalOnSelect,
            action = originalOnSelect and function(entity)
                originalOnSelect({ entity = entity })
            end or nil
        }
    end

    return converted
end

local function AddTargetEntity(entity, options)
    if not entity or entity == 0 then return end

    local system = GetTargetSystem()
    local converted = ConvertTargetOptions(options)

    if system == 'qb' then
        exports['qb-target']:AddTargetEntity(entity, {
            options = converted,
            distance = Config.TargetDistance or 2.5
        })
        return
    end

    exports.ox_target:addLocalEntity(entity, converted)
end

local function RemoveTargetZone(zoneId)
    if not zoneId then return end

    if GetTargetSystem() == 'qb' then
        exports['qb-target']:RemoveZone(zoneId)
    else
        exports.ox_target:removeZone(zoneId)
    end
end

local function RemoveAllZones()
    for _, zoneId in pairs(zones) do
        RemoveTargetZone(zoneId)
    end

    zones = {}
end

local function AddSphereZone(name, coords, radius, options)
    local system = GetTargetSystem()
    local converted = ConvertTargetOptions(options)

    if system == 'qb' then
        exports['qb-target']:AddCircleZone(name, coords, radius, {
            name = name,
            debugPoly = Config.Debug or false,
            useZ = true
        }, {
            options = converted,
            distance = Config.TargetDistance or 2.5
        })

        zones[name] = name
        return
    end

    zones[name] = exports.ox_target:addSphereZone({ coords = coords, radius = radius, debug = Config.Debug, options = converted })
end

local function IsCargoDoorOpen()
    if not spawnedVehicle or not DoesEntityExist(spawnedVehicle) then return false end
    return GetVehicleDoorAngleRatio(spawnedVehicle, 5) > 0.1 or GetVehicleDoorAngleRatio(spawnedVehicle, 2) > 0.1 or GetVehicleDoorAngleRatio(spawnedVehicle, 3) > 0.1
end

local function CleanupJobVehicle()
    DeleteCarryProp()
    if spawnedTrailer and DoesEntityExist(spawnedTrailer) then DeleteEntity(spawnedTrailer) end
    if spawnedVehicle and DoesEntityExist(spawnedVehicle) then DeleteEntity(spawnedVehicle) end
    spawnedTrailer = nil
    spawnedTrailerStartBody = 1000.0
    spawnedVehicle = nil
    reusableVehicle = nil
    garageVehicle = nil
    vehicleTargetAdded = false
    trailerTargetAdded = false
end

local function CleanupTrailerOnly()
    if spawnedTrailer and DoesEntityExist(spawnedTrailer) then DeleteEntity(spawnedTrailer) end
    spawnedTrailer = nil
    spawnedTrailerStartBody = 1000.0
end

local function HideMiniUI() SendNUIMessage({ action = 'hideMini' }) end

local function FormatExpectedCompletion(estimatedSeconds)
    estimatedSeconds = tonumber(estimatedSeconds) or 0
    if estimatedSeconds <= 0 then return '' end

    local etaMinutes = math.max(1, math.floor((estimatedSeconds / 60) + 0.5))
    local currentHour = GetClockHours()
    local currentMinute = GetClockMinutes()
    local dueMinutes = ((currentHour * 60) + currentMinute + etaMinutes) % 1440
    local dueHour = math.floor(dueMinutes / 60)
    local dueMinute = dueMinutes % 60

    return ('Expected by %02d:%02d (%sm ETA)'):format(dueHour, dueMinute, etaMinutes)
end

local function SetExpectedCompletionTime()
    if not activeContract then return end
    activeContract.expectedCompletion = FormatExpectedCompletion(activeContract.estimatedSeconds)
end

local function UpdateMiniUI()
    if not Config.MiniUIEnabled then return end
    if not activeContract then HideMiniUI() return end
    SendNUIMessage({ action = miniUIVisible and 'showMini' or 'hideMini', contract = { type = activeContract.type, label = activeContract.routeLabel or activeContract.label, stage = activeContract.stage, notice = activeContract.notice or '', currentStop = activeContract.currentStop or 0, totalStops = activeContract.totalStops or 0, payout = activeContract.payout, cargo = activeContract.cargo, destination = activeContract.destination or 'N/A', destinationAddress = activeContract.destinationAddress or nil, vehicle = activeContract.vehicleLabel or 'Company Vehicle', loadedCargo = activeContract.loadedCargo or 0, requiredCargo = activeContract.requiredCargo or 0, estimatedTime = activeContract.estimatedTime or '', expectedCompletion = activeContract.expectedCompletion or '', randomEventLabel = activeContract.randomEvent and activeContract.randomEvent.label or nil, contractAlert = activeContract.randomEvent and { label = activeContract.randomEvent.label or 'Dispatch Alert', description = activeContract.randomEvent.description or 'Route conditions changed.' } or nil } })
end

local function CanReuseVehicle(contractType)
    if not Config.AllowVehicleReuseAfterRoute then return false end
    if not reusableVehicle and not garageVehicle then return false end
    if not spawnedVehicle or not DoesEntityExist(spawnedVehicle) then return false end
    local currentType = reusableVehicle and reusableVehicle.type or garageVehicle and garageVehicle.type
    if Config.RequireSameTypeForVehicleReuse and currentType ~= contractType then return false end
    return true
end

local function GetReuseData()
    if not reusableVehicle and not garageVehicle then return { available = false } end
    if not spawnedVehicle or not DoesEntityExist(spawnedVehicle) then reusableVehicle = nil garageVehicle = nil return { available = false } end
    local data = reusableVehicle or garageVehicle
    return { available = true, type = data.type, label = data.label, vehicleLabel = data.vehicleLabel or data.label }
end

local function GetAttachedTrailer()
    if not spawnedVehicle or not DoesEntityExist(spawnedVehicle) then return 0 end
    local hasTrailer, trailer = GetVehicleTrailerVehicle(spawnedVehicle)
    if hasTrailer and trailer and trailer ~= 0 and DoesEntityExist(trailer) then return trailer end
    return 0
end

local function IsAssignedTrailerAttached()
    local attachedTrailer = GetAttachedTrailer()
    if attachedTrailer == 0 then return false end
    if spawnedTrailer and DoesEntityExist(spawnedTrailer) then return attachedTrailer == spawnedTrailer end
    return true
end

local function MarkTrailerHookedAuto()
    if not activeContract or activeContract.type ~= 'trailer' or activeContract.trailerHooked then return end
    if activeContract.trailerAttached then return end
    if not IsAssignedTrailerAttached() then return end

    activeContract.trailerAttached = true
    activeContract.loaded = false
    activeContract.loadChecklist = activeContract.loadChecklist or { truckSecure = false, trailerSecure = false }
    activeContract.stage = 'Complete load checklist'
    activeContract.notice = 'Trailer is hooked. Target the rear of the truck to review the checklist, secure the load connection, then confirm the trailer load is secure.'
    SetActiveDestination('Load checklist')

    Notify('Trailer attached. Complete the load checklist before starting the delivery route.', 'inform')
    UpdateMiniUI()
end

CreateThread(function()
    while true do
        Wait(Config.TrailerAutoDetectInterval or 750)
        if activeContract and activeContract.type == 'trailer' and not activeContract.trailerHooked then MarkTrailerHookedAuto() end
    end
end)


local trailerSpeedingSince = nil
local trailerSpeedWarningShown = false
local trailerRiskCooldown = 0

local function RollPercent(chance)
    chance = tonumber(chance) or 0
    if chance <= 0 then return false end
    return math.random(1, 100) <= chance
end

local function BurstRandomTrailerTyre(vehicle)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return false end

    local tyreIndexes = { 0, 1, 2, 3, 4, 5 }
    for _ = 1, #tyreIndexes do
        local index = tyreIndexes[math.random(1, #tyreIndexes)]
        if not IsVehicleTyreBurst(vehicle, index, false) then
            SetVehicleTyreBurst(vehicle, index, true, 1000.0)
            return true
        end
    end

    return false
end

local function ApplyTrailerSpeedRisk()
    local cfg = Config.SpeedRisk or {}
    if cfg.Enabled == false then return end
    if not activeContract or activeContract.type ~= 'trailer' or not activeContract.trailerHooked or activeContract.trailerDropped then
        trailerSpeedingSince = nil
        trailerSpeedWarningShown = false
        return
    end

    if not spawnedVehicle or not DoesEntityExist(spawnedVehicle) then return end

    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle ~= spawnedVehicle then return end

    local safeSpeed = tonumber(activeContract.safeSpeed) or tonumber(cfg.DefaultSafeSpeed) or 75.0
    local speedMph = GetEntitySpeed(spawnedVehicle) * 2.236936

    if speedMph <= safeSpeed then
        trailerSpeedingSince = nil
        trailerSpeedWarningShown = false
        return
    end

    local now = GetGameTimer()
    if not trailerSpeedingSince then trailerSpeedingSince = now end

    local speedingFor = now - trailerSpeedingSince
    if not trailerSpeedWarningShown and speedingFor >= (cfg.WarningAfter or 10000) then
        trailerSpeedWarningShown = true
        Notify(('%s Safe speed: %s MPH.'):format(cfg.WarningMessage or 'Dispatch: Reduce speed.', math.floor(safeSpeed)), 'warning')
    end

    if speedingFor < (cfg.RiskAfter or 20000) then return end
    if now < trailerRiskCooldown then return end
    trailerRiskCooldown = now + (cfg.CheckInterval or 5000)

    if spawnedTrailer and DoesEntityExist(spawnedTrailer) and RollPercent(cfg.TireBlowoutChance or 0) then
        if BurstRandomTrailerTyre(spawnedTrailer) then
            Notify('Dispatch: Trailer tire failure reported from unsafe speed.', 'error')
            return
        end
    end

    if RollPercent(cfg.EngineFailureChance or 0) then
        local currentHealth = GetVehicleEngineHealth(spawnedVehicle)
        local newHealth = math.max(tonumber(cfg.MinimumEngineHealth) or 350.0, currentHealth - (tonumber(cfg.EngineDamageAmount) or 120.0))
        SetVehicleEngineHealth(spawnedVehicle, newHealth)
        Notify('Dispatch: Engine strain detected from unsafe hauling speed.', 'error')
    end
end

CreateThread(function()
    while true do
        Wait((Config.SpeedRisk and Config.SpeedRisk.CheckInterval) or 5000)
        ApplyTrailerSpeedRisk()
    end
end)

local function LoadCargoIntoVehicle()
    if not activeContract then return end
    if activeContract.type == 'trailer' then Notify('Trailer hauling does not use cargo boxes.', 'error') return end
    if not IsCargoDoorOpen() then Notify('Open the vehicle trunk or rear cargo door before loading cargo.', 'error') return end
    if not carryingCargo then Notify('You need to carry a route item first.', 'error') return end
    if not spawnedVehicle or not DoesEntityExist(spawnedVehicle) then Notify('Your job vehicle is missing.', 'error') return end
    if not Progress('Loading cargo into open trunk...', Config.Progress.loadCargo, { dict = 'anim@heists@box_carry@', clip = 'idle' }) then return end
    local result = lib.callback.await('ls_trucking:server:loadCargoOne', false)
    if not result or not result.success then Notify(result and result.message or 'Could not load cargo.', 'error') return end
    DeleteCarryProp()
    activeContract.loadedCargo = result.loaded
    activeContract.loaded = false
    if result.ready then
        activeContract.cargoReady = true
        activeContract.verifiedCargo = false
        activeContract.stage = 'Verify loaded cargo'
        activeContract.notice = 'All cargo is loaded. Target the vehicle and verify loaded cargo before starting the route.'
        SetActiveDestination('Verify cargo at vehicle')
        Notify('All cargo loaded. Target the vehicle and verify the loaded cargo to start your route.', 'success')
    else
        activeContract.stage = 'Load cargo into vehicle'
        activeContract.notice = ('Load cargo one item at a time: %s/%s loaded.'):format(result.loaded, result.required)
        Notify(('Cargo loaded %s/%s. Get the next item from the pickup worker.'):format(result.loaded, result.required), 'success')
    end
    UpdateMiniUI()
end

local function VerifyLoadedCargo()
    if not activeContract then return end
    if activeContract.type == 'trailer' then return end
    if not activeContract.cargoReady then
        Notify('Load all route cargo before verifying.', 'error')
        return
    end

    if not Progress('Verifying loaded cargo...', Config.Progress.verifyLoadedCargo or 2500, {
        dict = 'missheistdockssetup1clipboard@base',
        clip = 'base'
    }, {
        model = `p_amb_clipboard_01`,
        bone = 18905,
        pos = vec3(0.10, 0.02, 0.08),
        rot = vec3(-80.0, 0.0, 0.0)
    }) then
        return
    end

    local result = lib.callback.await('ls_trucking:server:verifyLoadedCargo', false)
    if not result or not result.success then
        Notify(result and result.message or 'Could not verify loaded cargo.', 'error')
        return
    end

    activeContract.verifiedCargo = true
    activeContract.loaded = true
    activeContract.currentStop = result.currentStop or 1
    activeContract.stage = 'Deliver cargo'
    activeContract.notice = 'Cargo verified. Drive to the first stop. Open the trunk, grab one package, and deliver it.'
    SetExpectedCompletionTime()

    local firstStop = activeContract.dropoffs and activeContract.dropoffs[1]
    if firstStop then
        SetActiveDestination(firstStop.label, firstStop.coords)
        CreateRouteBlip(firstStop.coords, firstStop.label, GetCargoDeliveryBlipType(activeContract.type))
    end

    Notify('Cargo verified. Delivery route started.', 'success')
    UpdateMiniUI()
end

local function GrabCargoFromVehicle()
    if not activeContract then return end
    if not IsCargoDoorOpen() then Notify('Open the vehicle trunk or rear cargo door before grabbing cargo.', 'error') return end
    if carryingCargo then Notify('You are already carrying cargo.', 'error') return end
    if not Progress('Grabbing cargo from open trunk...', Config.Progress.grabCargo, { dict = 'anim@heists@box_carry@', clip = 'idle' }) then return end
    local result = lib.callback.await('ls_trucking:server:grabCargoFromVehicle', false)
    if not result or not result.success then Notify(result and result.message or 'Could not grab cargo.', 'error') return end
    activeContract.currentCarryCargoType = result.cargoType
    CarryCargoProp(activeContract.type, result.cargoType)
    activeContract.notice = 'Carry the package to the current dropoff target.'
    Notify(('Grabbed %s. Take it to the dropoff target.'):format(result.label), 'success')
    UpdateMiniUI()
end


local function GetChecklistStatusText()
    local checklist = activeContract.loadChecklist or { truckSecure = false, trailerSecure = false }
    local trailerLabel = activeContract.trailerLabel or 'Assigned Trailer'

    local truckStatus = checklist.truckSecure and 'Complete' or 'Pending'
    local trailerStatus = checklist.trailerSecure and 'Complete' or 'Pending'
    local readyStatus = (checklist.truckSecure and checklist.trailerSecure) and 'Ready for dispatch confirmation' or 'Incomplete'

    return table.concat({
        ('**Assigned Trailer:** %s'):format(trailerLabel),
        '',
        '**Load Checklist**',
        ('- Truck Connection Secured: %s'):format(truckStatus),
        ('- Trailer Load Secured: %s'):format(trailerStatus),
        ('- Dispatch Status: %s'):format(readyStatus),
        '',
        '**Required Steps**',
        '1. Target the rear of the truck and secure the load connection.',
        '2. Target the rear of the trailer and confirm the load is secure.',
        '3. Return to the rear of the truck and complete the checklist.'
    }, '\n\n')
end

local function ShowTrailerLoadChecklist()
    if not activeContract or activeContract.type ~= 'trailer' then
        Notify('You do not have a trailer hauling contract.', 'error')
        return
    end

    ShowFreightDialog('Trailer Load Checklist', GetChecklistStatusText(), 'Close Checklist')
end

local function SecureTruckLoadConnection()
    if not activeContract or activeContract.type ~= 'trailer' then
        Notify('You do not have a trailer hauling contract.', 'error')
        return
    end

    if activeContract.trailerHooked then
        Notify('This trailer load is already cleared for delivery.', 'inform')
        return
    end

    if not IsAssignedTrailerAttached() then
        Notify('Hook up the assigned trailer before securing the load connection.', 'error')
        return
    end

    activeContract.loadChecklist = activeContract.loadChecklist or { truckSecure = false, trailerSecure = false }

    if activeContract.loadChecklist.truckSecure then
        Notify('Truck connection is already secured.', 'inform')
        return
    end

    if not Progress('Securing truck load connection...', Config.Progress.secureTruckLoad or 3000, {
        dict = 'mini@repair',
        clip = 'fixing_a_ped'
    }) then
        return
    end

    activeContract.loadChecklist.truckSecure = true
    PlayUISound('secure')
    activeContract.stage = 'Complete load checklist'
    activeContract.notice = 'Truck connection secured. Now target the rear of the trailer and confirm the load is secure.'
    SetActiveDestination('Rear of trailer')

    Notify('Truck connection secured.', 'success')
    UpdateMiniUI()
end

local function SecureTrailerLoad()
    if not activeContract or activeContract.type ~= 'trailer' then
        Notify('You do not have a trailer hauling contract.', 'error')
        return
    end

    if activeContract.trailerHooked then
        Notify('This trailer load is already cleared for delivery.', 'inform')
        return
    end

    if not IsAssignedTrailerAttached() then
        Notify('Hook up the assigned trailer before confirming the trailer load.', 'error')
        return
    end

    activeContract.loadChecklist = activeContract.loadChecklist or { truckSecure = false, trailerSecure = false }

    if activeContract.loadChecklist.trailerSecure then
        Notify('Trailer load is already confirmed secure.', 'inform')
        return
    end

    if not Progress('Confirming trailer load secure...', Config.Progress.secureTrailerLoad or 3000, {
        dict = 'mini@repair',
        clip = 'fixing_a_ped'
    }) then
        return
    end

    activeContract.loadChecklist.trailerSecure = true
    PlayUISound('secure')
    activeContract.stage = 'Complete load checklist'
    activeContract.notice = 'Trailer load confirmed secure. Return to the rear of the truck to complete the load checklist.'
    SetActiveDestination('Rear of truck')

    Notify('Trailer load confirmed secure.', 'success')
    UpdateMiniUI()
end

local function CompleteTrailerLoadChecklist()
    if not activeContract or activeContract.type ~= 'trailer' then
        Notify('You do not have a trailer hauling contract.', 'error')
        return
    end

    if activeContract.trailerHooked then
        Notify('This trailer load is already cleared for delivery.', 'inform')
        return
    end

    if not IsAssignedTrailerAttached() then
        Notify('Hook up the assigned trailer before completing the checklist.', 'error')
        return
    end

    local checklist = activeContract.loadChecklist or { truckSecure = false, trailerSecure = false }

    if not checklist.truckSecure or not checklist.trailerSecure then
        ShowTrailerLoadChecklist()
        Notify('Complete both checklist items before dispatch clears the route.', 'error')
        return
    end

    local confirmed = ShowFreightConfirm(
        'Complete Load Checklist',
        GetChecklistStatusText() .. '\n\nConfirm this load is secured and ready for dispatch?',
        'Confirm Dispatch',
        'Go Back'
    )

    if not confirmed then return end

    if not Progress('Submitting load checklist...', Config.Progress.completeLoadChecklist or 2500, {
        dict = 'missheistdockssetup1clipboard@base',
        clip = 'base'
    }, {
        model = `p_amb_clipboard_01`,
        bone = 18905,
        pos = vec3(0.10, 0.02, 0.08),
        rot = vec3(-80.0, 0.0, 0.0)
    }) then
        return
    end

    local result = lib.callback.await('ls_trucking:server:markTrailerHooked', false)
    if not result or not result.success then
        Notify(result and result.message or 'Could not clear trailer load for dispatch.', 'error')
        return
    end

    activeContract.trailerAttached = true
    activeContract.trailerHooked = true
    activeContract.loaded = true
    activeContract.stage = 'Deliver trailer'
    activeContract.notice = 'Checklist complete. Drive to the receiving yard and detach the trailer in the drop zone.'
    SetExpectedCompletionTime()
    SetActiveDestination(activeContract.trailerDrop.label, activeContract.trailerDrop.coords)

    CreateRouteBlip(activeContract.trailerDrop.coords, activeContract.trailerDrop.label, 'trailer')
    Notify('Load checklist complete. Delivery waypoint assigned.', 'success')
    UpdateMiniUI()
end

local function IsAtRearOfEntity(entity, coords, minRearOffset)
    if not entity or entity == 0 or not DoesEntityExist(entity) then return false end
    local checkCoords = coords or GetEntityCoords(PlayerPedId())
    local offset = GetOffsetFromEntityGivenWorldCoords(entity, checkCoords.x, checkCoords.y, checkCoords.z)
    return offset.y < (minRearOffset or -0.5)
end


local function AddVehicleCargoTarget()
    if vehicleTargetAdded then return end
    if not spawnedVehicle or not DoesEntityExist(spawnedVehicle) then return end
    AddTargetEntity(spawnedVehicle, {
        { name = 'ls_trucking_load_cargo_one', label = 'Load Carried Cargo', icon = 'fa-solid fa-box', distance = 3.0, canInteract = function() return activeContract ~= nil and activeContract.type ~= 'trailer' and carryingCargo and not activeContract.loaded and not activeContract.cargoReady end, onSelect = LoadCargoIntoVehicle },
        { name = 'ls_trucking_verify_loaded_cargo', label = 'Verify Loaded Cargo', icon = 'fa-solid fa-clipboard-check', distance = 3.0, canInteract = function() return activeContract ~= nil and activeContract.type ~= 'trailer' and activeContract.cargoReady and not activeContract.verifiedCargo and not carryingCargo end, onSelect = VerifyLoadedCargo },
        { name = 'ls_trucking_grab_cargo_one', label = 'Grab Delivery Cargo', icon = 'fa-solid fa-box-open', distance = 3.0, canInteract = function() return activeContract ~= nil and activeContract.loaded and activeContract.verifiedCargo and activeContract.type ~= 'trailer' and not carryingCargo end, onSelect = GrabCargoFromVehicle },
        { name = 'ls_trucking_view_load_checklist', label = 'View Load Checklist', icon = 'fa-solid fa-clipboard-list', distance = 3.0, canInteract = function(entity, distance, coords)
            return activeContract ~= nil
                and activeContract.type == 'trailer'
                and activeContract.trailerAttached
                and not activeContract.trailerHooked
                and IsAtRearOfEntity(spawnedVehicle, coords, -0.5)
        end, onSelect = ShowTrailerLoadChecklist },
        { name = 'ls_trucking_secure_truck_load', label = 'Secure Load Attached', icon = 'fa-solid fa-link', distance = 3.0, canInteract = function(entity, distance, coords)
            return activeContract ~= nil
                and activeContract.type == 'trailer'
                and activeContract.trailerAttached
                and not activeContract.trailerHooked
                and IsAssignedTrailerAttached()
                and not (activeContract.loadChecklist and activeContract.loadChecklist.truckSecure)
                and IsAtRearOfEntity(spawnedVehicle, coords, -0.5)
        end, onSelect = SecureTruckLoadConnection },
        { name = 'ls_trucking_complete_load_checklist', label = 'Complete Load Checklist', icon = 'fa-solid fa-clipboard-check', distance = 3.0, canInteract = function(entity, distance, coords)
            return activeContract ~= nil
                and activeContract.type == 'trailer'
                and activeContract.trailerAttached
                and not activeContract.trailerHooked
                and IsAssignedTrailerAttached()
                and IsAtRearOfEntity(spawnedVehicle, coords, -0.5)
        end, onSelect = CompleteTrailerLoadChecklist }
    })
    vehicleTargetAdded = true
end

local function AddTrailerLoadTarget()
    if trailerTargetAdded then return end
    if not spawnedTrailer or not DoesEntityExist(spawnedTrailer) then return end

    AddTargetEntity(spawnedTrailer, {
        {
            name = 'ls_trucking_secure_trailer_load',
            label = 'Confirm Load Secure',
            icon = 'fa-solid fa-shield-alt',
            distance = 3.5,
            canInteract = function(entity, distance, coords)
                return activeContract ~= nil
                    and activeContract.type == 'trailer'
                    and activeContract.trailerAttached
                    and not activeContract.trailerHooked
                    and IsAssignedTrailerAttached()
                    and not (activeContract.loadChecklist and activeContract.loadChecklist.trailerSecure)
                    and IsAtRearOfEntity(spawnedTrailer, coords, -1.0)
            end,
            onSelect = SecureTrailerLoad
        }
    })

    trailerTargetAdded = true
end

local function GetRandomTrailerSpawn(trailerDepot)
    local spawns = trailerDepot and trailerDepot.spawns or nil

    if not spawns or #spawns == 0 then
        local depots = Config.TrailerDepots or {}
        local depotKey = trailerDepot and trailerDepot.key or 'docks'
        local depot = depots[depotKey] or depots.docks
        spawns = depot and depot.spawns or nil
    end

    if not spawns or #spawns == 0 then
        return vector4(1244.30, -3184.92, 5.90, 90.0)
    end

    return spawns[math.random(1, #spawns)]
end

local function SpawnTrailerOnly(vehicleData, routeTrailer, trailerDepot)
    CleanupTrailerOnly()

    routeTrailer = routeTrailer or {}

    -- Trailer model comes from the route now. vehicleData is only the truck/tractor.
    local trailerModelName = routeTrailer.model or vehicleData.trailer
    local trailerModel = LoadModel(trailerModelName)

    if not trailerModel then return false end

    local s = GetRandomTrailerSpawn(trailerDepot)
    spawnedTrailer = CreateVehicle(trailerModel, s.x, s.y, s.z, s.w, true, false)

    if routeTrailer.livery ~= nil then
        SetVehicleLivery(spawnedTrailer, routeTrailer.livery)
    elseif vehicleData.trailerLivery ~= nil then
        SetVehicleLivery(spawnedTrailer, vehicleData.trailerLivery)
    end

    ApplyExtras(spawnedTrailer, routeTrailer.extras or vehicleData.trailerExtras)
    SetVehicleDirtLevel(spawnedTrailer, 0.0)

    spawnedTrailerStartBody = GetVehicleBodyHealth(spawnedTrailer)
    if spawnedTrailerStartBody <= 0.0 then spawnedTrailerStartBody = 1000.0 end
    SetModelAsNoLongerNeeded(trailerModel)

    Wait(250)
    AddTrailerLoadTarget()

    return true
end

local function SpawnJobVehicle(data)
    local contractType, vehicleData, plate = data.contractType, data.vehicle, data.plate
    local s = Config.Depot.vehicleSpawn
    if contractType == 'van' or contractType == 'boxtruck' then
        local model = LoadModel(vehicleData.model)
        if not model then return false end
        spawnedVehicle = CreateVehicle(model, s.x, s.y, s.z, s.w, true, false)
        SetVehicleNumberPlateText(spawnedVehicle, plate)
        SetVehicleOptions(spawnedVehicle, vehicleData, false)
        SetFuel(spawnedVehicle, vehicleData.fuel)
        GiveKeys(spawnedVehicle)
        SetModelAsNoLongerNeeded(model)
        Wait(500)
        AddVehicleCargoTarget()
        Notify(('Your %s is ready at the depot.'):format(vehicleData.label), 'success')
        return true
    elseif contractType == 'trailer' then
        local model = LoadModel(vehicleData.model or vehicleData.truck)
        if not model then return false end
        spawnedVehicle = CreateVehicle(model, s.x, s.y, s.z, s.w, true, false)
        SetVehicleNumberPlateText(spawnedVehicle, plate)
        SetVehicleOptions(spawnedVehicle, vehicleData, false)
        SetFuel(spawnedVehicle, vehicleData.fuel)
        GiveKeys(spawnedVehicle)
        SetModelAsNoLongerNeeded(model)
        if not SpawnTrailerOnly(vehicleData, data.contract and data.contract.routeTrailer, data.contract and data.contract.trailerDepot) then Notify('Unable to spawn trailer.', 'error') return false end
        Wait(500)
        AddVehicleCargoTarget()
        Notify(('Your %s is ready. Trailer is waiting at %s.'):format(vehicleData.label, data.contract and data.contract.trailerDepot and data.contract.trailerDepot.label or 'the trailer yard'), 'success')
        return true
    end
    return false
end

local function SpawnGarageVehicle(data)
    if spawnedVehicle and DoesEntityExist(spawnedVehicle) then Notify('You already have a company vehicle out. Return it first.', 'error') return end
    local vehicleType, vehicleData, plate = data.vehicleType, data.vehicle, data.plate
    local s = Config.Depot.garageSpawn
    local modelName = vehicleData.model or vehicleData.truck
    local model = LoadModel(modelName)
    if not model then return end
    spawnedVehicle = CreateVehicle(model, s.x, s.y, s.z, s.w, true, false)
    SetVehicleNumberPlateText(spawnedVehicle, plate)
    SetVehicleOptions(spawnedVehicle, vehicleData, false)
    ApplyVehicleProps(spawnedVehicle, data.props)
    SetFuel(spawnedVehicle, vehicleData.fuel)
    GiveKeys(spawnedVehicle)
    SetModelAsNoLongerNeeded(model)
    garageVehicle = { type = vehicleType, index = data.vehicleIndex, plate = plate, label = vehicleData.label, vehicleLabel = vehicleData.label }
    reusableVehicle = { type = vehicleType, index = data.vehicleIndex, label = vehicleData.label, vehicleLabel = vehicleData.label }
    AddVehicleCargoTarget()
    Notify(('Company vehicle spawned: %s. Customize it, use it for jobs, then return it to the dispatcher.'):format(vehicleData.label), 'success')
end

local function ReturnCompanyVehicle()
    if activeContract then Notify('Finish or cancel your active job before returning the vehicle.', 'error') return end
    if not spawnedVehicle or not DoesEntityExist(spawnedVehicle) then Notify('You do not have a company vehicle out.', 'error') return end
    local garageData = garageVehicle or reusableVehicle
    if not garageData then Notify('Could not identify this company vehicle.', 'error') return end
    if not Progress('Returning company vehicle...', Config.Progress.returnVehicle, { dict = 'missheistdockssetup1clipboard@base', clip = 'base' }) then return end
    local props = GetVehicleProps(spawnedVehicle)
    local plate = GetVehicleNumberPlateText(spawnedVehicle)
    local result = lib.callback.await('ls_trucking:server:returnGarageVehicle', false, garageData.type, garageData.index or 1, plate, json.encode(props))
    if not result or not result.success then Notify(result and result.message or 'Could not return vehicle.', 'error') return end
    CleanupJobVehicle()
    ClearRouteBlip()
    RemoveAllZones()
    if Config.ReturnVehicleBonusEnabled then TriggerServerEvent('ls_trucking:server:returnVehicleBonus') else Notify('Company vehicle returned and saved.', 'success') end
end

local function SpawnStaticPed(key, pedData)
    if spawnedPeds[key] and DoesEntityExist(spawnedPeds[key]) then return spawnedPeds[key] end
    local model = LoadModel(pedData.model)
    if not model then return nil end
    local ped = CreatePed(0, model, pedData.coords.x, pedData.coords.y, pedData.coords.z - 1.0, pedData.coords.w, false, true)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    if pedData.scenario then TaskStartScenarioInPlace(ped, pedData.scenario, 0, true) end
    SetModelAsNoLongerNeeded(model)
    spawnedPeds[key] = ped
    return ped
end

local function CollectCargoFromPed()
    if not activeContract then Notify('You do not have an active contract.', 'error') return end
    if activeContract.type == 'trailer' then Notify('Trailer hauling does not use cargo boxes.', 'error') return end
    if carryingCargo then Notify('Load the cargo you are carrying before collecting another item.', 'error') return end
    if not Progress('Collecting route cargo...', Config.Progress.collectCargo, { dict = 'missheistdockssetup1clipboard@base', clip = 'base' }) then return end
    local result = lib.callback.await('ls_trucking:server:pickupCargoOne', false)
    if not result or not result.success then Notify(result and result.message or 'Could not collect cargo.', 'error') return end
    activeContract.currentCarryCargoType = result.cargoType
    CarryCargoProp(activeContract.type, result.cargoType)
    activeContract.stage = 'Carry cargo to vehicle'
    activeContract.notice = ('Carry this item to your vehicle, open the trunk, and load it. Pickup: %s/%s.'):format(result.pickedUp, result.required)
    SetActiveDestination('Your delivery vehicle')
    Notify(('Picked up %s for %s (%s/%s). Open your trunk and load it.'):format(result.label, result.receiver or 'route receiver', result.pickedUp, result.required), 'success')
    UpdateMiniUI()
end

local function DespawnDeliveredTrailer()
    if not spawnedTrailer or not DoesEntityExist(spawnedTrailer) then return end

    local trailer = spawnedTrailer
    local delay = Config.TrailerDespawnAfterDelivery or 10000

    SetTimeout(delay, function()
        if trailer and DoesEntityExist(trailer) then
            DeleteEntity(trailer)
        end

        if spawnedTrailer == trailer then
            spawnedTrailer = nil
        end
    end)
end

local function FinalizeTrailerDelivery()
    if not activeContract or activeContract.type ~= 'trailer' then Notify('You do not have a trailer delivery to finalize.', 'error') return end
    if not activeContract.trailerDropped then Notify('Drop the trailer inside the receiving yard first.', 'error') return end
    local ok = Progress('Verifying manifest, signing receipt...', Config.Progress.finalizeTrailer, { dict = 'missheistdockssetup1clipboard@base', clip = 'base' }, { model = `p_amb_clipboard_01`, bone = 18905, pos = vec3(0.10, 0.02, 0.08), rot = vec3(-80.0, 0.0, 0.0) })
    if not ok then return end
    local damageData = { startBody = spawnedTrailerStartBody or 1000.0, endBody = 1000.0 }
    if spawnedTrailer and DoesEntityExist(spawnedTrailer) then
        damageData.endBody = GetVehicleBodyHealth(spawnedTrailer)
    end
    local result = lib.callback.await('ls_trucking:server:finalizeTrailerDelivery', false, damageData)
    if not result or not result.success then Notify(result and result.message or 'Could not finalize delivery.', 'error') return end
    Notify('Trailer delivery confirmed. The trailer will be cleared from the yard shortly.', 'success')
    DespawnDeliveredTrailer()
    CompleteRoute()
end

local function AddPickupPedTarget(ped, contractType)
    AddTargetEntity(ped, { { name = ('ls_trucking_collect_cargo_%s'):format(contractType), label = 'Collect Route Cargo', icon = 'fa-solid fa-box', distance = Config.TargetDistance, canInteract = function() return activeContract ~= nil and activeContract.type == contractType and activeContract.type ~= 'trailer' and not activeContract.loaded end, onSelect = CollectCargoFromPed } })
end

local function AddReceiverPedTarget(ped, contractType, routeIndex)
    AddTargetEntity(ped, { { name = ('ls_trucking_finalize_trailer_%s_%s'):format(contractType, routeIndex), label = 'Finalize Trailer Delivery', icon = 'fa-solid fa-clipboard-check', distance = Config.TargetDistance, canInteract = function() return activeContract ~= nil and activeContract.type == contractType and activeContract.routeIndex == routeIndex and activeContract.trailerDropped end, onSelect = FinalizeTrailerDelivery } })
end

local function SetupRouteTargets()
    RemoveAllZones()
    if not activeContract then return end
    if activeContract.type == 'van' or activeContract.type == 'boxtruck' then
        for index, stop in ipairs(activeContract.dropoffs or {}) do
            AddSphereZone(('dropoff_%s'):format(index), stop.coords, 2.0, { { name = ('ls_trucking_dropoff_%s'):format(index), label = ('Deliver Cargo - %s'):format(stop.label), icon = 'fa-solid fa-box-open', distance = 2.5, canInteract = function() return activeContract and activeContract.loaded and activeContract.currentStop == index and carryingCargo end, onSelect = function()
                if not activeContract or activeContract.currentStop ~= index then return end
                if not Progress('Delivering cargo...', Config.Progress.deliverCargo, { dict = 'pickup_object', clip = 'pickup_low' }) then return end
                local result = lib.callback.await('ls_trucking:server:deliverCargoOne', false)
                if not result or not result.success then Notify(result and result.message or 'Could not deliver cargo.', 'error') return end
                DeleteCarryProp()
                activeContract.loadedCargo = result.loaded
                activeContract.currentStop = result.currentStop
                if result.routeComplete then
                    CompleteRoute()
                else
                    local currentStop = activeContract.dropoffs[activeContract.currentStop]
                    if result.stopComplete then
                        SetActiveDestination(currentStop.label, currentStop.coords)
                        activeContract.notice = 'Stop complete. Drive to the next stop, open your trunk, and grab another item.'
                        CreateRouteBlip(currentStop.coords, currentStop.label, GetCargoDeliveryBlipType(activeContract.type))
                        Notify(('Stop complete. Continue to stop %s/%s.'):format(activeContract.currentStop, activeContract.totalStops), 'success')
                    else
                        SetActiveDestination(currentStop.label, currentStop.coords)
                        activeContract.notice = ('This stop still needs %s more item(s). Open your trunk and grab another.'):format(result.requiredAtStop - result.deliveredAtStop)
                        Notify(activeContract.notice, 'inform')
                    end
                end
                UpdateMiniUI()
            end } })
        end
    elseif activeContract.type == 'trailer' then
        AddSphereZone('trailer_drop', activeContract.trailerDrop.coords, activeContract.trailerDrop.radius or 18.0, { { name = 'ls_trucking_confirm_trailer_drop', label = 'Confirm Trailer Dropped In Yard', icon = 'fa-solid fa-warehouse', distance = 3.5, canInteract = function() return activeContract and activeContract.type == 'trailer' and activeContract.trailerHooked and not activeContract.trailerDropped end, onSelect = function()
            if IsAssignedTrailerAttached() then Notify('Detach the trailer inside the receiving yard first.', 'error') return end
            if not Progress('Confirming trailer drop in yard...', Config.Progress.confirmTrailerDrop or 2500, {
                dict = 'missheistdockssetup1clipboard@base',
                clip = 'base'
            }, {
                model = `p_amb_clipboard_01`,
                bone = 18905,
                pos = vec3(0.10, 0.02, 0.08),
                rot = vec3(-80.0, 0.0, 0.0)
            }) then return end
            activeContract.trailerDropped = true
            activeContract.stage = 'Talk to receiver'
            activeContract.notice = 'Talk to the receiving yard worker to finalize the trailer delivery.'
            SetActiveDestination(activeContract.receiverPed.label, vector3(activeContract.receiverPed.coords.x, activeContract.receiverPed.coords.y, activeContract.receiverPed.coords.z))
            CreateRouteBlip(vector3(activeContract.receiverPed.coords.x, activeContract.receiverPed.coords.y, activeContract.receiverPed.coords.z), activeContract.receiverPed.label, 'receiver')
            Notify('Trailer drop confirmed. Talk to the receiver to finalize.', 'success')
            UpdateMiniUI()
        end } })
    end
end

function CompleteRoute()
    if not activeContract then return end
    TriggerServerEvent('ls_trucking:server:routeComplete', activeContract.contractId)
    reusableVehicle = { type = activeContract.type, index = activeContract.vehicleIndex or (garageVehicle and garageVehicle.index) or 1, label = activeContract.priorityLabel and (activeContract.priorityLabel .. ' - ' .. activeContract.label) or activeContract.label, vehicleLabel = activeContract.vehicleLabel }
    activeContract.stage = 'Route complete'
    activeContract.notice = 'Return the vehicle to the dispatcher or start another job with the same vehicle.'
    SetActiveDestination('Return vehicle or start another job', Config.Depot.vehicleReturn)
    UpdateMiniUI()
    ClearRouteBlip()
    RemoveAllZones()
    CreateRouteBlip(Config.Depot.vehicleReturn, 'Return Vehicle - LS Freight Dispatcher', 'return')
    activeContract = nil
    SetTimeout(2500, HideMiniUI)
end

local function BuildCancelReasonOptions()
    local options = {}
    local reasons = Config.CancelPenalty and Config.CancelPenalty.Reasons or nil

    if reasons and #reasons > 0 then
        for _, reason in ipairs(reasons) do
            options[#options + 1] = {
                value = reason.value or reason.label,
                label = reason.label or reason.value
            }
        end
    else
        options = {
            { value = 'vehicle_damaged', label = 'Vehicle / trailer damaged' },
            { value = 'wrong_vehicle', label = 'Wrong vehicle selected' },
            { value = 'route_issue', label = 'Route issue / blocked destination' },
            { value = 'out_of_time', label = 'Out of time' },
            { value = 'player_choice', label = 'Changed my mind' },
            { value = 'other', label = 'Other' }
        }
    end

    return options
end

local function GetCancelReasonLabel(value)
    for _, option in ipairs(BuildCancelReasonOptions()) do
        if option.value == value then
            return option.label
        end
    end

    return tostring(value or 'Not specified')
end

local function ConfirmCancelContract()
    local repLoss = 0

    if Config.CancelPenalty and Config.CancelPenalty.Enabled then
        repLoss = tonumber(Config.CancelPenalty.ReputationLoss) or 0
    end

    return ShowFreightCancelDialog(repLoss, BuildCancelReasonOptions())
end

local function CancelActiveContract()
    if not activeContract then Notify('You do not have an active contract.', 'error') return end

    local reason = ConfirmCancelContract()
    if not reason then
        Notify('Route cancellation aborted.', 'inform')
        return
    end

    TriggerServerEvent('ls_trucking:server:cancelContract', GetCancelReasonLabel(reason))
    ClearRouteBlip()
    RemoveAllZones()
    DeleteCarryProp()
    activeContract = nil
    UpdateMiniUI()
end

local function GetTrailerHookStage(routeTrailer)
    if routeTrailer and routeTrailer.label then
        return ('Hook up %s'):format(routeTrailer.label)
    end

    if routeTrailer and routeTrailer.model then
        return ('Hook up %s'):format(routeTrailer.model)
    end

    return 'Hook up trailer'
end

local function StartLocalContract(data, reuseVehicle)
    local contract, contractType = data.contract, data.contractType
    local vehicleLabel = data.vehicle and data.vehicle.label or 'Company Vehicle'
    local trailerHookStage = GetTrailerHookStage(contract.routeTrailer)
    if reuseVehicle then
        if not CanReuseVehicle(contractType) then Notify('You cannot reuse your current vehicle for this contract.', 'error') TriggerServerEvent('ls_trucking:server:cancelContract', '__system_cleanup') return end
        ClearRouteBlip()
        if contractType == 'trailer' then
            if not SpawnTrailerOnly(data.vehicle, contract.routeTrailer, contract.trailerDepot) then Notify('Unable to spawn new trailer.', 'error') TriggerServerEvent('ls_trucking:server:cancelContract', '__system_cleanup') return end
        else
            AddVehicleCargoTarget()
        end
        Notify(('New route assigned using your current %s.'):format(vehicleLabel), 'success')
    else
        if Config.DeleteOldVehicleOnNewContract then CleanupJobVehicle() end
        if not SpawnJobVehicle(data) then Notify('Unable to spawn selected job vehicle.', 'error') TriggerServerEvent('ls_trucking:server:cancelContract', '__system_cleanup') return end
        garageVehicle = { type = contractType, index = data.vehicleIndex, plate = data.plate, label = vehicleLabel, vehicleLabel = vehicleLabel }
    end
    reusableVehicle = nil
    local notice = 'Go to the pickup worker. Collect one item, carry it to your vehicle, open the trunk, and load it.'
    local destination = contract.pickup.label
    local loaded, loadedCargo = false, 0
    if contractType == 'trailer' then
        notice = ('Drive to %s and hook up the assigned trailer: %s. After hooking up, complete the load checklist to start the route.'):format(contract.trailerDepot and contract.trailerDepot.label or 'the trailer yard', trailerHookStage:gsub('^Hook up%s+', ''))
        loadedCargo = 1
    end
    activeContract = { contractId = data.contractId, type = contractType, label = contract.label, priorityLabel = contract.priorityLabel, routeLabel = contract.routeLabel, routeLength = contract.routeLength, routeIndex = data.routeIndex, cargo = contract.cargo, payout = data.payout, plate = data.plate, vehicleIndex = data.vehicleIndex, stage = contractType == 'trailer' and trailerHookStage or 'Talk to pickup worker', notice = notice, pickup = contract.pickup, dropoffs = contract.dropoffs, trailerDrop = contract.trailerDrop, receiverPed = contract.receiverPed, currentStop = 0, totalStops = contract.dropoffs and #contract.dropoffs or 1, loaded = loaded, loadedCargo = loadedCargo, requiredCargo = contract.requiredCargo or 1, destination = destination, vehicleLabel = vehicleLabel, trailerAttached = false, trailerHooked = false, trailerDropped = false, loadChecklist = { truckSecure = false, trailerSecure = false }, estimatedSeconds = contract.estimatedSeconds, estimatedTime = contract.estimatedTime, randomEvent = contract.randomEvent, routeTrailer = contract.routeTrailer, trailerDepot = contract.trailerDepot, trailerLabel = contract.routeTrailer and contract.routeTrailer.label or nil, trailerContents = contract.routeTrailer and contract.routeTrailer.contents or nil, trailerInstructions = contract.routeTrailer and contract.routeTrailer.instructions or nil, safeSpeed = contract.routeTrailer and contract.routeTrailer.safeSpeed or (Config.SpeedRisk and Config.SpeedRisk.DefaultSafeSpeed) or 75.0, cargoType = contract.cargoType, cargoItem = contract.cargoItem, cargoLabel = contract.cargoLabel, cargoConfig = contract.cargoType and Config.CargoTypes and Config.CargoTypes[contract.cargoType] or nil, manifest = contract.manifest, cargoReady = false, verifiedCargo = false }
    SetActiveDestination(contract.pickup.label, contract.pickup.coords)
    SetupRouteTargets()
    CreateRouteBlip(contract.pickup.coords, contract.pickup.label, 'pickup')
    if contract.randomEvent then
        Notify(('Dispatch Event: %s - %s'):format(contract.randomEvent.label or 'Route Update', contract.randomEvent.description or 'Route conditions changed.'), 'inform')
    end
    UpdateMiniUI()
    Notify(contractType == 'trailer' and ('Contract accepted. Go to the docks and %s.'):format(trailerHookStage:sub(1, 1):lower() .. trailerHookStage:sub(2)) or 'Contract accepted. Go to the pickup worker to collect route cargo.', 'success')
end


local function ShowActiveManifest()
    if not activeContract then
        Notify('You do not have an active delivery manifest.', 'error')
        return
    end

    local lines = {}

    local function AddField(label, value)
        if value == nil or value == '' then return end
        lines[#lines + 1] = ('%s: %s'):format(label, tostring(value))
    end

    AddField('Driver', currentDriverInfo and currentDriverInfo.name or GetPlayerName(PlayerId()) or 'Driver')
    AddField('Job / Grade', currentDriverInfo and (currentDriverInfo.jobText or currentDriverInfo.jobLabel) or 'Unknown')
    AddField('Printed', GetClientTimestamp())
    AddField('Contract', activeContract.contractId)
    AddField('Route', activeContract.routeLabel)
    AddField('Load Type', activeContract.priorityLabel)

    if activeContract.type == 'trailer' then
        AddField('Pickup Depot', activeContract.trailerDepot and activeContract.trailerDepot.label or 'Trailer Pickup Yard')
        AddField('Trailer', activeContract.trailerLabel or 'Assigned Trailer')
        AddField('Contents', activeContract.trailerContents or 'Trailer Freight')
        AddField('Safe Speed', ('%s MPH'):format(math.floor(tonumber(activeContract.safeSpeed) or 75)))
        AddField('Dropoff', activeContract.trailerDrop and activeContract.trailerDrop.label or 'Receiving Yard')

        lines[#lines + 1] = ''
        lines[#lines + 1] = 'Instructions'
        lines[#lines + 1] = '------------'
        local instructions = activeContract.trailerInstructions or { 'Complete the load checklist, deliver the trailer, detach it inside the receiving yard, then talk to the receiver.' }
        if type(instructions) == 'string' then instructions = { instructions } end
        for _, instruction in ipairs(instructions) do
            lines[#lines + 1] = ('- %s'):format(instruction)
        end
    else
        AddField('Cargo', activeContract.cargoLabel or activeContract.cargo)

        lines[#lines + 1] = ''
        lines[#lines + 1] = 'Delivery Stops'
        lines[#lines + 1] = '--------------'

        local groupedStops = {}
        local orderedStops = {}

        for _, entry in ipairs(activeContract.manifest or {}) do
            local stopKey = entry.stop or entry.dropoff or entry.receiver or (#orderedStops + 1)

            if not groupedStops[stopKey] then
                groupedStops[stopKey] = {
                    stop = entry.stop or (#orderedStops + 1),
                    receiver = entry.receiver or entry.dropoff or 'Receiver',
                    dropoff = entry.dropoff or entry.receiver or 'Dropoff',
                    count = 0,
                    cargo = {}
                }

                orderedStops[#orderedStops + 1] = stopKey
            end

            groupedStops[stopKey].count = groupedStops[stopKey].count + 1

            local cargoLabel = entry.cargoLabel or entry.label or 'Delivery Cargo'
            groupedStops[stopKey].cargo[cargoLabel] = (groupedStops[stopKey].cargo[cargoLabel] or 0) + 1
        end

        table.sort(orderedStops, function(a, b)
            local left = groupedStops[a] and groupedStops[a].stop or 0
            local right = groupedStops[b] and groupedStops[b].stop or 0
            return left < right
        end)

        for index, stopKey in ipairs(orderedStops) do
            local stop = groupedStops[stopKey]
            local cargoParts = {}

            for cargoLabel, amount in pairs(stop.cargo or {}) do
                cargoParts[#cargoParts + 1] = ('%s x%s'):format(cargoLabel, amount)
            end

            table.sort(cargoParts)

            lines[#lines + 1] = ('Stop %s - %s'):format(index, stop.receiver)
            lines[#lines + 1] = ('  Dropoff: %s'):format(stop.dropoff)
            lines[#lines + 1] = ('  Packages: %s'):format(#cargoParts > 0 and table.concat(cargoParts, ', ') or tostring(stop.count))
        end
    end

    ShowFreightDialog('Delivery Manifest', lines, 'Close Manifest')
end

RegisterNetEvent('ls_trucking:client:openManifest', ShowActiveManifest)

function OpenDispatch()
    local data = lib.callback.await('ls_trucking:server:getDispatchData', false)
    if not data or not data.allowed then Notify(data and data.message or 'Unable to open trucking dispatch.', 'error') return end
    currentDriverInfo = data.player or currentDriverInfo
    data.reuse = GetReuseData()
    data.config = { allowVehicleReuseAfterRoute = Config.AllowVehicleReuseAfterRoute, requireSameTypeForVehicleReuse = Config.RequireSameTypeForVehicleReuse, radioFrequency = Config.RadioFrequency, uiSounds = Config.UI or {} }
    data.lastRouteSummary = lastRouteSummary
    if activeContract then data.currentJob = { id = activeContract.contractId, type = activeContract.type, label = activeContract.priorityLabel and (activeContract.priorityLabel .. ' - ' .. activeContract.label) or activeContract.label, stage = activeContract.stage, payout = activeContract.payout, loadedCargo = activeContract.loadedCargo, requiredCargo = activeContract.requiredCargo, currentStop = activeContract.currentStop, totalStops = activeContract.totalStops } end
    StartTabletAnim()
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', data = data })
end

RegisterNetEvent('ls_trucking:client:openDispatch', OpenDispatch)
RegisterNetEvent('ls_trucking:client:toggleMiniUI', function() miniUIVisible = not miniUIVisible UpdateMiniUI() end)

RegisterCommand(Config.Command, OpenDispatch, false)
RegisterCommand(Config.MiniUIToggleCommand, function() miniUIVisible = not miniUIVisible UpdateMiniUI() end, false)
RegisterCommand(Config.CancelCommand, CancelActiveContract, false)

RegisterNUICallback('freightDialogClose', function(_, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'hideFreightDialog' })

    if freightDialogPromise then
        freightDialogPromise:resolve({ confirmed = false })
        freightDialogPromise = nil
    end

    cb(true)
end)

RegisterNUICallback('freightDialogResult', function(data, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'hideFreightDialog' })

    if freightDialogPromise then
        freightDialogPromise:resolve(data or { confirmed = false })
        freightDialogPromise = nil
    end

    cb(true)
end)
RegisterNUICallback('close', function(_, cb) StopTabletAnim() SetNuiFocus(false, false) SendNUIMessage({ action = 'close' }) cb(true) end)
RegisterNUICallback('startContract', function(data, cb)
    local contractType = data and data.contractType
    local vehicleIndex = data and data.vehicleIndex or 1
    local reuseVehicle = data and data.reuseVehicle == true
    local priorityKey = data and data.priorityKey or 'standard'
    local currentPlate = reuseVehicle and GetJobVehiclePlate() or nil
    if not contractType then cb({ success = false }) return end
    if activeContract then Notify('You already have an active job. Cancel it from the Current Job panel first.', 'error') cb({ success = false }) return end
    if reuseVehicle and not CanReuseVehicle(contractType) then Notify('Your current vehicle cannot be reused for this contract type.', 'error') cb({ success = false }) return end
    local result = lib.callback.await('ls_trucking:server:createContract', false, contractType, vehicleIndex, reuseVehicle, currentPlate, priorityKey)
    if not result or not result.success then Notify(result and result.message or 'Unable to start contract.', 'error') cb({ success = false }) return end
    StopTabletAnim()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    StartLocalContract(result, reuseVehicle)
    cb({ success = true })
end)

RegisterNUICallback('cancelCurrentJob', function(_, cb)
    StopTabletAnim()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    Wait(100)
    CancelActiveContract()
    cb(true)
end)
RegisterNUICallback('spawnGarageVehicle', function(data, cb)
    if activeContract then Notify('You cannot spawn a garage vehicle while on a job.', 'error') cb({ success = false }) return end
    if spawnedVehicle and DoesEntityExist(spawnedVehicle) then Notify('You already have a company vehicle out. Return it first.', 'error') cb({ success = false }) return end
    if not data or not data.vehicleType or not data.vehicleIndex then cb({ success = false }) return end
    if not Progress('Requesting company vehicle...', Config.Progress.spawnGarageVehicle, { dict = 'missheistdockssetup1clipboard@base', clip = 'base' }) then cb({ success = false }) return end
    local result = lib.callback.await('ls_trucking:server:spawnGarageVehicle', false, data.vehicleType, data.vehicleIndex)
    if not result or not result.success then Notify(result and result.message or 'Unable to spawn garage vehicle.', 'error') cb({ success = false }) return end
    StopTabletAnim()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    SpawnGarageVehicle(result)
    cb({ success = true })
end)
RegisterNUICallback('returnGarageVehicle', function(_, cb) StopTabletAnim() SetNuiFocus(false, false) SendNUIMessage({ action = 'close' }) ReturnCompanyVehicle() cb(true) end)


local function FormatSummarySeconds(seconds)
    seconds = tonumber(seconds) or 0
    seconds = math.max(0, math.floor(seconds))

    local minutes = math.floor(seconds / 60)
    local secs = seconds % 60

    if minutes >= 60 then
        local hours = math.floor(minutes / 60)
        local mins = minutes % 60
        return ('%sh %sm'):format(hours, mins)
    end

    return ('%sm %02ds'):format(minutes, secs)
end

local function FormatPercent(percent)
    percent = tonumber(percent) or 0.0
    local sign = percent > 0 and '+' or ''
    return ('%s%s%%'):format(sign, math.floor(percent * 100))
end

local function GetContractTypeLabel(contractType)
    if contractType == 'van' then return 'Van Delivery' end
    if contractType == 'boxtruck' then return 'Box Truck Delivery' end
    if contractType == 'trailer' then return 'Trailer Hauling' end
    return tostring(contractType or 'Delivery')
end

local function ShowRouteSummary(data)
    if not data then return end

    local lines = {}
    local timeData = data.time or {}
    local elapsed = timeData.elapsedSeconds or 0
    local estimated = timeData.estimatedSeconds or data.estimatedSeconds or 0
    local timingStatus = timeData.label or 'Delivery complete'

    local function AddSection(title)
        if #lines > 0 then
            lines[#lines + 1] = ''
        end

        lines[#lines + 1] = tostring(title)
        lines[#lines + 1] = string.rep('-', #tostring(title))
    end

    local function AddField(label, value)
        if value == nil then return end
        value = tostring(value)
        if value == '' then return end

        lines[#lines + 1] = ('%s: %s'):format(label, value)
    end

    AddSection('Contract Information')
    AddField('Driver', data.driverName or (currentDriverInfo and currentDriverInfo.name) or GetPlayerName(PlayerId()) or 'Driver')
    AddField('Job / Grade', data.jobText or (currentDriverInfo and (currentDriverInfo.jobText or currentDriverInfo.jobLabel)) or 'Unknown')
    AddField('Completed At', data.completedAt or GetClientTimestamp())
    AddField('Contract Type', GetContractTypeLabel(data.contractType))
    AddField('Load Type', data.priorityLabel)
    AddField('Route', data.routeLabel)
    AddField('Route Length', data.routeLength)
    AddField('Vehicle', data.vehicleLabel)

    AddSection('Delivery Time')
    AddField('Estimated Time', FormatSummarySeconds(estimated))
    AddField('Completed In', FormatSummarySeconds(elapsed))
    AddField('Timing Result', timingStatus)

    if data.randomEvent and data.randomEvent.label then
        AddSection('Dispatch Event')
        AddField('Event', data.randomEvent.label)
        AddField('Details', data.randomEvent.description)
    end

    if data.contractType == 'trailer' then
        AddSection('Trailer Condition')
        AddField('Trailer Damage', ('%s%%'):format(math.floor(tonumber(data.damagePercent) or 0.0)))
    end

    local adjustmentLines = {}

    if data.adjustments then
        for _, adj in ipairs(data.adjustments) do
            if adj and adj.percent and adj.percent ~= 0 then
                adjustmentLines[#adjustmentLines + 1] = {
                    label = adj.label or 'Adjustment',
                    value = FormatPercent(adj.percent)
                }
            end
        end
    end

    AddSection('Payout Summary')
    AddField('Base Payout', ('$%s'):format(data.basePayout or data.payout or 0))

    if #adjustmentLines > 0 then
        lines[#lines + 1] = 'Payout Adjustments:'

        for _, adjustment in ipairs(adjustmentLines) do
            lines[#lines + 1] = ('  - %s: %s'):format(adjustment.label, adjustment.value)
        end
    else
        AddField('Payout Adjustments', 'None')
    end

    AddField('Final Payout', ('$%s'):format(data.payout or 0))
    AddField('XP Earned', data.xp or 0)
    AddField('Reputation Earned', data.rep or 0)

    ShowFreightDialog('Los Santos Freight Co. Route Summary', lines, 'Close Summary')
end

RegisterNetEvent('ls_trucking:client:routePaid', function(data)
    -- Save the latest route summary so it can be shown on the Current Job tab.
    SaveLastRouteSummary(data)

    -- Route completion is shown with an ox_lib alert dialog instead of a notify.
    ShowRouteSummary(data)
end)
RegisterNetEvent('ls_trucking:client:returnBonusPaid', function(amount) Notify(('Company vehicle returned and saved. Bonus paid: $%s.'):format(amount), 'success') end)

RegisterNetEvent('ls_trucking:client:contractCancelled', function(data)
    data = data or {}
    local repLoss = tonumber(data.repLoss) or 0
    local reason = data.reason or 'Not specified'

    Notify(('Route cancelled. Reason: %s. Reputation lost: %s.'):format(reason, repLoss), 'error')
end)

CreateThread(function()
    if Config.UseBlip then
        local blip = AddBlipForCoord(Config.DispatchBlip.coords.x, Config.DispatchBlip.coords.y, Config.DispatchBlip.coords.z)
        SetBlipSprite(blip, Config.DispatchBlip.sprite)
        SetBlipColour(blip, Config.DispatchBlip.color)
        SetBlipScale(blip, Config.DispatchBlip.scale)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING') AddTextComponentString(Config.DispatchBlip.label) EndTextCommandSetBlipName(blip)
    end
    if Config.UsePed then
        local model = LoadModel(Config.DispatchPed.model)
        if model then
            dispatchPed = CreatePed(0, model, Config.DispatchPed.coords.x, Config.DispatchPed.coords.y, Config.DispatchPed.coords.z - 1.0, Config.DispatchPed.coords.w, false, true)
            FreezeEntityPosition(dispatchPed, true)
            SetEntityInvincible(dispatchPed, true)
            SetBlockingOfNonTemporaryEvents(dispatchPed, true)
            if Config.DispatchPed.scenario then TaskStartScenarioInPlace(dispatchPed, Config.DispatchPed.scenario, 0, true) end
            AddTargetEntity(dispatchPed, {
                { name = 'ls_trucking_open_dispatch_ped', label = 'Open Freight Dispatch', icon = 'fa-solid fa-tablet-screen-button', distance = Config.TargetDistance, onSelect = OpenDispatch },
                { name = 'ls_trucking_return_company_vehicle', label = 'Return Company Vehicle', icon = 'fa-solid fa-rotate-left', distance = Config.TargetDistance, canInteract = function() return spawnedVehicle ~= nil and DoesEntityExist(spawnedVehicle) and activeContract == nil end, onSelect = ReturnCompanyVehicle }
            })
            SetModelAsNoLongerNeeded(model)
        end
    end
    if Config.UseTerminalTargetZone then
        AddSphereZone('ls_trucking_open_dispatch_terminal', Config.Depot.terminal, 2.0, { { name = 'ls_trucking_open_dispatch_terminal', label = 'Open Freight Dispatch', icon = 'fa-solid fa-tablet-screen-button', distance = Config.TargetDistance, onSelect = OpenDispatch } })
    end
    for contractType, contract in pairs(Config.Contracts) do
        if contract.pickupPed then local ped = SpawnStaticPed(('pickup_%s'):format(contractType), contract.pickupPed) if ped then AddPickupPedTarget(ped, contractType) end end
        if contract.routes then for routeIndex, route in ipairs(contract.routes) do if route.receiverPed then local ped = SpawnStaticPed(('receiver_%s_%s'):format(contractType, routeIndex), route.receiverPed) if ped then AddReceiverPedTarget(ped, contractType, routeIndex) end end end end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    StopTabletAnim()
    ClearRouteBlip()
    RemoveAllZones()
    CleanupJobVehicle()
    if dispatchPed and DoesEntityExist(dispatchPed) then DeleteEntity(dispatchPed) end
    for _, ped in pairs(spawnedPeds) do if ped and DoesEntityExist(ped) then DeleteEntity(ped) end end
end)
