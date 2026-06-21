LS_Trucking = LS_Trucking or {}

local JobBlips = {}
local registered = false
local forceUpdate = true
local lastSignature = ''
local viewerCache = {}
local unitCache = {}
local registeredContext = nil
local queuedUpdate = false

local function GetConfig()
    return Config.JobBlips or {}
end

local function IsEnabled()
    return GetConfig().enabled ~= false
end

local function GetUpdateInterval()
    return math.max(2000, tonumber(GetConfig().updateInterval) or 7500)
end

local function GetMinMoveDistance()
    return math.max(0.0, tonumber(GetConfig().minMoveDistance) or 25.0)
end

local function TrimString(value)
    value = tostring(value or '')
    return value:match('^%s*(.-)%s*$') or value
end

local function CoordsTable(coords)
    if not coords then return nil end
    return {
        x = coords.x + 0.0,
        y = coords.y + 0.0,
        z = coords.z + 0.0
    }
end

local function DistanceSquared(a, b)
    if not a or not b then return math.huge end

    local dx = (a.x or 0.0) - (b.x or 0.0)
    local dy = (a.y or 0.0) - (b.y or 0.0)
    local dz = (a.z or 0.0) - (b.z or 0.0)
    return (dx * dx) + (dy * dy) + (dz * dz)
end

local function HasMovedEnough(oldCoords, newCoords)
    if not oldCoords or not newCoords then return true end

    local minDistance = GetMinMoveDistance()
    if minDistance <= 0.0 then return true end

    return DistanceSquared(oldCoords, newCoords) >= (minDistance * minDistance)
end

local function GetPlayerCoords(src)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return nil end

    local ok, coords = pcall(GetEntityCoords, ped)
    if ok and coords then return coords end

    return nil
end

local function IsPlayerInVehicle(src)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return false end

    local ok, vehicle = pcall(GetVehiclePedIsIn, ped, false)
    return ok and vehicle and vehicle ~= 0
end

local function HasTrackerAccess(ctx, src)
    if not IsEnabled() then return false end
    if ctx.HasRequiredJob and not ctx.HasRequiredJob(src) then return false end

    if GetConfig().requireDuty ~= false then
        local onDuty = ctx.GetPlayerDutyState and ctx.GetPlayerDutyState(src)
        if onDuty ~= true then return false end
    end

    return true
end

local function NormalizeUnitType(unitType)
    unitType = tostring(unitType or ''):lower()

    if unitType == 'van' or unitType == 'boxtruck' or unitType == 'trailer' then
        return unitType
    end

    if unitType == 'box' or unitType == 'box_truck' then return 'boxtruck' end
    if unitType == 'semi' or unitType == 'tractor' then return 'trailer' end

    return unitType ~= '' and 'unknown' or 'foot'
end

local function BuildUnitState(ctx, src)
    local active = ctx.ActiveContracts and ctx.ActiveContracts[src] or nil
    local checkedOut = (ctx.CheckedOutVehicles and ctx.CheckedOutVehicles[src]) or (ctx.ReusableVehicles and ctx.ReusableVehicles[src])
    local name = TrimString((ctx.GetCharacterName and ctx.GetCharacterName(src)) or GetPlayerName(src) or ('Driver %s'):format(src))
    local unitType = 'foot'
    local state = 'idle'
    local routeLabel = nil
    local vehicleLabel = nil
    local plate = nil
    local sourceLabel = nil

    if active then
        unitType = active.type or (checkedOut and checkedOut.type) or 'unknown'
        state = active.contractor and 'contractor' or 'activeRoute'
        routeLabel = active.routeLabel or active.label
        vehicleLabel = active.vehicleLabel
        plate = active.plate
        sourceLabel = active.contractor and 'contractor' or 'company'
    elseif checkedOut then
        unitType = checkedOut.type or 'unknown'
        state = checkedOut.source == 'contractor' and 'contractor' or 'idle'
        plate = checkedOut.plate
        sourceLabel = checkedOut.source
    elseif IsPlayerInVehicle(src) then
        unitType = 'unknown'
    end

    unitType = NormalizeUnitType(unitType)

    local status = routeLabel or vehicleLabel or (unitType ~= 'foot' and unitType:gsub('^%l', string.upper) or 'On Duty')

    return {
        source = src,
        name = name,
        label = TrimString(('%s - %s'):format(name, status)),
        unitType = unitType,
        state = state,
        routeLabel = routeLabel,
        vehicleLabel = vehicleLabel,
        plate = plate,
        sourceLabel = sourceLabel
    }
