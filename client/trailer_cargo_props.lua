LS_Trucking = LS_Trucking or {}

local TrailerCargoProps = {}
local attachedByTrailer = {}

local function LoadModel(modelName)
    if not modelName then return nil end

    local model = type(modelName) == 'number' and modelName or joaat(modelName)
    if not IsModelInCdimage(model) then return nil end

    RequestModel(model)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(model) and GetGameTimer() < timeout do
        Wait(0)
    end

    if not HasModelLoaded(model) then return nil end
    return model
end

local function ReadVec3(value, fallback)
    fallback = fallback or { x = 0.0, y = 0.0, z = 0.0 }
    if not value then return { x = fallback.x, y = fallback.y, z = fallback.z } end

    local valueType = type(value)
    if valueType ~= 'table' and valueType ~= 'vector3' and valueType ~= 'vector4' then
        return { x = fallback.x, y = fallback.y, z = fallback.z }
    end

    return {
        x = tonumber(value.x) or tonumber(value[1]) or fallback.x,
        y = tonumber(value.y) or tonumber(value[2]) or fallback.y,
        z = tonumber(value.z) or tonumber(value[3]) or fallback.z
    }
end

local function DeleteEntitySafe(entity)
    if not entity or entity == 0 or not DoesEntityExist(entity) then return end
    SetEntityAsMissionEntity(entity, true, true)
    DeleteEntity(entity)
end

function TrailerCargoProps.CleanupForTrailer(trailer)
    local props = attachedByTrailer[trailer]
    if not props then return end

    for _, entity in ipairs(props) do
        DeleteEntitySafe(entity)
    end

    attachedByTrailer[trailer] = nil
end

function TrailerCargoProps.CleanupAll()
    for trailer in pairs(attachedByTrailer) do
        TrailerCargoProps.CleanupForTrailer(trailer)
    end
end

function TrailerCargoProps.AttachToTrailer(trailer, cargoProps)
    if not trailer or trailer == 0 or not DoesEntityExist(trailer) then return {} end

    TrailerCargoProps.CleanupForTrailer(trailer)

    if type(cargoProps) ~= 'table' or #cargoProps == 0 then
        return {}
    end

    local trailerCoords = GetEntityCoords(trailer)
    local attachedProps = {}

    for _, propData in ipairs(cargoProps) do
        if type(propData) == 'table' and propData.model then
            local model = LoadModel(propData.model)
            if model then
                local offset = ReadVec3(propData.offset)
                local rotation = ReadVec3(propData.rotation)
                local prop = CreateObject(model, trailerCoords.x, trailerCoords.y, trailerCoords.z + 1.0, true, true, false)

                SetEntityAsMissionEntity(prop, true, true)
                SetEntityCollision(prop, false, false)
                SetEntityNoCollisionEntity(prop, trailer, true)
                AttachEntityToEntity(
                    prop,
                    trailer,
                    0,
                    offset.x, offset.y, offset.z,
                    rotation.x, rotation.y, rotation.z,
                    false, false, false, false, 2, true
                )

                attachedProps[#attachedProps + 1] = prop
                SetModelAsNoLongerNeeded(model)
            end
        end
    end

    attachedByTrailer[trailer] = attachedProps
    return attachedProps
end

LS_Trucking.TrailerCargoProps = TrailerCargoProps
