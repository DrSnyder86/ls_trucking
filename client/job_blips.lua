LS_Trucking = LS_Trucking or {}

local JobBlips = {}
local activeBlips = {}

local function GetConfig()
    return Config.JobBlips or {}
end

local function GetSprite(unitType)
    local sprites = GetConfig().sprites or {}
    return tonumber(sprites[unitType or 'unknown'] or sprites.unknown or 1) or 1
end

local function GetColor(state)
    local colors = GetConfig().colors or {}
    return tonumber(colors[state or 'idle'] or colors.idle or 5) or 5
end

local function GetScale()
    return tonumber(GetConfig().scale) or 0.72
end

local function RemoveBlipForSource(source)
    local blip = activeBlips[source]
    if blip and DoesBlipExist(blip) then
        RemoveBlip(blip)
    end

    activeBlips[source] = nil
end

local function ClearBlips()
    for source in pairs(activeBlips) do
        RemoveBlipForSource(source)
    end
end

local function SetBlipName(blip, label)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(label or GetConfig().label or 'LSFC Unit')
    EndTextCommandSetBlipName(blip)
end

local function UpdateBlip(unit)
    if not unit or not unit.source or not unit.coords then return end

    local coords = unit.coords
    local blip = activeBlips[unit.source]

    if not blip or not DoesBlipExist(blip) then
        blip = AddBlipForCoord(coords.x + 0.0, coords.y + 0.0, coords.z + 0.0)
        activeBlips[unit.source] = blip
    else
        SetBlipCoords(blip, coords.x + 0.0, coords.y + 0.0, coords.z + 0.0)
    end

    SetBlipSprite(blip, GetSprite(unit.unitType))
    SetBlipColour(blip, GetColor(unit.state))
    SetBlipScale(blip, GetScale())
    SetBlipDisplay(blip, 4)
    SetBlipAsShortRange(blip, GetConfig().shortRange ~= false)
    ShowHeadingIndicatorOnBlip(blip, false)
    SetBlipName(blip, unit.label)
end

RegisterNetEvent('ls_trucking:client:updateJobBlips', function(units)
    if GetConfig().enabled == false then
        ClearBlips()
        return
    end

    units = type(units) == 'table' and units or {}

    local seen = {}
    local selfSource = GetPlayerServerId(PlayerId())

    for _, unit in ipairs(units) do
        if unit and unit.source then
            if GetConfig().showSelf == true or tonumber(unit.source) ~= tonumber(selfSource) then
                seen[unit.source] = true
                UpdateBlip(unit)
            end
        end
    end

    for source in pairs(activeBlips) do
        if not seen[source] then
            RemoveBlipForSource(source)
        end
    end
end)

RegisterNetEvent('ls_trucking:client:clearJobBlips', ClearBlips)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        ClearBlips()
    end
end)

LS_Trucking.JobBlipsClient = JobBlips
