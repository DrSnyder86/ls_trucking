LS_Trucking = LS_Trucking or {}

local SpawnUtils = {}

local function GetSpawnConfig()
    return Config.SpawnOccupancy or {}
end

local function GetRadius(key, fallback)
    local cfg = GetSpawnConfig()
    return tonumber(cfg[key]) or fallback
end

function SpawnUtils.GetVehicleRadius()
    return GetRadius('VehicleRadius', 4.0)
end

function SpawnUtils.GetTrailerRadius()
    return GetRadius('TrailerRadius', 6.0)
end

function SpawnUtils.IsSpawnClear(spawn, radius)
    if not spawn then return false end

    local cfg = GetSpawnConfig()
    if cfg.Enabled == false then return true end

    radius = tonumber(radius) or SpawnUtils.GetVehicleRadius()
    return not IsAnyVehicleNearPoint(spawn.x, spawn.y, spawn.z, radius)
end

function SpawnUtils.FindClearSpawn(spawns, radius)
    if not spawns then return nil, nil end

    local list = {}
    if spawns.x and spawns.y and spawns.z then
        list[1] = spawns
    else
        for _, spawn in ipairs(spawns) do
            if spawn and spawn.x and spawn.y and spawn.z then
                list[#list + 1] = spawn
            end
        end
    end

    if #list == 0 then return nil, nil end

    local startIndex = math.random(1, #list)
    for offset = 0, #list - 1 do
        local index = ((startIndex + offset - 2) % #list) + 1
        local spawn = list[index]

        if SpawnUtils.IsSpawnClear(spawn, radius) then
            return spawn, index
        end
    end

    return nil, nil
end

LS_Trucking.SpawnUtils = SpawnUtils
