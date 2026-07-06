LS_Trucking = LS_Trucking or {}

local activeContract = nil
local reusableVehicle = nil
local activeBlip = nil
local activeAreaBlip = nil
local spawnedVehicle = nil
local spawnedTrailer = nil
local spawnedTrailerStartBody = 1000.0
local carryingProp = nil
local carryingCargo = false
local garageVehicle = nil
local contractorVehicle = nil
local fullReceiverVisible = false
local dispatchUIVisible = false
local dispatchPed = nil
local spawnedPeds = {}
local activeContractPedKeys = {}
local zones = {}
local vehicleTargetAdded = false
local trailerTargetAdded = false

local Notify

local tabletOpen = false
local tabletProp = nil
local tabletStopToken = 0
local receiverProp = nil
local receiverStopToken = 0
local receiverAccessPending = false
local receiverDockUserHidden = false
local miniDockVisible = false
local miniFullVisible = false
local commandSuggestions = {}
local contractorBoardRefreshToken = 0
local receiverControlBlockUntil = 0
local dispatchActiveTab = 'home'
local freightHandoffPending = false

local VEHICLE_SPAWN_INTERACTION_DISTANCE = 20.0
local VEHICLE_RETURN_INTERACTION_DISTANCE = 20.0

local cargoConditionLastHealth = nil
local cargoConditionLastSpeed = 0.0
local cargoConditionSpeedingSince = nil
local cargoConditionIncidentCooldown = 0

local RouteHistory = LS_Trucking and LS_Trucking.RouteHistory or {}
local GetClientTimestamp = RouteHistory.GetClientTimestamp or function() return 'Current Session' end
local ReceiverVehicleControls = LS_Trucking and LS_Trucking.ReceiverVehicleControls or {}
local SpawnUtils = LS_Trucking and LS_Trucking.SpawnUtils or {}
local DepotVehicles = LS_Trucking and LS_Trucking.DepotVehicles or {}
local RouteState = LS_Trucking and LS_Trucking.RouteState or {}
local Routes = LS_Trucking and LS_Trucking.Routes or {}
local ContractorUI = LS_Trucking and LS_Trucking.ContractorUI or {}
local TrailerCargoEditor = LS_Trucking and LS_Trucking.TrailerCargoEditor or {}
local TrailerCargoTester = LS_Trucking and LS_Trucking.TrailerCargoTester or {}
local ServiceBay = LS_Trucking and LS_Trucking.ServiceBay or {}

local function GetConfigCoords3(coords)
    if not coords then return nil end
    return vector3(coords.x, coords.y, coords.z)
end

local function IsPlayerNearCoords(coords, distance)
    local targetCoords = GetConfigCoords3(coords)
    if not targetCoords then return true end
    local ped = PlayerPedId()
    local playerCoords = GetEntityCoords(ped)
    return #(playerCoords - targetCoords) <= (distance or 20.0)
end

local function ForceDepotDistanceNotify(message)
    message = message or 'You are too far away from the depot.'

    if lib and lib.notify then
        lib.notify({
            title = (Config.Notifications and Config.Notifications.Title) or 'Los Santos Freight Co.',
            description = message,
            type = 'error',
            duration = (Config.Notifications and Config.Notifications.Duration) or Config.NotificationDuration or 8500
        })
        return
    end

    if Notify then
        Notify(message, 'error')
    end
end

local function RequireNearCoords(coords, distance, message, forceNotify)
    if IsPlayerNearCoords(coords, distance) then return true end

    if forceNotify then
        ForceDepotDistanceNotify(message or 'You are too far away from the depot.')
    elseif Notify then
        Notify(message or 'You are too far away.', 'error')
    end

    return false
end

local function RequireNearDepotRequestArea(message)
    if DepotVehicles.RequireNearDepotRequestArea then
        return DepotVehicles.RequireNearDepotRequestArea(message)
    end

    ForceDepotDistanceNotify(message or 'You need to be closer to the LS Freight depot.')
    return false
end


local currentDriverInfo = nil
local lastCompletedCargoCondition = nil

RouteHistory.Load()

local function PlayUISound(soundType)
    SendNUIMessage({ action = 'playSound', sound = soundType or 'click' })
end

local function SetKeepInput(enabled)
    if SetNuiFocusKeepInput then
        SetNuiFocusKeepInput(enabled == true)
    end
end

local function BlockReceiverPauseControls()
    DisableControlAction(0, 177, true) -- frontend cancel / back
    DisableControlAction(0, 199, true) -- pause
    DisableControlAction(0, 200, true) -- pause alternate
    DisableControlAction(0, 322, true) -- escape
    DisableControlAction(2, 177, true)
    DisableControlAction(2, 199, true)
    DisableControlAction(2, 200, true)
    DisableControlAction(2, 322, true)
end

local function StopReceiverAnim()
    receiverStopToken = receiverStopToken + 1

    local ped = PlayerPedId()
    ClearPedSecondaryTask(ped)

    if receiverProp and DoesEntityExist(receiverProp) then
        DeleteEntity(receiverProp)
    end

    receiverProp = nil
end

local function StopReceiverAnimDeferred(delay)
    receiverStopToken = receiverStopToken + 1
    local token = receiverStopToken

    CreateThread(function()
        Wait(delay or 360)

        if token ~= receiverStopToken or fullReceiverVisible then return end
        StopReceiverAnim()
    end)
end

local function StartReceiverAnim()
    receiverStopToken = receiverStopToken + 1
    StopReceiverAnim()

    local ped = PlayerPedId()
    local dict = 'cellphone@'
    local anim = 'cellphone_text_read_base'
    local model = `prop_npc_phone_02`

    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(0) end

    RequestModel(model)
    while not HasModelLoaded(model) do Wait(0) end

    local coords = GetEntityCoords(ped)
    receiverProp = CreateObject(model, coords.x, coords.y, coords.z, true, true, false)

    AttachEntityToEntity(
        receiverProp,
        ped,
        GetPedBoneIndex(ped, 28422),
        0.00, 0.00, 0.0,   
        0.0, 0.0, 0.0,
        true, true, false, true, 1, true
    )

    TaskPlayAnim(ped, dict, anim, 3.0, 3.0, -1, 49, 0, false, false, false)
    SetModelAsNoLongerNeeded(model)
end

local function StopTabletAnim()
    tabletStopToken = tabletStopToken + 1
    tabletOpen = false

    local ped = PlayerPedId()
    ClearPedSecondaryTask(ped)

    if tabletProp and DoesEntityExist(tabletProp) then
        DeleteEntity(tabletProp)
    end

    tabletProp = nil
end

local function StopTabletAnimDeferred(delay)
    tabletStopToken = tabletStopToken + 1
    local token = tabletStopToken
    tabletOpen = false

    CreateThread(function()
        Wait(delay or 180)

        if token ~= tabletStopToken or dispatchUIVisible then return end

        if fullReceiverVisible then
            if tabletProp and DoesEntityExist(tabletProp) then
                DeleteEntity(tabletProp)
            end

            tabletProp = nil
            return
        end

        StopTabletAnim()
    end)
end

local function StopTabletAnimForDispatchClose()
    if fullReceiverVisible then
        StopTabletAnim()
        return
    end

    StopTabletAnimDeferred(420)
end

local function StartTabletAnim()
    tabletStopToken = tabletStopToken + 1
    StopReceiverAnim()
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

CreateThread(function()
    while true do
        if fullReceiverVisible and not dispatchUIVisible then
            local ped = PlayerPedId()

            if not receiverProp or not DoesEntityExist(receiverProp) then
                StartReceiverAnim()
            elseif not IsEntityPlayingAnim(ped, 'cellphone@', 'cellphone_text_read_base', 3) then
                TaskPlayAnim(ped, 'cellphone@', 'cellphone_text_read_base', 3.0, 3.0, -1, 49, 0, false, false, false)
            end

            Wait(1500)
        else
            if receiverProp and DoesEntityExist(receiverProp) then
                StopReceiverAnim()
            end

            Wait(1000)
        end
    end
end)

CreateThread(function()
    while true do
        local receiverInputActive = fullReceiverVisible and not dispatchUIVisible
        local blockPauseAfterClose = receiverControlBlockUntil > GetGameTimer()

        if receiverInputActive or blockPauseAfterClose then
            BlockReceiverPauseControls()

            if receiverInputActive then
                DisableControlAction(0, 1, true) -- look left/right
                DisableControlAction(0, 2, true) -- look up/down
                DisableControlAction(0, 3, true) -- look up only
                DisableControlAction(0, 4, true) -- look down only
                DisableControlAction(0, 5, true) -- look left only
                DisableControlAction(0, 6, true) -- look right only
                DisableControlAction(0, 24, true) -- attack
                DisableControlAction(0, 25, true) -- aim
                DisableControlAction(0, 68, true) -- vehicle aim
                DisableControlAction(0, 69, true) -- vehicle attack
                DisableControlAction(0, 70, true) -- vehicle attack 2
                DisableControlAction(0, 81, true) -- vehicle radio next
                DisableControlAction(0, 82, true) -- vehicle radio previous
                DisableControlAction(0, 83, true) -- vehicle radio next track
                DisableControlAction(0, 84, true) -- vehicle radio previous track
                DisableControlAction(0, 85, true) -- vehicle radio wheel
                DisableControlAction(0, 91, true) -- passenger aim
                DisableControlAction(0, 92, true) -- passenger attack
                DisableControlAction(0, 106, true) -- vehicle mouse look override
            end

            Wait(0)
        else
            Wait(500)
        end
    end
end)

function Notify(message, notifyType)
    notifyType = notifyType or 'inform'

    local soundMap = Config.Notifications and Config.Notifications.SoundMap or {}
    local notifySound = soundMap[notifyType]

    if notifySound == nil and (notifyType == 'warning' or notifyType == 'error') then
        notifySound = 'alert'
    end

    if notifySound and (not Config.Notifications or Config.Notifications.Sounds ~= false) then
        PlayUISound(notifySound)
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
local freightDialogReturnFocus = false

local function ShowFreightDialog(header, lines, closeLabel)
    if type(lines) == 'table' then
        lines = table.concat(lines, '\n')
    end

    freightDialogReturnFocus = tabletOpen == true or fullReceiverVisible == true
    SetKeepInput(false)
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'showFreightDialog',
        mode = 'info',
        locale = Config.Locale or 'en',
        header = header or 'Los Santos Freight Co.',
        content = lines or '',
        closeLabel = closeLabel
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

    freightDialogReturnFocus = tabletOpen == true or fullReceiverVisible == true
    SetKeepInput(false)
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'showFreightDialog',
        mode = 'confirm',
        locale = Config.Locale or 'en',
        header = header or 'Los Santos Freight Co.',
        content = lines or '',
        confirmLabel = confirmLabel,
        cancelLabel = cancelLabel
    })

    local result = Citizen.Await(p)
    return result and result.confirmed == true
end

local function ShowFreightHandoff(mode, pedLabel, manifest)
    if freightDialogPromise then
        freightDialogPromise:resolve({ confirmed = false })
        freightDialogPromise = nil
    end

    local p = promise.new()
    freightDialogPromise = p

    freightDialogReturnFocus = tabletOpen == true or fullReceiverVisible == true
    SetKeepInput(false)
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'showFreightHandoff',
        mode = mode,
        locale = Config.Locale or 'en',
        pedLabel = pedLabel or 'Freight Clerk',
        signerName = currentDriverInfo and currentDriverInfo.name or GetPlayerName(PlayerId()) or 'Assigned Driver',
        contracts = { manifest }
    })

    local result = Citizen.Await(p)
    return result or { confirmed = false }
end

local function ShowFreightCancelDialog(repLoss, reasons)
    if freightDialogPromise then
        freightDialogPromise:resolve({ confirmed = false })
        freightDialogPromise = nil
    end

    local p = promise.new()
    freightDialogPromise = p

    freightDialogReturnFocus = tabletOpen == true or fullReceiverVisible == true
    SetKeepInput(false)
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'showFreightCancelDialog',
        locale = Config.Locale or 'en',
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
    for extraKey, enabled in pairs(extras) do
        local extraId = tonumber(extraKey)
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

local function RemoveKeys(vehicle, plate)
    plate = plate or (vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) and GetVehicleNumberPlateText(vehicle)) or nil
    if Config.RemoveVehicleKeys then
        Config.RemoveVehicleKeys(vehicle, plate)
    end
end

local function NormalizeKeyPlate(plate)
    return tostring(plate or ''):upper():gsub('%s+', '')
end

local function FindVehicleByPlate(plate)
    local normalized = NormalizeKeyPlate(plate)
    if normalized == '' then return nil end

    for _, vehicle in ipairs(GetGamePool('CVehicle')) do
        if DoesEntityExist(vehicle) and NormalizeKeyPlate(GetVehicleNumberPlateText(vehicle)) == normalized then
            return vehicle
        end
    end

    return nil
end

RegisterNetEvent('ls_trucking:client:syncVehicleKeyOwner', function(plate, ownerServerId)
    if Config.Keys and Config.Keys.OwnerOnly == false then return end
    if tonumber(ownerServerId) == GetPlayerServerId(PlayerId()) then return end

    local vehicle = FindVehicleByPlate(plate)
    RemoveKeys(vehicle, plate)
end)

local function CoerceServiceBoolean(value)
    if value == true or value == 1 or value == '1' or value == 'true' then return true end
    if value == false or value == 0 or value == '0' or value == 'false' then return false end
    return nil
end

local function GetTurboStageConfig(stage)
    stage = math.max(0, math.floor(tonumber(stage) or 0))
    if stage <= 0 then return nil end

    local serviceBay = Config.ServiceBay or {}
    local stages = serviceBay.TurboStages or {}
    if type(stages) ~= 'table' then return nil end

    for _, cfg in ipairs(stages) do
        if math.floor(tonumber(cfg.level) or 0) == stage then return cfg end
    end

    return nil
end

local function ResolveTurboStageFromProps(props, fallbackTurbo)
    if type(props) ~= 'table' then return fallbackTurbo and 1 or 0 end

    local stage = tonumber(props.lsfcTurboStage or props.turboStage)
    if stage then return math.max(0, math.floor(stage)) end

    local turbo = CoerceServiceBoolean(props.turbo)
    if turbo ~= nil then return turbo and 1 or 0 end

    local toggles = props.toggles
    if type(toggles) == 'table' then
        turbo = CoerceServiceBoolean(toggles['18'])
        if turbo ~= nil then return turbo and 1 or 0 end
        turbo = CoerceServiceBoolean(toggles[18])
        if turbo ~= nil then return turbo and 1 or 0 end
    end

    return fallbackTurbo and 1 or 0
end

local function GetVehicleTurboStage(vehicle)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return 0 end

    local stage = nil
    if Entity then
        local state = Entity(vehicle).state
        stage = tonumber(state.lsfcTurboStage or state.turboStage)
        if stage then return math.max(0, math.floor(stage)) end
        if state.lsfcTurboInstalled == true then return 1 end
    end

    return IsToggleModOn(vehicle, 18) and 1 or 0
end

local function ApplyTurboStage(vehicle, stage)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return end

    stage = math.max(0, math.floor(tonumber(stage) or 0))
    local turboEnabled = stage > 0
    local cfg = GetTurboStageConfig(stage) or {}

    SetVehicleModKit(vehicle, 0)
    ToggleVehicleMod(vehicle, 18, turboEnabled)

    if Entity then
        local state = Entity(vehicle).state
        state:set('lsfcTurboInstalled', turboEnabled, true)
        state:set('lsfcTurboStage', stage, true)
    end

    if stage <= 1 then
        SetVehicleEnginePowerMultiplier(vehicle, 0.0)
        SetVehicleEngineTorqueMultiplier(vehicle, 1.0)
        return
    end

    SetVehicleEnginePowerMultiplier(vehicle, tonumber(cfg.power) or 0.0)
    SetVehicleEngineTorqueMultiplier(vehicle, tonumber(cfg.torque) or 1.0)
end

