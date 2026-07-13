LS_Trucking = LS_Trucking or {}

local DepotVehicles = {}
local clientContext = {}
local METERS_PER_MILE = 1609.344
local MILEAGE_SAMPLE_MS = 1000
local MILEAGE_MAX_SAMPLE_METERS = 250.0
local contractorMileage = {
    vehicle = 0,
    base = 0.0,
    traveledMeters = 0.0,
    lastCoords = nil
}

local function Ctx()
    return clientContext or {}
end

local function Notify(message, notifyType)
    local ctx = Ctx()
    if ctx.Notify then ctx.Notify(message, notifyType) end
end

local function SetValue(name, value)
    local setter = Ctx()[name]
    if setter then setter(value) end
end

local function GetValue(name)
    local getter = Ctx()[name]
    return getter and getter() or nil
end

local function NormalizePlateText(plate)
    local normalized = tostring(plate or ''):upper():gsub('%s+', '')
    if #normalized > 8 then normalized = normalized:sub(1, 8) end
    return normalized
end

local function ResetContractorMileage()
    contractorMileage.vehicle = 0
    contractorMileage.base = 0.0
    contractorMileage.traveledMeters = 0.0
    contractorMileage.lastCoords = nil
end

local function StartContractorMileage(vehicle, mileage)
    contractorMileage.vehicle = vehicle or 0
    contractorMileage.base = math.max(0.0, tonumber(mileage) or 0.0)
    contractorMileage.traveledMeters = 0.0
    contractorMileage.lastCoords = vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) and GetEntityCoords(vehicle) or nil
end

function DepotVehicles.GetContractorVehicleMileage()
    return contractorMileage.base + (contractorMileage.traveledMeters / METERS_PER_MILE)
end

