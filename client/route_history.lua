LS_Trucking = LS_Trucking or {}

local RouteHistory = {}

local ROUTE_HISTORY_LIMIT = 10
local LAST_ROUTE_SUMMARY_KVP = 'ls_trucking_last_route_summary'
local ROUTE_HISTORY_KVP = 'ls_trucking_route_history'

local lastRouteSummary = nil
local routeHistory = {}

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

function RouteHistory.Load()
    local raw = GetResourceKvpString(LAST_ROUTE_SUMMARY_KVP)

    if raw and raw ~= '' then
        local ok, decoded = pcall(json.decode, raw)

        if ok and type(decoded) == 'table' then
            lastRouteSummary = decoded
        end
    end

    local historyRaw = GetResourceKvpString(ROUTE_HISTORY_KVP)
    if historyRaw and historyRaw ~= '' then
        local ok, decoded = pcall(json.decode, historyRaw)
        if ok and type(decoded) == 'table' then
            routeHistory = decoded
        end
    end
end

function RouteHistory.GetLast()
    return lastRouteSummary
end

function RouteHistory.GetHistory()
    return routeHistory
end

function RouteHistory.Save(data)
    if not data or type(data) ~= 'table' then return end

    lastRouteSummary = data
    data.historyId = data.historyId or ('%s:%s'):format(tostring(data.contractId or 'route'), tostring(data.completedAt or RouteHistory.GetClientTimestamp()))

    local nextHistory = { data }
    local seen = { [data.historyId] = true }

    for _, entry in ipairs(routeHistory or {}) do
        local entryId = entry and (entry.historyId or ('%s:%s'):format(tostring(entry.contractId or 'route'), tostring(entry.completedAt or '')))
        if entry and entryId and not seen[entryId] then
            entry.historyId = entryId
            nextHistory[#nextHistory + 1] = entry
            seen[entryId] = true
            if #nextHistory >= ROUTE_HISTORY_LIMIT then break end
        end
    end

    routeHistory = nextHistory
    SetResourceKvp(LAST_ROUTE_SUMMARY_KVP, json.encode(data))
    SetResourceKvp(ROUTE_HISTORY_KVP, json.encode(routeHistory))

    SendNUIMessage({
        action = 'updateRouteHistory',
        summary = lastRouteSummary,
        history = routeHistory
    })
end

LS_Trucking.RouteHistory = RouteHistory
