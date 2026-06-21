LS_Trucking = LS_Trucking or {}

local ReceiverVehicleControls = {}

local commandBusy = false
local hazardsOn = false
local interiorLightOn = false

local doorActions = {
    door_0 = { doors = { 0 }, label = 'driver door' },
    door_1 = { doors = { 1 }, label = 'passenger door' },
    door_2 = { doors = { 2 }, label = 'rear left door' },
    door_3 = { doors = { 3 }, label = 'rear right door' },
    door_4 = { doors = { 4 }, label = 'hood' },
    door_5 = { doors = { 5 }, label = 'trunk' },
    hood = { doors = { 4 }, label = 'hood' },
    trunk = { doors = { 5 }, label = 'trunk' },
    cab = { doors = { 0, 1 }, label = 'cab doors' },
    cargo = { doors = { 5, 2, 3 }, label = 'cargo doors' }
}

local function notify(context, message, notifyType)
    if context and type(context.notify) == 'function' then
        context.notify(message, notifyType or 'inform')
    end
end

local function playSound(context, soundType)
    if context and type(context.playSound) == 'function' then
        context.playSound(soundType)
    end
end

local function updateMini(context)
    if context and type(context.updateMiniUI) == 'function' then
        context.updateMiniUI()
    end
end

local function getVehicle(context)
    if context and type(context.getVehicle) == 'function' then
        return context.getVehicle() or 0
    end

    return 0
end

local function vehicleDoorGroupIsOpen(vehicle, doors)
    for _, doorIndex in ipairs(doors) do
        if not IsVehicleDoorDamaged(vehicle, doorIndex) and GetVehicleDoorAngleRatio(vehicle, doorIndex) > 0.1 then
            return true
        end
    end

    return false
end

local function setVehicleDoorGroup(vehicle, doors, open)
    for _, doorIndex in ipairs(doors) do
        if not IsVehicleDoorDamaged(vehicle, doorIndex) then
            if open then
                SetVehicleDoorOpen(vehicle, doorIndex, false, false)
            else
                SetVehicleDoorShut(vehicle, doorIndex, false)
            end
        end
    end
end

local function toggleVehicleDoorGroup(vehicle, doors)
    setVehicleDoorGroup(vehicle, doors, not vehicleDoorGroupIsOpen(vehicle, doors))
end

local function flashVehicleLights(vehicle, pulses)
    if not vehicle or vehicle == 0 then return end

    pulses = math.max(1, math.min(3, tonumber(pulses) or 1))

    for _ = 1, pulses do
        if not DoesEntityExist(vehicle) then return end

        SetVehicleLights(vehicle, 2)
        SetVehicleFullbeam(vehicle, true)
        Wait(120)
        SetVehicleFullbeam(vehicle, false)
        SetVehicleLights(vehicle, 0)
        Wait(100)
    end
end

local function pulseHorn(vehicle, pulses)
    if not vehicle or vehicle == 0 then return end

    pulses = math.max(1, math.min(3, tonumber(pulses) or 1))

    for _ = 1, pulses do
        if not DoesEntityExist(vehicle) then return end

        StartVehicleHorn(vehicle, 90, GetHashKey('HELDDOWN'), false)
        Wait(150)
    end
end

local function isKnownAction(action)
    if doorActions[action] then return true end
    return action == 'engine'
        or action == 'locks'
        or action == 'doors'
        or action == 'locate'
        or action == 'hazards'
        or action == 'interior'
end

local function performVehicleControl(vehicle, action, context)
    local doorAction = doorActions[action]

    if action == 'engine' then
        local running = GetIsVehicleEngineRunning(vehicle)
        SetVehicleEngineOn(vehicle, not running, true, true)
        notify(context, running and 'Receiver command sent: engine off.' or 'Receiver command sent: engine on.', 'inform')
    elseif action == 'locks' then
        local locked = GetVehicleDoorLockStatus(vehicle) >= 2
        local locking = not locked
        SetVehicleDoorsLocked(vehicle, locking and 2 or 1)
        pulseHorn(vehicle, locking and 2 or 1)
        notify(context, locking and 'Receiver command sent: doors locked.' or 'Receiver command sent: doors unlocked.', 'inform')
    elseif doorAction then
        toggleVehicleDoorGroup(vehicle, doorAction.doors)
        notify(context, ('Receiver command sent: %s toggled.'):format(doorAction.label), 'inform')
    elseif action == 'doors' then
        toggleVehicleDoorGroup(vehicle, { 0, 1, 2, 3, 4, 5 })
        notify(context, 'Receiver command sent: all doors toggled.', 'inform')
    elseif action == 'locate' then
        local coords = GetEntityCoords(vehicle)
        SetNewWaypoint(coords.x, coords.y)
        playSound(context, 'destination')
        notify(context, 'Receiver ping sent: company vehicle marked on GPS.', 'success')
    elseif action == 'hazards' then
        hazardsOn = not hazardsOn
        SetVehicleIndicatorLights(vehicle, 0, hazardsOn)
        SetVehicleIndicatorLights(vehicle, 1, hazardsOn)
        notify(context, hazardsOn and 'Receiver command sent: hazards on.' or 'Receiver command sent: hazards off.', 'inform')
    elseif action == 'interior' then
        interiorLightOn = not interiorLightOn
        SetVehicleInteriorlight(vehicle, interiorLightOn)
        notify(context, interiorLightOn and 'Receiver command sent: cab light on.' or 'Receiver command sent: cab light off.', 'inform')
    else
        notify(context, 'Unknown receiver vehicle command.', 'error')
        return false
    end

    return true
end

function ReceiverVehicleControls.Handle(action, context)
    local vehicle = getVehicle(context)
    if vehicle == 0 then
        notify(context, 'No current vehicle detected.', 'error')
        return false
    end

    action = tostring(action or '')

    if not isKnownAction(action) then
        notify(context, 'Unknown receiver vehicle command.', 'error')
        return false
    end

    if commandBusy then
        notify(context, 'Receiver vehicle command already in progress.', 'inform')
        return false
    end

    commandBusy = true

    CreateThread(function()
        Wait(250)

        local currentVehicle = getVehicle(context)
        if currentVehicle == 0 then
            notify(context, 'No current vehicle detected.', 'error')
            commandBusy = false
            return
        end

        flashVehicleLights(currentVehicle, 1)

        local success = performVehicleControl(currentVehicle, action, context)
        if success and DoesEntityExist(currentVehicle) then
            flashVehicleLights(currentVehicle, 1)
            updateMini(context)
        end

        commandBusy = false
    end)

    return true
end

LS_Trucking.ReceiverVehicleControls = ReceiverVehicleControls