local function AddCoord(list, coords)
    if coords then list[#list + 1] = coords end
end

local function GetDepotDistanceLimit()
    local depot = Config.Depot or {}
    if depot.requestRadius then
        return tonumber(depot.requestRadius) or 20.0
    end

    local security = Config.Security or {}
    local distances = security.DistanceChecks or {}
    return tonumber(distances.Depot) or 20.0
end

local function BuildDepotRequestCoords()
    local depot = Config.Depot or {}
    local coords = {}
    AddCoord(coords, depot.request or depot.terminal)
    AddCoord(coords, depot.terminal)
    AddCoord(coords, depot.garageSpawn)
    AddCoord(coords, depot.vehicleSpawn)
    return coords
end

function DepotVehicles.RequireNearDepotRequestArea(message)
    local ctx = Ctx()
    local distance = GetDepotDistanceLimit()

    for _, coords in ipairs(BuildDepotRequestCoords()) do
        if ctx.IsPlayerNearCoords and ctx.IsPlayerNearCoords(coords, distance) then
            return true
        end
    end

    if ctx.ForceDepotDistanceNotify then
        ctx.ForceDepotDistanceNotify(message or 'You need to be closer to the LS Freight depot.')
    else
        Notify(message or 'You need to be closer to the LS Freight depot.', 'error')
    end

    return false
end

local function GetSpawnUtils()
    return LS_Trucking and LS_Trucking.SpawnUtils or {}
end

local function GetTrailerCargoProps()
    return LS_Trucking and LS_Trucking.TrailerCargoProps or {}
end

local function GetVehicleSpawnRadius()
    local utils = GetSpawnUtils()
    if utils.GetVehicleRadius then
        return utils.GetVehicleRadius()
    end

    return Config.SpawnOccupancy and Config.SpawnOccupancy.VehicleRadius or 4.0
end

local function GetTrailerSpawnRadius()
    local utils = GetSpawnUtils()
    if utils.GetTrailerRadius then
        return utils.GetTrailerRadius()
    end

    return Config.SpawnOccupancy and Config.SpawnOccupancy.TrailerRadius or 6.0
end

local function IsSpawnClear(spawn, radius)
    local utils = GetSpawnUtils()
    if utils.IsSpawnClear then
        return utils.IsSpawnClear(spawn, radius)
    end

    if not spawn then return false end
    return not IsAnyVehicleNearPoint(spawn.x, spawn.y, spawn.z, radius or 4.0)
end

local function FindClearSpawn(spawns, radius)
    local utils = GetSpawnUtils()
    if utils.FindClearSpawn then
        return utils.FindClearSpawn(spawns, radius)
    end

    if not spawns then return nil, nil end
    if spawns.x and spawns.y and spawns.z then
        return IsSpawnClear(spawns, radius) and spawns or nil, 1
    end

    for index, spawn in ipairs(spawns) do
        if IsSpawnClear(spawn, radius) then
            return spawn, index
        end
    end

    return nil, nil
end

local function GetClearVehicleSpawn(spawn, label)
    if not spawn then
        Notify(('No %s spawn point is configured.'):format(label or 'vehicle'), 'error')
        return nil
    end

    if IsSpawnClear(spawn, GetVehicleSpawnRadius()) then
        return spawn
    end

    Notify(('%s spawn point is occupied. Clear the area and try again.'):format(label or 'Vehicle'), 'error')
    return nil
end

local function GetTrailerSpawns(trailerDepot)
    local spawns = trailerDepot and trailerDepot.spawns or nil

    if not spawns or #spawns == 0 then
        local depots = Config.TrailerDepots or {}
        local depotKey = trailerDepot and trailerDepot.key or 'docks'
        local depot = depots[depotKey] or depots.docks
        spawns = depot and depot.spawns or nil
    end

    if not spawns or #spawns == 0 then
        return { vector4(1244.30, -3184.92, 5.90, 90.0) }
    end

    return spawns
end

local function GetClearTrailerSpawn(trailerDepot)
    local spawns = GetTrailerSpawns(trailerDepot)
    return FindClearSpawn(spawns, GetTrailerSpawnRadius())
end

local function CleanupTrailerOnly()
    local trailer = GetValue('GetSpawnedTrailer')
    if trailer and DoesEntityExist(trailer) then
        local cargoProps = GetTrailerCargoProps()
        if cargoProps.CleanupForTrailer then
            cargoProps.CleanupForTrailer(trailer)
        end

        DeleteEntity(trailer)
    end

    SetValue('SetSpawnedTrailer', nil)
    SetValue('SetSpawnedTrailerStartBody', 1000.0)
    SetValue('SetTrailerTargetAdded', false)
end

function DepotVehicles.GetJobVehiclePlate()
    local vehicle = GetValue('GetSpawnedVehicle')
    if not vehicle or not DoesEntityExist(vehicle) then return nil end
    return NormalizePlateText(GetVehicleNumberPlateText(vehicle))
end

function DepotVehicles.BuildReceiverReuseData()
    local data = GetValue('GetContractorVehicle') or GetValue('GetReusableVehicle') or GetValue('GetGarageVehicle')
    if not data then return { available = false } end

    local vehicle = GetValue('GetSpawnedVehicle')
    if not vehicle or not DoesEntityExist(vehicle) then
        SetValue('SetReusableVehicle', nil)
        SetValue('SetGarageVehicle', nil)
        SetValue('SetContractorVehicle', nil)
        return { available = false }
    end

    local source = GetValue('GetContractorVehicle') and 'contractor' or (GetValue('GetGarageVehicle') and 'garage' or 'reusable')
    return {
        available = true,
        type = data.type,
        index = data.index or 1,
        label = data.label,
        vehicleLabel = data.vehicleLabel or data.label,
        plate = DepotVehicles.GetJobVehiclePlate(),
        source = source,
        contractor = source == 'contractor',
        vehicleId = data.id
    }
end

function DepotVehicles.BuildCurrentVehicleState()
    local vehicle = GetValue('GetSpawnedVehicle')
    vehicle = vehicle and DoesEntityExist(vehicle) and vehicle or 0
    if vehicle == 0 then return nil end

    local fuel
    if Config.GetVehicleFuel then
        fuel = Config.GetVehicleFuel(vehicle)
    end
    if fuel == nil then fuel = GetVehicleFuelLevel(vehicle) end

    return {
        plate = GetVehicleNumberPlateText(vehicle),
        fuel = fuel,
        engineHealth = GetVehicleEngineHealth(vehicle),
        bodyHealth = GetVehicleBodyHealth(vehicle),
        mileage = contractorMileage.vehicle == vehicle and DepotVehicles.GetContractorVehicleMileage() or nil
    }
end

function DepotVehicles.CanReuseVehicle(contractType, allowContractor)
    local contractorVehicle = GetValue('GetContractorVehicle')
    local reusableVehicle = GetValue('GetReusableVehicle')
    local garageVehicle = GetValue('GetGarageVehicle')
    local spawnedVehicle = GetValue('GetSpawnedVehicle')

    if allowContractor and contractorVehicle then
        if not spawnedVehicle or not DoesEntityExist(spawnedVehicle) then return false end
        if Config.RequireSameTypeForVehicleReuse and contractorVehicle.type ~= contractType then return false end
        return true
    end

    if not Config.AllowVehicleReuseAfterRoute then return false end
    if not reusableVehicle and not garageVehicle then return false end
    if not spawnedVehicle or not DoesEntityExist(spawnedVehicle) then return false end

    local currentType = reusableVehicle and reusableVehicle.type or garageVehicle and garageVehicle.type
    if Config.RequireSameTypeForVehicleReuse and currentType ~= contractType then return false end
    return true
end

function DepotVehicles.SpawnTrailerOnly(vehicleData, routeTrailer, trailerDepot)
    local ctx = Ctx()
    CleanupTrailerOnly()

    routeTrailer = routeTrailer or {}

    local trailerModelName = routeTrailer.model or vehicleData.trailer
    local trailerModel = ctx.LoadModel and ctx.LoadModel(trailerModelName)
    if not trailerModel then return false end

    local s = GetClearTrailerSpawn(trailerDepot)
    if not s then
        Notify(('All trailer spawn spots at %s are occupied. Clear a spot and try again.'):format(trailerDepot and trailerDepot.label or 'the trailer depot'), 'error')
        SetModelAsNoLongerNeeded(trailerModel)
        return false
    end

    local trailer = CreateVehicle(trailerModel, s.x, s.y, s.z, s.w, true, false)
    SetValue('SetSpawnedTrailer', trailer)

    if routeTrailer.livery ~= nil then
        SetVehicleLivery(trailer, routeTrailer.livery)
    elseif vehicleData.trailerLivery ~= nil then
        SetVehicleLivery(trailer, vehicleData.trailerLivery)
    end

    if ctx.ApplyExtras then ctx.ApplyExtras(trailer, routeTrailer.extras or vehicleData.trailerExtras) end
    SetVehicleDirtLevel(trailer, 0.0)

    local cargoProps = GetTrailerCargoProps()
    if cargoProps.AttachToTrailer then
        cargoProps.AttachToTrailer(trailer, routeTrailer.cargoProps)
    end

    local startBody = GetVehicleBodyHealth(trailer)
    if startBody <= 0.0 then startBody = 1000.0 end
    SetValue('SetSpawnedTrailerStartBody', startBody)
    SetModelAsNoLongerNeeded(trailerModel)

    Wait(250)
    if ctx.AddTrailerLoadTarget then ctx.AddTrailerLoadTarget() end

    return true
end

local function DecodeVehicleProps(props)
    if type(props) == 'string' and props ~= '' then
        local ok, decoded = pcall(json.decode, props)
        if ok and type(decoded) == 'table' then return decoded end
        return nil
    end
    if type(props) == 'table' then return props end
    return nil
end

local function CoerceBoolean(value)
    if value == true or value == 1 or value == '1' or value == 'true' then return true end
    if value == false or value == 0 or value == '0' or value == 'false' then return false end
    return nil
end

local function GetSavedTurboStage(props)
    props = DecodeVehicleProps(props)
    if not props then return nil end

    local stage = tonumber(props.lsfcTurboStage or props.turboStage)
    if stage then return math.max(0, math.floor(stage)) end

    local turbo = CoerceBoolean(props.turbo)
    if turbo ~= nil then return turbo and 1 or 0 end

    local toggles = props.toggles
    if type(toggles) == 'table' then
        turbo = CoerceBoolean(toggles['18'])
        if turbo ~= nil then return turbo and 1 or 0 end
        turbo = CoerceBoolean(toggles[18])
        if turbo ~= nil then return turbo and 1 or 0 end
    end

    return nil
end

local function ApplySavedTurboState(vehicle, props)
    local stage = GetSavedTurboStage(props)
    if stage == nil or not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return end

    local ctx = Ctx()
    if ctx.ApplyTurboStage then
        ctx.ApplyTurboStage(vehicle, stage)
        return
    end

    SetVehicleModKit(vehicle, 0)
    ToggleVehicleMod(vehicle, 18, stage > 0)
    if Entity then
        Entity(vehicle).state:set('lsfcTurboInstalled', stage > 0, true)
        Entity(vehicle).state:set('lsfcTurboStage', stage, true)
    end
end
local function SpawnBaseVehicle(modelName, spawn, plate, vehicleData, props, fuel, engineHealth, bodyHealth)
    local ctx = Ctx()
    local model = ctx.LoadModel and ctx.LoadModel(modelName)
    if not model then return nil end
    local canonicalPlate = NormalizePlateText(plate)

    local vehicle = CreateVehicle(model, spawn.x, spawn.y, spawn.z, spawn.w, true, false)
    SetValue('SetSpawnedVehicle', vehicle)

    SetVehicleNumberPlateText(vehicle, canonicalPlate)
    if ctx.SetVehicleOptions then ctx.SetVehicleOptions(vehicle, vehicleData, false) end
    if props and ctx.ApplyVehicleProps then ctx.ApplyVehicleProps(vehicle, props) end
    SetVehicleNumberPlateText(vehicle, canonicalPlate)
    ApplySavedTurboState(vehicle, props)
    if ctx.SetFuel then ctx.SetFuel(vehicle, fuel) end
    if ctx.ApplyVehicleHealthState then ctx.ApplyVehicleHealthState(vehicle, engineHealth, bodyHealth) end
    Wait(100)
    ApplySavedTurboState(vehicle, props)
    if ctx.GiveKeys then ctx.GiveKeys(vehicle) end
    SetModelAsNoLongerNeeded(model)

    return vehicle
end

function DepotVehicles.SpawnJobVehicle(data)
    local ctx = Ctx()
    local contractType, vehicleData, plate = data.contractType, data.vehicle, data.plate
    local s = GetClearVehicleSpawn(Config.Depot.vehicleSpawn, 'Company vehicle')
    if not s then return false end

    if contractType == 'van' or contractType == 'boxtruck' then
        if not SpawnBaseVehicle(vehicleData.model, s, plate, vehicleData, nil, vehicleData.fuel) then return false end
        Wait(500)
        if ctx.AddVehicleCargoTarget then ctx.AddVehicleCargoTarget() end
        Notify(('Your %s is ready at the depot.'):format(vehicleData.label), 'success')
        return true
    elseif contractType == 'trailer' then
        if not SpawnBaseVehicle(vehicleData.model or vehicleData.truck, s, plate, vehicleData, nil, vehicleData.fuel) then return false end
        if not DepotVehicles.SpawnTrailerOnly(vehicleData, data.contract and data.contract.routeTrailer, data.contract and data.contract.trailerDepot) then
            local vehicle = GetValue('GetSpawnedVehicle')
            if vehicle and DoesEntityExist(vehicle) then DeleteEntity(vehicle) end
            SetValue('SetSpawnedVehicle', nil)
            return false
        end
        Wait(500)
        if ctx.AddVehicleCargoTarget then ctx.AddVehicleCargoTarget() end
        Notify(('Your %s is ready. Trailer is waiting at %s.'):format(vehicleData.label, data.contract and data.contract.trailerDepot and data.contract.trailerDepot.label or 'the trailer yard'), 'success')
        return true
    end

    return false
end

function DepotVehicles.SpawnGarageVehicle(data)
    local ctx = Ctx()
    if not DepotVehicles.RequireNearDepotRequestArea('You need to be closer to the company garage area to request a vehicle.') then return false end

    local currentVehicle = GetValue('GetSpawnedVehicle')
    if currentVehicle and DoesEntityExist(currentVehicle) then Notify('You already have a company vehicle out. Return it first.', 'error') return false end

    local vehicleType, vehicleData, plate = data.vehicleType, data.vehicle, data.plate
    local s = GetClearVehicleSpawn(Config.Depot.garageSpawn or Config.Depot.vehicleSpawn, 'Company garage')
    if not s then return false end

    if not SpawnBaseVehicle(vehicleData.model or vehicleData.truck, s, plate, vehicleData, data.props, vehicleData.fuel) then return false end

    local vehicleState = { type = vehicleType, index = data.vehicleIndex, plate = NormalizePlateText(plate), label = vehicleData.label, vehicleLabel = vehicleData.label }
    SetValue('SetGarageVehicle', vehicleState)
    SetValue('SetReusableVehicle', { type = vehicleType, index = data.vehicleIndex, plate = NormalizePlateText(plate), label = vehicleData.label, vehicleLabel = vehicleData.label })
    if ctx.AddVehicleCargoTarget then ctx.AddVehicleCargoTarget() end
    Notify(('Company vehicle spawned: %s. Customize it, use it for jobs, then return it to the dispatcher.'):format(vehicleData.label), 'success')
    return true
end

function DepotVehicles.SpawnContractorVehicle(data)
    local ctx = Ctx()
    if not DepotVehicles.RequireNearDepotRequestArea('You need to be closer to the contractor vehicle pickup area.') then return false end

    local currentVehicle = GetValue('GetSpawnedVehicle')
    if currentVehicle and DoesEntityExist(currentVehicle) then Notify('You already have a vehicle out. Store or return it first.', 'error') return false end
    if not data or not data.vehicle then Notify('Could not load contractor vehicle data.', 'error') return false end

    local vehicleType, vehicleData, plate = data.vehicleType, data.vehicle, data.plate
    local s = GetClearVehicleSpawn(Config.Depot.garageSpawn or Config.Depot.vehicleSpawn, 'Contractor vehicle')
    if not s then return false end

    local vehicle = SpawnBaseVehicle(vehicleData.model or vehicleData.truck, s, plate, vehicleData, data.props, data.fuel or vehicleData.fuel or 100, data.engineHealth, data.bodyHealth)
    if not vehicle then return false end
    StartContractorMileage(vehicle, data.mileage)

    SetValue('SetContractorVehicle', {
        id = data.vehicleId,
        type = vehicleType,
        index = data.vehicleIndex,
        plate = NormalizePlateText(plate),
        label = vehicleData.label,
        vehicleLabel = vehicleData.label
    })
    SetValue('SetGarageVehicle', nil)
    SetValue('SetReusableVehicle', nil)

    if ctx.AddVehicleCargoTarget then ctx.AddVehicleCargoTarget() end
    if ctx.UpdateMiniUI then ctx.UpdateMiniUI() end
    Notify(('Contractor vehicle spawned: %s. Fuel, condition, and mileage will be saved when stored.'):format(vehicleData.label), 'success')
    return true
end

function DepotVehicles.ReturnCompanyVehicle()
    local ctx = Ctx()
    if not ctx.RequireNearCoords or not ctx.RequireNearCoords(Config.Depot.vehicleReturn or Config.Depot.terminal, ctx.VehicleReturnDistance or 20.0, 'You need to be closer to the company return point to return this vehicle.', true) then return end
    if GetValue('GetActiveContract') then Notify('Finish or cancel your active job before returning the vehicle.', 'error') return end

    local vehicle = GetValue('GetSpawnedVehicle')
    if not vehicle or not DoesEntityExist(vehicle) then Notify('You do not have a company vehicle out.', 'error') return end

    local garageData = GetValue('GetGarageVehicle') or GetValue('GetReusableVehicle')
    if not garageData then Notify('Could not identify this company vehicle.', 'error') return end
    if not ctx.Progress or not ctx.Progress('Returning company vehicle...', Config.Progress.returnVehicle, { dict = 'missheistdockssetup1clipboard@base', clip = 'base' }) then return end

    local props = ctx.GetVehicleProps and ctx.GetVehicleProps(vehicle)
    local plate = GetVehicleNumberPlateText(vehicle)
    local result = lib.callback.await('ls_trucking:server:returnGarageVehicle', false, garageData.type, garageData.index or 1, plate, json.encode(props))
    if not result or not result.success then Notify(result and result.message or 'Could not return vehicle.', 'error') return end

    if Config.Keys and Config.Keys.RemoveOnReturn == true and ctx.RemoveKeys then
        ctx.RemoveKeys(vehicle, plate)
    end

    if ctx.CleanupJobVehicle then ctx.CleanupJobVehicle() end
    if ctx.ClearRouteBlip then ctx.ClearRouteBlip() end
    if ctx.RemoveAllZones then ctx.RemoveAllZones() end

    if result.bonus and result.bonus > 0 then
        Notify(('Company vehicle returned and saved. Bonus paid: $%s.'):format(result.bonus), 'success')
    else
        Notify('Company vehicle returned and saved.', 'success')
    end
end

function DepotVehicles.StoreContractorVehicle()
    local ctx = Ctx()
    if not ctx.RequireNearCoords or not ctx.RequireNearCoords(Config.Depot.vehicleReturn or Config.Depot.terminal, ctx.VehicleReturnDistance or 20.0, 'You need to be closer to the contractor vehicle return point.', true) then return end
    if GetValue('GetActiveContract') then Notify('Finish or cancel your active job before storing this vehicle.', 'error') return end

    local vehicle = GetValue('GetSpawnedVehicle')
    if not vehicle or not DoesEntityExist(vehicle) then Notify('You do not have a vehicle out.', 'error') return end

    local contractorVehicle = GetValue('GetContractorVehicle')
    if not contractorVehicle or not contractorVehicle.id then Notify('Could not identify this contractor vehicle.', 'error') return end
    if not ctx.Progress or not ctx.Progress('Storing contractor vehicle...', Config.Progress.returnVehicle, { dict = 'missheistdockssetup1clipboard@base', clip = 'base' }) then return end

    local props = ctx.GetVehicleProps and ctx.GetVehicleProps(vehicle)
    local state = DepotVehicles.BuildCurrentVehicleState() or {}
    local plate = state.plate or GetVehicleNumberPlateText(vehicle)
    local result = lib.callback.await('ls_trucking:server:storeContractorVehicle', false, contractorVehicle.id, plate, json.encode(props), state.fuel, state.engineHealth, state.bodyHealth, state.mileage)
    if not result or not result.success then Notify(result and result.message or 'Could not store contractor vehicle.', 'error') return end

    if Config.Keys and Config.Keys.RemoveOnReturn == true and ctx.RemoveKeys then
        ctx.RemoveKeys(vehicle, plate)
    end

    if ctx.CleanupJobVehicle then ctx.CleanupJobVehicle() end
    ResetContractorMileage()
    if ctx.ClearRouteBlip then ctx.ClearRouteBlip() end
    if ctx.RemoveAllZones then ctx.RemoveAllZones() end
    if ctx.UpdateMiniUI then ctx.UpdateMiniUI() end
    Notify(result.message or 'Contractor vehicle stored.', 'success')
end

function DepotVehicles.ConfigureClient(context)
    clientContext = context or {}
end

CreateThread(function()
    while true do
        local vehicle = contractorMileage.vehicle
        if vehicle == 0 or not DoesEntityExist(vehicle) then
            contractorMileage.lastCoords = nil
            Wait(2000)
        else
            Wait(MILEAGE_SAMPLE_MS)

            if contractorMileage.vehicle == vehicle and DoesEntityExist(vehicle) then
                local coords = GetEntityCoords(vehicle)
                local lastCoords = contractorMileage.lastCoords
                if lastCoords then
                    local traveled = #(coords - lastCoords)
                    if traveled > 0.05 and traveled <= MILEAGE_MAX_SAMPLE_METERS then
                        contractorMileage.traveledMeters = contractorMileage.traveledMeters + traveled
                    end
                end
                contractorMileage.lastCoords = coords
            end
        end
    end
end)

LS_Trucking.DepotVehicles = DepotVehicles