end

local function UnitStateKey(unit)
    return table.concat({
        unit.unitType or '',
        unit.state or '',
        unit.routeLabel or '',
        unit.vehicleLabel or '',
        unit.plate or '',
        unit.sourceLabel or ''
    }, ':')
end

local function BuildSignature(units)
    local parts = {}

    for _, unit in ipairs(units) do
        local coords = unit.coords or {}
        parts[#parts + 1] = ('%s:%s:%s:%d:%d:%d'):format(
            unit.source or 0,
            unit.unitType or 'unknown',
            unit.state or 'idle',
            math.floor((coords.x or 0.0) + 0.5),
            math.floor((coords.y or 0.0) + 0.5),
            math.floor((coords.z or 0.0) + 0.5)
        )
    end

    return table.concat(parts, '|')
end

local function SendClear(src)
    TriggerClientEvent('ls_trucking:client:clearJobBlips', src)
end

local function SendUpdate(src, units)
    TriggerClientEvent('ls_trucking:client:updateJobBlips', src, units)
end

local function BuildSnapshot(ctx)
    local viewers = {}
    local newViewers = {}
    local currentUnits = {}
    local units = {}

    for _, playerId in ipairs(GetPlayers()) do
        local src = tonumber(playerId)

        if src and HasTrackerAccess(ctx, src) then
            viewers[src] = true
            if not viewerCache[src] then newViewers[src] = true end

            local coords = CoordsTable(GetPlayerCoords(src))
            if coords then
                local unit = BuildUnitState(ctx, src)
                local cache = unitCache[src] or {}
                local stateKey = UnitStateKey(unit)

                if forceUpdate or cache.stateKey ~= stateKey or HasMovedEnough(cache.coords, coords) then
                    cache.coords = coords
                    cache.stateKey = stateKey
                    unitCache[src] = cache
                end

                unit.coords = cache.coords or coords
                units[#units + 1] = unit
                currentUnits[src] = true
            end
        end
    end

    for src in pairs(viewerCache) do
        if not viewers[src] then SendClear(src) end
    end

    for src in pairs(unitCache) do
        if not currentUnits[src] then unitCache[src] = nil end
    end

    table.sort(units, function(a, b)
        return (a.source or 0) < (b.source or 0)
    end)

    return viewers, newViewers, units
end

local function Tick(ctx)
    if not IsEnabled() then
        for src in pairs(viewerCache) do SendClear(src) end
        viewerCache = {}
        unitCache = {}
        lastSignature = ''
        forceUpdate = false
        return
    end

    local viewers, newViewers, units = BuildSnapshot(ctx)
    local signature = BuildSignature(units)
    local changed = forceUpdate or signature ~= lastSignature

    if changed then
        for src in pairs(viewers) do SendUpdate(src, units) end
        lastSignature = signature
    else
        for src in pairs(newViewers) do SendUpdate(src, units) end
    end

    viewerCache = viewers
    forceUpdate = false
end

function JobBlips.QueueUpdate()
    forceUpdate = true

    if registeredContext and not queuedUpdate then
        queuedUpdate = true

        CreateThread(function()
            Wait(500)
            queuedUpdate = false
            Tick(registeredContext)
        end)
    end
end

function JobBlips.RegisterServer(ctx)
    if registered then return end
    registered = true
    ctx = ctx or {}
    registeredContext = ctx

    CreateThread(function()
        while true do
            Wait(GetUpdateInterval())
            Tick(ctx)
        end
    end)
end

LS_Trucking.JobBlips = JobBlips