local function GetVehicleProps(vehicle)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return {} end
    SetVehicleModKit(vehicle, 0)
    local color1, color2 = GetVehicleColours(vehicle)
    local pearl, wheel = GetVehicleExtraColours(vehicle)
    local nr, ng, nb = GetVehicleNeonLightsColour(vehicle)
    local sr, sg, sb = GetVehicleTyreSmokeColor(vehicle)
    local turboInstalled = IsToggleModOn(vehicle, 18)
    local turboStage = GetVehicleTurboStage(vehicle)
    if Entity then
        local turboState = Entity(vehicle).state.lsfcTurboInstalled
        if turboState == true then turboInstalled = true end
    end
    if turboStage > 0 then turboInstalled = true end

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
        lsfcLastServiceMileage = Entity and (tonumber(Entity(vehicle).state.lsfcLastServiceMileage) or 0.0) or 0.0,
        tyresCanBurst = GetVehicleTyresCanBurst(vehicle),
        lsfcTurboStage = turboStage,
        turbo = turboInstalled,
        mods = {}, toggles = {}, extras = {}
    }
    for i = 0, 49 do props.mods[tostring(i)] = GetVehicleMod(vehicle, i) end
    props.toggles['18'] = turboInstalled
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
    if props.toggles then for modType, enabled in pairs(props.toggles) do ToggleVehicleMod(vehicle, tonumber(modType), enabled == true or enabled == 1 or enabled == '1' or enabled == 'true') end end
    if props.turbo ~= nil then
        local turboEnabled = CoerceServiceBoolean(props.turbo) == true
        ApplyTurboStage(vehicle, ResolveTurboStageFromProps(props, turboEnabled))
    elseif props.lsfcTurboStage ~= nil or props.turboStage ~= nil then
        ApplyTurboStage(vehicle, ResolveTurboStageFromProps(props, false))
    end
    if props.extras then
        for extraKey, enabled in pairs(props.extras) do
            local extraId = tonumber(extraKey)
            if extraId and DoesExtraExist(vehicle, extraId) then SetVehicleExtra(vehicle, extraId, enabled and 0 or 1) end
        end
    end
    if props.livery and props.livery >= 0 then SetVehicleLivery(vehicle, props.livery) end
    if props.neonEnabled then for i = 0, 3 do SetVehicleNeonLightEnabled(vehicle, i, props.neonEnabled[i + 1] == true) end end
    if props.neonColor then SetVehicleNeonLightsColour(vehicle, props.neonColor[1] or 255, props.neonColor[2] or 255, props.neonColor[3] or 255) end
    if props.tyreSmokeColor then SetVehicleTyreSmokeColor(vehicle, props.tyreSmokeColor[1] or 255, props.tyreSmokeColor[2] or 255, props.tyreSmokeColor[3] or 255) end
    if props.tyresCanBurst ~= nil then SetVehicleTyresCanBurst(vehicle, props.tyresCanBurst == true) end
    if Entity then
        local state = Entity(vehicle).state
        state:set('lsfcLastServiceMileage', tonumber(props.lsfcLastServiceMileage) or 0.0, true)
        if props.tyresCanBurst ~= nil then state:set('lsfcTyresCanBurst', props.tyresCanBurst == true, true) end
        state:set('lsfcTurboStage', ResolveTurboStageFromProps(props, false), true)
    end
    SetVehicleDirtLevel(vehicle, props.dirtLevel or 0.0)
    SetVehicleBodyHealth(vehicle, props.bodyHealth or 1000.0)
    SetVehicleEngineHealth(vehicle, props.engineHealth or 1000.0)
    SetVehiclePetrolTankHealth(vehicle, props.tankHealth or 1000.0)
end

CreateThread(function()
    local boostedVehicle = 0

    while true do
        local waitTime = 1000
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        local boostActive = false

        if vehicle ~= 0 and DoesEntityExist(vehicle) and GetPedInVehicleSeat(vehicle, -1) == ped then
            local stage = GetVehicleTurboStage(vehicle)
            if stage > 1 then
                local cfg = GetTurboStageConfig(stage) or {}
                SetVehicleEnginePowerMultiplier(vehicle, tonumber(cfg.power) or 0.0)
                SetVehicleEngineTorqueMultiplier(vehicle, tonumber(cfg.torque) or 1.0)
                boostedVehicle = vehicle
                boostActive = true
                waitTime = 0
            end
        end

        if not boostActive and boostedVehicle ~= 0 then
            if DoesEntityExist(boostedVehicle) then
                SetVehicleEnginePowerMultiplier(boostedVehicle, 0.0)
                SetVehicleEngineTorqueMultiplier(boostedVehicle, 1.0)
            end
            boostedVehicle = 0
        end

        Wait(waitTime)
    end
end)

local function ClampVehicleHealth(value, fallback)
    value = tonumber(value)
    if not value then return fallback or 1000.0 end
    return math.max(0.0, math.min(1000.0, value))
end

local function ApplyVehicleHealthState(vehicle, engineHealth, bodyHealth)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return end

    engineHealth = ClampVehicleHealth(engineHealth, 1000.0)
    bodyHealth = ClampVehicleHealth(bodyHealth, 1000.0)

    SetVehicleEngineHealth(vehicle, engineHealth)
    SetVehicleBodyHealth(vehicle, bodyHealth)

    if engineHealth >= 300.0 then
        SetVehicleUndriveable(vehicle, false)
    end

    if engineHealth >= 950.0 and bodyHealth >= 950.0 then
        SetVehicleDeformationFixed(vehicle)
    end
end

local function GetJobVehiclePlate()
    if DepotVehicles.GetJobVehiclePlate then
        return DepotVehicles.GetJobVehiclePlate()
    end

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
    local zoneName = GetNameOfZone(x, y, z)
    local zoneLabel = zoneName and zoneName ~= '' and GetLabelText(zoneName) or nil
    if zoneLabel == 'NULL' or zoneLabel == '' then zoneLabel = nil end

    if street and street ~= '' and crossing and crossing ~= '' then
        return ('%s / %s'):format(street, crossing)
    end

    if street and street ~= '' and zoneLabel then
        return ('%s / %s'):format(street, zoneLabel)
    end

    if street and street ~= '' then
        return street
    end

    if zoneLabel then
        return zoneLabel
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

local ClearRouteAreaBlip

local function CreateRouteBlip(coords, label, blipType)
    if activeBlip then RemoveBlip(activeBlip) activeBlip = nil end
    if ClearRouteAreaBlip then ClearRouteAreaBlip() end
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

ClearRouteAreaBlip = function()
    if activeAreaBlip then
        RemoveBlip(activeAreaBlip)
        activeAreaBlip = nil
    end
end

local function CreateRouteAreaBlip(coords, radius, areaType)
    ClearRouteAreaBlip()
    if not coords then return end

    local cfg = Config.AreaBlips or {}
    if cfg.Enabled == false then return end

    local style = cfg[areaType or 'TrailerDrop'] or {}
    radius = tonumber(radius) or tonumber(style.fallbackRadius) or tonumber(style.radius) or 22.0
    if radius <= 0.0 then return end

    activeAreaBlip = AddBlipForRadius(coords.x, coords.y, coords.z, radius + 0.0)
    SetBlipColour(activeAreaBlip, style.color or 47)
    SetBlipAlpha(activeAreaBlip, style.alpha or 80)
    SetBlipAsShortRange(activeAreaBlip, false)
end

local function GetCargoDeliveryBlipType(contractType)
    if contractType == 'boxtruck' then return 'crate' end
    if contractType == 'trailer' then return 'trailer' end
    return 'package'
end

local function ClearRouteBlip()
    if activeBlip then RemoveBlip(activeBlip) activeBlip = nil end
    ClearRouteAreaBlip()
end

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

local function StartCargoCarryAnim()
    local ped = PlayerPedId()
    lib.requestAnimDict('anim@heists@box_carry@')
    TaskPlayAnim(ped, 'anim@heists@box_carry@', 'idle', 8.0, 8.0, -1, 49, 0, false, false, false)
end

local function CarryCargoProp(contractType, cargoTypeOverride, startAnim)
    local cargo = GetCargoConfigForContract(contractType, cargoTypeOverride)
    if not cargo then return false end
    local ped = PlayerPedId()
    local propModel = LoadModel(cargo.prop)
    if not propModel then return false end

    if startAnim ~= false then StartCargoCarryAnim() end
    local prop = CreateObject(propModel, 0.0, 0.0, 0.0, true, true, false)
    SetModelAsNoLongerNeeded(propModel)

    local o = cargo.carryOffset
    AttachEntityToEntity(prop, ped, GetPedBoneIndex(ped, o.bone), o.pos.x, o.pos.y, o.pos.z, o.rot.x, o.rot.y, o.rot.z, true, true, false, true, 1, true)
    carryingProp = prop
    carryingCargo = true
    return true
end

local function DeleteCarryProp(keepTasks)
    if not keepTasks then ClearPedTasks(PlayerPedId()) end
    if carryingProp and DoesEntityExist(carryingProp) then DeleteEntity(carryingProp) end
    carryingProp = nil
    carryingCargo = false
    if activeContract then activeContract.currentCarryCargoType = nil end
end

local function PlayCargoTimedAction(dict, clip, duration, momentAt, onMoment, afterAction)
    local ped = PlayerPedId()
    duration = tonumber(duration) or 900
    momentAt = tonumber(momentAt) or math.floor(duration * 0.5)

    lib.requestAnimDict(dict)
    TaskPlayAnim(ped, dict, clip, 4.0, 4.0, duration, 48, 0, false, false, false)

    local started = GetGameTimer()
    local fired = false

    while GetGameTimer() - started < duration do
        local elapsed = GetGameTimer() - started

        DisableControlAction(0, 21, true) -- sprint
        DisableControlAction(0, 22, true) -- jump
        DisableControlAction(0, 24, true) -- attack
        DisableControlAction(0, 25, true) -- aim
        DisableControlAction(0, 30, true) -- move left/right
        DisableControlAction(0, 31, true) -- move forward/back

        if not fired and elapsed >= momentAt then
            fired = true
            if onMoment then onMoment() end
        end

        Wait(0)
    end

    if not fired and onMoment then onMoment() end
    if afterAction then afterAction() end
end

local function PlayCargoPickupTransition(contractType, cargoTypeOverride)
    local attached = false

    PlayCargoTimedAction('pickup_object', 'pickup_low', 900, 430, function()
        attached = CarryCargoProp(contractType, cargoTypeOverride, false)
    end, function()
        if attached then StartCargoCarryAnim() end
    end)
end

local function PlayCargoLoadTransition()
    PlayCargoTimedAction('anim@heists@narcotics@trash', 'throw_b', 1050, 520, function()
        DeleteCarryProp(true)
    end, function()
        ClearPedSecondaryTask(PlayerPedId())
    end)
end

local function PlayCargoSetDownTransition()
    PlayCargoTimedAction('pickup_object', 'pickup_low', 950, 420, function()
        DeleteCarryProp(true)
    end, function()
        ClearPedSecondaryTask(PlayerPedId())
    end)
end

CreateThread(function()
    while true do
        Wait(1000)

        if carryingCargo and carryingProp and DoesEntityExist(carryingProp) then
            local ped = PlayerPedId()

            if not IsEntityPlayingAnim(ped, 'anim@heists@box_carry@', 'idle', 3) then
                StartCargoCarryAnim()
            end
        end
    end
end)

