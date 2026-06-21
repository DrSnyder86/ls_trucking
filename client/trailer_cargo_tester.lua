LS_Trucking = LS_Trucking or {}

local Tester = {}
local testTrailer = nil
local testTrailerKey = nil

local function Notify(message, notifyType)
    if lib and lib.notify then
        lib.notify({
            title = 'LS Freight Trailer Test',
            description = message,
            type = notifyType or 'inform'
        })
    else
        print(('[LS Freight Trailer Test] %s'):format(message))
    end
end

local function TrailerCargoProps()
    return LS_Trucking and LS_Trucking.TrailerCargoProps or {}
end

local function LoadModel(modelName)
    if not modelName then return nil end

    local model = type(modelName) == 'number' and modelName or joaat(modelName)
    if not IsModelInCdimage(model) then
        Notify(('Model does not exist: %s'):format(tostring(modelName)), 'error')
        return nil
    end

    RequestModel(model)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(model) and GetGameTimer() < timeout do
        Wait(0)
    end

    if not HasModelLoaded(model) then
        Notify(('Timed out loading model: %s'):format(tostring(modelName)), 'error')
        return nil
    end

    return model
end

local function ApplyExtras(vehicle, extras)
    if not vehicle or vehicle == 0 or not extras then return end

    for extraId, enabled in pairs(extras) do
        extraId = tonumber(extraId)
        if extraId and DoesExtraExist(vehicle, extraId) then
            SetVehicleExtra(vehicle, extraId, enabled and 0 or 1)
        end
    end
end

local function BuildSpawnCoords()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local forward = GetEntityForwardVector(ped)
    local spawnX = coords.x + forward.x * 8.0
    local spawnY = coords.y + forward.y * 8.0
    local spawnZ = coords.z + 0.5
    local foundGround, groundZ = GetGroundZFor_3dCoord(spawnX, spawnY, spawnZ + 5.0, false)

    if foundGround then spawnZ = groundZ end

    return vector4(spawnX, spawnY, spawnZ, GetEntityHeading(ped))
end

function Tester.Clear(silent)
    if testTrailer and DoesEntityExist(testTrailer) then
        local cargo = TrailerCargoProps()
        if cargo.CleanupForTrailer then
            cargo.CleanupForTrailer(testTrailer)
        end

        SetEntityAsMissionEntity(testTrailer, true, true)
        DeleteEntity(testTrailer)
    end

    testTrailer = nil
    testTrailerKey = nil

    if not silent then
        Notify('Trailer test unit cleared.', 'success')
    end
end

function Tester.Spawn(trailerKey)
    trailerKey = trailerKey or 'flatbed_crates'

    local trailer = Config.RouteTrailers and Config.RouteTrailers[trailerKey] or nil
    if not trailer then
        Notify(('Unknown RouteTrailers key: %s'):format(tostring(trailerKey)), 'error')
        return false
    end

    Tester.Clear(true)

    local model = LoadModel(trailer.model)
    if not model then return false end

    local spawn = BuildSpawnCoords()
    local vehicle = CreateVehicle(model, spawn.x, spawn.y, spawn.z, spawn.w, true, false)
    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleOnGroundProperly(vehicle)
    SetVehicleDirtLevel(vehicle, 0.0)

    if trailer.livery ~= nil then
        SetVehicleLivery(vehicle, trailer.livery)
    end

    ApplyExtras(vehicle, trailer.extras)

    local cargo = TrailerCargoProps()
    if cargo.AttachToTrailer then
        cargo.AttachToTrailer(vehicle, trailer.cargoProps)
    end

    SetModelAsNoLongerNeeded(model)

    testTrailer = vehicle
    testTrailerKey = trailerKey

    local propCount = type(trailer.cargoProps) == 'table' and #trailer.cargoProps or 0
    Notify(('Spawned %s with %s cargo prop%s.'):format(trailer.label or trailerKey, propCount, propCount == 1 and '' or 's'), 'success')
    return true
end

function Tester.GetCurrent()
    return testTrailer, testTrailerKey
end

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    Tester.Clear(true)
end)

LS_Trucking.TrailerCargoTester = Tester
