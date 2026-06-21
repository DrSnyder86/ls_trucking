
local function resourceStarted(resource)
    return GetResourceState(resource) == 'started'
end

local function shouldUse(configured, resource)
    return configured == 'auto' or configured == resource
end

Config.SetVehicleFuel = function(vehicle, amount)
    if not vehicle or vehicle == 0 then return end

    amount = tonumber(amount) or (Config.Fuel and Config.Fuel.DefaultFuel) or 100.0
    local configured = (Config.Fuel and Config.Fuel.System) or 'auto'

    if configured == 'none' then
        SetVehicleFuelLevel(vehicle, amount + 0.0)
        return
    end

    if shouldUse(configured, 'ox_fuel') and resourceStarted('ox_fuel') then
        Entity(vehicle).state.fuel = amount
        pcall(function() exports.ox_fuel:setFuel(vehicle, amount) end)
        return
    end

    if shouldUse(configured, 'LegacyFuel') and resourceStarted('LegacyFuel') then
        exports['LegacyFuel']:SetFuel(vehicle, amount)
        return
    end

    if shouldUse(configured, 'ps-fuel') and resourceStarted('ps-fuel') then
        exports['ps-fuel']:SetFuel(vehicle, amount)
        return
    end

    if shouldUse(configured, 'cdn-fuel') and resourceStarted('cdn-fuel') then
        exports['cdn-fuel']:SetFuel(vehicle, amount)
        return
    end

    if shouldUse(configured, 'lj-fuel') and resourceStarted('lj-fuel') then
        exports['lj-fuel']:SetFuel(vehicle, amount)
        return
    end

    if shouldUse(configured, 'qb-fuel') and resourceStarted('qb-fuel') then
        exports['qb-fuel']:SetFuel(vehicle, amount)
        return
    end

    if shouldUse(configured, 'BigDaddy-Fuel') and resourceStarted('BigDaddy-Fuel') then
        exports['BigDaddy-Fuel']:SetFuel(vehicle, amount)
        return
    end

    SetVehicleFuelLevel(vehicle, amount + 0.0)
end

local function getExportFuel(resource, vehicle)
    local ok, fuel = pcall(function()
        return exports[resource]:GetFuel(vehicle)
    end)

    if ok and fuel ~= nil then
        return tonumber(fuel)
    end

    return nil
end

Config.GetVehicleFuel = function(vehicle)
    if not vehicle or vehicle == 0 then return nil end

    local configured = (Config.Fuel and Config.Fuel.System) or 'auto'

    if configured == 'none' then
        return tonumber(GetVehicleFuelLevel(vehicle))
    end

    if shouldUse(configured, 'ox_fuel') and resourceStarted('ox_fuel') then
        local stateFuel = Entity(vehicle).state.fuel
        if stateFuel ~= nil then
            return tonumber(stateFuel)
        end

        local ok, fuel = pcall(function()
            return exports.ox_fuel:getFuel(vehicle)
        end)

        if ok and fuel ~= nil then
            return tonumber(fuel)
        end
    end

    for _, resource in ipairs({ 'LegacyFuel', 'ps-fuel', 'cdn-fuel', 'lj-fuel', 'qb-fuel', 'BigDaddy-Fuel' }) do
        if shouldUse(configured, resource) and resourceStarted(resource) then
            local fuel = getExportFuel(resource, vehicle)
            if fuel ~= nil then
                return fuel
            end
        end
    end

    return tonumber(GetVehicleFuelLevel(vehicle))
end