CreateThread(function()
    while true do
        if carryingCargo then
            local ped = PlayerPedId()

            -- Prevent sprinting/jumping while carrying freight while still allowing a reasonable walking pace.
            DisableControlAction(0, 21, true) -- INPUT_SPRINT
            DisableControlAction(0, 22, true) -- INPUT_JUMP
            DisableControlAction(0, 36, true) -- INPUT_DUCK

            if not IsPedInAnyVehicle(ped, false) then
                SetPedMoveRateOverride(ped, 0.88)
            end

            Wait(0)
        else
            Wait(500)
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


local function TurnPlayerTowardEntityTarget(target)
    local entity = nil

    if type(target) == 'table' then
        entity = target.entity or target[1]
    else
        entity = target
    end

    if entity and entity ~= 0 and DoesEntityExist(entity) then
        local ped = PlayerPedId()
        if not IsPedInAnyVehicle(ped, false) then
            TaskTurnPedToFaceEntity(ped, entity, 650)
            Wait(250)
        end
    end
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
            onSelect = originalOnSelect and function(data)
                TurnPlayerTowardEntityTarget(data)
                originalOnSelect(data)
            end or nil,
            action = originalOnSelect and function(entity)
                TurnPlayerTowardEntityTarget(entity)
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

    for _, doorIndex in ipairs({ 5, 2, 3 }) do
        if IsVehicleDoorDamaged(spawnedVehicle, doorIndex) or GetVehicleDoorAngleRatio(spawnedVehicle, doorIndex) > 0.1 then
            return true
        end
    end

    return false
end

local function CleanupJobVehicle()
    DeleteCarryProp()
    if spawnedTrailer and DoesEntityExist(spawnedTrailer) then
        local cargoProps = LS_Trucking and LS_Trucking.TrailerCargoProps or {}
        if cargoProps.CleanupForTrailer then
            cargoProps.CleanupForTrailer(spawnedTrailer)
        end

        DeleteEntity(spawnedTrailer)
    end
    if spawnedVehicle and DoesEntityExist(spawnedVehicle) then DeleteEntity(spawnedVehicle) end
    spawnedTrailer = nil
    spawnedTrailerStartBody = 1000.0
    spawnedVehicle = nil
    reusableVehicle = nil
    garageVehicle = nil
    contractorVehicle = nil
    vehicleTargetAdded = false
    trailerTargetAdded = false
end

local function CleanupTrailerOnly()
    if spawnedTrailer and DoesEntityExist(spawnedTrailer) then
        local cargoProps = LS_Trucking and LS_Trucking.TrailerCargoProps or {}
        if cargoProps.CleanupForTrailer then
            cargoProps.CleanupForTrailer(spawnedTrailer)
        end

        DeleteEntity(spawnedTrailer)
    end
    spawnedTrailer = nil
    spawnedTrailerStartBody = 1000.0
    trailerTargetAdded = false
end

local function HideMiniUI()
    if miniFullVisible then SendNUIMessage({ action = 'hideMini' }) end
    if miniDockVisible then SendNUIMessage({ action = 'hideMiniDock' }) end
    miniFullVisible = false
    miniDockVisible = false
end

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

local function GetCargoConditionState(score, contractType)
    score = tonumber(score) or 100

    if score >= 90 then
        return contractType == 'trailer' and 'TRAILER SECURE' or 'CARGO STABLE', 'stable', 'No load movement detected.'
    elseif score >= 70 then
        return 'CARGO SHIFTED', 'shifted', 'Minor load movement logged.'
    elseif score >= 45 then
        return 'CARGO SCUFFED', 'damaged', 'Cargo handling warning logged.'
    end

    return 'CARGO DAMAGED', 'critical', 'Cargo damage report pending receiver review.'
end

local function ResetCargoCondition()
    cargoConditionLastHealth = nil
    cargoConditionLastSpeed = 0.0
    cargoConditionSpeedingSince = nil
    cargoConditionIncidentCooldown = 0

    if not activeContract then return end

    local label, level, note = GetCargoConditionState(100, activeContract.type)
    activeContract.cargoConditionScore = 100
    activeContract.cargoConditionLabel = label
    activeContract.cargoConditionLevel = level
    activeContract.cargoConditionNote = note
    activeContract.cargoConditionLastReason = 'Loaded clean'
end

local function GetMiniSignalData()
    local targetCoords = nil

    if dispatchPed and DoesEntityExist(dispatchPed) then
        targetCoords = GetEntityCoords(dispatchPed)
    elseif Config.DispatchPed and Config.DispatchPed.coords then
        targetCoords = GetConfigCoords3(Config.DispatchPed.coords)
    elseif Config.Depot and Config.Depot.terminal then
        targetCoords = GetConfigCoords3(Config.Depot.terminal)
    end

    if not targetCoords then
        return 4, 'Dispatch signal locked', true
    end

    local playerCoords = GetEntityCoords(PlayerPedId())
    local distance = #(playerCoords - targetCoords)
    local bars = 0

    if distance <= 1500.0 then
        bars = 4
    elseif distance <= 5000.0 then
        bars = 3
    elseif distance <= 10000.0 then
        bars = 2
    elseif distance <= 15000.0 then
        bars = 1
    end

    local label = ('Dispatch signal: %s/4 (%sm)'):format(bars, math.floor(distance))
    return bars, label, true
end

local function BuildReceiverReuseData()
    if DepotVehicles.BuildReceiverReuseData then
        return DepotVehicles.BuildReceiverReuseData()
    end

    return { available = false }
end

local function BuildCurrentVehicleState()
    if DepotVehicles.BuildCurrentVehicleState then
        return DepotVehicles.BuildCurrentVehicleState()
    end

    return nil
end

if RouteState.ConfigureClient then
    RouteState.ConfigureClient({
        GetActiveContract = function() return activeContract end,
        GetSpawnedVehicle = function() return spawnedVehicle end,
        GetCurrentDriverInfo = function() return currentDriverInfo end,
        GetReceiverDockUserHidden = function() return receiverDockUserHidden end,
        GetMiniSignalData = GetMiniSignalData,
        BuildReceiverReuseData = BuildReceiverReuseData,
        GetRouteHistory = function() return RouteHistory.GetHistory() end,
        GetLastRadioChatter = function() return LS_Trucking.LastRadioChatter end,
        GetLastRadioDirection = function() return LS_Trucking.LastRadioDirection end,
        IsContractRequestPending = function() return LS_Trucking.ContractRequestPending == true end
    })
end

local function BuildReceiverPayload(minimal)
    if RouteState.BuildReceiverPayload then
        return RouteState.BuildReceiverPayload(minimal)
    end

    return { type = 'standby', label = 'DISPATCH STANDBY', hasActiveRoute = false }
end

local function UpdateMiniUI(passive)
    if not Config.MiniUIEnabled then HideMiniUI() return end

    local payload = BuildReceiverPayload(passive == true)
    payload.locale = Config.Locale or 'en'
    payload.config = payload.config or {}
    payload.config.locale = Config.Locale or 'en'

    if activeContract and Config.ReceiverDockEnabled ~= false and not receiverDockUserHidden then
        SendNUIMessage({ action = 'showMiniDock', contract = payload })
        miniDockVisible = true
    else
        if miniDockVisible then
            SendNUIMessage({ action = 'hideMiniDock' })
            miniDockVisible = false
        end
    end

    if fullReceiverVisible and Config.FullReceiverEnabled ~= false then
        SendNUIMessage({ action = (passive == true and miniFullVisible) and 'refreshMini' or 'showMini', contract = payload })
        miniFullVisible = true
    else
        if miniFullVisible then
            SendNUIMessage({ action = 'hideMini' })
            miniFullVisible = false
        end
    end
end

CreateThread(function()
    while true do
        Wait(math.max(5000, tonumber(Config.ReceiverRefreshInterval) or 10000))

        if Config.MiniUIEnabled and (activeContract or fullReceiverVisible) then
            UpdateMiniUI(true)
        end
    end
end)

local function DispatchChatter(message, notifyType, soundType, options)
    if not message or message == '' then return end
    options = options or {}

    LS_Trucking.LastRadioChatter = message
    LS_Trucking.LastRadioChatterAt = GetClientTimestamp()
    LS_Trucking.LastRadioDirection = options.direction == 'tx' and 'tx' or 'rx'

    if activeContract then
        activeContract.radioChatter = message
        activeContract.radioChatterAt = GetClientTimestamp()
        activeContract.radioDirection = LS_Trucking.LastRadioDirection
    end

    local soundMap = Config.Notifications and Config.Notifications.SoundMap or {}
    local shouldNotify = options.notify ~= false
    local notifyHasSound = shouldNotify and (soundMap[notifyType or 'inform'] ~= nil or notifyType == 'warning' or notifyType == 'error')
    if not LS_Trucking.FreightHandoff.PlayNativeRadioMessageAudio(spawnedVehicle) and not notifyHasSound then
        PlayUISound(soundType or 'destination')
    end

    if shouldNotify then
        Notify(('Dispatch: %s'):format(message), notifyType or 'inform')
    end

    UpdateMiniUI()
end

LS_Trucking.BeginContractRequest = function(message)
    if LS_Trucking.ContractRequestPending then
        Notify('Dispatch is already processing a contract request.', 'inform')
        return false
    end

    LS_Trucking.ContractRequestPending = true
    DispatchChatter(message or 'Contract request transmitted. Waiting for dispatch review.', 'inform', 'secure', { direction = 'tx' })

    local exchange = Config.DispatchExchange or {}
    if exchange.Enabled ~= false then
        Wait(math.max(0, tonumber(exchange.RequestDelay) or 1250))
    end

    return true
end

LS_Trucking.ResolveContractRequest = function(result, approvedMessage)
    local exchange = Config.DispatchExchange or {}

    if result and result.success then
        DispatchChatter(approvedMessage or 'Dispatch approved the contract. Route data and GPS are now active.', 'success', 'destination')
        if exchange.Enabled ~= false then
            Wait(math.max(0, tonumber(exchange.ResponseDelay) or 900))
        end
    else
        DispatchChatter(('Dispatch denied the contract request. %s'):format(result and result.message or 'No route was assigned.'), 'error', 'alert')
    end

    LS_Trucking.ContractRequestPending = false
    UpdateMiniUI()
end

local function SetCargoConditionScore(score, reason)
    if not activeContract then return end

    local oldLevel = activeContract.cargoConditionLevel or 'stable'
    score = math.max(0, math.min(100, math.floor(tonumber(score) or 100)))

    local label, level, note = GetCargoConditionState(score, activeContract.type)
    activeContract.cargoConditionScore = score
    activeContract.cargoConditionLabel = label
    activeContract.cargoConditionLevel = level
    activeContract.cargoConditionNote = reason or note
    activeContract.cargoConditionLastReason = reason or note

    if level ~= oldLevel then
        if level == 'shifted' then
            DispatchChatter('Load movement detected. Smooth driving advised.', 'warning', 'alert')
        elseif level == 'damaged' then
            DispatchChatter('Cargo condition warning logged. Receiver may inspect this load.', 'warning', 'alert')
        elseif level == 'critical' then
            DispatchChatter('Cargo damage report transmitted. Expect receiver inspection.', 'error', 'alert')
        elseif level == 'stable' then
            UpdateMiniUI()
        end
    else
        UpdateMiniUI()
    end
end

local function IsCargoConditionActive()
    if not activeContract or not activeContract.loaded then return false end
    if activeContract.type == 'trailer' then
        return activeContract.trailerHooked == true and activeContract.trailerDropped ~= true
    end

    return activeContract.verifiedCargo == true
end

local function GetCargoConditionVehicle()
    if not activeContract then return nil end

    if activeContract.type == 'trailer' and spawnedTrailer and DoesEntityExist(spawnedTrailer) then
        return spawnedTrailer
    end

    if spawnedVehicle and DoesEntityExist(spawnedVehicle) then
        return spawnedVehicle
    end

    return nil
end

local function ApplyCargoConditionWatch()
    local cfg = Config.CargoCondition or {}

    if cfg.Enabled == false or not IsCargoConditionActive() then
        cargoConditionLastHealth = nil
        cargoConditionLastSpeed = 0.0
        cargoConditionSpeedingSince = nil
        return
    end

    local vehicle = GetCargoConditionVehicle()
    if not vehicle then return end

    local now = GetGameTimer()
    local bodyHealth = GetVehicleBodyHealth(vehicle)
    local speedMph = GetEntitySpeed(vehicle) * 2.236936

    if not cargoConditionLastHealth then
        cargoConditionLastHealth = bodyHealth
        cargoConditionLastSpeed = speedMph
        return
    end

    local incidentReady = now >= cargoConditionIncidentCooldown
    local healthDrop = cargoConditionLastHealth - bodyHealth
    local threshold = tonumber(cfg.HealthDropThreshold) or 12.0

    if incidentReady and healthDrop >= threshold then
        cargoConditionIncidentCooldown = now + (tonumber(cfg.IncidentCooldown) or 6000)
        incidentReady = false
        local scoreDrop = math.max(2, math.floor(healthDrop * (tonumber(cfg.DamageScoreMultiplier) or 0.08)))
        SetCargoConditionScore((activeContract.cargoConditionScore or 100) - scoreDrop, 'Impact detected during route.')
    end

    local speedDrop = cargoConditionLastSpeed - speedMph
    local brakeMin = tonumber(cfg.HardBrakeMinSpeed) or 35.0
    local brakeDrop = tonumber(cfg.HardBrakeDropMph) or 28.0

    if incidentReady and cargoConditionLastSpeed >= brakeMin and speedDrop >= brakeDrop then
        cargoConditionIncidentCooldown = now + (tonumber(cfg.IncidentCooldown) or 6000)
        incidentReady = false
        SetCargoConditionScore((activeContract.cargoConditionScore or 100) - (tonumber(cfg.HardBrakePenalty) or 4), 'Hard braking event logged.')
    end

    local safeSpeed = nil
    if activeContract.type == 'trailer' then
        safeSpeed = tonumber(activeContract.safeSpeed)
    end

    safeSpeed = safeSpeed or (cfg.SafeSpeed and (tonumber(cfg.SafeSpeed[activeContract.type]) or tonumber(cfg.SafeSpeed.default)) or nil) or 80.0

    if speedMph > safeSpeed then
        if not cargoConditionSpeedingSince then cargoConditionSpeedingSince = now end
        if incidentReady and now - cargoConditionSpeedingSince >= (tonumber(cfg.SpeedWarningAfter) or 9000) then
            cargoConditionIncidentCooldown = now + (tonumber(cfg.IncidentCooldown) or 6000)
            incidentReady = false
            SetCargoConditionScore((activeContract.cargoConditionScore or 100) - (tonumber(cfg.SpeedPenalty) or 2), ('Overspeed handling logged above %s MPH.'):format(math.floor(safeSpeed)))
        end
    else
        cargoConditionSpeedingSince = nil
    end

    cargoConditionLastHealth = bodyHealth
    cargoConditionLastSpeed = speedMph
end

CreateThread(function()
    while true do
        Wait((Config.CargoCondition and Config.CargoCondition.CheckInterval) or 2000)
        ApplyCargoConditionWatch()
    end
end)

local function CanReuseVehicle(contractType, allowContractor)
    if DepotVehicles.CanReuseVehicle then
        return DepotVehicles.CanReuseVehicle(contractType, allowContractor)
    end

    return false
end

local function GetReuseData()
    return BuildReceiverReuseData()
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
    if not activeContract or activeContract.type ~= 'trailer' then return end
    if activeContract.trailerAttached then return end
    if not IsAssignedTrailerAttached() then return end
    if activeContract.trailerHooked and not activeContract.trailerConnectionLost then return end
    if LS_Trucking.TrailerCouplePending then return end

    LS_Trucking.TrailerCouplePending = true
    LS_Trucking.TrailerCoupleToken = (LS_Trucking.TrailerCoupleToken or 0) + 1
    local token = LS_Trucking.TrailerCoupleToken

    CreateThread(function()
        Wait(math.max(0, tonumber(Config.TrailerCoupleNoticeDelay) or 500))

        if token ~= LS_Trucking.TrailerCoupleToken
            or not activeContract
            or activeContract.type ~= 'trailer'
            or not IsAssignedTrailerAttached() then
            if token == LS_Trucking.TrailerCoupleToken then LS_Trucking.TrailerCouplePending = false end
            return
        end

        local reconnecting = activeContract.trailerHooked == true and activeContract.trailerConnectionLost == true
        activeContract.trailerAttached = true
        activeContract.loadChecklist = activeContract.loadChecklist or { truckSecure = false, trailerSecure = false }
        activeContract.stage = reconnecting and 'Secure trailer attachment' or 'Complete load checklist'

        if reconnecting then
            activeContract.notice = 'Trailer recoupled. Target the rear of the truck and redo Secure Load Attached before continuing.'
            SetActiveDestination('Rear of truck')
            Notify('Trailer recoupled. Redo Secure Load Attached before continuing.', 'warning')
            DispatchChatter('Trailer telemetry restored. Repeat the secure attachment check before continuing the route.', 'warning', 'trailerConnect')
        else
            activeContract.loaded = false
            if (Config.LoadVerificationMode or 'receiver') == 'receiver' then
                activeContract.notice = 'Trailer is hooked. Target the rear of the truck and trailer to complete the physical checks, then submit the checklist through the receiver.'
                SetActiveDestination('Rear of truck')
            else
                activeContract.notice = 'Trailer is hooked. Target the rear of the truck to complete the connection and load security checklist.'
                SetActiveDestination('Load checklist')
            end

            Notify('Trailer attached. Complete the load checklist before starting the delivery route.', 'inform')
            DispatchChatter('Trailer telemetry shows coupled. Complete load secure checks before departure.', 'inform', 'secure')
        end

        LS_Trucking.TrailerCouplePending = false
        UpdateMiniUI()
    end)
end

CreateThread(function()
    while true do
        Wait(Config.TrailerAutoDetectInterval or 750)
        if activeContract and activeContract.type == 'trailer' then
            local attachedTrailer = GetAttachedTrailer()
            local assignedTrailerExists = spawnedTrailer and DoesEntityExist(spawnedTrailer)
            local incorrectTrailer = attachedTrailer ~= 0 and assignedTrailerExists and attachedTrailer ~= spawnedTrailer
            local assignedAttached = IsAssignedTrailerAttached()

            if LS_Trucking.AssignedTrailerWasAttached == true and not assignedAttached then
                activeContract.trailerAttached = false
                LS_Trucking.TrailerCoupleToken = (LS_Trucking.TrailerCoupleToken or 0) + 1
                LS_Trucking.TrailerCouplePending = false

                local intentionalDrop = false
                if activeContract.trailerHooked
                    and spawnedTrailer
                    and DoesEntityExist(spawnedTrailer)
                    and activeContract.trailerDrop
                    and activeContract.trailerDrop.coords then
                    local trailerCoords = GetEntityCoords(spawnedTrailer)
                    local dropCoords = activeContract.trailerDrop.coords
                    local dx = trailerCoords.x - dropCoords.x
                    local dy = trailerCoords.y - dropCoords.y
                    local dropDistance = math.sqrt((dx * dx) + (dy * dy))
                    local marker = Config.TrailerDropMarker or {}
                    local allowedDistance = marker.Enabled == false
                        and math.max(1.0, tonumber(activeContract.trailerDrop.radius) or 18.0)
                        or math.max(0.5, tonumber(marker.PositionTolerance) or 1.40)
                    intentionalDrop = dropDistance <= allowedDistance
                end

                activeContract.loadChecklist = activeContract.loadChecklist or { truckSecure = false, trailerSecure = false }
                local connectionWasSecure = activeContract.loadChecklist.truckSecure == true
                if connectionWasSecure and not intentionalDrop then PlayUISound('trailerDisconnect') end

                if not intentionalDrop then
                    activeContract.loadChecklist.truckSecure = false

                    if connectionWasSecure then
                        activeContract.trailerConnectionLost = activeContract.trailerHooked == true
                        activeContract.stage = 'Reconnect trailer'
                        activeContract.notice = 'Trailer connection lost. Reattach the assigned trailer and redo Secure Load Attached.'
                        SetActiveDestination('Assigned trailer')
                        Notify('Trailer disconnected. Reattach it and redo Secure Load Attached.', 'warning')
                        DispatchChatter('Trailer connection lost. Reconnect the assigned trailer and repeat the secure attachment check.', 'warning', 'trailerDisconnect')
                        UpdateMiniUI()
                    elseif not activeContract.trailerHooked then
                        activeContract.stage = 'Hook up trailer'
                        activeContract.notice = 'Hook up the assigned trailer to continue the load checklist.'
                        SetActiveDestination(activeContract.trailerDepot and activeContract.trailerDepot.label or 'Assigned trailer')
                        UpdateMiniUI()
                    end
                end
            end

            LS_Trucking.AssignedTrailerWasAttached = assignedAttached

            if not activeContract.trailerHooked and incorrectTrailer then
                if LS_Trucking.LastIncorrectTrailer ~= attachedTrailer then
                    LS_Trucking.LastIncorrectTrailer = attachedTrailer
                    activeContract.notice = ('Incorrect trailer detected. Detach it and connect the assigned %s.'):format(activeContract.trailerLabel or 'route trailer')
                    DispatchChatter(('Incorrect trailer detected at the depot. Detach that unit and connect the assigned %s.'):format(activeContract.trailerLabel or 'route trailer'), 'warning', 'alert')
                end
            else
                if attachedTrailer == 0 or attachedTrailer == spawnedTrailer then
                    LS_Trucking.LastIncorrectTrailer = nil
                end
                MarkTrailerHookedAuto()
            end
        else
            LS_Trucking.LastIncorrectTrailer = nil
            LS_Trucking.AssignedTrailerWasAttached = nil
            LS_Trucking.TrailerCoupleToken = (LS_Trucking.TrailerCoupleToken or 0) + 1
            LS_Trucking.TrailerCouplePending = false
        end
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
    if not Progress('Positioning cargo at open trunk...', Config.Progress.loadCargo, { dict = 'anim@heists@box_carry@', clip = 'idle' }) then return end
    local result = lib.callback.await('ls_trucking:server:loadCargoOne', false)
    if not result or not result.success then Notify(result and result.message or 'Could not load cargo.', 'error') return end
    PlayCargoLoadTransition()
    activeContract.loadedCargo = result.loaded
    activeContract.loaded = false
    if result.ready then
        activeContract.cargoReady = true
        activeContract.verifiedCargo = false
        activeContract.stage = 'Verify loaded cargo'
        if (Config.LoadVerificationMode or 'receiver') == 'receiver' then
            activeContract.notice = 'All cargo is loaded. Open the receiver Load page and submit the manifest for dispatch verification.'
            SetActiveDestination('Verify cargo in receiver')
            Notify('All cargo loaded. Verify the manifest from the receiver Load page to start your route.', 'success')
        else
            activeContract.notice = 'All cargo is loaded. Target the vehicle and verify loaded cargo before starting the route.'
            SetActiveDestination('Verify cargo at vehicle')
            Notify('All cargo loaded. Target the vehicle and verify the loaded cargo to start your route.', 'success')
        end
        DispatchChatter('Pickup load count matches manifest. Verify cargo before departure.', 'inform', 'secure')
    else
        activeContract.stage = 'Load cargo into vehicle'
        activeContract.notice = ('Load cargo one item at a time: %s/%s loaded.'):format(result.loaded, result.required)
        Notify(('Cargo loaded %s/%s. Get the next item from the pickup worker.'):format(result.loaded, result.required), 'success')
    end
    UpdateMiniUI()
end

local function VerifyLoadedCargo(fromReceiver)
    fromReceiver = fromReceiver == true
    if not activeContract then return false end
    if activeContract.type == 'trailer' then return false end
    if not activeContract.cargoReady then
        Notify('Load all route cargo before verifying.', 'error')
        return false
    end

    if fromReceiver then
        if not spawnedVehicle or not DoesEntityExist(spawnedVehicle) then
            Notify('Your assigned vehicle is not available for verification.', 'error')
            return false
        end

        if #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(spawnedVehicle)) > 8.0 then
            Notify('Stand near the loaded vehicle before submitting the manifest.', 'error')
            return false
        end

        if GetEntitySpeed(spawnedVehicle) > 0.75 then
            Notify('Stop the vehicle before submitting the manifest.', 'error')
            return false
        end

        DispatchChatter('Verifying cargo manifest with dispatch. Stand by for load clearance.', 'inform', 'secure', { direction = 'tx' })
        local exchange = Config.DispatchExchange or {}
        if exchange.Enabled ~= false then
            Wait(math.max(0, tonumber(exchange.RequestDelay) or 1250))
        end
    elseif not Progress('Verifying loaded cargo...', Config.Progress.verifyLoadedCargo or 2500, {
            dict = 'missheistdockssetup1clipboard@base',
            clip = 'base'
        }, {
            model = `p_amb_clipboard_01`,
            bone = 18905,
            pos = vec3(0.10, 0.02, 0.08),
            rot = vec3(-80.0, 0.0, 0.0)
        }) then
        return false
    end

    local result = lib.callback.await('ls_trucking:server:verifyLoadedCargo', false)
    if not result or not result.success then
        Notify(result and result.message or 'Could not verify loaded cargo.', 'error')
        if fromReceiver then
            DispatchChatter(('Manifest verification failed. %s'):format(result and result.message or 'Dispatch could not clear the load.'), 'error', 'alert')
        end
        return false
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
    DispatchChatter(fromReceiver and 'Dispatch verified manifest. Route confirmed. GPS activated.' or 'Cargo seal verified. Receiver has been notified of your departure.', 'inform', 'secure')
    UpdateMiniUI()
    return true
end

local function GrabCargoFromVehicle()
    if not activeContract then return end
    if not IsCargoDoorOpen() then Notify('Open the vehicle trunk or rear cargo door before grabbing cargo.', 'error') return end
    if carryingCargo then Notify('You are already carrying cargo.', 'error') return end
    if not Progress('Reaching into open trunk...', Config.Progress.grabCargo, { dict = 'pickup_object', clip = 'pickup_low' }) then return end
    local result = lib.callback.await('ls_trucking:server:grabCargoFromVehicle', false)
    if not result or not result.success then Notify(result and result.message or 'Could not grab cargo.', 'error') return end
    activeContract.currentCarryCargoType = result.cargoType
    PlayCargoPickupTransition(activeContract.type, result.cargoType)
    activeContract.notice = 'Carry the package to the current dropoff target.'
    Notify(('Grabbed %s. Take it to the dropoff target.'):format(result.label), 'success')
    UpdateMiniUI()
end


local function GetChecklistStatusText()
    local checklist = activeContract.loadChecklist or { truckSecure = false, trailerSecure = false }
    local trailerLabel = activeContract.trailerLabel or 'Assigned Trailer'
    local receiverMode = (Config.LoadVerificationMode or 'receiver') == 'receiver'

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
        receiverMode and '3. Submit the completed checklist to dispatch.' or '3. Return to the rear of the truck and complete the checklist.'
    }, '\n\n')
