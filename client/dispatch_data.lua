LS_Trucking = LS_Trucking or {}

local DispatchData = {}
local clientContext = {}
local contractorBoardRefreshToken = 0

local function Ctx()
    return clientContext or {}
end

local function IsDispatchVisible()
    local ctx = Ctx()
    return ctx.IsDispatchVisible and ctx.IsDispatchVisible() == true
end

local function Notify(message, notifyType)
    local ctx = Ctx()
    if ctx.Notify then ctx.Notify(message, notifyType) end
end

local function DispatchMapCoords(coords)
    if not coords then return nil end

    return {
        x = coords.x + 0.0,
        y = coords.y + 0.0,
        z = coords.z + 0.0
    }
end

local function DispatchMapZone(coords)
    if not coords then return 'San Andreas' end

    local x = tonumber(coords.x) or 0.0
    local y = tonumber(coords.y) or 0.0

    if y > 5600 then return 'Paleto Bay / North County' end
    if y > 2200 then return 'Blaine County' end
    if y < -2400 then return 'Port of Los Santos' end
    if x < -1500 then return 'West Coast' end
    if x > 1200 then return 'East County' end
    return 'Los Santos'
end

local function DispatchMapStreetAddress(coords)
    if not coords then return 'Address unavailable' end

    local streetHash, crossingHash = GetStreetNameAtCoord(coords.x + 0.0, coords.y + 0.0, coords.z + 0.0)
    local street = streetHash and streetHash ~= 0 and GetStreetNameFromHashKey(streetHash) or nil
    local crossing = crossingHash and crossingHash ~= 0 and GetStreetNameFromHashKey(crossingHash) or nil

    if street and street ~= '' and crossing and crossing ~= '' and crossing ~= street then
        return ('%s / %s'):format(street, crossing)
    end

    if street and street ~= '' then return street end

    return DispatchMapZone(coords)
end

local function GetDispatchHomeConfig()
    return Config.DispatchHome or {}
end

local function DispatchHomePhoto(key)
    local photos = GetDispatchHomeConfig().Photos or {}
    local photo = photos[key]
    if photo and photo ~= '' then return photo end

    return nil
end

local function DispatchTrailerDepotPhoto(depotKey)
    local photos = GetDispatchHomeConfig().Photos or {}
    local depotPhotos = photos.trailerDepots or {}
    local photo = depotPhotos[depotKey] or photos.trailerDepot
    if photo and photo ~= '' then return photo end

    return nil
end

