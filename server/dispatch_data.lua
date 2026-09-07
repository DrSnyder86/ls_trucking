LS_Trucking = LS_Trucking or {}

local DispatchData = {}
local serverRegistered = false

local GarageVehicleTypeOrder = { 'van', 'boxtruck', 'trailer' }
local GarageVehicleTypeSort = { van = 1, boxtruck = 2, trailer = 3 }

local function BuildCurrentJob(active)
    if not active then return nil end

    return {
        id = active.id,
        type = active.type,
        label = active.label,
        routeLabel = active.routeLabel,
        priorityLabel = active.priorityLabel,
        stage = active.stage or 'Active',
        notice = active.notice,
        payout = active.payout,
        loadedCargo = active.loadedCargo or 0,
        requiredCargo = active.requiredCargo or 0,
        currentStop = active.currentStop or 0,
        totalStops = active.totalStops or 0,
        cargo = active.cargo,
        destination = active.destination,
        destinationAddress = active.destinationAddress,
        pickup = active.pickup and active.pickup.label or nil,
        routeLength = active.routeLength,
        estimatedTime = active.estimatedTime,
        expectedCompletion = active.expectedCompletion,
        vehicleLabel = active.vehicleLabel,
        plate = active.plate,
        contractor = active.contractor == true,
        contractorDailyRouteKey = active.contractorDailyRouteKey
    }
end

local function IsContractorCheckout(checkout)
    return checkout and tostring(checkout.source or ''):find('contractor', 1, true) ~= nil
end

local function ResolveCheckoutGarageId(ctx, checkout)
    if not checkout or IsContractorCheckout(checkout) then return nil end
    if checkout.garageId then return checkout.garageId end

    local vehicleData = (Config.JobVehicles or {})[checkout.type]
        and Config.JobVehicles[checkout.type][tonumber(checkout.index) or 1]
        or nil
    if not vehicleData or not ctx.ResolveGarageVehicleId then return nil end
    return ctx.ResolveGarageVehicleId(checkout.type, vehicleData, checkout.index)
end

function DispatchData.BuildGarageList(ctx, citizenid, checkout)
    ctx = ctx or {}
    local list = {}
    local assignments = ctx.GetGarageFleetAssignments and ctx.GetGarageFleetAssignments(citizenid) or {}
    local checkedOutGarageId = ResolveCheckoutGarageId(ctx, checkout)

    -- Keep company garage ordering stable across restarts and config edits.
    for _, vehicleType in ipairs(GarageVehicleTypeOrder) do
        local vehicles = Config.JobVehicles[vehicleType] or {}
        for index, vehicleData in ipairs(vehicles) do
            local garageId = ctx.ResolveGarageVehicleId
                and ctx.ResolveGarageVehicleId(vehicleType, vehicleData, index)
                or ('%s:%s'):format(vehicleType, index)
            local row = assignments[garageId]
            if not ctx.GetGarageFleetAssignments and ctx.EnsureGarageVehicle then
                row = ctx.EnsureGarageVehicle(citizenid, vehicleType, index)
            end

            list[#list + 1] = {
                garageId = garageId,
                type = vehicleType,
                index = index,
                sortType = GarageVehicleTypeSort[vehicleType] or 99,
                sortOrder = index,
                label = vehicleData.label,
                model = ctx.GetGarageVehicleModel and ctx.GetGarageVehicleModel(vehicleType, vehicleData) or vehicleData.model or vehicleData.truck,
                plate = row and row.plate or '',
                assigned = row ~= nil,
                stored = garageId ~= checkedOutGarageId,
                photo = vehicleData.photo,
                trailerPhoto = nil,
                minRank = vehicleData.minRank or 1
            }
        end
    end

    table.sort(list, function(a, b)
        if a.sortType ~= b.sortType then
            return a.sortType < b.sortType
        end

        if (a.minRank or 1) ~= (b.minRank or 1) then
            return (a.minRank or 1) < (b.minRank or 1)
        end

        if (a.sortOrder or 0) ~= (b.sortOrder or 0) then
            return (a.sortOrder or 0) < (b.sortOrder or 0)
        end

        return tostring(a.label or a.model or '') < tostring(b.label or b.model or '')
    end)

    return list
end

function DispatchData.BuildPayload(ctx, src)
    ctx = ctx or {}

    if not ctx.CheckRateLimit(src, 'dispatch', ctx.GetSecurityCooldown('Dispatch', 500)) then
        return { allowed = false, message = T('dispatch.wait_reopen') }
    end

    local access = ctx.GetUIAccess and ctx.GetUIAccess(src) or nil
    if access then
        if not access.allowed then return access end
    elseif not ctx.HasRequiredJob(src) then
        return { allowed = false, message = T('error.not_trucker', { job = Config.JobName or 'the required job' }) }
    end

    local citizenid = ctx.GetCitizenId(src)
    local playerInfo = access and access.player or ctx.BuildPlayerPayload(src)
    local checkout = ctx.GetCheckedOutVehicle and ctx.GetCheckedOutVehicle(src) or nil
    local contractorCheckout = IsContractorCheckout(checkout)
    local checkoutGarageId = ResolveCheckoutGarageId(ctx, checkout)

    return {
        allowed = true,
        player = playerInfo,
        ranks = Config.Ranks,
        contracts = Config.Contracts,
        payouts = Config.Payouts,
        mileagePayout = Config.MileagePayout or { Enabled = true, RatePerMile = 100 },
        vehicles = Config.JobVehicles,
        priorityLoads = Config.PriorityLoads or {},
        routeTrailers = Config.RouteTrailers or {},
        garage = DispatchData.BuildGarageList(ctx, citizenid, checkout),
        garageState = {
            blocked = checkout ~= nil,
            companyVehicleOut = checkout ~= nil and not contractorCheckout,
            contractorVehicleOut = contractorCheckout == true,
            garageId = checkoutGarageId,
            type = checkout and checkout.type or nil,
            index = checkout and checkout.index or nil,
            plate = checkout and checkout.plate or nil
        },
        contractor = ctx.BuildContractorPayload(src, citizenid, playerInfo),
        companyStats = ctx.BuildCompanyStatsPayload and ctx.BuildCompanyStatsPayload(citizenid) or {},
        currentJob = BuildCurrentJob(ctx.ActiveContracts and ctx.ActiveContracts[src]),
        radioFrequency = Config.RadioFrequency
    }
end

function DispatchData.RegisterServer(ctx)
    if serverRegistered then return end
    serverRegistered = true
    ctx = ctx or {}

    lib.callback.register('ls_trucking:server:getDispatchData', function(src)
        return DispatchData.BuildPayload(ctx, src)
    end)
end

LS_Trucking.DispatchData = DispatchData