end

local function ShowTrailerLoadChecklist()
    if not activeContract or activeContract.type ~= 'trailer' then
        Notify('You do not have a trailer hauling contract.', 'error')
        return
    end

    ShowFreightDialog('Trailer Load Checklist', GetChecklistStatusText(), 'Close Checklist')
end

local AddTrailerLoadTarget

local function SecureTruckLoadConnection(fromReceiver)
    fromReceiver = fromReceiver == true
    if not activeContract or activeContract.type ~= 'trailer' then
        Notify('You do not have a trailer hauling contract.', 'error')
        return
    end

    local reconnecting = activeContract.trailerHooked == true and activeContract.trailerConnectionLost == true

    if activeContract.trailerHooked and not reconnecting then
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

    if fromReceiver then
        DispatchChatter('Running air and electrical connection check. Hold for telemetry.', 'inform', 'trailerConnect')
        local exchange = Config.DispatchExchange or {}
        if exchange.Enabled ~= false then
            Wait(math.max(0, tonumber(exchange.ChecklistStepDelay) or 700))
        end
    elseif not Progress('Securing truck load connection...', Config.Progress.secureTruckLoad or 3000, {
            dict = 'mini@repair',
            clip = 'fixing_a_ped'
        }) then
        return false
    end

    activeContract.loadChecklist.truckSecure = true
    PlayUISound('trailerConnect')

    if reconnecting then
        activeContract.trailerConnectionLost = false
        activeContract.trailerAttached = true
        activeContract.loaded = true
        activeContract.stage = 'Deliver trailer'
        activeContract.notice = (Config.TrailerDropMarker or {}).Enabled ~= false
            and 'Trailer connection re-secured. Place the trailer inside the receiving marker, detach it, and wait for yard acceptance.'
            or 'Trailer connection re-secured. Drive to the receiving yard and detach the trailer in the drop zone.'
        SetActiveDestination(activeContract.trailerDrop.label, activeContract.trailerDrop.coords)
        Notify('Trailer connection re-secured. Route clearance restored.', 'success')
        DispatchChatter('Secure attachment verified. Trailer route clearance restored.', 'success', 'secure')
        UpdateMiniUI()
        return true
    end

    activeContract.stage = 'Complete load checklist'
    activeContract.notice = 'Truck connection secured. Target the rear of the trailer and confirm the load is secure.'
    SetActiveDestination('Rear of trailer')
    AddTrailerLoadTarget()

    Notify('Truck connection secured.', 'success')
    if fromReceiver then DispatchChatter('Connection telemetry confirmed. Air and electrical lines are secure.', 'success', 'secure') end
    UpdateMiniUI()
    return true
end

local function SecureTrailerLoad(fromReceiver)
    fromReceiver = fromReceiver == true
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

    if fromReceiver then
        DispatchChatter('Checking trailer load security and stability sensors.', 'inform', 'secure')
        local exchange = Config.DispatchExchange or {}
        if exchange.Enabled ~= false then
            Wait(math.max(0, tonumber(exchange.ChecklistStepDelay) or 700))
        end
    elseif not Progress('Confirming trailer load secure...', Config.Progress.secureTrailerLoad or 3000, {
            dict = 'mini@repair',
            clip = 'fixing_a_ped'
        }) then
        return false
    end

    activeContract.loadChecklist.trailerSecure = true
    PlayUISound('secure')
    activeContract.stage = 'Complete load checklist'
    if (Config.LoadVerificationMode or 'receiver') == 'receiver' then
        activeContract.notice = 'Trailer load confirmed secure. Submit the completed checklist from the receiver Load page.'
        SetActiveDestination('Submit load checklist')
    else
        activeContract.notice = 'Trailer load confirmed secure. Return to the rear of the truck to complete the load checklist.'
        SetActiveDestination('Rear of truck')
    end

    Notify('Trailer load confirmed secure.', 'success')
    if fromReceiver then DispatchChatter('Trailer load security confirmed. Checklist is ready for dispatch submission.', 'success', 'secure') end
    UpdateMiniUI()
    return true
end

local function CompleteTrailerLoadChecklist(fromReceiver)
    fromReceiver = fromReceiver == true
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

    if fromReceiver then
        DispatchChatter('Submitting completed trailer load checklist to dispatch. Awaiting route clearance.', 'inform', 'secure', { direction = 'tx' })
        local exchange = Config.DispatchExchange or {}
        if exchange.Enabled ~= false then
            Wait(math.max(0, tonumber(exchange.RequestDelay) or 1250))
        end
    else
        local confirmed = ShowFreightConfirm(
            'Complete Load Checklist',
            GetChecklistStatusText() .. '\n\nConfirm this load is secured and ready for dispatch?',
            'Confirm Dispatch',
            'Go Back'
        )

        if not confirmed then return false end

        if not Progress('Submitting load checklist...', Config.Progress.completeLoadChecklist or 2500, {
                dict = 'missheistdockssetup1clipboard@base',
                clip = 'base'
            }, {
                model = `p_amb_clipboard_01`,
                bone = 18905,
                pos = vec3(0.10, 0.02, 0.08),
                rot = vec3(-80.0, 0.0, 0.0)
            }) then
            return false
        end
    end

    local result = lib.callback.await('ls_trucking:server:markTrailerHooked', false)
    if not result or not result.success then
        Notify(result and result.message or 'Could not clear trailer load for dispatch.', 'error')
        if fromReceiver then
            DispatchChatter(('Checklist verification failed. %s'):format(result and result.message or 'Dispatch could not clear the trailer.'), 'error', 'alert')
        end
        return false
    end

    activeContract.trailerAttached = true
    activeContract.trailerHooked = true
    activeContract.loaded = true
    activeContract.stage = 'Deliver trailer'
    activeContract.notice = (Config.TrailerDropMarker or {}).Enabled ~= false
        and 'Checklist complete. Place the trailer inside the receiving marker, detach it, and wait for yard acceptance.'
        or 'Checklist complete. Drive to the receiving yard and detach the trailer in the drop zone.'
    SetExpectedCompletionTime()
    SetActiveDestination(activeContract.trailerDrop.label, activeContract.trailerDrop.coords)

    CreateRouteBlip(activeContract.trailerDrop.coords, activeContract.trailerDrop.label, 'trailer')
    CreateRouteAreaBlip(activeContract.trailerDrop.coords, activeContract.trailerDrop.radius, 'TrailerDrop')
    Notify('Load checklist complete. Delivery waypoint assigned.', 'success')
    DispatchChatter(fromReceiver and 'Dispatch verified checklist. Trailer route confirmed. GPS activated.' or 'Checklist received. Trailer load released to receiver.', 'inform', 'secure')
    UpdateMiniUI()
    return true
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
        { name = 'ls_trucking_verify_loaded_cargo', label = 'Verify Loaded Cargo', icon = 'fa-solid fa-clipboard-check', distance = 3.0, canInteract = function() return (Config.LoadVerificationMode or 'receiver') == 'target' and activeContract ~= nil and activeContract.type ~= 'trailer' and activeContract.cargoReady and not activeContract.verifiedCargo and not carryingCargo end, onSelect = VerifyLoadedCargo },
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
                and (not activeContract.trailerHooked or activeContract.trailerConnectionLost)
                and IsAssignedTrailerAttached()
                and not (activeContract.loadChecklist and activeContract.loadChecklist.truckSecure)
                and IsAtRearOfEntity(spawnedVehicle, coords, -0.5)
        end, onSelect = SecureTruckLoadConnection },
        { name = 'ls_trucking_secure_trailer_load_from_truck', label = 'Confirm Trailer Load Secure', icon = 'fa-solid fa-shield-alt', distance = 3.0, canInteract = function(entity, distance, coords)
            local checklist = activeContract and activeContract.loadChecklist or {}

            return activeContract ~= nil
                and activeContract.type == 'trailer'
                and activeContract.trailerAttached
                and not activeContract.trailerHooked
                and IsAssignedTrailerAttached()
                and checklist.truckSecure == true
                and not checklist.trailerSecure
                and IsAtRearOfEntity(spawnedVehicle, coords, -0.5)
        end, onSelect = SecureTrailerLoad },
        { name = 'ls_trucking_complete_load_checklist', label = 'Complete Load Checklist', icon = 'fa-solid fa-clipboard-check', distance = 3.0, canInteract = function(entity, distance, coords)
            return (Config.LoadVerificationMode or 'receiver') == 'target'
                and activeContract ~= nil
                and activeContract.type == 'trailer'
                and activeContract.trailerAttached
                and not activeContract.trailerHooked
                and IsAssignedTrailerAttached()
                and IsAtRearOfEntity(spawnedVehicle, coords, -0.5)
        end, onSelect = CompleteTrailerLoadChecklist },
        { name = 'ls_trucking_disconnect_contract_trailer', label = 'Disconnect Contract Trailer', icon = 'fa-solid fa-link-slash', distance = 3.0, canInteract = function(entity, distance, coords)
            return LS_Trucking.TrailerDropMarker
                and LS_Trucking.TrailerDropMarker.CanDisconnectTrailer
                and LS_Trucking.TrailerDropMarker.CanDisconnectTrailer()
                and IsAtRearOfEntity(spawnedVehicle, coords, -0.5)
        end, onSelect = function()
            if LS_Trucking.TrailerDropMarker and LS_Trucking.TrailerDropMarker.DisconnectTrailer then
                LS_Trucking.TrailerDropMarker.DisconnectTrailer()
            end
        end }
    })
    vehicleTargetAdded = true
end

AddTrailerLoadTarget = function()
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
            end,
            onSelect = SecureTrailerLoad
        }
    })

    trailerTargetAdded = true
end

if DepotVehicles.ConfigureClient then
    DepotVehicles.ConfigureClient({
        Notify = Notify,
        IsPlayerNearCoords = IsPlayerNearCoords,
        ForceDepotDistanceNotify = ForceDepotDistanceNotify,
        RequireNearCoords = RequireNearCoords,
        VehicleReturnDistance = VEHICLE_RETURN_INTERACTION_DISTANCE,
        GetActiveContract = function() return activeContract end,
        GetSpawnedVehicle = function() return spawnedVehicle end,
        SetSpawnedVehicle = function(value) spawnedVehicle = value end,
        GetSpawnedTrailer = function() return spawnedTrailer end,
        SetSpawnedTrailer = function(value) spawnedTrailer = value end,
        SetSpawnedTrailerStartBody = function(value) spawnedTrailerStartBody = value end,
        SetTrailerTargetAdded = function(value) trailerTargetAdded = value end,
        GetGarageVehicle = function() return garageVehicle end,
        SetGarageVehicle = function(value) garageVehicle = value end,
        GetReusableVehicle = function() return reusableVehicle end,
        SetReusableVehicle = function(value) reusableVehicle = value end,
        GetContractorVehicle = function() return contractorVehicle end,
        SetContractorVehicle = function(value) contractorVehicle = value end,
        LoadModel = LoadModel,
        SetVehicleOptions = SetVehicleOptions,
        ApplyVehicleProps = ApplyVehicleProps,
        ApplyTurboStage = ApplyTurboStage,
        ApplyVehicleHealthState = ApplyVehicleHealthState,
        ApplyExtras = ApplyExtras,
        SetFuel = SetFuel,
        GiveKeys = GiveKeys,
        RemoveKeys = RemoveKeys,
        AddVehicleCargoTarget = AddVehicleCargoTarget,
        AddTrailerLoadTarget = AddTrailerLoadTarget,
        GetVehicleProps = GetVehicleProps,
        CleanupJobVehicle = CleanupJobVehicle,
        ClearRouteBlip = ClearRouteBlip,
        RemoveAllZones = RemoveAllZones,
        Progress = Progress,
        UpdateMiniUI = UpdateMiniUI
    })
