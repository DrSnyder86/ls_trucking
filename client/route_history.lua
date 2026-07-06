LS_Trucking = LS_Trucking or {}

local RouteHistory = {}

local ROUTE_HISTORY_LIMIT = 10
local LAST_ROUTE_SUMMARY_KVP = 'ls_trucking_last_route_summary'
local ROUTE_HISTORY_KVP = 'ls_trucking_route_history'

local lastRouteSummary = nil
local routeHistory = {}
local currentCharacterId = nil
local currentLastKey = LAST_ROUTE_SUMMARY_KVP
local currentHistoryKey = ROUTE_HISTORY_KVP

local function NormalizeCharacterId(value)
    value = tostring(value or '')
    value = value:gsub('%s+', '')
    if value == '' then return nil end
    return value
end

local function BuildCharacterKey(baseKey, characterId)
    characterId = NormalizeCharacterId(characterId)
    if not characterId then return baseKey end
    return ('%s:%s'):format(baseKey, characterId:gsub('[^%w_%-:]', '_'))
end

local function EntryBelongsToCharacter(entry)
    if not currentCharacterId or not entry or not entry.citizenid then return true end
    return tostring(entry.citizenid) == currentCharacterId
end

local function LoadFromCurrentKeys()
    lastRouteSummary = nil
    routeHistory = {}

    local raw = GetResourceKvpString(currentLastKey)
    if raw and raw ~= '' then
        local ok, decoded = pcall(json.decode, raw)
        if ok and type(decoded) == 'table' and EntryBelongsToCharacter(decoded) then
            lastRouteSummary = decoded
        end
    end

    local historyRaw = GetResourceKvpString(currentHistoryKey)
    if historyRaw and historyRaw ~= '' then
        local ok, decoded = pcall(json.decode, historyRaw)
        if ok and type(decoded) == 'table' then
            for _, entry in ipairs(decoded) do
                if EntryBelongsToCharacter(entry) then
                    routeHistory[#routeHistory + 1] = entry
                    if #routeHistory >= ROUTE_HISTORY_LIMIT then break end
                end
            end
        end
    end

    if not lastRouteSummary and routeHistory[1] then
        lastRouteSummary = routeHistory[1]
    end
end

function RouteHistory.GetClientTimestamp()
    local function pad(number)
        number = tonumber(number) or 0
        return number < 10 and ('0' .. number) or tostring(number)
    end

    if GetLocalTime then
        local ok, year, month, a, b, c, d, e = pcall(GetLocalTime)

        if ok and tonumber(year) and tonumber(month) then
            -- Some FiveM builds return: year, month, dayOfWeek, day, hour, minute, second
            if tonumber(e) then
                local day = tonumber(b) or 1
                local hour = tonumber(c) or 0
                local minute = tonumber(d) or 0
                return ('%04d-%s-%s %s:%s'):format(tonumber(year), pad(month), pad(day), pad(hour), pad(minute))
            end

            -- Other builds may return: year, month, day, hour, minute, second
            if tonumber(d) then
                local day = tonumber(a) or 1
                local hour = tonumber(b) or 0
                local minute = tonumber(c) or 0
                return ('%04d-%s-%s %s:%s'):format(tonumber(year), pad(month), pad(day), pad(hour), pad(minute))
            end
        end
    end

    return 'Current Session'
end

function RouteHistory.Load(characterId)
    currentCharacterId = NormalizeCharacterId(characterId)
    currentLastKey = BuildCharacterKey(LAST_ROUTE_SUMMARY_KVP, currentCharacterId)
    currentHistoryKey = BuildCharacterKey(ROUTE_HISTORY_KVP, currentCharacterId)
    LoadFromCurrentKeys()
end

function RouteHistory.SetCharacter(characterId)
    local normalized = NormalizeCharacterId(characterId)
    if normalized == currentCharacterId then return end
    RouteHistory.Load(normalized)
end

function RouteHistory.GetLast()
    if lastRouteSummary and EntryBelongsToCharacter(lastRouteSummary) then return lastRouteSummary end
    return nil
end

function RouteHistory.GetHistory()
    if not currentCharacterId then return routeHistory end

    local filtered = {}
    for _, entry in ipairs(routeHistory or {}) do
        if EntryBelongsToCharacter(entry) then filtered[#filtered + 1] = entry end
    end
    return filtered
end

function RouteHistory.Save(data)
    if not data or type(data) ~= 'table' then return end

    local dataCharacterId = NormalizeCharacterId(data.citizenid) or currentCharacterId
    if dataCharacterId and dataCharacterId ~= currentCharacterId then
        RouteHistory.SetCharacter(dataCharacterId)
    end

    if currentCharacterId then data.citizenid = currentCharacterId end

    lastRouteSummary = data
    data.historyId = data.historyId or ('%s:%s'):format(tostring(data.contractId or 'route'), tostring(data.completedAt or RouteHistory.GetClientTimestamp()))

    local nextHistory = { data }
    local seen = { [data.historyId] = true }

    for _, entry in ipairs(routeHistory or {}) do
        local entryId = entry and (entry.historyId or ('%s:%s'):format(tostring(entry.contractId or 'route'), tostring(entry.completedAt or '')))
        if entry and entryId and not seen[entryId] and EntryBelongsToCharacter(entry) then
            entry.historyId = entryId
            nextHistory[#nextHistory + 1] = entry
            seen[entryId] = true
            if #nextHistory >= ROUTE_HISTORY_LIMIT then break end
        end
    end

    routeHistory = nextHistory
    SetResourceKvp(currentLastKey, json.encode(data))
    SetResourceKvp(currentHistoryKey, json.encode(routeHistory))

    SendNUIMessage({
        action = 'updateRouteHistory',
        summary = lastRouteSummary,
        history = routeHistory
    })
end

LS_Trucking.RouteHistory = RouteHistory