Config.GiveVehicleKeys = function(vehicle, plate)
    if not vehicle or vehicle == 0 then return end
    if Config.Keys and Config.Keys.GiveOnSpawn == false then return end

    plate = plate or GetVehicleNumberPlateText(vehicle)
    local configured = (Config.Keys and Config.Keys.System) or 'auto'
    if configured == 'none' then return end

    if shouldUse(configured, 'qbx_vehiclekeys') and resourceStarted('qbx_vehiclekeys') then
        if pcall(function() exports.qbx_vehiclekeys:GiveKeys(vehicle) end) then return end
        if pcall(function() exports.qbx_vehiclekeys:GiveKeys(plate) end) then return end
    end

    if shouldUse(configured, 'qb-vehiclekeys') and resourceStarted('qb-vehiclekeys') then
        TriggerEvent('vehiclekeys:client:SetOwner', plate)
        TriggerServerEvent('qb-vehiclekeys:server:AcquireVehicleKeys', plate)
        return
    end

    if shouldUse(configured, 'Renewed-Vehiclekeys') and resourceStarted('Renewed-Vehiclekeys') then
        if pcall(function() exports['Renewed-Vehiclekeys']:addKey(plate) end) then return end
        if pcall(function() exports['Renewed-Vehiclekeys']:AddKey(plate) end) then return end
    end

    if shouldUse(configured, 'MrNewbVehicleKeys') and resourceStarted('MrNewbVehicleKeys') then
        if pcall(function() exports['MrNewbVehicleKeys']:GiveKeys(vehicle) end) then return end
        if pcall(function() exports['MrNewbVehicleKeys']:GiveKeys(plate) end) then return end
    end

    if shouldUse(configured, 'wasabi_carlock') and resourceStarted('wasabi_carlock') then
        if pcall(function() exports.wasabi_carlock:GiveKey(plate) end) then return end
        if pcall(function() exports.wasabi_carlock:GiveKeys(plate) end) then return end
    end

    if shouldUse(configured, 'cd_garage') and resourceStarted('cd_garage') then
        if pcall(function() TriggerEvent('cd_garage:AddKeys', plate) end) then return end
    end
end

Config.RemoveVehicleKeys = function(vehicle, plate)
    plate = plate or (vehicle and vehicle ~= 0 and GetVehicleNumberPlateText(vehicle)) or nil
    if not plate or plate == '' then return end

    local configured = (Config.Keys and Config.Keys.System) or 'auto'
    if configured == 'none' then return end

    if shouldUse(configured, 'qbx_vehiclekeys') and resourceStarted('qbx_vehiclekeys') then
        if vehicle and vehicle ~= 0 and pcall(function() exports.qbx_vehiclekeys:RemoveKeys(vehicle) end) then return end
        if pcall(function() exports.qbx_vehiclekeys:RemoveKeys(plate) end) then return end
        if pcall(function() exports.qbx_vehiclekeys:RemoveKey(plate) end) then return end
    end

    if shouldUse(configured, 'qb-vehiclekeys') and resourceStarted('qb-vehiclekeys') then
        TriggerEvent('vehiclekeys:client:RemoveKeys', plate)
        TriggerEvent('qb-vehiclekeys:client:RemoveKeys', plate)
        TriggerServerEvent('qb-vehiclekeys:server:RemoveKeys', plate)
        TriggerServerEvent('qb-vehiclekeys:server:RemoveVehicleKeys', plate)
        return
    end

    if shouldUse(configured, 'Renewed-Vehiclekeys') and resourceStarted('Renewed-Vehiclekeys') then
        if pcall(function() exports['Renewed-Vehiclekeys']:removeKey(plate) end) then return end
        if pcall(function() exports['Renewed-Vehiclekeys']:RemoveKey(plate) end) then return end
        if pcall(function() exports['Renewed-Vehiclekeys']:removeKeys(plate) end) then return end
        if pcall(function() exports['Renewed-Vehiclekeys']:RemoveKeys(plate) end) then return end
    end

    if shouldUse(configured, 'MrNewbVehicleKeys') and resourceStarted('MrNewbVehicleKeys') then
        if vehicle and vehicle ~= 0 and pcall(function() exports['MrNewbVehicleKeys']:RemoveKeys(vehicle) end) then return end
        if pcall(function() exports['MrNewbVehicleKeys']:RemoveKeys(plate) end) then return end
        if pcall(function() exports['MrNewbVehicleKeys']:RemoveKey(plate) end) then return end
    end

    if shouldUse(configured, 'wasabi_carlock') and resourceStarted('wasabi_carlock') then
        if pcall(function() exports.wasabi_carlock:RemoveKey(plate) end) then return end
        if pcall(function() exports.wasabi_carlock:RemoveKeys(plate) end) then return end
    end

    if shouldUse(configured, 'cd_garage') and resourceStarted('cd_garage') then
        if pcall(function() TriggerEvent('cd_garage:RemoveKeys', plate) end) then return end
    end
end