end



local function SpawnTrailerOnly(vehicleData, routeTrailer, trailerDepot)
    return DepotVehicles.SpawnTrailerOnly and DepotVehicles.SpawnTrailerOnly(vehicleData, routeTrailer, trailerDepot) or false
end

local function SpawnJobVehicle(data)
    return DepotVehicles.SpawnJobVehicle and DepotVehicles.SpawnJobVehicle(data) or false
end

local function SpawnGarageVehicle(data)
    if DepotVehicles.SpawnGarageVehicle then return DepotVehicles.SpawnGarageVehicle(data) == true end
    return false
end

local function SpawnContractorVehicle(data)
    if DepotVehicles.SpawnContractorVehicle then return DepotVehicles.SpawnContractorVehicle(data) == true end
    return false
end

local function ReturnCompanyVehicle()
    if DepotVehicles.ReturnCompanyVehicle then DepotVehicles.ReturnCompanyVehicle() end
end

local function StoreContractorVehicle()
    if DepotVehicles.StoreContractorVehicle then DepotVehicles.StoreContractorVehicle() end
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
    if not Progress('Receiving route cargo...', Config.Progress.collectCargo, { dict = 'pickup_object', clip = 'pickup_low' }) then return end
    local result = lib.callback.await('ls_trucking:server:pickupCargoOne', false)
    if not result or not result.success then Notify(result and result.message or 'Could not collect cargo.', 'error') return end
    activeContract.currentCarryCargoType = result.cargoType
    PlayCargoPickupTransition(activeContract.type, result.cargoType)
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
            local cargoProps = LS_Trucking and LS_Trucking.TrailerCargoProps or {}
            if cargoProps.CleanupForTrailer then
                cargoProps.CleanupForTrailer(trailer)
            end

            DeleteEntity(trailer)
        end

        if spawnedTrailer == trailer then
            spawnedTrailer = nil
        end
    end)
end

local function FinalizeTrailerDelivery(signature)
    if not activeContract or activeContract.type ~= 'trailer' then Notify('You do not have a trailer delivery to finalize.', 'error') return end
    if not activeContract.trailerDropped then Notify('Drop the trailer inside the receiving yard first.', 'error') return end
    local ok = Progress('Receiver reviewing signed manifest...', Config.Progress.finalizeTrailer, { dict = 'missheistdockssetup1clipboard@base', clip = 'base' }, { model = `p_amb_clipboard_01`, bone = 18905, pos = vec3(0.10, 0.02, 0.08), rot = vec3(-80.0, 0.0, 0.0) })
    if not ok then return false end
    local damageData = { startBody = spawnedTrailerStartBody or 1000.0, endBody = 1000.0 }
    if spawnedTrailer and DoesEntityExist(spawnedTrailer) then
        damageData.endBody = GetVehicleBodyHealth(spawnedTrailer)
    end
    local result = lib.callback.await('ls_trucking:server:finalizeTrailerDelivery', false, damageData, signature)
    if not result or not result.success then
        DispatchChatter(('Receiver rejected the delivery handoff: %s'):format(result and result.message or 'paperwork could not be verified.'), 'error', 'alert', { notify = false, direction = 'rx' })
        Notify(result and result.message or 'Could not finalize delivery.', 'error')
        return false
    end

    if activeContract then activeContract.deliverySignature = result.signature end
    DispatchChatter(('Receiver signature verified. Contract %s cleared for closeout.'):format(activeContract.contractId), 'success', 'secure', { notify = false, direction = 'rx' })
    Wait(math.max(350, tonumber((Config.RadioMessageAudio or {}).EndDelay) or 575))
    DespawnDeliveredTrailer()
    CompleteRoute()
    return true
end

local function HandlePickupPedInteraction(ped, pedLabel, scenario)
    if freightHandoffPending then return end
    if not activeContract then Notify('You do not have an active contract.', 'error') return end

    LS_Trucking.FreightHandoff.PlayPedGreeting(ped, scenario)

    local handoff = Config.FreightHandoff or {}
    if handoff.Enabled == false or handoff.RequirePickupSignature == false or activeContract.pickupManifestSigned then
        CollectCargoFromPed()
        return
    end

    freightHandoffPending = true
    local form = ShowFreightHandoff('pickup', pedLabel, LS_Trucking.FreightHandoff.BuildManifest(activeContract, 'pickup', pedLabel))
    if not form.confirmed then
        freightHandoffPending = false
        return
    end

    local contractId = activeContract and activeContract.contractId
    DispatchChatter(('Pickup authorization for Contract %s transmitted to %s.'):format(contractId or 'N/A', pedLabel or 'the freight clerk'), 'inform', 'secure', { notify = false, direction = 'tx' })
    Wait(math.max(0, tonumber(handoff.ResponseDelay) or 900))

    local result = lib.callback.await('ls_trucking:server:authorizePickupHandoff', false, {
        contractId = form.contractId,
        signatureAccepted = form.signatureAccepted == true
    })

    if not result or not result.success then
        DispatchChatter(('Pickup authorization rejected: %s'):format(result and result.message or 'manifest validation failed.'), 'error', 'alert', { notify = false, direction = 'rx' })
        Notify(result and result.message or 'Could not authorize cargo pickup.', 'error')
        freightHandoffPending = false
        return
    end

    if activeContract and activeContract.contractId == contractId then
        activeContract.pickupManifestSigned = true
        activeContract.pickupSignature = result.signature
    end

    DispatchChatter(('Dispatch verified Contract %s. Cargo release approved.'):format(contractId or 'N/A'), 'success', 'secure', { notify = false, direction = 'rx' })
    freightHandoffPending = false
    Notify('Manifest signed and cargo released. Target the freight clerk again to collect the next route item.', 'success')
    UpdateMiniUI()
end

local function HandleReceiverPedInteraction(ped, pedLabel, scenario)
    if freightHandoffPending then return end
    if not activeContract or activeContract.type ~= 'trailer' then Notify('You do not have a trailer delivery to finalize.', 'error') return end

    LS_Trucking.FreightHandoff.PlayPedGreeting(ped, scenario)

    local handoff = Config.FreightHandoff or {}
    if handoff.Enabled == false or handoff.RequireTrailerSignature == false then
        FinalizeTrailerDelivery()
        return
    end

    freightHandoffPending = true
    local form = ShowFreightHandoff('trailer', pedLabel, LS_Trucking.FreightHandoff.BuildManifest(activeContract, 'trailer', pedLabel))
    if not form.confirmed then
        freightHandoffPending = false
        return
    end

    local contractId = activeContract and activeContract.contractId
    DispatchChatter(('Proof of delivery for Contract %s transmitted from %s.'):format(contractId or 'N/A', pedLabel or 'the receiving clerk'), 'inform', 'secure', { notify = false, direction = 'tx' })
    Wait(math.max(0, tonumber(handoff.ResponseDelay) or 900))

    local success = FinalizeTrailerDelivery({
        contractId = form.contractId,
        signatureAccepted = form.signatureAccepted == true
    })
    freightHandoffPending = false
    return success
end

local function AddPickupPedTarget(ped, contractType)
    local pedData = Config.Contracts and Config.Contracts[contractType] and Config.Contracts[contractType].pickupPed or {}
    local pedLabel = pedData.label or 'Pickup Worker'
    local handoff = Config.FreightHandoff or {}
    local handoffRequired = handoff.Enabled ~= false and handoff.RequirePickupSignature ~= false
    local pickupLabel = contractType == 'boxtruck' and 'Pick Up Route Crate' or 'Pick Up Route Package'

    AddTargetEntity(ped, {
        {
            name = ('ls_trucking_talk_pickup_%s'):format(contractType),
            label = ('Talk to %s'):format(pedLabel),
            icon = 'fa-solid fa-comments',
            distance = Config.TargetDistance,
            canInteract = function()
                return handoffRequired and activeContract ~= nil and activeContract.type == contractType and not activeContract.loaded and not activeContract.pickupManifestSigned
            end,
            onSelect = function()
                HandlePickupPedInteraction(ped, pedLabel, pedData.scenario)
            end
        },
        {
            name = ('ls_trucking_collect_cargo_%s'):format(contractType),
            label = pickupLabel,
            icon = 'fa-solid fa-box',
            distance = Config.TargetDistance,
            canInteract = function()
                return activeContract ~= nil
                    and activeContract.type == contractType
                    and not activeContract.loaded
                    and (not handoffRequired or activeContract.pickupManifestSigned == true)
            end,
            onSelect = CollectCargoFromPed
        }
    })
end

local function AddReceiverPedTarget(ped, contractType, routeIndex)
    local pedLabel = activeContract and activeContract.receiverPed and activeContract.receiverPed.label or 'Receiving Clerk'
    AddTargetEntity(ped, { { name = ('ls_trucking_finalize_trailer_%s_%s'):format(contractType, routeIndex), label = ('Talk to %s'):format(pedLabel), icon = 'fa-solid fa-comments', distance = Config.TargetDistance, canInteract = function() return activeContract ~= nil and activeContract.type == contractType and activeContract.routeIndex == routeIndex and activeContract.trailerDropped end, onSelect = function() HandleReceiverPedInteraction(ped, pedLabel, activeContract and activeContract.receiverPed and activeContract.receiverPed.scenario) end } })
end

local function CleanupActiveContractPeds(delay)
    local pedsToClean = {}

    for key, ped in pairs(activeContractPedKeys) do
        pedsToClean[key] = ped
    end

    if not next(pedsToClean) then return end

    local function removePeds()
        for key, ped in pairs(pedsToClean) do
            if ped and DoesEntityExist(ped) then
                if GetTargetSystem() == 'qb' then
                    pcall(function() exports['qb-target']:RemoveTargetEntity(ped) end)
                else
                    pcall(function() exports.ox_target:removeLocalEntity(ped) end)
                end
                DeleteEntity(ped)
            end
            LS_Trucking.FreightHandoff.ClearPed(ped)

            if spawnedPeds[key] == ped then
                spawnedPeds[key] = nil
            end

            if activeContractPedKeys[key] == ped then
                activeContractPedKeys[key] = nil
            end
        end
    end

    LS_Trucking.ActivePedCleanupToken = (LS_Trucking.ActivePedCleanupToken or 0) + 1
    local cleanupToken = LS_Trucking.ActivePedCleanupToken

    if delay then
        LS_Trucking.ActivePedCleanupPending = true
        local cleanupDelay = type(delay) == 'number' and delay or (tonumber(Config.TrailerDespawnAfterDelivery) or 10000)
        SetTimeout(cleanupDelay, function()
            if cleanupToken ~= LS_Trucking.ActivePedCleanupToken then return end
            removePeds()
            LS_Trucking.ActivePedCleanupPending = false
        end)
    else
        LS_Trucking.ActivePedCleanupPending = false
        removePeds()
    end
end

local function SetupActiveContractPeds()
    if not activeContract or not Config.UsePed then
        if next(activeContractPedKeys) and LS_Trucking.ActivePedCleanupPending ~= true then CleanupActiveContractPeds() end
        return
    end

    if LS_Trucking.ActivePedCleanupPending == true then
        LS_Trucking.ActivePedCleanupToken = (LS_Trucking.ActivePedCleanupToken or 0) + 1
        LS_Trucking.ActivePedCleanupPending = false
    end

    local key, pedData
    if activeContract.type == 'van' or activeContract.type == 'boxtruck' then
        local contract = Config.Contracts and Config.Contracts[activeContract.type]
        if contract and contract.pickupPed then
            key = ('active_pickup_%s'):format(activeContract.type)
            pedData = contract.pickupPed
        end
    elseif activeContract.type == 'trailer' and activeContract.receiverPed then
        key = ('active_receiver_%s_%s'):format(activeContract.type, activeContract.routeIndex or 1)
        pedData = activeContract.receiverPed
    end

    if not key or not pedData or not pedData.coords then
        if next(activeContractPedKeys) then CleanupActiveContractPeds() end
        return
    end

    if not activeContractPedKeys[key] and next(activeContractPedKeys) then
        CleanupActiveContractPeds()
    end

    local pedConfig = Config.ActiveContractPeds or {}
    local playerCoords = GetEntityCoords(PlayerPedId())
    local pedCoords = vector3(pedData.coords.x, pedData.coords.y, pedData.coords.z)
    local distance = #(playerCoords - pedCoords)
    local existingPed = activeContractPedKeys[key]

    if distance <= math.max(10.0, tonumber(pedConfig.SpawnDistance) or 100.0) then
        if existingPed and DoesEntityExist(existingPed) then return end

        local ped = SpawnStaticPed(key, pedData)
        if ped then
            activeContractPedKeys[key] = ped
            if activeContract.type == 'trailer' then
                AddReceiverPedTarget(ped, activeContract.type, activeContract.routeIndex or 1)
            else
                AddPickupPedTarget(ped, activeContract.type)
            end
        end
    elseif existingPed and distance >= math.max(15.0, tonumber(pedConfig.DespawnDistance) or 130.0) then
        CleanupActiveContractPeds()
    end
end

CreateThread(function()
    while true do
        SetupActiveContractPeds()
        Wait(math.max(250, tonumber((Config.ActiveContractPeds or {}).CheckInterval) or 750))
    end
end)

local function SetupRouteTargets()
    RemoveAllZones()
    if not activeContract then return end
    if activeContract.type == 'van' or activeContract.type == 'boxtruck' then
        for index, stop in ipairs(activeContract.dropoffs or {}) do
            local dropoffTarget = Config.DropoffTarget or {}
            local targetCoords = vector3(stop.coords.x, stop.coords.y, stop.coords.z + (tonumber(dropoffTarget.HeightOffset) or 0.75))
            local targetRadius = math.max(1.5, tonumber(dropoffTarget.Radius) or 3.5)
            local targetDistance = math.max(Config.TargetDistance or 2.5, tonumber(dropoffTarget.Distance) or 3.5)
            AddSphereZone(('dropoff_%s'):format(index), targetCoords, targetRadius, { { name = ('ls_trucking_dropoff_%s'):format(index), label = ('Deliver Cargo - %s'):format(stop.label), icon = 'fa-solid fa-box-open', distance = targetDistance, canInteract = function() return activeContract and activeContract.loaded and activeContract.currentStop == index and carryingCargo end, onSelect = function()
                if not activeContract or activeContract.currentStop ~= index then return end
                if not Progress('Checking delivery spot...', Config.Progress.deliverCargo, { dict = 'anim@heists@box_carry@', clip = 'idle' }) then return end
                local result = lib.callback.await('ls_trucking:server:deliverCargoOne', false)
                if not result or not result.success then Notify(result and result.message or 'Could not deliver cargo.', 'error') return end
                PlayCargoSetDownTransition()
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
                        DispatchChatter(('Stop complete. Proceed to stop %s of %s.'):format(activeContract.currentStop, activeContract.totalStops), 'inform', 'destination')
                    else
                        SetActiveDestination(currentStop.label, currentStop.coords)
                        activeContract.notice = ('This stop still needs %s more item(s). Open your trunk and grab another.'):format(result.requiredAtStop - result.deliveredAtStop)
                        Notify(activeContract.notice, 'inform')
                    end
                end
                UpdateMiniUI()
            end } })
        end
    elseif activeContract.type == 'trailer' and (Config.TrailerDropMarker or {}).Enabled == false then
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
            local result = lib.callback.await('ls_trucking:server:confirmTrailerDropped', false)
            if not result or not result.success then Notify(result and result.message or 'Could not confirm trailer drop.', 'error') return end
            activeContract.trailerDropped = true
            activeContract.stage = 'Talk to receiver'
            activeContract.notice = 'Talk to the receiving yard worker to finalize the trailer delivery.'
            SetActiveDestination(activeContract.receiverPed.label, vector3(activeContract.receiverPed.coords.x, activeContract.receiverPed.coords.y, activeContract.receiverPed.coords.z))
            CreateRouteBlip(vector3(activeContract.receiverPed.coords.x, activeContract.receiverPed.coords.y, activeContract.receiverPed.coords.z), activeContract.receiverPed.label, 'receiver')
            Notify('Trailer drop confirmed. Talk to the receiver to finalize.', 'success')
            DispatchChatter('Trailer drop confirmed. Receiver paperwork is ready for signature.', 'inform', 'secure')
            UpdateMiniUI()
        end } })
    end