local function AddDispatchMapPoint(points, point)
    if not point or not point.coords then return end

    point.zone = point.zone or DispatchMapZone(point.coords)
    point.address = point.address or DispatchMapStreetAddress(point.coords)
    point.details = point.details or {
        { icon = 'fa-road', label = 'Street Address', value = point.address },
        { icon = 'fa-clipboard-check', label = 'Use', value = point.description or 'LSFC operating point.' }
    }

    points[#points + 1] = point
end

function DispatchData.BuildHomeMap()
    local points = {}
    local depot = Config.Depot or {}
    local contracts = Config.Contracts or {}
    local homeConfig = GetDispatchHomeConfig()

    AddDispatchMapPoint(points, {
        id = 'depot-terminal',
        category = 'terminal',
        icon = 'fas fa-tower-broadcast',
        shortLabel = 'LSFC',
        label = 'Los Santos Freight Co. Terminal',
        description = 'Primary dispatch terminal for contracts, route review, vehicle requests, and company paperwork.',
        coords = DispatchMapCoords(depot.terminal or (Config.DispatchBlip and Config.DispatchBlip.coords)),
        photo = DispatchHomePhoto('terminal'),
        details = {
            { icon = 'fa-file-contract', label = 'Functions', value = 'Dispatch board, current jobs, history, contractor desk' },
            { icon = 'fa-road', label = 'Street Address', value = DispatchMapStreetAddress(depot.terminal or (Config.DispatchBlip and Config.DispatchBlip.coords)) }
        }
    })

    AddDispatchMapPoint(points, {
        id = 'depot-vehicle-spawn',
        category = 'vehicle',
        icon = 'fas fa-truck-fast',
        shortLabel = 'UNIT',
        label = 'Company Vehicle Spawn',
        description = 'Company route vehicles are staged here after contract approval.',
        coords = DispatchMapCoords(depot.vehicleSpawn),
        photo = DispatchHomePhoto('vehicleSpawn'),
        details = {
            { icon = 'fa-truck-fast', label = 'Functions', value = 'Company contract vehicle pickup' },
            { icon = 'fa-circle-info', label = 'Spawn Check', value = 'Area must be clear before vehicle release' },
            { icon = 'fa-road', label = 'Street Address', value = DispatchMapStreetAddress(depot.vehicleSpawn) }
        }
    })

    AddDispatchMapPoint(points, {
        id = 'depot-garage-spawn',
        category = 'garage',
        icon = 'fas fa-warehouse',
        shortLabel = 'GAR',
        label = 'Garage Vehicle Spawn',
        description = 'Stored company and contractor units are released from this garage staging area.',
        coords = DispatchMapCoords(depot.garageSpawn or depot.vehicleSpawn),
        photo = DispatchHomePhoto('garageSpawn'),
        details = {
            { icon = 'fa-warehouse', label = 'Functions', value = 'Company garage and private fleet pickup' },
            { icon = 'fa-key', label = 'Access', value = 'Assigned vehicle owner receives keys' },
            { icon = 'fa-road', label = 'Street Address', value = DispatchMapStreetAddress(depot.garageSpawn or depot.vehicleSpawn) }
        }
    })

    local pickupTypes = {
        { type = 'van', category = 'van', label = 'Van Package Pickup', photo = DispatchHomePhoto('vanPickup'), icon = 'fas fa-box', shortLabel = 'VAN' },
        { type = 'boxtruck', category = 'boxtruck', label = 'Box Truck Freight Pickup', photo = DispatchHomePhoto('boxTruckPickup'), icon = 'fas fa-truck-moving', shortLabel = 'BOX' }
    }

    for _, pickupType in ipairs(pickupTypes) do
        local contract = contracts[pickupType.type]
        local pickup = contract and contract.pickup

        AddDispatchMapPoint(points, {
            id = ('pickup-%s'):format(pickupType.type),
            category = pickupType.category,
            icon = pickupType.icon,
            shortLabel = pickupType.shortLabel,
            label = (pickup and pickup.label) or pickupType.label,
            description = contract and contract.description or 'Freight pickup location.',
            coords = DispatchMapCoords(pickup and pickup.coords),
            photo = pickupType.photo,
            details = {
                { icon = 'fa-boxes-stacked', label = 'Cargo', value = contract and contract.cargo or 'Cargo' },
                { icon = 'fa-route', label = 'Route Type', value = contract and contract.label or pickupType.label },
                { icon = 'fa-road', label = 'Street Address', value = DispatchMapStreetAddress(pickup and pickup.coords) }
            }
        })
    end

    local trailerDepotKeys = {}
    for key in pairs(Config.TrailerDepots or {}) do trailerDepotKeys[#trailerDepotKeys + 1] = key end
    table.sort(trailerDepotKeys)

    for _, key in ipairs(trailerDepotKeys) do
        local trailerDepot = Config.TrailerDepots[key]
        AddDispatchMapPoint(points, {
            id = ('trailer-%s'):format(key),
            category = 'trailer',
            icon = 'fas fa-trailer',
            shortLabel = 'TRL',
            label = trailerDepot.label or 'Trailer Depot',
            description = 'Trailer hookup yard for assigned trailer haul contracts.',
            coords = DispatchMapCoords(trailerDepot.pickup),
            photo = DispatchTrailerDepotPhoto(key),
            details = {
                { icon = 'fa-trailer', label = 'Functions', value = 'Trailer pickup, hookup, and yard release' },
                { icon = 'fa-square-parking', label = 'Spawn Spots', value = tostring(#(trailerDepot.spawns or {})) },
                { icon = 'fa-road', label = 'Street Address', value = DispatchMapStreetAddress(trailerDepot.pickup) }
            }
        })
    end

    return {
        points = points,
        mapImage = homeConfig.MapImage,
        mapBounds = homeConfig.MapBounds,
        mapZoom = homeConfig.MapZoom,
        mapZoomMin = homeConfig.MapZoomMin,
        mapZoomMax = homeConfig.MapZoomMax,
        mapZoomStep = homeConfig.MapZoomStep
    }
end

function DispatchData.Build()
    local ctx = Ctx()
    local data = lib.callback.await('ls_trucking:server:getDispatchData', false)
    if not data or not data.allowed then
        return nil, data and data.message or 'Unable to open trucking dispatch.'
    end

    local currentDriverInfo = data.player or (ctx.GetCurrentDriverInfo and ctx.GetCurrentDriverInfo())
    if ctx.SetCurrentDriverInfo then ctx.SetCurrentDriverInfo(currentDriverInfo) end

    local routeHistory = LS_Trucking.RouteHistory or {}
    if currentDriverInfo and currentDriverInfo.citizenid and routeHistory.SetCharacter then
        routeHistory.SetCharacter(currentDriverInfo.citizenid)
    end

    data.reuse = ctx.GetReuseData and ctx.GetReuseData() or nil
    data.config = {
        allowVehicleReuseAfterRoute = Config.AllowVehicleReuseAfterRoute,
        requireSameTypeForVehicleReuse = Config.RequireSameTypeForVehicleReuse,
        radioFrequency = Config.RadioFrequency,
        locale = Config.Locale or 'en',
        uiSounds = Config.UI or {}
    }
    data.dispatchHome = DispatchData.BuildHomeMap()
    data.lastRouteSummary = routeHistory.GetLast and routeHistory.GetLast() or nil
    data.routeHistory = routeHistory.GetHistory and routeHistory.GetHistory() or {}

    local routeState = LS_Trucking.RouteState or {}
    local activeContract = ctx.GetActiveContract and ctx.GetActiveContract() or nil
    data.currentJob = routeState.BuildCurrentJob and routeState.BuildCurrentJob(activeContract) or nil
    return data
end

function DispatchData.Refresh(delayMs, attempts)
    if not IsDispatchVisible() then return end

    delayMs = tonumber(delayMs) or 0
    attempts = math.max(1, tonumber(attempts) or 1)

    CreateThread(function()
        if delayMs > 0 then Wait(delayMs) end

        for attempt = 1, attempts do
            if not IsDispatchVisible() then return end

            local data, message = DispatchData.Build()
            if data then
                SendNUIMessage({ action = 'refreshDispatch', data = data })
                return
            end

            if attempt < attempts then
                Wait(550)
            else
                Notify(message or 'Unable to refresh trucking dispatch.', 'error')
            end
        end
    end)
end

function DispatchData.StartContractorRefresh()
    contractorBoardRefreshToken = contractorBoardRefreshToken + 1
    local token = contractorBoardRefreshToken

    CreateThread(function()
        local minutes = tonumber(Config.PrivateContractor and Config.PrivateContractor.ContractBoardRefreshMinutes) or 60
        local refreshMs = math.max(60000, math.floor(minutes * 60000))

        while IsDispatchVisible() and token == contractorBoardRefreshToken do
            Wait(refreshMs)

            local ctx = Ctx()
            local activeTab = ctx.GetDispatchActiveTab and ctx.GetDispatchActiveTab() or 'home'
            if IsDispatchVisible() and token == contractorBoardRefreshToken and activeTab == 'contractor' then
                DispatchData.Refresh(0, 1)
            end
        end
    end)
end

function DispatchData.ConfigureClient(context)
    clientContext = context or {}
end

LS_Trucking.DispatchData = DispatchData
