LS_Trucking = LS_Trucking or {}

local Editor = {}
local draft = nil
local previewBlips = {}
local previewThreadRunning = false
local pedModelNamesByHash = nil

local ROUTE_TYPES = {
    { key = 'van', label = 'Package Delivery' },
    { key = 'boxtruck', label = 'Crate Delivery' },
    { key = 'trailer', label = 'Trailer Hauling' }
}

local POOL_LABELS = {
    commercial = 'Commercial (Standard + Priority)',
    government = 'Government',
    military = 'Military'
}

local function Notify(message, notifyType)
    if lib and lib.notify then
        lib.notify({
            title = 'LS Freight Route Editor',
            description = message,
            type = notifyType or 'inform'
        })
    else
        print(('[LS Freight Route Editor] %s'):format(message))
    end
end

local function Round(value, precision)
    local multiplier = 10 ^ (precision or 3)
    value = tonumber(value) or 0.0
    if value >= 0 then
        return math.floor(value * multiplier + 0.5) / multiplier
    end

    return math.ceil(value * multiplier - 0.5) / multiplier
end

local function PlainVec3(value)
    if not value then return nil end
    return {
        x = Round(value.x or value[1]),
        y = Round(value.y or value[2]),
        z = Round(value.z or value[3])
    }
end

local function PlainVec4(value)
    if not value then return nil end
    return {
        x = Round(value.x or value[1]),
        y = Round(value.y or value[2]),
        z = Round(value.z or value[3]),
        w = Round(value.w or value[4])
    }
end

local function ModelHashKey(value)
    local hash = tonumber(value)
    if not hash then return nil end
    return math.floor(hash) % 4294967296
end

local function RegisterPedModelName(lookup, modelName)
    modelName = tostring(modelName or ''):match('^%s*([%a_][%w_]*)%s*$')
    if not modelName then return end

    local modelHash = type(joaat) == 'function' and joaat(modelName) or GetHashKey(modelName)
    local hashKey = ModelHashKey(modelHash)
    if hashKey then lookup[hashKey] = modelName end
end

local function BuildPedModelNameLookup()
    local lookup = {}
    RegisterPedModelName(lookup, 's_m_m_gaffer_01')

    -- Backtick model literals are hashes at runtime, so recover their source names for config-ready exports.
    local resourceName = type(GetCurrentResourceName) == 'function' and GetCurrentResourceName() or ''
    local source = resourceName ~= '' and LoadResourceFile(resourceName, 'config/contracts.lua') or nil
    if type(source) == 'string' then
        for modelName in source:gmatch('model%s*=%s*`([%w_]+)`') do RegisterPedModelName(lookup, modelName) end
        for modelName in source:gmatch("model%s*=%s*'([%w_]+)'") do RegisterPedModelName(lookup, modelName) end
        for modelName in source:gmatch('model%s*=%s*"([%w_]+)"') do RegisterPedModelName(lookup, modelName) end
    end

    return lookup
end

local function ResolvePedModelName(value)
    local modelName = tostring(value or '')
    if modelName:match('^[%a_][%w_]*$') then return modelName end

    pedModelNamesByHash = pedModelNamesByHash or BuildPedModelNameLookup()
    return pedModelNamesByHash[ModelHashKey(value)] or modelName
end

local function CurrentPosition()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    return {
        x = Round(coords.x),
        y = Round(coords.y),
        z = Round(coords.z),
        w = Round(GetEntityHeading(ped), 2)
    }
end

local function CurrentStreetLabel(prefix)
    local position = CurrentPosition()
    local streetHash, crossingHash = GetStreetNameAtCoord(position.x, position.y, position.z)
    local street = streetHash and GetStreetNameFromHashKey(streetHash) or ''
    local crossing = crossingHash and crossingHash ~= 0 and GetStreetNameFromHashKey(crossingHash) or ''
    local location = street

    if crossing ~= '' and crossing ~= street then
        location = location ~= '' and ('%s / %s'):format(location, crossing) or crossing
    end

    if location == '' then return prefix end
    return ('%s - %s'):format(prefix, location)
end