end

if LS_Trucking.TrailerDropMarker and LS_Trucking.TrailerDropMarker.ConfigureClient then
    LS_Trucking.TrailerDropMarker.ConfigureClient({
        GetActiveContract = function() return activeContract end,
        GetSpawnedVehicle = function() return spawnedVehicle end,
        GetSpawnedTrailer = function() return spawnedTrailer end,
        IsAssignedTrailerAttached = IsAssignedTrailerAttached,
        SetActiveDestination = SetActiveDestination,
        CreateRouteBlip = CreateRouteBlip,
        Notify = Notify,
        DispatchChatter = DispatchChatter,
        UpdateMiniUI = UpdateMiniUI,
        Progress = Progress,
        PlayUISound = PlayUISound
    })
end

if Routes.ConfigureClient then
    Routes.ConfigureClient({
        Notify = Notify,
        ShowFreightCancelDialog = ShowFreightCancelDialog,
        GetActiveContract = function() return activeContract end,
        SetActiveContract = function(value) activeContract = value end,
        GetGarageVehicle = function() return garageVehicle end,
        SetGarageVehicle = function(value) garageVehicle = value end,
        SetReusableVehicle = function(value) reusableVehicle = value end,
        SetReceiverDockUserHidden = function(value) receiverDockUserHidden = value end,
        SetLastCompletedCargoCondition = function(value) lastCompletedCargoCondition = value end,
        CanReuseVehicle = CanReuseVehicle,
        SpawnTrailerOnly = SpawnTrailerOnly,
        SpawnJobVehicle = SpawnJobVehicle,
        CleanupJobVehicle = CleanupJobVehicle,
        AddVehicleCargoTarget = AddVehicleCargoTarget,
        ResetCargoCondition = ResetCargoCondition,
        SetupActiveContractPeds = SetupActiveContractPeds,
        SetupRouteTargets = SetupRouteTargets,
        RegisterAssignedTrailer = function(contractId)
            if spawnedTrailer and DoesEntityExist(spawnedTrailer) then
                TriggerServerEvent('ls_trucking:server:registerAssignedTrailer', contractId, NetworkGetNetworkIdFromEntity(spawnedTrailer))
            end
        end,
        CleanupActiveContractPeds = CleanupActiveContractPeds,
        SetActiveDestination = SetActiveDestination,
        CreateRouteBlip = CreateRouteBlip,
        CreateRouteAreaBlip = CreateRouteAreaBlip,
        ClearRouteBlip = ClearRouteBlip,
        RemoveAllZones = RemoveAllZones,
        DeleteCarryProp = DeleteCarryProp,
        DispatchChatter = DispatchChatter,
        UpdateMiniUI = UpdateMiniUI,
        CleanupPendingContractStart = function()
            return lib.callback.await('ls_trucking:server:cleanupPendingContractStart', false)
        end
    })
end

function CompleteRoute()
    if Routes.CompleteRoute then Routes.CompleteRoute() end
end

local function CancelActiveContract()
    if Routes.CancelActiveContract then Routes.CancelActiveContract() end
end

local function CancelActiveContractFromReceiver()
    return Routes.CancelActiveContract and Routes.CancelActiveContract({ fromReceiver = true }) or false
end

local function CleanupFailedLocalRouteStart(data, reuseVehicle)
    lib.callback.await('ls_trucking:server:cleanupPendingContractStart', false)

    if data and data.contractor == true and reuseVehicle == true then
        if data.contractType == 'trailer' then CleanupTrailerOnly() end
        return
    end

    CleanupJobVehicle()
end

