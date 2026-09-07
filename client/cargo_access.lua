LS_Trucking = LS_Trucking or {}

local CargoAccess = {}
local modelBounds = {}
local rearDoorBones = { 'door_dside_r', 'door_pside_r', 'door_hatch_r' }
local cargoDoorIndexes = { 5, 2, 3 }

local function Clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end

local function GetBounds(vehicle)
    local model = GetEntityModel(vehicle)
    if modelBounds[model] then return modelBounds[model].minimum, modelBounds[model].maximum end

    local ok, minimum, maximum = pcall(GetModelDimensions, model)
    if not ok or not minimum or not maximum then
        minimum = { x = -1.0, y = -2.5, z = -0.5 }
        maximum = { x = 1.0, y = 2.5, z = 2.0 }
    end

    modelBounds[model] = { minimum = minimum, maximum = maximum }
    return minimum, maximum
end

local function GetBonePosition(vehicle, boneName)
    local boneIndex = GetEntityBoneIndexByName(vehicle, boneName)
    if not boneIndex or boneIndex < 0 then return nil end

    local position = GetWorldPositionOfEntityBone(vehicle, boneIndex)
    if not position or position.x == nil or position.y == nil then return nil end
    return position
end

local function GetRearDoorPosition(vehicle, minimum)
    local positions = {}
    for _, boneName in ipairs(rearDoorBones) do
        local position = GetBonePosition(vehicle, boneName)
        if position then positions[#positions + 1] = position end
    end

    if #positions == 0 then
        local boot = GetBonePosition(vehicle, 'boot')
        if boot then positions[1] = boot end
    end

    if #positions > 0 then
        local x, y, z = 0.0, 0.0, 0.0
        for _, position in ipairs(positions) do
            x = x + position.x
            y = y + position.y
            z = z + (position.z or 0.0)
        end
        return { x = x / #positions, y = y / #positions, z = z / #positions }
    end

    return GetOffsetFromEntityInWorldCoords(vehicle, 0.0, (minimum.y or -2.5) - 0.15, 0.0)
end

function CargoAccess.HasOpenDoor(vehicle)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return false end

    for _, doorIndex in ipairs(cargoDoorIndexes) do
        if IsVehicleDoorDamaged(vehicle, doorIndex) or GetVehicleDoorAngleRatio(vehicle, doorIndex) > 0.1 then
            return true
        end
    end

    return false
end

function CargoAccess.IsNearRearDoor(vehicle, playerCoords)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return false end

    local coords = playerCoords or GetEntityCoords(PlayerPedId())
    local minimum, maximum = GetBounds(vehicle)
    local localCoords = GetOffsetFromEntityGivenWorldCoords(vehicle, coords.x, coords.y, coords.z)
    local width = math.max(1.0, (maximum.x or 1.0) - (minimum.x or -1.0))
    local length = math.max(2.0, (maximum.y or 2.5) - (minimum.y or -2.5))
    local lateralPadding = Clamp(width * 0.12, 0.25, 0.45)
    local rearTolerance = Clamp(length * 0.08, 0.45, 0.8)

    if localCoords.x < (minimum.x or -1.0) - lateralPadding then return false end
    if localCoords.x > (maximum.x or 1.0) + lateralPadding then return false end
    if localCoords.y > (minimum.y or -2.5) + rearTolerance then return false end

    local accessPoint = GetRearDoorPosition(vehicle, minimum)
    local deltaX = coords.x - accessPoint.x
    local deltaY = coords.y - accessPoint.y
    local accessRadius = Clamp(width * 0.5 + 0.65, 1.55, 2.1)
    return math.sqrt(deltaX * deltaX + deltaY * deltaY) <= accessRadius
end

function CargoAccess.CanHandleCargo(vehicle, playerCoords)
    return CargoAccess.HasOpenDoor(vehicle) and CargoAccess.IsNearRearDoor(vehicle, playerCoords)
end

function CargoAccess.GetSearchRadius(vehicle)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return 6.0 end
    local minimum = GetBounds(vehicle)
    return Clamp(math.abs(minimum.y or -2.5) + 2.25, 4.0, 8.0)
end

LS_Trucking.CargoAccess = CargoAccess