local function SortedKeys(source)
    local keys = {}
    for key in pairs(source or {}) do
        keys[#keys + 1] = tostring(key)
    end
    table.sort(keys)
    return keys
end

local function RouteTypeExists(routeType)
    for _, entry in ipairs(ROUTE_TYPES) do
        if entry.key == routeType then return true end
    end
    return false
end

local function NormalizeRouteType(routeType)
    routeType = tostring(routeType or ''):lower()
    return RouteTypeExists(routeType) and routeType or 'van'
end

local function PoolHasRoutes(routeType, pool)
    if pool == 'commercial' then
        return Config.Contracts and Config.Contracts[routeType] and type(Config.Contracts[routeType].routes) == 'table'
    end

    local priority = Config.PriorityLoads and Config.PriorityLoads[routeType] and Config.PriorityLoads[routeType][pool]
    return priority and type(priority.routes) == 'table'
end

local function NormalizePool(routeType, pool)
    pool = tostring(pool or ''):lower()
    if PoolHasRoutes(routeType, pool) then return pool end
    return 'commercial'
end

local function GetRoutePool(routeType, pool)
    if pool == 'commercial' then
        local contract = Config.Contracts and Config.Contracts[routeType]
        return contract and contract.routes or {}
    end

    local priority = Config.PriorityLoads and Config.PriorityLoads[routeType] and Config.PriorityLoads[routeType][pool]
    return priority and priority.routes or {}
end

local function RoutePath(routeType, pool)
    if pool == 'commercial' then
        return ('Config.Contracts.%s.routes'):format(routeType)
    end

    return ('Config.PriorityLoads.%s.%s.routes'):format(routeType, pool)
end

local function DefaultUnload(routeType)
    return routeType == 'boxtruck' and 2 or 1
end

local function CopyDeliveryRoute(route)
    local copy = {
        label = tostring(route and route.label or ''),
        routeLength = tostring(route and route.routeLength or ''),
        dropoffs = {}
    }

    for _, stop in ipairs(route and route.dropoffs or {}) do
        copy.dropoffs[#copy.dropoffs + 1] = {
            label = tostring(stop.label or ''),
            coords = PlainVec3(stop.coords),
            unload = math.max(1, math.floor(tonumber(stop.unload) or 1))
        }
    end

    return copy
end

local function CopyTrailerRoute(route)
    route = route or {}
    return {
        label = tostring(route.label or ''),
        routeLength = tostring(route.routeLength or ''),
        pickupDepot = tostring(route.pickupDepot or ''),
        trailerKey = tostring(route.trailerKey or ''),
        trailerContents = tostring(route.trailerContents or ''),
        trailerDrop = {
            label = tostring(route.trailerDrop and route.trailerDrop.label or ''),
            coords = PlainVec3(route.trailerDrop and route.trailerDrop.coords),
            radius = Round(route.trailerDrop and route.trailerDrop.radius or 22.0, 1)
        },
        receiverPed = {
            label = tostring(route.receiverPed and route.receiverPed.label or ''),
            model = ResolvePedModelName(route.receiverPed and route.receiverPed.model or 's_m_m_gaffer_01'),
            coords = PlainVec4(route.receiverPed and route.receiverPed.coords),
            scenario = tostring(route.receiverPed and route.receiverPed.scenario or 'WORLD_HUMAN_CLIPBOARD')
        }
    }
end

local function FirstKey(source)
    local keys = SortedKeys(source)
    return keys[1] or ''
end

local function NewRoute(routeType)
    if routeType == 'trailer' then
        local trailerKey = FirstKey(Config.RouteTrailers)
        local trailer = Config.RouteTrailers and Config.RouteTrailers[trailerKey] or {}
        return {
            label = 'New Trailer Route',
            routeLength = '',
            pickupDepot = FirstKey(Config.TrailerDepots),
            trailerKey = trailerKey,
            trailerContents = tostring(trailer.contents or ''),
            trailerDrop = { label = 'Receiving Yard', coords = nil, radius = 22.0 },
            receiverPed = {
                label = 'Warehouse Receiver',
                model = 's_m_m_gaffer_01',
                coords = nil,
                scenario = 'WORLD_HUMAN_CLIPBOARD'
            }
        }
    end

    return {
        label = routeType == 'boxtruck' and 'New Freight Route' or 'New Package Route',
        routeLength = '',
        dropoffs = {}
    }
end

local function NewDraft(routeType, pool)
    routeType = NormalizeRouteType(routeType)
    pool = NormalizePool(routeType, pool)
    return {
        routeType = routeType,
        pool = pool,
        mode = 'new',
        sourceIndex = nil,
        selectedIndex = 1,
        preview = false,
        route = NewRoute(routeType)
    }
end

local function CopyExistingRoute(routeType, route)
    if routeType == 'trailer' then return CopyTrailerRoute(route) end
    return CopyDeliveryRoute(route)
end

local function HasCoordinates(coords)
    if type(coords) ~= 'table' then return false end
    local x = tonumber(coords.x)
    local y = tonumber(coords.y)
    local z = tonumber(coords.z)
    if not x or not y or not z then return false end
    return math.abs(x) + math.abs(y) + math.abs(z) > 0.01
end

local function AddIssue(issues, level, message)
    issues[#issues + 1] = { level = level, message = message }
end

local function ValidateDraft()
    local issues = {}
    if not draft then
        AddIssue(issues, 'error', 'No route draft is open.')
        return issues
    end

    local route = draft.route or {}
    if tostring(route.label or ''):match('^%s*$') then
        AddIssue(issues, 'error', 'Enter a route name.')
    end
    if tostring(route.routeLength or ''):match('^%s*$') then
        AddIssue(issues, 'warning', 'Route length is blank. Use Estimate Distance or enter a value.')
    end

    local routes = GetRoutePool(draft.routeType, draft.pool)
    for index, existing in ipairs(routes) do
        if index ~= draft.sourceIndex and tostring(existing.label or ''):lower() == tostring(route.label or ''):lower() then
            AddIssue(issues, 'warning', ('A route named "%s" already exists in this pool.'):format(route.label))
            break
        end
    end

    if draft.routeType ~= 'trailer' then
        local totalUnload = 0
        if #(route.dropoffs or {}) == 0 then
            AddIssue(issues, 'error', 'Capture at least one delivery stop.')
        end

        for index, stop in ipairs(route.dropoffs or {}) do
            if tostring(stop.label or ''):match('^%s*$') then
                AddIssue(issues, 'error', ('Stop %s needs a label.'):format(index))
            end
            if not HasCoordinates(stop.coords) then
                AddIssue(issues, 'error', ('Stop %s has not been positioned.'):format(index))
            end
            local unload = math.floor(tonumber(stop.unload) or 0)
            if unload < 1 then
                AddIssue(issues, 'error', ('Stop %s must unload at least one item.'):format(index))
            end
            totalUnload = totalUnload + math.max(0, unload)
        end

        local contract = Config.Contracts and Config.Contracts[draft.routeType] or {}
        local requiredCargo = math.floor(tonumber(contract.requiredCargo) or 0)
        if requiredCargo > 0 and totalUnload ~= requiredCargo then
            AddIssue(issues, 'warning', ('Route unload total is %s; %s routes currently load %s items.'):format(
                totalUnload,
                draft.routeType == 'boxtruck' and 'box-truck' or 'van',
                requiredCargo
            ))
        end
    else
        if not Config.TrailerDepots or not Config.TrailerDepots[route.pickupDepot] then
            AddIssue(issues, 'error', 'Select a valid trailer pickup depot.')
        end
        if not Config.RouteTrailers or not Config.RouteTrailers[route.trailerKey] then
            AddIssue(issues, 'error', 'Select a valid trailer configuration.')
        end
        if tostring(route.trailerContents or ''):match('^%s*$') then
            AddIssue(issues, 'warning', 'Trailer contents are blank.')
        end
        if tostring(route.trailerDrop and route.trailerDrop.label or ''):match('^%s*$') then
            AddIssue(issues, 'error', 'Enter a trailer drop label.')
        end
        if not HasCoordinates(route.trailerDrop and route.trailerDrop.coords) then
            AddIssue(issues, 'error', 'Capture the trailer drop position.')
        end
        if tonumber(route.trailerDrop and route.trailerDrop.radius) and tonumber(route.trailerDrop.radius) < 5.0 then
            AddIssue(issues, 'warning', 'Trailer drop radius is unusually small.')
        end
        if tostring(route.receiverPed and route.receiverPed.label or ''):match('^%s*$') then
            AddIssue(issues, 'error', 'Enter a receiver label.')
        end
        local receiverModel = tostring(route.receiverPed and route.receiverPed.model or '')
        if receiverModel:match('^%s*$') then
            AddIssue(issues, 'error', 'Enter a receiver ped model.')
        elseif receiverModel:match('^%-?%d+$') then
            AddIssue(issues, 'error', 'Receiver ped hash could not be resolved. Enter its model name instead.')
        elseif not receiverModel:match('^[%a_][%w_]*$') then
            AddIssue(issues, 'error', 'Receiver ped model must begin with a letter or underscore and contain only letters, numbers, and underscores.')
        end
        if not HasCoordinates(route.receiverPed and route.receiverPed.coords) then
            AddIssue(issues, 'error', 'Capture the receiver ped position.')
        end
    end

    return issues
end

local function LuaString(value)
    return ('%q'):format(tostring(value or ''))
end

local function LuaVec3(coords)
    coords = coords or {}
    return ('vector3(%.3f, %.3f, %.3f)'):format(
        tonumber(coords.x) or 0.0,
        tonumber(coords.y) or 0.0,
        tonumber(coords.z) or 0.0
    )
end

local function LuaVec4(coords)
    coords = coords or {}
    return ('vector4(%.3f, %.3f, %.3f, %.2f)'):format(
        tonumber(coords.x) or 0.0,
        tonumber(coords.y) or 0.0,
        tonumber(coords.z) or 0.0,
        tonumber(coords.w) or 0.0
    )
end

local function BuildLuaExport()
    if not draft then return '' end
    local route = draft.route or {}
    local lines = {
        ('-- Add inside %s'):format(RoutePath(draft.routeType, draft.pool))
    }

    if draft.sourceIndex then
        lines[#lines + 1] = ('-- Replaces route #%s in the current file.'):format(draft.sourceIndex)
    end

    lines[#lines + 1] = '{'
    lines[#lines + 1] = ('    label = %s,'):format(LuaString(route.label))
    if tostring(route.routeLength or '') ~= '' then
        lines[#lines + 1] = ('    routeLength = %s,'):format(LuaString(route.routeLength))
    end

    if draft.routeType == 'trailer' then
        lines[#lines + 1] = ('    pickupDepot = %s,'):format(LuaString(route.pickupDepot))
        lines[#lines + 1] = ('    trailerKey = %s,'):format(LuaString(route.trailerKey))
        lines[#lines + 1] = ('    trailerContents = %s,'):format(LuaString(route.trailerContents))
        lines[#lines + 1] = '    trailerDrop = {'
        lines[#lines + 1] = ('        label = %s,'):format(LuaString(route.trailerDrop and route.trailerDrop.label))
        lines[#lines + 1] = ('        coords = %s,'):format(LuaVec3(route.trailerDrop and route.trailerDrop.coords))
        lines[#lines + 1] = ('        radius = %.1f'):format(tonumber(route.trailerDrop and route.trailerDrop.radius) or 22.0)
        lines[#lines + 1] = '    },'
        lines[#lines + 1] = '    receiverPed = {'
        lines[#lines + 1] = ('        label = %s,'):format(LuaString(route.receiverPed and route.receiverPed.label))
        local receiverModel = ResolvePedModelName(route.receiverPed and route.receiverPed.model or 's_m_m_gaffer_01'):gsub('[^%w_]', '')
        lines[#lines + 1] = ('        model = `%s`,'):format(receiverModel)
        lines[#lines + 1] = ('        coords = %s,'):format(LuaVec4(route.receiverPed and route.receiverPed.coords))
        lines[#lines + 1] = ('        scenario = %s'):format(LuaString(route.receiverPed and route.receiverPed.scenario or 'WORLD_HUMAN_CLIPBOARD'))
        lines[#lines + 1] = '    }'
    else
        lines[#lines + 1] = '    dropoffs = {'
        for _, stop in ipairs(route.dropoffs or {}) do
            lines[#lines + 1] = ('        { label = %s, coords = %s, unload = %s },'):format(
                LuaString(stop.label),
                LuaVec3(stop.coords),
                math.max(1, math.floor(tonumber(stop.unload) or 1))
            )
        end
        lines[#lines + 1] = '    }'
    end

    lines[#lines + 1] = '},'
    return table.concat(lines, '\n')
end

local function RouteTypeCatalog()
    local output = {}
    for _, entry in ipairs(ROUTE_TYPES) do
        output[#output + 1] = { key = entry.key, label = entry.label }
    end
    return output
end

local function PoolCatalog(routeType)
    local output = {}
    for _, key in ipairs({ 'commercial', 'government', 'military' }) do
        if PoolHasRoutes(routeType, key) then
            output[#output + 1] = { key = key, label = POOL_LABELS[key] }
        end
    end
    return output
end

local function ExistingRouteCatalog(routeType, pool)
    local output = {}
    for index, route in ipairs(GetRoutePool(routeType, pool)) do
        output[#output + 1] = {
            index = index,
            label = route.label or ('Route %s'):format(index),
            routeLength = route.routeLength or '',
            stops = routeType == 'trailer' and 1 or #(route.dropoffs or {})
        }
    end
    return output
end

local function KeyedCatalog(source)
    local output = {}
    for _, key in ipairs(SortedKeys(source)) do
        local entry = source[key] or {}
        output[#output + 1] = {
            key = key,
            label = entry.label or key,
            model = entry.model or '',
            contents = entry.contents or ''
        }
    end
    return output
end

local function RouteSummary()
    if not draft then return {} end
    if draft.routeType == 'trailer' then
        return { points = 2, totalUnload = 1, requiredCargo = 1 }
    end

    local totalUnload = 0
    for _, stop in ipairs(draft.route.dropoffs or {}) do
        totalUnload = totalUnload + math.max(0, math.floor(tonumber(stop.unload) or 0))
    end
    local contract = Config.Contracts and Config.Contracts[draft.routeType] or {}
    return {
        points = #(draft.route.dropoffs or {}),
        totalUnload = totalUnload,
        requiredCargo = math.floor(tonumber(contract.requiredCargo) or 0)
    }
end

local function BuildState()
    local issues = ValidateDraft()
    local errors = 0
    local warnings = 0
    for _, issue in ipairs(issues) do
        if issue.level == 'error' then errors = errors + 1 else warnings = warnings + 1 end
    end

    return {
        routeType = draft.routeType,
        pool = draft.pool,
        poolLabel = POOL_LABELS[draft.pool] or draft.pool,
        mode = draft.mode,
        sourceIndex = draft.sourceIndex,
        selectedIndex = draft.selectedIndex,
        preview = draft.preview == true,
        path = RoutePath(draft.routeType, draft.pool),
        route = draft.route,
        currentPosition = CurrentPosition(),
        types = RouteTypeCatalog(),
        pools = PoolCatalog(draft.routeType),
        existingRoutes = ExistingRouteCatalog(draft.routeType, draft.pool),
        depots = KeyedCatalog(Config.TrailerDepots),
        trailers = KeyedCatalog(Config.RouteTrailers),
        summary = RouteSummary(),
        issues = issues,
        errorCount = errors,
        warningCount = warnings,
        canExport = errors == 0,
        exportText = BuildLuaExport()
    }
end

local function ClearPreviewBlips()
    for _, blip in ipairs(previewBlips) do
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end
    previewBlips = {}
end

local function PreviewPoints()
    local points = {}
    if not draft then return points end

    if draft.routeType == 'trailer' then
        if HasCoordinates(draft.route.trailerDrop and draft.route.trailerDrop.coords) then
            points[#points + 1] = {
                label = draft.route.trailerDrop.label or 'Trailer Drop',
                coords = draft.route.trailerDrop.coords,
                kind = 'drop'
            }
        end
        if HasCoordinates(draft.route.receiverPed and draft.route.receiverPed.coords) then
            points[#points + 1] = {
                label = draft.route.receiverPed.label or 'Receiver',
                coords = draft.route.receiverPed.coords,
                kind = 'receiver'
            }
        end
        return points
    end

    for index, stop in ipairs(draft.route.dropoffs or {}) do
        if HasCoordinates(stop.coords) then
            points[#points + 1] = {
                label = stop.label or ('Stop %s'):format(index),
                coords = stop.coords,
                kind = 'stop',
                sourceIndex = index
            }
        end
    end
    return points
end

local function RefreshPreviewBlips()
    ClearPreviewBlips()
    if not draft or not draft.preview then return end

    local points = PreviewPoints()
    for index, point in ipairs(points) do
        local blip = AddBlipForCoord(point.coords.x, point.coords.y, point.coords.z)
        SetBlipSprite(blip, point.kind == 'receiver' and 480 or 1)
        SetBlipColour(blip, point.kind == 'receiver' and 2 or 5)
        SetBlipScale(blip, point.kind == 'receiver' and 0.68 or 0.72)
        SetBlipAsShortRange(blip, false)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(('Route Editor: %s'):format(point.label))
        EndTextCommandSetBlipName(blip)
        if ShowNumberOnBlip then ShowNumberOnBlip(blip, index) end

        local isSelected = draft.routeType == 'trailer'
            and ((draft.selectedIndex == 1 and point.kind == 'drop') or (draft.selectedIndex == 2 and point.kind == 'receiver'))
            or point.sourceIndex == draft.selectedIndex
        if isSelected then
            SetBlipRoute(blip, true)
            SetBlipRouteColour(blip, 5)
        end
        previewBlips[#previewBlips + 1] = blip
    end
end

local function EnsurePreviewThread()
    if previewThreadRunning then return end
    previewThreadRunning = true

    CreateThread(function()
        while draft do
            if draft.preview then
                local playerCoords = GetEntityCoords(PlayerPedId())
                for index, point in ipairs(PreviewPoints()) do
                    local dx = playerCoords.x - point.coords.x
                    local dy = playerCoords.y - point.coords.y
                    local dz = playerCoords.z - point.coords.z
                    if (dx * dx + dy * dy + dz * dz) < 90000.0 then
                        local selected = draft.routeType == 'trailer'
                            and ((draft.selectedIndex == 1 and point.kind == 'drop') or (draft.selectedIndex == 2 and point.kind == 'receiver'))
                            or point.sourceIndex == draft.selectedIndex
                        local red, green, blue = 239, 190, 88
                        if selected then red, green, blue = 92, 255, 111 end
                        DrawMarker(
                            point.kind == 'receiver' and 2 or 1,
                            point.coords.x, point.coords.y, point.coords.z - 0.75,
                            0.0, 0.0, 0.0,
                            0.0, 0.0, 0.0,
                            selected and 1.5 or 1.1, selected and 1.5 or 1.1, 0.3,
                            red, green, blue, selected and 190 or 135,
                            false, false, 2, false, nil, nil, false
                        )
                    end
                end
                Wait(0)
            else
                Wait(500)
            end
        end
        previewThreadRunning = false
    end)
end

local function SendState()
    if not draft then return end
    RefreshPreviewBlips()
    EnsurePreviewThread()
    SendNUIMessage({ action = 'updateRouteEditor', state = BuildState() })
end

local function LoadExisting(index)
    if not draft then return end
    index = math.floor(tonumber(index) or 0)
    local source = GetRoutePool(draft.routeType, draft.pool)[index]
    if not source then
        Notify(('Route #%s is not available in this pool.'):format(index), 'error')
        return
    end

    draft.route = CopyExistingRoute(draft.routeType, source)
    draft.sourceIndex = index
    draft.mode = 'edit'
    draft.selectedIndex = 1
end

local function SetCoordinate(target, axis, value)
    if not target or (axis ~= 'x' and axis ~= 'y' and axis ~= 'z' and axis ~= 'w') then return end
    target[axis] = Round(value, axis == 'w' and 2 or 3)
end

local function CaptureStop()
    if not draft or draft.routeType == 'trailer' then return end
    local index = #(draft.route.dropoffs or {}) + 1
    draft.route.dropoffs = draft.route.dropoffs or {}
    draft.route.dropoffs[index] = {
        label = CurrentStreetLabel(('Stop %s'):format(index)),
        coords = PlainVec3(CurrentPosition()),
        unload = DefaultUnload(draft.routeType)
    }
    draft.selectedIndex = index
end

local function CaptureSelectedStop()
    if not draft or draft.routeType == 'trailer' then return end
    local stop = draft.route.dropoffs and draft.route.dropoffs[draft.selectedIndex]
    if not stop then return end

    stop.coords = PlainVec3(CurrentPosition())
    if tostring(stop.label or ''):match('^%s*$') then
        stop.label = CurrentStreetLabel(('Stop %s'):format(draft.selectedIndex))
    end
end

local function CaptureTrailerPoint(target)
    if not draft or draft.routeType ~= 'trailer' then return end
    local position = CurrentPosition()
    if target == 'receiver' then
        draft.route.receiverPed.coords = PlainVec4(position)
        if draft.route.receiverPed.label == '' then
            draft.route.receiverPed.label = CurrentStreetLabel('Receiver')
        end
        draft.selectedIndex = 2
    else
        draft.route.trailerDrop.coords = PlainVec3(position)
        if draft.route.trailerDrop.label == '' then
            draft.route.trailerDrop.label = CurrentStreetLabel('Trailer Drop')
        end
        draft.selectedIndex = 1
    end
end

local function SelectedPoint()
    if not draft then return nil end
    if draft.routeType == 'trailer' then
        return draft.selectedIndex == 2 and draft.route.receiverPed.coords or draft.route.trailerDrop.coords
    end
    local stop = draft.route.dropoffs and draft.route.dropoffs[draft.selectedIndex]
    return stop and stop.coords or nil
end

local function EstimateDistance()
    if not draft then return end
    local route = draft.route
    local points = {}
    local start = nil

    if draft.routeType == 'trailer' then
        local depot = Config.TrailerDepots and Config.TrailerDepots[route.pickupDepot]
        start = depot and PlainVec3(depot.pickup)
        if HasCoordinates(route.trailerDrop and route.trailerDrop.coords) then
            points[1] = route.trailerDrop.coords
        end
    else
        local contract = Config.Contracts and Config.Contracts[draft.routeType]
        start = contract and contract.pickup and PlainVec3(contract.pickup.coords)
        for _, stop in ipairs(route.dropoffs or {}) do
            if HasCoordinates(stop.coords) then points[#points + 1] = stop.coords end
        end
    end

    if not HasCoordinates(start) or #points == 0 then
        Notify('Capture route points before estimating distance.', 'error')
        return
    end

    local meters = 0.0
    local previous = start
    for _, point in ipairs(points) do
        local segment = CalculateTravelDistanceBetweenPoints(
            previous.x, previous.y, previous.z,
            point.x, point.y, point.z
        )
        if not segment or segment <= 0.0 then
            local dx = point.x - previous.x
            local dy = point.y - previous.y
            local dz = point.z - previous.z
            segment = math.sqrt(dx * dx + dy * dy + dz * dz)
        end
        meters = meters + segment
        previous = point
    end

    route.routeLength = ('%.1f mi'):format(math.max(0.1, meters / 1609.344))
end

local function UpdateRouteField(data)
    if not draft then return end
    local field = tostring(data.field or '')
    local allowed = {
        label = true,
        routeLength = true,
        pickupDepot = true,
        trailerKey = true,
        trailerContents = true
    }
    if not allowed[field] then return end

    draft.route[field] = tostring(data.value or '')
    if field == 'trailerKey' and draft.route.trailerContents == '' then
        local trailer = Config.RouteTrailers and Config.RouteTrailers[draft.route.trailerKey]
        draft.route.trailerContents = trailer and tostring(trailer.contents or '') or ''
    end
end

local function UpdateStop(data)
    if not draft or draft.routeType == 'trailer' then return end
    local index = math.floor(tonumber(data.index) or draft.selectedIndex or 1)
    local stop = draft.route.dropoffs and draft.route.dropoffs[index]
    if not stop then return end

    local field = tostring(data.field or '')
    if field == 'label' then
        stop.label = tostring(data.value or '')
    elseif field == 'unload' then
        stop.unload = math.max(1, math.floor(tonumber(data.value) or 1))
    elseif field == 'x' or field == 'y' or field == 'z' then
        stop.coords = stop.coords or { x = 0.0, y = 0.0, z = 0.0 }
        SetCoordinate(stop.coords, field, data.value)
    end
end

local function UpdateTrailerPoint(data)
    if not draft or draft.routeType ~= 'trailer' then return end
    local targetName = data.target == 'receiver' and 'receiver' or 'drop'
    local target = targetName == 'receiver' and draft.route.receiverPed or draft.route.trailerDrop
    local field = tostring(data.field or '')

    if field == 'label' or (targetName == 'receiver' and (field == 'model' or field == 'scenario')) then
        target[field] = tostring(data.value or '')
    elseif targetName == 'drop' and field == 'radius' then
        target.radius = math.max(1.0, Round(data.value, 1))
    elseif field == 'x' or field == 'y' or field == 'z' or (targetName == 'receiver' and field == 'w') then
        target.coords = target.coords or { x = 0.0, y = 0.0, z = 0.0, w = 0.0 }
        SetCoordinate(target.coords, field, data.value)
    end
end

local function MoveStop(index, direction)
    if not draft or draft.routeType == 'trailer' then return end
    local stops = draft.route.dropoffs or {}
    index = math.floor(tonumber(index) or 0)
    local target = index + (direction == 'up' and -1 or 1)
    if not stops[index] or not stops[target] then return end
    stops[index], stops[target] = stops[target], stops[index]
    draft.selectedIndex = target
end

local function DeleteStop(index)
    if not draft or draft.routeType == 'trailer' then return end
    local stops = draft.route.dropoffs or {}
    index = math.floor(tonumber(index) or draft.selectedIndex or 1)
    if not stops[index] then return end
    table.remove(stops, index)
    draft.selectedIndex = math.max(1, math.min(index, #stops))
end

local function PrintExport()
    local issues = ValidateDraft()
    for _, issue in ipairs(issues) do
        if issue.level == 'error' then
            Notify('Resolve validation errors before exporting this route.', 'error')
            return
        end
    end

    print(('\n%s\n'):format(BuildLuaExport()))
    TriggerEvent('chat:addMessage', {
        args = { 'LS Freight', 'Route config printed to the F8 console.' }
    })
    Notify('Route config printed to the F8 console.', 'success')
end

function Editor.Hide()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'hideRouteEditor' })
end

function Editor.Discard(skipFocus)
    ClearPreviewBlips()
    draft = nil
    SendNUIMessage({ action = 'hideRouteEditor' })
    if not skipFocus then SetNuiFocus(false, false) end
end

function Editor.Open(routeType, pool, sourceIndex)
    local hasArguments = routeType ~= nil or pool ~= nil or sourceIndex ~= nil
    if not draft or hasArguments then
        draft = NewDraft(routeType, pool)
        if sourceIndex then LoadExisting(sourceIndex) end
    end

    local trailerEditor = LS_Trucking.TrailerCargoEditor or {}
    if trailerEditor.Close then trailerEditor.Close(true) end

    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'showRouteEditor', state = BuildState() })
    EnsurePreviewThread()
    return true
end

local function HandleAction(data)
    data = type(data) == 'table' and data or {}
    local action = tostring(data.action or '')

    if action == 'minimize' then
        Editor.Hide()
        Notify('Draft minimized. Use /lsrouteeditor to reopen it.', 'inform')
        return
    elseif action == 'discard' then
        Editor.Discard()
        Notify('Route editor draft discarded.', 'success')
        return
    end
    if not draft then return end

    if action == 'setContext' then
        local nextType = NormalizeRouteType(data.routeType or draft.routeType)
        local nextPool = NormalizePool(nextType, data.pool or draft.pool)
        ClearPreviewBlips()
        draft = NewDraft(nextType, nextPool)
    elseif action == 'new' then
        ClearPreviewBlips()
        draft = NewDraft(draft.routeType, draft.pool)
    elseif action == 'loadExisting' then
        ClearPreviewBlips()
        LoadExisting(data.index)
    elseif action == 'duplicate' then
        draft.sourceIndex = nil
        draft.mode = 'duplicate'
        draft.route.label = ('%s Copy'):format(draft.route.label or 'Route')
    elseif action == 'setField' then
        UpdateRouteField(data)
    elseif action == 'captureStop' then
        CaptureStop()
    elseif action == 'captureSelectedStop' then
        CaptureSelectedStop()
    elseif action == 'selectStop' then
        draft.selectedIndex = math.max(1, math.floor(tonumber(data.index) or 1))
    elseif action == 'updateStop' then
        UpdateStop(data)
    elseif action == 'moveStop' then
        MoveStop(data.index, data.direction)
    elseif action == 'deleteStop' then
        DeleteStop(data.index)
    elseif action == 'captureTrailerPoint' then
        CaptureTrailerPoint(data.target)
    elseif action == 'selectTrailerPoint' then
        draft.selectedIndex = data.target == 'receiver' and 2 or 1
    elseif action == 'updateTrailerPoint' then
        UpdateTrailerPoint(data)
    elseif action == 'estimateDistance' then
        EstimateDistance()
    elseif action == 'togglePreview' then
        draft.preview = not draft.preview
    elseif action == 'setGps' then
        local coords = SelectedPoint()
        if HasCoordinates(coords) then
            SetNewWaypoint(coords.x, coords.y)
            Notify('GPS set to the selected route point.', 'success')
        else
            Notify('Select a positioned route point first.', 'error')
        end
    elseif action == 'print' then
        PrintExport()
    elseif action == 'validate' then
        local errors = 0
        local warnings = 0
        for _, issue in ipairs(ValidateDraft()) do
            if issue.level == 'error' then errors = errors + 1 else warnings = warnings + 1 end
        end
        Notify(('Validation complete: %s error(s), %s warning(s).'):format(errors, warnings), errors > 0 and 'error' or warnings > 0 and 'warning' or 'success')
    end

    if draft then SendState() end
end

RegisterNUICallback('routeEditorAction', function(data, cb)
    HandleAction(data)
    cb({ success = true })
end)

RegisterNUICallback('routeEditorClose', function(_, cb)
    Editor.Hide()
    cb({ success = true })
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    Editor.Discard(true)
end)

LS_Trucking.RouteEditor = Editor