local function StartLocalContract(data, reuseVehicle)
    if Routes.StartLocalContract then
        local ok, started = pcall(Routes.StartLocalContract, data, reuseVehicle)

        if not ok then
            if Config.Debug then
                print(('[ls_trucking] Client route start failed: %s'):format(started))
            end

            CleanupFailedLocalRouteStart(data, reuseVehicle)
            Notify('Unable to start the route locally. Dispatch released the pending contract.', 'error')
            return false
        end

        return started == true
    end

    return false
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
    AddField('Vehicle', activeContract.vehicleLabel)
    AddField('Plate', activeContract.plate)
    AddField('Cargo Condition', activeContract.cargoConditionLabel)
    AddField('Condition Notes', activeContract.cargoConditionNote)
    AddField('Last Dispatch', activeContract.radioChatter)

    if activeContract.pickupSignature or activeContract.deliverySignature then
        lines[#lines + 1] = ''
        lines[#lines + 1] = 'Handoff Paperwork'
        lines[#lines + 1] = '-----------------'
    end

    if activeContract.pickupSignature then
        AddField('Pickup Signed By', activeContract.pickupSignature.name)
        AddField('Pickup Signed At', activeContract.pickupSignature.signedAt)
        AddField('Pickup Location', activeContract.pickupSignature.location)
    end

    if activeContract.deliverySignature then
        AddField('Delivery Signed By', activeContract.deliverySignature.name)
        AddField('Delivery Signed At', activeContract.deliverySignature.signedAt)
        AddField('Receiver Location', activeContract.deliverySignature.location)
    end

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
            lines[#lines + 1] = ('  Packages: %s'):format(#cargoParts > 0 and table.concat(cargoParts, ', ') or tostring(stop.count))
        end
    end

    ShowFreightDialog('Route Manifest / Paperwork', lines, 'Close Manifest')
end

RegisterNetEvent('ls_trucking:client:openManifest', ShowActiveManifest)

local function HandleReceiverVehicleControl(action)
    return ReceiverVehicleControls.Handle(action, {
        getVehicle = function()
            if spawnedVehicle and DoesEntityExist(spawnedVehicle) then return spawnedVehicle end
            return 0
        end,
        notify = Notify,
        playSound = PlayUISound,
        updateMiniUI = UpdateMiniUI
    })
end

local function DispatchMapCoords(coords)
    if not coords then return nil end

    return {
        x = coords.x + 0.0,
        y = coords.y + 0.0,
        z = coords.z + 0.0
    }
end

local function DispatchMapZone(coords)
    if not coords then return 'San Andreas' end

    local x = tonumber(coords.x) or 0.0
    local y = tonumber(coords.y) or 0.0

    if y > 5600 then return 'Paleto Bay / North County' end
    if y > 2200 then return 'Blaine County' end
    if y < -2400 then return 'Port of Los Santos' end
    if x < -1500 then return 'West Coast' end
    if x > 1200 then return 'East County' end
    return 'Los Santos'
end

local function DispatchMapStreetAddress(coords)
    if not coords then return 'Address unavailable' end

    local streetHash, crossingHash = GetStreetNameAtCoord(coords.x + 0.0, coords.y + 0.0, coords.z + 0.0)
    local street = streetHash and streetHash ~= 0 and GetStreetNameFromHashKey(streetHash) or nil
    local crossing = crossingHash and crossingHash ~= 0 and GetStreetNameFromHashKey(crossingHash) or nil

    if street and street ~= '' and crossing and crossing ~= '' and crossing ~= street then
        return ('%s / %s'):format(street, crossing)
    end

    if street and street ~= '' then return street end

    return DispatchMapZone(coords)
end

local function GetDispatchHomeConfig()
    return Config.DispatchHome or {}
end

local function DispatchHomePhoto(key)
    local photos = GetDispatchHomeConfig().Photos or {}
    local photo = photos[key]
    if photo and photo ~= '' then return photo end

    return nil
end

local function DispatchTrailerDepotPhoto(depotKey)
    local photos = GetDispatchHomeConfig().Photos or {}
    local depotPhotos = photos.trailerDepots or {}
    local photo = depotPhotos[depotKey] or photos.trailerDepot
    if photo and photo ~= '' then return photo end

    return nil
end

local function AddDispatchMapPoint(points, point)
    if not point or not point.coords then return end

    point.zone = point.zone or DispatchMapZone(point.coords)
    point.address = point.address or DispatchMapStreetAddress(point.coords)
    point.details = point.details or {
        { icon = 'fa-road', label = 'Street Address', value = point.address },
        { icon = 'fa-clipboard-check', label = 'Use', value = point.description or 'LSFC operating point.' }
    }

    points[#points + 1] = point
end

local function BuildDispatchHomeMapData()
    local points = {}
    local depot = Config.Depot or {}
    local contracts = Config.Contracts or {}
    local homeConfig = GetDispatchHomeConfig()

    AddDispatchMapPoint(points, {
        id = 'depot-terminal',
        category = 'terminal',
        icon = 'fas fa-tower-broadcast',
        shortLabel = 'LSFC',
        label = 'Los Santos Freight Co. Terminal',
        description = 'Primary dispatch terminal for contracts, route review, vehicle requests, and company paperwork.',
        coords = DispatchMapCoords(depot.terminal or (Config.DispatchBlip and Config.DispatchBlip.coords)),
        photo = DispatchHomePhoto('terminal'),
        details = {
            { icon = 'fa-file-contract', label = 'Functions', value = 'Dispatch board, current jobs, history, contractor desk' },
            { icon = 'fa-road', label = 'Street Address', value = DispatchMapStreetAddress(depot.terminal or (Config.DispatchBlip and Config.DispatchBlip.coords)) }
        }
    })

    AddDispatchMapPoint(points, {
        id = 'depot-vehicle-spawn',
        category = 'vehicle',
        icon = 'fas fa-truck-fast',
        shortLabel = 'UNIT',
        label = 'Company Vehicle Spawn',
        description = 'Company route vehicles are staged here after contract approval.',
        coords = DispatchMapCoords(depot.vehicleSpawn),
        photo = DispatchHomePhoto('vehicleSpawn'),
        details = {
            { icon = 'fa-truck-fast', label = 'Functions', value = 'Company contract vehicle pickup' },
            { icon = 'fa-circle-info', label = 'Spawn Check', value = 'Area must be clear before vehicle release' },
            { icon = 'fa-road', label = 'Street Address', value = DispatchMapStreetAddress(depot.vehicleSpawn) }
        }
    })

    AddDispatchMapPoint(points, {
        id = 'depot-garage-spawn',
        category = 'garage',
        icon = 'fas fa-warehouse',
        shortLabel = 'GAR',
        label = 'Garage Vehicle Spawn',
        description = 'Stored company and contractor units are released from this garage staging area.',
        coords = DispatchMapCoords(depot.garageSpawn or depot.vehicleSpawn),
        photo = DispatchHomePhoto('garageSpawn'),
        details = {
            { icon = 'fa-warehouse', label = 'Functions', value = 'Company garage and private fleet pickup' },
            { icon = 'fa-key', label = 'Access', value = 'Assigned vehicle owner receives keys' },
            { icon = 'fa-road', label = 'Street Address', value = DispatchMapStreetAddress(depot.garageSpawn or depot.vehicleSpawn) }
        }
    })

    local pickupTypes = {
        { type = 'van', category = 'van', label = 'Van Package Pickup', photo = DispatchHomePhoto('vanPickup'), icon = 'fas fa-box', shortLabel = 'VAN' },
        { type = 'boxtruck', category = 'boxtruck', label = 'Box Truck Freight Pickup', photo = DispatchHomePhoto('boxTruckPickup'), icon = 'fas fa-truck-moving', shortLabel = 'BOX' }
    }

    for _, pickupType in ipairs(pickupTypes) do
        local contract = contracts[pickupType.type]
        local pickup = contract and contract.pickup

        AddDispatchMapPoint(points, {
            id = ('pickup-%s'):format(pickupType.type),
            category = pickupType.category,
            icon = pickupType.icon,
            shortLabel = pickupType.shortLabel,
            label = (pickup and pickup.label) or pickupType.label,
            description = contract and contract.description or 'Freight pickup location.',
            coords = DispatchMapCoords(pickup and pickup.coords),
            photo = pickupType.photo,
            details = {
                { icon = 'fa-boxes-stacked', label = 'Cargo', value = contract and contract.cargo or 'Cargo' },
                { icon = 'fa-route', label = 'Route Type', value = contract and contract.label or pickupType.label },
                { icon = 'fa-road', label = 'Street Address', value = DispatchMapStreetAddress(pickup and pickup.coords) }
            }
        })
    end

    local trailerDepotKeys = {}
    for key in pairs(Config.TrailerDepots or {}) do trailerDepotKeys[#trailerDepotKeys + 1] = key end
    table.sort(trailerDepotKeys)

    for _, key in ipairs(trailerDepotKeys) do
        local trailerDepot = Config.TrailerDepots[key]
        AddDispatchMapPoint(points, {
            id = ('trailer-%s'):format(key),
            category = 'trailer',
            icon = 'fas fa-trailer',
            shortLabel = 'TRL',
            label = trailerDepot.label or 'Trailer Depot',
            description = 'Trailer hookup yard for assigned trailer haul contracts.',
            coords = DispatchMapCoords(trailerDepot.pickup),
            photo = DispatchTrailerDepotPhoto(key),
            details = {
                { icon = 'fa-trailer', label = 'Functions', value = 'Trailer pickup, hookup, and yard release' },
                { icon = 'fa-square-parking', label = 'Spawn Spots', value = tostring(#(trailerDepot.spawns or {})) },
                { icon = 'fa-road', label = 'Street Address', value = DispatchMapStreetAddress(trailerDepot.pickup) }
            }
        })
    end

    return {
        points = points,
        mapImage = homeConfig.MapImage,
        mapBounds = homeConfig.MapBounds,
        mapZoom = homeConfig.MapZoom,
        mapZoomMin = homeConfig.MapZoomMin,
        mapZoomMax = homeConfig.MapZoomMax,
        mapZoomStep = homeConfig.MapZoomStep
    }
end

local function BuildDispatchUIData()
    local data = lib.callback.await('ls_trucking:server:getDispatchData', false)
    if not data or not data.allowed then return nil, data and data.message or 'Unable to open trucking dispatch.' end
    currentDriverInfo = data.player or currentDriverInfo
    if currentDriverInfo and currentDriverInfo.citizenid and RouteHistory.SetCharacter then RouteHistory.SetCharacter(currentDriverInfo.citizenid) end
    data.reuse = GetReuseData()
    data.config = { allowVehicleReuseAfterRoute = Config.AllowVehicleReuseAfterRoute, requireSameTypeForVehicleReuse = Config.RequireSameTypeForVehicleReuse, radioFrequency = Config.RadioFrequency, locale = Config.Locale or 'en', uiSounds = Config.UI or {} }
    data.dispatchHome = BuildDispatchHomeMapData()
    data.lastRouteSummary = RouteHistory.GetLast()
    data.routeHistory = RouteHistory.GetHistory()
    data.currentJob = RouteState.BuildCurrentJob and RouteState.BuildCurrentJob(activeContract) or nil
    return data
end

local function RefreshDispatchUI(delayMs, attempts)
    if not dispatchUIVisible then return end
    delayMs = tonumber(delayMs) or 0
    attempts = math.max(1, tonumber(attempts) or 1)

    CreateThread(function()
        if delayMs > 0 then Wait(delayMs) end

        for attempt = 1, attempts do
            if not dispatchUIVisible then return end

            local data, message = BuildDispatchUIData()
            if data then
                SendNUIMessage({ action = 'refreshDispatch', data = data })
                return
            end

            if attempt < attempts then
                Wait(550)
            else
                Notify(message or 'Unable to refresh trucking dispatch.', 'error')
            end
        end
    end)
end

local function GetContractorBoardRefreshMs()
    local minutes = tonumber(Config.PrivateContractor and Config.PrivateContractor.ContractBoardRefreshMinutes) or 60
    return math.max(60000, math.floor(minutes * 60000))
end

local function StartContractorBoardRefreshLoop()
    contractorBoardRefreshToken = contractorBoardRefreshToken + 1
    local token = contractorBoardRefreshToken

    CreateThread(function()
        while dispatchUIVisible and token == contractorBoardRefreshToken do
            Wait(GetContractorBoardRefreshMs())
            if dispatchUIVisible and token == contractorBoardRefreshToken and dispatchActiveTab == 'contractor' then
                RefreshDispatchUI(0, 1)
            end
        end
    end)
end

LS_Trucking.RequestReceiverAccess = function()
    if receiverAccessPending then return nil end

    receiverAccessPending = true
    local access = lib.callback.await('ls_trucking:server:canUseReceiver', false)
    receiverAccessPending = false

    if access and access.player then
        currentDriverInfo = access.player or currentDriverInfo
        if currentDriverInfo and currentDriverInfo.citizenid and RouteHistory.SetCharacter then RouteHistory.SetCharacter(currentDriverInfo.citizenid) end
    end

    if Config.RequireJob and (not access or not access.allowed) then
        Notify(access and access.message or 'Receiver access denied.', 'error')
        return nil
    end

    return access or { allowed = true }
end

LS_Trucking.ToggleDutyStatus = function()
    if LS_Trucking.DutyTogglePending then return end

    LS_Trucking.DutyTogglePending = true
    local result = lib.callback.await('ls_trucking:server:toggleDuty', false)
    LS_Trucking.DutyTogglePending = false

    if not result then
        Notify('Unable to update duty status.', 'error')
        return
    end

    Notify(result.message or 'Duty status updated.', result.success and 'success' or 'error')

    if result.success and dispatchUIVisible then
        RefreshDispatchUI(250, 1)
    end
end

function OpenDispatch()
    local data, message = BuildDispatchUIData()
    if not data then Notify(message or 'Unable to open trucking dispatch.', 'error') return end
    StartTabletAnim()
    dispatchUIVisible = true
    dispatchActiveTab = 'home'
    SetKeepInput(false)
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', data = data })
    StartContractorBoardRefreshLoop()
end

RegisterNetEvent('ls_trucking:client:openDispatch', OpenDispatch)

local function ToggleFullReceiver()
    if Config.FullReceiverEnabled == false or Config.MiniUIEnabled == false then return end

    if fullReceiverVisible then
        receiverControlBlockUntil = GetGameTimer() + 700
        fullReceiverVisible = false
        SendNUIMessage({ action = 'hideMini' })
        miniFullVisible = false

        if not dispatchUIVisible then
            SetNuiFocus(false, false)
            SetKeepInput(false)
            StopReceiverAnimDeferred(420)
        end

        return
    end

    local access = LS_Trucking.RequestReceiverAccess()
    if not access then return end

    fullReceiverVisible = true
    SetNuiFocus(true, true)
    SetKeepInput(not dispatchUIVisible)
    if not dispatchUIVisible then StartReceiverAnim() end
    UpdateMiniUI()
end

local function ToggleReceiverDock()
    if Config.MiniUIEnabled == false or Config.ReceiverDockEnabled == false then
        Notify('Receiver dock is disabled.', 'error')
        return
    end

    if not activeContract then
        Notify('No active route dock is available.', 'inform')
        return
    end

    if receiverDockUserHidden then
        local access = LS_Trucking.RequestReceiverAccess()
        if not access then return end
    end

    receiverDockUserHidden = not receiverDockUserHidden
    UpdateMiniUI()
    Notify(receiverDockUserHidden and 'Compact receiver dock hidden.' or 'Compact receiver dock shown.', 'inform')
end

RegisterNetEvent('ls_trucking:client:toggleReceiver', ToggleFullReceiver)
RegisterNetEvent('ls_trucking:client:toggleDock', ToggleReceiverDock)
RegisterNetEvent('ls_trucking:client:toggleMiniUI', ToggleReceiverDock)
RegisterNetEvent('ls_trucking:client:cancelActiveContract', CancelActiveContract)

local function AddCommandSuggestion(command, help, params)
    command = tostring(command or ''):gsub('^/', '')
    if command == '' or commandSuggestions[command] then return end

    commandSuggestions[command] = true
    TriggerEvent('chat:addSuggestion', ('/%s'):format(command), help, params or {})
end

local function RegisterCommandSuggestions()
    AddCommandSuggestion(Config.Command or 'trucking', 'Open the Los Santos Freight Co. dispatch tablet.')

    local receiverCommand = Config.FullReceiverCommand or 'truckreceiver'
    AddCommandSuggestion(receiverCommand, 'Toggle the LS Freight handheld receiver.')

    if Config.MiniUIToggleCommand and Config.MiniUIToggleCommand ~= receiverCommand then
        AddCommandSuggestion(Config.MiniUIToggleCommand, 'Toggle the compact LS Freight route dock.')
    end

    AddCommandSuggestion(Config.CancelCommand or 'canceltrucking', 'Cancel your active LS Freight route.')

    local showAdminCommands = lib.callback.await('ls_trucking:server:canUseAdminCommand', false) == true
    if not showAdminCommands then return end

    AddCommandSuggestion('lstruck_resetjob', 'Admin: force reset your active trucking job.')
    AddCommandSuggestion('lstruck_clearpeds', 'Admin: clear active contract worker peds.')
    AddCommandSuggestion('lstruck_giveitems', 'Admin: give yourself cargo items for the active route.')
    AddCommandSuggestion('lstruck_summary', 'Admin: open a route state summary.')
    AddCommandSuggestion('lstraileredit', 'Admin: open the trailer cargo prop editor.', {
        { name = 'trailerKey', help = 'Config.RouteTrailers key, for example flatbed_crates' }
    })
    AddCommandSuggestion('lstrailertest', 'Admin: spawn a configured trailer without starting a contract.', {
        { name = 'trailerKey', help = 'Config.RouteTrailers key, for example flatbed_crates' }
    })
    AddCommandSuggestion('lstrailerclear', 'Admin: remove the currently spawned trailer test unit.')
    AddCommandSuggestion('lstruck_rank', 'Admin: set trucking rank XP.', {
        { name = 'rank', help = 'Rank number to apply' }
    })
    AddCommandSuggestion('lstruck_rep', 'Admin: adjust trucking reputation.', {
        { name = 'amount', help = 'Reputation amount to add or remove' }
    })
    AddCommandSuggestion('lstruck_resetstats', 'Admin: reset your trucking stats.')
end

CreateThread(function()
    Wait(750)
    RegisterCommandSuggestions()
end)

local receiverCommandName = Config.FullReceiverCommand or 'truckreceiver'
RegisterCommand(Config.Command or 'trucking', OpenDispatch, false)
RegisterCommand(receiverCommandName, ToggleFullReceiver, false)
if Config.MiniUIToggleCommand and Config.MiniUIToggleCommand ~= receiverCommandName then
    RegisterCommand(Config.MiniUIToggleCommand, ToggleReceiverDock, false)
end
if RegisterKeyMapping and Config.DispatchKey then
    RegisterKeyMapping(Config.Command or 'trucking', 'Open Los Santos Freight dispatch', 'keyboard', Config.DispatchKey)
end
if RegisterKeyMapping and Config.FullReceiverKey then
    RegisterKeyMapping(receiverCommandName, 'Toggle LS Freight handheld receiver', 'keyboard', Config.FullReceiverKey)
end
RegisterCommand(Config.CancelCommand, CancelActiveContract, false)

RegisterNUICallback('freightDialogClose', function(_, cb)
    local returnFocus = freightDialogReturnFocus == true
    freightDialogReturnFocus = false
    SetNuiFocus(returnFocus, returnFocus)
    SetKeepInput(returnFocus and fullReceiverVisible and not dispatchUIVisible)
    SendNUIMessage({ action = 'hideFreightDialog' })

    if freightDialogPromise then
        freightDialogPromise:resolve({ confirmed = false })
        freightDialogPromise = nil
    end

    cb(true)
end)

RegisterNUICallback('freightDialogResult', function(data, cb)
    local returnFocus = freightDialogReturnFocus == true
    freightDialogReturnFocus = false
    SetNuiFocus(returnFocus, returnFocus)
    SetKeepInput(returnFocus and fullReceiverVisible and not dispatchUIVisible)
    SendNUIMessage({ action = 'hideFreightDialog' })

    if freightDialogPromise then
        freightDialogPromise:resolve(data or { confirmed = false })
        freightDialogPromise = nil
    end

    cb(true)
end)
RegisterNUICallback('close', function(_, cb)
    freightDialogReturnFocus = false
    dispatchUIVisible = false
    dispatchActiveTab = 'home'
    StopTabletAnimForDispatchClose()
    SetNuiFocus(fullReceiverVisible, fullReceiverVisible)
    SetKeepInput(fullReceiverVisible)
    if fullReceiverVisible then StartReceiverAnim() end
    SendNUIMessage({ action = 'hideFreightDialog' })
    SendNUIMessage({ action = 'close' })
    cb(true)
end)

RegisterNUICallback('dispatchTabChanged', function(data, cb)
    local tab = data and data.tab or 'home'
    if type(tab) ~= 'string' then tab = 'home' end
    dispatchActiveTab = tab
    cb(true)

    if dispatchUIVisible and dispatchActiveTab == 'contractor' then
        RefreshDispatchUI(650, 2)
    end
end)

RegisterNUICallback('dispatchSetGps', function(data, cb)
    local x = data and tonumber(data.x) or nil
    local y = data and tonumber(data.y) or nil

    if not x or not y then
        Notify('Unable to set GPS for that dispatch location.', 'error')
        cb({ success = false })
        return
    end

    SetNewWaypoint(x + 0.0, y + 0.0)
    Notify(('GPS set to %s.'):format(data.label or 'dispatch location'), 'success')
    cb({ success = true })
end)

RegisterNUICallback('closeReceiver', function(_, cb)
    receiverControlBlockUntil = GetGameTimer() + 700
    fullReceiverVisible = false
    SendNUIMessage({ action = 'hideMini' })
    miniFullVisible = false
    if not dispatchUIVisible then
        SetNuiFocus(false, false)
        SetKeepInput(false)
    end
    cb(true)
    StopReceiverAnimDeferred(420)
end)

RegisterNUICallback('startContract', function(data, cb)
    local contractType = data and data.contractType
    local vehicleIndex = data and data.vehicleIndex or 1
    local reuseVehicle = data and data.reuseVehicle == true
    local priorityKey = data and data.priorityKey or 'standard'
    local previewRouteIndex = data and tonumber(data.routeIndex) or nil
    local currentPlate = reuseVehicle and GetJobVehiclePlate() or nil
    if not contractType then cb({ success = false }) return end
    if activeContract then Notify('You already have an active job. Cancel it from the Current Job panel first.', 'error') cb({ success = false }) return end
    if reuseVehicle and not CanReuseVehicle(contractType) then Notify(T('error.vehicle_reuse_type'), 'error') cb({ success = false }) return end
    if not reuseVehicle and spawnedVehicle and DoesEntityExist(spawnedVehicle) then Notify('Store or return your current vehicle before starting another contract.', 'error') cb({ success = false }) return end
    if not reuseVehicle and not RequireNearDepotRequestArea(T('error.need_company_spawn_area')) then cb({ success = false }) return end
    if not LS_Trucking.BeginContractRequest(('Contract request transmitted for %s service. Dispatch is reviewing route and vehicle availability.'):format(contractType)) then cb({ success = false }) return end
    local result = lib.callback.await('ls_trucking:server:createContract', false, contractType, vehicleIndex, reuseVehicle, currentPlate, priorityKey, previewRouteIndex)
    LS_Trucking.ResolveContractRequest(result, result and result.success and ('Dispatch approved %s. Contract %s confirmed. Vehicle release and GPS authorized.'):format(result.contract and result.contract.routeLabel or 'the selected route', result.contractId or 'pending') or nil)
    if not result or not result.success then cb({ success = false }) return end
    if not StartLocalContract(result, reuseVehicle) then
        RefreshDispatchUI(650, 2)
        cb({ success = false })
        return
    end

    dispatchUIVisible = false
    StopTabletAnimForDispatchClose()
    SetNuiFocus(fullReceiverVisible, fullReceiverVisible)
    SetKeepInput(fullReceiverVisible)
    if fullReceiverVisible then StartReceiverAnim() end
    SendNUIMessage({ action = 'close' })
    cb({ success = true })
end)

RegisterNUICallback('receiverVehicleControl', function(data, cb)
    local success = HandleReceiverVehicleControl(data and data.action)
    cb({ success = success })
end)

RegisterNUICallback('receiverToggleDock', function(_, cb)
    ToggleReceiverDock()
    cb({ success = true })
end)

RegisterNUICallback('receiverLoadAction', function(data, cb)
    if (Config.LoadVerificationMode or 'receiver') ~= 'receiver' then
        Notify('Load verification is configured for target interactions.', 'error')
        cb({ success = false })
        return
    end

    if LS_Trucking.ReceiverLoadActionPending then
        Notify('Dispatch is already processing a load request.', 'inform')
        cb({ success = false })
        return
    end

    if not activeContract then
        Notify('No active load is assigned to this receiver.', 'error')
        cb({ success = false })
        return
    end

    if not spawnedVehicle or not DoesEntityExist(spawnedVehicle) then
        Notify('Your assigned vehicle is not available.', 'error')
        cb({ success = false })
        return
    end

    if #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(spawnedVehicle)) > 8.0 then
        Notify('Stand near the assigned vehicle to complete load verification.', 'error')
        cb({ success = false })
        return
    end

    if GetEntitySpeed(spawnedVehicle) > 0.75 then
        Notify('Stop the vehicle before completing load verification.', 'error')
        cb({ success = false })
        return
    end

    local action = data and data.action or ''
    LS_Trucking.ReceiverLoadActionPending = true
    activeContract.receiverLoadAction = action
    UpdateMiniUI()

    local success = false
    if action == 'verify_cargo' then
        success = VerifyLoadedCargo(true) == true
    elseif action == 'submit_checklist' then
        success = CompleteTrailerLoadChecklist(true) == true
    else
        Notify('Unknown receiver load action.', 'error')
    end

    LS_Trucking.ReceiverLoadActionPending = false
    if activeContract then activeContract.receiverLoadAction = nil end
    UpdateMiniUI()
    cb({ success = success })
end)

RegisterNUICallback('receiverStartCurrentJob', function(data, cb)
    if activeContract then
        Notify('Finish or cancel your active route before requesting another load.', 'error')
        cb({ success = false })
        return
    end

    local priorityKey = data and data.priorityKey or 'standard'

    if contractorVehicle then
        if not spawnedVehicle or not DoesEntityExist(spawnedVehicle) then
            Notify('No current contractor vehicle detected.', 'error')
            cb({ success = false })
            return
        end

        local state = BuildCurrentVehicleState()
        if not state then
            Notify('Could not read contractor vehicle state.', 'error')
            cb({ success = false })
            return
        end

        if not LS_Trucking.BeginContractRequest('Private load request transmitted. Dispatch is verifying contractor authority and route availability.') then cb({ success = false }) return end
        local result = lib.callback.await('ls_trucking:server:createContractorContract', false, contractorVehicle.id, priorityKey, nil, state)
        LS_Trucking.ResolveContractRequest(result, result and result.success and ('Dispatch approved %s. Private contract %s confirmed. GPS authorized.'):format(result.contract and result.contract.routeLabel or 'the assigned route', result.contractId or 'pending') or nil)
        if not result or not result.success then
            cb({ success = false })
            return
        end

        if not StartLocalContract(result, true) then
            cb({ success = false })
            return
        end

        cb({ success = true })
        return
    end

    if Config.AllowVehicleReuseAfterRoute == false then
        Notify('Current-vehicle route requests are disabled.', 'error')
        cb({ success = false })
        return
    end

    local reuse = BuildReceiverReuseData()
    if not reuse.available or not reuse.type then
        Notify('No current vehicle detected.', 'error')
        cb({ success = false })
        return
    end

    if not CanReuseVehicle(reuse.type) then
        Notify('Your current vehicle cannot be used for a new route.', 'error')
        cb({ success = false })
        return
    end

    local plate = GetJobVehiclePlate()
    if not LS_Trucking.BeginContractRequest('Current-unit load request transmitted. Dispatch is searching available company routes.') then cb({ success = false }) return end
    local result = lib.callback.await('ls_trucking:server:createContract', false, reuse.type, reuse.index or 1, true, plate, priorityKey, nil)
    LS_Trucking.ResolveContractRequest(result, result and result.success and ('Dispatch assigned %s. Contract %s confirmed. GPS authorized.'):format(result.contract and result.contract.routeLabel or 'a new route', result.contractId or 'pending') or nil)

    if not result or not result.success then
        cb({ success = false })
        return
    end

    if not StartLocalContract(result, true) then
        cb({ success = false })
        return
    end

    cb({ success = true })
end)

RegisterNUICallback('receiverCancelRoute', function(_, cb)
    local success = CancelActiveContractFromReceiver()
    cb({ success = success == true })
end)

RegisterNUICallback('cancelCurrentJob', function(_, cb)
    dispatchUIVisible = false
    StopTabletAnimForDispatchClose()
    SetNuiFocus(fullReceiverVisible, fullReceiverVisible)
    SetKeepInput(fullReceiverVisible)
    if fullReceiverVisible then StartReceiverAnim() end
    SendNUIMessage({ action = 'close' })
    Wait(100)
    CancelActiveContract()
    cb(true)
end)

RegisterNUICallback('openActiveManifest', function(_, cb)
    ShowActiveManifest()
    cb(true)
end)

function LS_Trucking.IsStaleVehicleCheckoutMessage(message)
    message = tostring(message or ''):lower()
    return message:find('vehicle checked out', 1, true) ~= nil
        or message:find('vehicle out', 1, true) ~= nil
        or message:find('unit out', 1, true) ~= nil
        or message:find('only one private contractor vehicle', 1, true) ~= nil
end

function LS_Trucking.TryReleaseStaleVehicleCheckout()
    if spawnedVehicle and DoesEntityExist(spawnedVehicle) then return false end

    local result = lib.callback.await('ls_trucking:server:releaseStaleVehicleCheckout', false)
    return result and result.success and result.released == true
end

function LS_Trucking.CloseDispatchForVehicleSpawn()
    dispatchUIVisible = false
    StopTabletAnimForDispatchClose()
    SetNuiFocus(fullReceiverVisible, fullReceiverVisible)
    SetKeepInput(fullReceiverVisible)
    if fullReceiverVisible then StartReceiverAnim() end
    SendNUIMessage({ action = 'close' })
end

RegisterNUICallback('spawnGarageVehicle', function(data, cb)
    if activeContract then Notify('You cannot spawn a garage vehicle while on a job.', 'error') cb({ success = false }) return end
    if spawnedVehicle and DoesEntityExist(spawnedVehicle) then Notify('You already have a company vehicle out. Return it first.', 'error') cb({ success = false }) return end
    if not data or not data.vehicleType or not data.vehicleIndex then cb({ success = false }) return end
    if not RequireNearDepotRequestArea('You need to be closer to the company garage area to request a vehicle.') then cb({ success = false }) return end
    if not Progress('Requesting company vehicle...', Config.Progress.spawnGarageVehicle, { dict = 'missheistdockssetup1clipboard@base', clip = 'base' }) then cb({ success = false }) return end
    local result = lib.callback.await('ls_trucking:server:spawnGarageVehicle', false, data.vehicleType, data.vehicleIndex)
    if (not result or not result.success) and LS_Trucking.IsStaleVehicleCheckoutMessage(result and result.message) and LS_Trucking.TryReleaseStaleVehicleCheckout() then
        result = lib.callback.await('ls_trucking:server:spawnGarageVehicle', false, data.vehicleType, data.vehicleIndex)
    end
    if not result or not result.success then Notify(result and result.message or 'Unable to spawn garage vehicle.', 'error') cb({ success = false }) return end
    if not SpawnGarageVehicle(result) then
        lib.callback.await('ls_trucking:server:releaseStaleVehicleCheckout', false)
        cb({ success = false })
        return
    end
    LS_Trucking.CloseDispatchForVehicleSpawn()
    cb({ success = true })
end)
RegisterNUICallback('returnGarageVehicle', function(_, cb)
    LS_Trucking.CloseDispatchForVehicleSpawn()
    ReturnCompanyVehicle()
    cb(true)
end)


if ServiceBay.ConfigureClient then
    ServiceBay.ConfigureClient({
        Notify = Notify,
        SetKeepInput = SetKeepInput,
        PlayUISound = PlayUISound,
        GetSpawnedVehicle = function() return spawnedVehicle end,
        GetGarageVehicle = function() return garageVehicle end,
        GetContractorVehicle = function() return contractorVehicle end,
        GetVehicleProps = GetVehicleProps,
        ApplyVehicleProps = ApplyVehicleProps,
        GetTurboStage = GetVehicleTurboStage,
        ApplyTurboStage = ApplyTurboStage,
        BuildCurrentVehicleState = BuildCurrentVehicleState,
        SetFuel = SetFuel
    })
end
if ContractorUI.RegisterClient then
    ContractorUI.RegisterClient({
        Notify = Notify,
        RefreshDispatchUI = RefreshDispatchUI,
        ShowFreightConfirm = ShowFreightConfirm,
        GetActiveContract = function() return activeContract end,
        GetSpawnedVehicle = function() return spawnedVehicle end,
        GetContractorVehicle = function() return contractorVehicle end,
        RequireNearDepotRequestArea = RequireNearDepotRequestArea,
        Progress = Progress,
        IsStaleVehicleCheckoutMessage = LS_Trucking.IsStaleVehicleCheckoutMessage,
        TryReleaseStaleVehicleCheckout = LS_Trucking.TryReleaseStaleVehicleCheckout,
        SpawnContractorVehicle = SpawnContractorVehicle,
        StoreContractorVehicle = StoreContractorVehicle,
        BuildCurrentVehicleState = BuildCurrentVehicleState,
        BeginContractRequest = function(message) return LS_Trucking.BeginContractRequest(message) end,
        ResolveContractRequest = function(result, message) return LS_Trucking.ResolveContractRequest(result, message) end,
        StartLocalContract = StartLocalContract,
        CloseDispatch = LS_Trucking.CloseDispatchForVehicleSpawn
    })
end

RegisterNetEvent('ls_trucking:client:routePaid', function(data)
    if data and lastCompletedCargoCondition then
        data.cargoCondition = lastCompletedCargoCondition
    end

    -- Save the latest route summary so it can be reviewed later without forcing a modal.
    RouteHistory.Save(data)

    local routeName = data and (data.routeLabel or data.contractLabel) or 'route'
    DispatchChatter(('Route %s closed. Payment of $%s processed and summary logged.'):format(routeName, data and data.payout or 0), 'success', 'confirm')
end)
RegisterNetEvent('ls_trucking:client:returnBonusPaid', function(amount) Notify(('Company vehicle returned and saved. Bonus paid: $%s.'):format(amount), 'success') end)

RegisterNetEvent('ls_trucking:client:contractCancelled', function(data)
    data = data or {}
    local repLoss = tonumber(data.repLoss) or 0
    local fee = tonumber(data.fee) or 0
    local reason = data.reason or 'Not specified'

    if fee > 0 then
        Notify(('Route cancelled. Reason: %s. Reputation lost: %s. Contractor fee: $%s.'):format(reason, repLoss, fee), 'error')
        return
    end

    Notify(('Route cancelled. Reason: %s. Reputation lost: %s.'):format(reason, repLoss), 'error')
end)

LS_Trucking.DutyTargetEnabled = function()
    local dutyConfig = Config.DutyTarget or Config.DutyLocation or {}
    return Config.RequireJob == true and Config.RequireDuty ~= false and dutyConfig.enabled ~= false
end

LS_Trucking.GetDutyTargetCoords = function()
    local dutyConfig = Config.DutyTarget or Config.DutyLocation or {}
    return GetConfigCoords3(dutyConfig.coords)
        or GetConfigCoords3(Config.DispatchPed and Config.DispatchPed.coords)
        or GetConfigCoords3(Config.Depot and Config.Depot.terminal)
end

LS_Trucking.BuildDutyTargetOption = function()
    local dutyConfig = Config.DutyTarget or Config.DutyLocation or {}

    return {
        name = 'ls_trucking_toggle_duty',
        label = dutyConfig.label or 'Clock In / Out',
        icon = dutyConfig.icon or 'fa-solid fa-clock',
        distance = Config.TargetDistance,
        onSelect = LS_Trucking.ToggleDutyStatus
    }
end

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
            local dispatchOptions = {
                { name = 'ls_trucking_open_dispatch_ped', label = 'Open Freight Dispatch', icon = 'fa-solid fa-tablet-screen-button', distance = Config.TargetDistance, onSelect = OpenDispatch },
                { name = 'ls_trucking_return_company_vehicle', label = 'Return Company Vehicle', icon = 'fa-solid fa-rotate-left', distance = Config.TargetDistance, canInteract = function() return spawnedVehicle ~= nil and DoesEntityExist(spawnedVehicle) and contractorVehicle == nil and activeContract == nil end, onSelect = ReturnCompanyVehicle },
                { name = 'ls_trucking_store_contractor_vehicle', label = 'Store Contractor Vehicle', icon = 'fa-solid fa-square-parking', distance = Config.TargetDistance, canInteract = function() return spawnedVehicle ~= nil and DoesEntityExist(spawnedVehicle) and contractorVehicle ~= nil and activeContract == nil end, onSelect = StoreContractorVehicle }
            }

            if LS_Trucking.DutyTargetEnabled() and ((Config.DutyTarget or Config.DutyLocation or {}).useDispatchPed ~= false) then
                dispatchOptions[#dispatchOptions + 1] = LS_Trucking.BuildDutyTargetOption()
            end

            AddTargetEntity(dispatchPed, dispatchOptions)
            SetModelAsNoLongerNeeded(model)
        end
    end
    if Config.UseTerminalTargetZone then
        AddSphereZone('ls_trucking_open_dispatch_terminal', Config.Depot.terminal, 2.0, { { name = 'ls_trucking_open_dispatch_terminal', label = 'Open Freight Dispatch', icon = 'fa-solid fa-tablet-screen-button', distance = Config.TargetDistance, onSelect = OpenDispatch } })
    end
    if LS_Trucking.DutyTargetEnabled() and (not Config.UsePed or ((Config.DutyTarget or Config.DutyLocation or {}).useDispatchPed == false)) then
        local dutyCoords = LS_Trucking.GetDutyTargetCoords()
        if dutyCoords then
            local dutyConfig = Config.DutyTarget or Config.DutyLocation or {}
            AddSphereZone('ls_trucking_toggle_duty', dutyCoords, tonumber(dutyConfig.radius) or 2.0, { LS_Trucking.BuildDutyTargetOption() })
        end
    end
end)


function LS_Trucking.AdminCommandEnabled()
    local allowed = lib.callback.await('ls_trucking:server:canUseAdminCommand', false)
    if allowed then return true end

    Notify('You need admin permissions to use this LS Freight command.', 'error')
    return false
end

function LS_Trucking.ForceJobCleanup(message, keepVehicle)
    if message then Notify(message, 'warning') end

    TriggerServerEvent('ls_trucking:server:cancelContract', '__system_cleanup')
    ClearRouteBlip()
    RemoveAllZones()
    CleanupActiveContractPeds(true)
    DeleteCarryProp()

    if not keepVehicle then
        CleanupJobVehicle()
    else
        CleanupTrailerOnly()
    end

    activeContract = nil
    carryingCargo = false
    UpdateMiniUI()
end

RegisterCommand('lstruck_resetjob', function()
    if not LS_Trucking.AdminCommandEnabled() then return end
    LS_Trucking.ForceJobCleanup('Admin: active trucking job has been force reset.', false)
end, false)

RegisterCommand('lstruck_clearpeds', function()
    if not LS_Trucking.AdminCommandEnabled() then return end
    CleanupActiveContractPeds(false)
    Notify('Admin: active contract peds cleared.', 'success')
end, false)

RegisterCommand('lstruck_giveitems', function()
    if not LS_Trucking.AdminCommandEnabled() then return end
    TriggerServerEvent('ls_trucking:server:debugGiveItems')
end, false)

RegisterCommand('lstruck_summary', function()
    if not LS_Trucking.AdminCommandEnabled() then return end

    if not activeContract then
        ShowFreightDialog('Admin Route Summary', 'No active trucking contract.', 'Close')
        return
    end

    ShowFreightDialog('Admin Route Summary', {
        ('Contract ID: %s'):format(activeContract.contractId or 'N/A'),
        ('Type: %s'):format(activeContract.type or 'N/A'),
        ('Route: %s'):format(activeContract.routeLabel or activeContract.label or 'N/A'),
        ('Stage: %s'):format(activeContract.stage or 'N/A'),
        ('Vehicle: %s'):format(activeContract.vehicleLabel or 'N/A'),
        ('Plate: %s'):format(activeContract.plate or 'N/A'),
        ('Cargo: %s/%s'):format(activeContract.loadedCargo or 0, activeContract.requiredCargo or 0),
        ('Stop: %s/%s'):format(activeContract.currentStop or 0, activeContract.totalStops or 0),
        ('Trailer Hooked: %s'):format(tostring(activeContract.trailerHooked == true)),
        ('Trailer Dropped: %s'):format(tostring(activeContract.trailerDropped == true)),
    }, 'Close')
end, false)

RegisterCommand('lstraileredit', function(_, args)
    if not LS_Trucking.AdminCommandEnabled() then return end

    local trailerKey = args and args[1] or 'flatbed_crates'
    if TrailerCargoEditor.Open then
        TrailerCargoEditor.Open(trailerKey)
    else
        Notify('Trailer cargo editor is unavailable.', 'error')
    end
end, false)

RegisterCommand('lstrailertest', function(_, args)
    if not LS_Trucking.AdminCommandEnabled() then return end

    local trailerKey = args and args[1] or 'flatbed_crates'
    if TrailerCargoTester.Spawn then
        TrailerCargoTester.Spawn(trailerKey)
    else
        Notify('Trailer test spawner is unavailable.', 'error')
    end
end, false)

RegisterCommand('lstrailerclear', function()
    if not LS_Trucking.AdminCommandEnabled() then return end

    if TrailerCargoTester.Clear then
        TrailerCargoTester.Clear(false)
    else
        Notify('Trailer test spawner is unavailable.', 'error')
    end
end, false)

CreateThread(function()
    local missingVehicleTicks = 0
    local missingTrailerTicks = 0
    local lastDeadCargoCleanup = 0

    while true do
        Wait(5000)

        if activeContract then
            if spawnedVehicle and DoesEntityExist(spawnedVehicle) then
                missingVehicleTicks = 0
            else
                missingVehicleTicks = missingVehicleTicks + 1
            end

            if missingVehicleTicks >= 3 then
                missingVehicleTicks = 0
                LS_Trucking.ForceJobCleanup('Freight job cancelled: the company vehicle could not be found.', false)
            end

            if activeContract and activeContract.type == 'trailer' and activeContract.trailerDepot then
                if spawnedTrailer and DoesEntityExist(spawnedTrailer) then
                    missingTrailerTicks = 0
                else
                    missingTrailerTicks = missingTrailerTicks + 1
                end

                if missingTrailerTicks >= 3 then
                    missingTrailerTicks = 0
                    LS_Trucking.ForceJobCleanup('Freight job cancelled: the assigned trailer could not be found.', false)
                end
            else
                missingTrailerTicks = 0
            end

            if carryingCargo and IsEntityDead(PlayerPedId()) then
                local now = GetGameTimer()
                if now - lastDeadCargoCleanup > 10000 then
                    DeleteCarryProp()
                    carryingCargo = false
                    lastDeadCargoCleanup = now
                    Notify('Cargo carry animation was reset because your player went down.', 'warning')
                end
            end
        else
            missingVehicleTicks = 0
            missingTrailerTicks = 0
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for command in pairs(commandSuggestions) do
        TriggerEvent('chat:removeSuggestion', ('/%s'):format(command))
    end
    SetKeepInput(false)
    StopReceiverAnim()
    StopTabletAnim()
    ClearRouteBlip()
    RemoveAllZones()
    if TrailerCargoEditor.Close then TrailerCargoEditor.Close(true) end
    if TrailerCargoTester.Clear then TrailerCargoTester.Clear(true) end
    local cargoProps = LS_Trucking and LS_Trucking.TrailerCargoProps or {}
    if cargoProps.CleanupAll then cargoProps.CleanupAll() end
    CleanupJobVehicle()
    if dispatchPed and DoesEntityExist(dispatchPed) then DeleteEntity(dispatchPed) end
    for _, ped in pairs(spawnedPeds) do if ped and DoesEntityExist(ped) then DeleteEntity(ped) end end
end)
