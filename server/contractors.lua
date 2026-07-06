LS_Trucking = LS_Trucking or {}

local Contractors = {}
local serverContext = {}
local serverRegistered = false
local startupStarted = false

local function Ctx()
    return serverContext or {}
end

local function RequireWorkAccess(ctx, src)
    if ctx.RequireWorkAccess then
        return ctx.RequireWorkAccess(src)
    end

    if ctx.HasRequiredJob and not ctx.HasRequiredJob(src) then
        return false, T('error.not_trucker', { job = Config.JobName or 'the required job' })
    end

    return true
end

function Contractors.GetConfig()
    return Config.PrivateContractor or {}
end

function Contractors.IsEnabled()
    return Contractors.GetConfig().Enabled == true
end

function Contractors.IsDatabaseTrue(value)
    if value == true or value == 1 then return true end
    if type(value) == 'string' then
        local normalized = value:lower()
        return normalized == '1' or normalized == 'true' or normalized == 'yes'
    end
    return false
end

local function EnsureTables()
    local ctx = Ctx()
    if ctx.EnsureDatabaseMigrations then ctx.EnsureDatabaseMigrations() end
end

local function GetDateKey()
    local resetHour = tonumber(Contractors.GetConfig().DailyResetHour) or 6
    return os.date('%Y-%m-%d', os.time() - (resetHour * 3600))
end

local function ParseDatabaseTimestamp(value)
    if type(value) == 'number' then return value end
    if type(value) ~= 'string' or value == '' then return nil end

    local year, month, day, hour, min, sec = value:match('^(%d+)%-(%d+)%-(%d+)%s+(%d+):(%d+):(%d+)')
    if not year then
        year, month, day = value:match('^(%d+)%-(%d+)%-(%d+)')
        hour, min, sec = 0, 0, 0
    end
    if not year then return nil end

    return os.time({
        year = tonumber(year),
        month = tonumber(month),
        day = tonumber(day),
        hour = tonumber(hour) or 0,
        min = tonumber(min) or 0,
        sec = tonumber(sec) or 0
    })
end

local function GetDailyRouteChangeStatus(profile)
    if not profile or not profile.daily_route_key or profile.daily_route_key == '' then
        return true, nil, 0
    end

    local days = tonumber(Contractors.GetConfig().DailyRouteChangeCooldownDays) or 7
    local cooldown = math.max(0, days * 86400)
    if cooldown <= 0 then return true, nil, 0 end

    local selectedAt = ParseDatabaseTimestamp(profile.daily_route_selected_at)
    if not selectedAt then return true, nil, 0 end

    local availableAt = selectedAt + cooldown
    local remaining = availableAt - os.time()
    if remaining <= 0 then return true, availableAt, 0 end
    return false, availableAt, remaining
end

local function EnsureProfile(citizenid)
    EnsureTables()
    MySQL.insert.await('INSERT IGNORE INTO trucking_contractor_profiles (citizenid) VALUES (?)', { citizenid })
end

function Contractors.GetProfile(citizenid)
    EnsureProfile(citizenid)
    local row = MySQL.single.await('SELECT * FROM trucking_contractor_profiles WHERE citizenid = ?', { citizenid }) or {}
    local dateKey = GetDateKey()

    if row.daily_route_date ~= dateKey then
        row.daily_route_completed = 0
        row.daily_route_date = dateKey
        MySQL.update.await('UPDATE trucking_contractor_profiles SET daily_route_date = ?, daily_route_completed = 0 WHERE citizenid = ?', { dateKey, citizenid })
    end

    return row
end

local function TypeLabel(vehicleType)
    if vehicleType == 'boxtruck' then return 'Box Truck' end
    if vehicleType == 'trailer' then return 'Tractor' end
    return 'Van'
end

local function TableHasValue(values, target)
    if not values then return false end
    for _, value in ipairs(values) do
        if value == target then return true end
    end
    return false
end

local function GetVehicleOptions(vehicleData)
    vehicleData = vehicleData or {}
    local options = vehicleData.contractor
    if options == false then return { enabled = false } end
    if type(options) ~= 'table' then options = {} end

    local enabled = options.enabled
    if enabled == nil then enabled = vehicleData.contractorEnabled end
    if enabled == nil then enabled = true end

    return {
        enabled = enabled ~= false,
        price = tonumber(options.price) or tonumber(vehicleData.contractorPrice),
        minRank = tonumber(options.minRank)
    }
end

local function GetVehiclePrice(vehicleType, vehicleIndex, vehicleData)
    local options = GetVehicleOptions(vehicleData)
    if options.price then return math.floor(options.price) end

    local pricing = Contractors.GetConfig().VehiclePricing or {}
    local priceData = pricing[vehicleType] or {}
    local base = tonumber(priceData.base) or 100000
    local step = tonumber(priceData.step) or 25000
    return math.floor(base + ((tonumber(vehicleIndex) or 1) - 1) * step)
end

local function GetVehicleResale(row, vehicleData)
    row = row or {}
    vehicleData = vehicleData or (Config.JobVehicles[row.vehicle_type] and Config.JobVehicles[row.vehicle_type][tonumber(row.vehicle_index) or 1]) or {}

    local originalPrice = tonumber(row.original_price) or 0
    if originalPrice <= 0 then
        originalPrice = GetVehiclePrice(row.vehicle_type, tonumber(row.vehicle_index) or 1, vehicleData)
    end

    local mileage = math.max(0.0, tonumber(row.mileage) or 0.0)
    local resalePercent = math.max(0.0, math.min(1.0, tonumber(Contractors.GetConfig().ResaleBasePercent) or 0.80))
    local depreciationPerMile = math.max(0.0, tonumber(Contractors.GetConfig().DepreciationPerMile) or 10.0)
    local resalePrice = math.max(0, math.floor((originalPrice * resalePercent) - (mileage * depreciationPerMile)))
    return resalePrice, originalPrice, mileage, depreciationPerMile
end

local function GetRouteStopCount(contractType, route)
    if route and route.dropoffs then return #route.dropoffs end
    if contractType == 'trailer' then return 1 end
    return 0
end

local function GetRouteDestination(contractType, route)
    if not route then return nil end
    if contractType == 'trailer' and route.trailerDrop then return route.trailerDrop.label end
    if route.dropoffs and route.dropoffs[1] then return route.dropoffs[1].label end
    return nil
end

local function GetDailyRouteIndex(contractType, routeCount)
    routeCount = tonumber(routeCount) or 0
    if routeCount <= 0 then return nil end

    local seed = ('%s:%s'):format(GetDateKey(), contractType or 'route')
    local hash = 0
    for i = 1, #seed do
        hash = ((hash * 33) + seed:byte(i)) % 2147483647
    end
    return (hash % routeCount) + 1
end

local function BuildDailyRouteOption(routeConfig, playerRank, explicitRouteIndex)
    local ctx = Ctx()
    routeConfig = routeConfig or {}
    local contractType = routeConfig.type or routeConfig.contractType or (routeConfig.types and routeConfig.types[1])
    local routePool, priority, priorityKey, contract = ctx.GetRoutePool(contractType, routeConfig.priorityKey or 'standard')
    if not contractType or not contract or not routePool or #routePool == 0 then return nil end

    local routeIndex = tonumber(explicitRouteIndex) or tonumber(routeConfig.routeIndex) or GetDailyRouteIndex(contractType, #routePool)
    if not routeIndex or routeIndex < 1 or routeIndex > #routePool then return nil end

    routeIndex = math.floor(routeIndex)
    local route = routePool[routeIndex]
    if not route then return nil end
    priorityKey = priorityKey or 'standard'

    local stopCount = GetRouteStopCount(contractType, route)
    local destination = GetRouteDestination(contractType, route)
    local routeLength = route.routeLength or 'Route length pending'
    local minRank = tonumber(routeConfig.minRank) or tonumber(Contractors.GetConfig().UnlockRank) or 1
    local stopLabel = ('%s stop%s'):format(stopCount, stopCount == 1 and '' or 's')
    local description = ('%s - %s - %s'):format(TypeLabel(contractType), routeLength, stopLabel)
    local routeTrailer = contractType == 'trailer' and ctx.ResolveRouteTrailer(route, priority) or nil

    if destination then description = ('%s - %s'):format(description, destination) end

    local defaultKey = priorityKey == 'standard'
        and ('%s:%s'):format(contractType, routeIndex)
        or ('%s:%s:%s'):format(contractType, priorityKey, routeIndex)
    local configuredKey = routeConfig.key
    if configuredKey and explicitRouteIndex and not routeConfig.routeIndex then
        configuredKey = ('%s:%s'):format(configuredKey, routeIndex)
    end

    return {
        key = configuredKey or defaultKey,
        type = contractType,
        types = { contractType },
        label = route.label or routeConfig.label or contract.label,
        description = routeConfig.description or description,
        destination = destination,
        routeIndex = routeIndex,
        routeLabel = route.label or contract.label,
        routeLength = routeLength,
        stopCount = stopCount,
        priorityKey = priorityKey,
        priorityLabel = priority and priority.label or 'Standard Commercial Route',
        priorityShortLabel = priority and (priority.shortLabel or priority.label) or 'Standard',
        trailerKey = routeTrailer and routeTrailer.key or nil,
        trailerLabel = routeTrailer and routeTrailer.label or nil,
        trailerPhoto = routeTrailer and routeTrailer.photo or nil,
        trailerContents = routeTrailer and routeTrailer.contents or nil,
        minRank = minRank,
        unlocked = playerRank == nil or ctx.CheckRankRequirement(playerRank, minRank)
    }
end

local function BuildDailyRouteOptions(playerRank)
    local ctx = Ctx()
    local routes = {}
    local seen = {}
    local configuredRoutes = Contractors.GetConfig().DailyRoutes

    local function addOption(option)
        if not option or seen[option.key] then return end
        seen[option.key] = true
        routes[#routes + 1] = option
    end

    local function addConfiguredRoute(routeConfig)
        routeConfig = routeConfig or {}
        local contractType = routeConfig.type or routeConfig.contractType or (routeConfig.types and routeConfig.types[1])
        local routePool = ctx.GetRoutePool(contractType, routeConfig.priorityKey or 'standard')
        if not contractType or not routePool or #routePool == 0 then return end

        if routeConfig.routeIndex then
            addOption(BuildDailyRouteOption(routeConfig, playerRank))
            return
        end

        local limit = tonumber(Contractors.GetConfig().DailyRouteOptionsPerType)
        limit = limit and limit >= 1 and math.floor(limit) or nil
        local count = limit and math.min(#routePool, limit) or #routePool
        for routeIndex = 1, count do
            addOption(BuildDailyRouteOption(routeConfig, playerRank, routeIndex))
        end
    end

    if configuredRoutes and #configuredRoutes > 0 then
        for _, routeConfig in ipairs(configuredRoutes) do addConfiguredRoute(routeConfig) end
    else
        for _, contractType in ipairs(Contractors.GetConfig().VehicleTypes or { 'van', 'boxtruck', 'trailer' }) do
            addConfiguredRoute({ type = contractType })
        end
    end

    return routes
end

local function GetDailyRouteOption(routeKey)
    for _, route in ipairs(BuildDailyRouteOptions(nil)) do
        if route.key == routeKey then return route end
    end
    return nil
end

local function GetVehicleRows(citizenid)
    EnsureTables()
    return MySQL.query.await('SELECT * FROM trucking_contractor_vehicles WHERE citizenid = ? ORDER BY vehicle_type, vehicle_index, id', { citizenid }) or {}
end

local function NormalizeVehicle(row)
    if not row then return nil end

    local vehicleData = Config.JobVehicles[row.vehicle_type] and Config.JobVehicles[row.vehicle_type][tonumber(row.vehicle_index) or 1] or {}
    local hasSavedProps = row.props ~= nil and tostring(row.props) ~= '' and tostring(row.props) ~= 'null'
    local engineHealth = tonumber(row.engine_health) or 1000.0
    local bodyHealth = tonumber(row.body_health) or 1000.0
    if not hasSavedProps and engineHealth < 100.0 then engineHealth = 1000.0 end
    if not hasSavedProps and bodyHealth < 100.0 then bodyHealth = 1000.0 end
    engineHealth = math.max(0.0, math.min(1000.0, engineHealth))
    bodyHealth = math.max(0.0, math.min(1000.0, bodyHealth))
    local condition = math.max(0, math.min(100, math.floor((math.min(engineHealth, bodyHealth) / 10.0) + 0.5)))
    local resalePrice, originalPrice, mileage, depreciationPerMile = GetVehicleResale(row, vehicleData)

    return {
        id = row.id,
        type = row.vehicle_type,
        index = tonumber(row.vehicle_index) or 1,
        typeLabel = TypeLabel(row.vehicle_type),
        label = row.vehicle_label,
        model = row.vehicle_model,
        photo = vehicleData.photo,
        plate = row.plate,
        stored = Contractors.IsDatabaseTrue(row.stored),
        out = Contractors.IsDatabaseTrue(row.out_state) or not Contractors.IsDatabaseTrue(row.stored),
        fuel = math.max(0, math.min(100, math.floor((tonumber(row.fuel) or 0) + 0.5))),
        condition = condition,
        engineHealth = engineHealth,
        bodyHealth = bodyHealth,
        originalPrice = originalPrice,
        mileage = mileage,
        depreciationPerMile = depreciationPerMile,
        resalePrice = resalePrice
    }
end

local function NormalizeVehicles(rows)
    local vehicles = {}
    for _, row in ipairs(rows or {}) do
        local vehicle = NormalizeVehicle(row)
        if vehicle then vehicles[#vehicles + 1] = vehicle end
    end
    return vehicles
end

function Contractors.GetVehicleById(citizenid, vehicleId)
    EnsureTables()
    vehicleId = tonumber(vehicleId) or 0
    if vehicleId <= 0 then return nil end
    return MySQL.single.await('SELECT * FROM trucking_contractor_vehicles WHERE citizenid = ? AND id = ?', { citizenid, vehicleId })
end

function Contractors.GetOutVehicle(citizenid)
    EnsureTables()
    return MySQL.single.await('SELECT * FROM trucking_contractor_vehicles WHERE citizenid = ? AND (stored = 0 OR out_state = 1) LIMIT 1', { citizenid })
end

local function BuildVehicleMarket(citizenid, playerRank, vehicleRows)
    local ctx = Ctx()
    local owned = {}
    for _, row in ipairs(vehicleRows or GetVehicleRows(citizenid)) do
        owned[('%s:%s'):format(row.vehicle_type, row.vehicle_index)] = true
    end

    local market = {}
    for _, vehicleType in ipairs(Contractors.GetConfig().VehicleTypes or { 'van', 'boxtruck', 'trailer' }) do
        for index, vehicleData in ipairs(Config.JobVehicles[vehicleType] or {}) do
            local options = GetVehicleOptions(vehicleData)
            if options.enabled then
                local minRank = tonumber(options.minRank) or tonumber(vehicleData.minRank) or 1
                market[#market + 1] = {
                    type = vehicleType,
                    index = index,
                    typeLabel = TypeLabel(vehicleType),
                    label = vehicleData.label,
                    model = ctx.GetGarageVehicleModel(vehicleType, vehicleData),
                    photo = vehicleData.photo,
                    platePrefix = vehicleData.platePrefix,
                    minRank = minRank,
                    unlocked = ctx.CheckRankRequirement(playerRank, minRank),
                    owned = owned[('%s:%s'):format(vehicleType, index)] == true,
                    price = GetVehiclePrice(vehicleType, index, vehicleData)
                }
            end
        end
    end
    return market
end

local function GetSelectedDailyRoute(profile)
    if not profile or not profile.daily_route_key or profile.daily_route_key == '' then return nil end
    return GetDailyRouteOption(profile.daily_route_key)
end

local function GetBoardRefreshSeconds()
    local minutes = tonumber(Contractors.GetConfig().ContractBoardRefreshMinutes) or 60
    return math.max(60, math.floor(minutes * 60))
end

local function GetStableHash(value)
    value = tostring(value or '')
    local hash = 0
    for i = 1, #value do
        hash = ((hash * 33) + value:byte(i)) % 2147483647
    end
    return hash
end

local function NextBoardRandom(state, maxValue)
    maxValue = math.max(1, math.floor(tonumber(maxValue) or 1))
    state = ((tonumber(state) or 1) * 1103515245 + 12345) % 2147483647
    return state, (state % maxValue) + 1
end

local function GetBoardRouteIndexes(citizenid, contractType, priorityKey, routeCount, limit, excludedIndex)
    routeCount = tonumber(routeCount) or 0
    if routeCount <= 0 then return {} end

    excludedIndex = tonumber(excludedIndex)

    local candidates = {}
    for index = 1, routeCount do
        if not excludedIndex or routeCount == 1 or index ~= excludedIndex then
            candidates[#candidates + 1] = index
        end
    end

    limit = math.min(#candidates, math.floor(tonumber(limit) or 5))
    if limit <= 0 then return {} end

    local refreshBucket = math.floor(os.time() / GetBoardRefreshSeconds())
    local seed = GetStableHash(('%s:%s:%s:%s:%s:board'):format(
        citizenid or 'driver',
        contractType or 'route',
        priorityKey or 'standard',
        routeCount,
        refreshBucket
    ))

    for i = #candidates, 2, -1 do
        local swapIndex
        seed, swapIndex = NextBoardRandom(seed, i)
        candidates[i], candidates[swapIndex] = candidates[swapIndex], candidates[i]
    end

    local indexes = {}
    for i = 1, limit do indexes[#indexes + 1] = candidates[i] end
    return indexes
end

local function BuildBoardEntry(contractType, priorityKey, routeIndex, route, contract, priority, payoutData, outVehicle, isDaily)
    local ctx = Ctx()
    priority = priority or { label = 'Standard Commercial Route', shortLabel = 'Standard', minRank = 1, payoutMultiplier = 1.0, xpMultiplier = 1.0, repBonus = 0 }

    local payoutMultiplier = (priority.payoutMultiplier or 1.0) * (Contractors.GetConfig().PayoutMultiplier or 1.0)
    local xpMultiplier = (priority.xpMultiplier or 1.0) * (Contractors.GetConfig().XpMultiplier or 1.0)
    local destination = GetRouteDestination(contractType, route)
    local stopCount = GetRouteStopCount(contractType, route)
    local routeTrailer = contractType == 'trailer' and ctx.ResolveRouteTrailer(route, priority) or nil
    local mileageBonus, routeMiles, mileageRate = ctx.GetMileagePayout(route.routeLength)

    return {
        key = ('%s:%s:%s:%s'):format(contractType, priorityKey or 'standard', routeIndex, isDaily and 'daily' or 'contract'),
        type = contractType,
        typeLabel = TypeLabel(contractType),
        priorityKey = priorityKey or 'standard',
        priorityLabel = priority.label or 'Standard Commercial Route',
        priorityShortLabel = priority.shortLabel or priority.label or 'Standard',
        routeIndex = routeIndex,
        routeLabel = route.label or contract.label,
        routeLength = route.routeLength,
        destination = destination,
        stopCount = stopCount,
        trailerKey = routeTrailer and routeTrailer.key or nil,
        trailerLabel = routeTrailer and routeTrailer.label or nil,
        trailerPhoto = routeTrailer and routeTrailer.photo or nil,
        trailerContents = routeTrailer and routeTrailer.contents or nil,
        vehicleId = outVehicle and outVehicle.id or nil,
        vehicleLabel = outVehicle and outVehicle.label or nil,
        canStart = outVehicle ~= nil,
        daily = isDaily == true,
        payoutMin = math.floor((payoutData.min or 0) * payoutMultiplier) + mileageBonus,
        payoutMax = math.floor((payoutData.max or 0) * payoutMultiplier) + mileageBonus,
        mileageBonus = mileageBonus,
        routeMiles = routeMiles,
        mileageRate = mileageRate,
        xp = math.floor((payoutData.xp or 0) * xpMultiplier),
        rep = (payoutData.rep or 0) + (priority.repBonus or 0) + (Contractors.GetConfig().RepBonus or 0)
    }
end

local function BuildBoard(citizenid, playerRank, profile, vehicles)
    local ctx = Ctx()
    local routeOption = GetSelectedDailyRoute(profile)
    local outByType = {}
    local activeOutVehicle = nil
    for _, vehicle in ipairs(vehicles or {}) do
        if vehicle.out then
            outByType[vehicle.type] = vehicle
            activeOutVehicle = activeOutVehicle or vehicle
        end
    end

    local board = {}
    if not activeOutVehicle then return board end

    local boardLimit = tonumber(Contractors.GetConfig().ContractBoardRoutesPerType) or 5
    local dateKey = GetDateKey()
    local dailyCompleted = profile and profile.daily_route_date == dateKey and Contractors.IsDatabaseTrue(profile.daily_route_completed)
    local dailyContractType = routeOption and (routeOption.type or (routeOption.types and routeOption.types[1])) or nil

    if routeOption and not dailyCompleted and activeOutVehicle.type == dailyContractType then
        local routePool, priority, priorityKey, contract = ctx.GetRoutePool(dailyContractType, routeOption.priorityKey or 'standard')
        priority = priority or { label = 'Standard Commercial Route', shortLabel = 'Standard', minRank = 1, payoutMultiplier = 1.0, xpMultiplier = 1.0, repBonus = 0 }
        local routeIndex = tonumber(routeOption.routeIndex)
        local route = routePool and routeIndex and routePool[routeIndex] or nil
        local payoutData = dailyContractType and Config.Payouts[dailyContractType] or nil
        if contract and payoutData and route and ctx.CheckRankRequirement(playerRank, routeOption.minRank) and ctx.CheckRankRequirement(playerRank, priority.minRank) then
            board[#board + 1] = BuildBoardEntry(dailyContractType, priorityKey, routeIndex, route, contract, priority, payoutData, outByType[dailyContractType], true)
            board[#board].dailyRouteKey = routeOption.key
        end
    end

    local contractType = activeOutVehicle.type
    local routePool, priority, priorityKey, contract = ctx.GetRoutePool(contractType, 'standard')
    priority = priority or { label = 'Standard Commercial Route', shortLabel = 'Standard', minRank = 1, payoutMultiplier = 1.0, xpMultiplier = 1.0, repBonus = 0 }
    local payoutData = Config.Payouts[contractType]
    if contract and payoutData and routePool and #routePool > 0 and ctx.CheckRankRequirement(playerRank, priority.minRank) then
        local excludedRouteIndex = routeOption and not dailyCompleted and dailyContractType == contractType and tonumber(routeOption.routeIndex) or nil
        local remainingBoardSlots = math.max(0, boardLimit - #board)
        for _, routeIndex in ipairs(GetBoardRouteIndexes(citizenid, contractType, priorityKey, #routePool, remainingBoardSlots, excludedRouteIndex)) do
            local route = routePool[routeIndex]
            if route then
                board[#board + 1] = BuildBoardEntry(contractType, priorityKey, routeIndex, route, contract, priority, payoutData, outByType[contractType], false)
            end
        end
    end

    return board
end

function Contractors.BuildPayload(src, citizenid, playerInfo)
    local ctx = Ctx()
    local cfg = Contractors.GetConfig()
    if cfg.Enabled ~= true then return { enabled = false } end

    local playerRank = playerInfo and playerInfo.rank or 1
    local unlockRank = tonumber(cfg.UnlockRank) or 1
    local profile = Contractors.GetProfile(citizenid)
    local vehicleRows = GetVehicleRows(citizenid)
    local vehicles = NormalizeVehicles(vehicleRows)
    local dailyOption = GetSelectedDailyRoute(profile)
    local canChange, changeAt, remaining = GetDailyRouteChangeStatus(profile)

    return {
        enabled = true,
        unlocked = ctx.CheckRankRequirement(playerRank, unlockRank),
        unlockRank = unlockRank,
        licensed = Contractors.IsDatabaseTrue(profile.licensed),
        licenseCost = tonumber(cfg.LicenseCost) or 0,
        rep = tonumber(profile.contractor_rep) or 0,
        minFuel = tonumber(cfg.MinFuel) or 0,
        minCondition = tonumber(cfg.MinCondition) or 0,
        cancelFee = tonumber(cfg.CancelFee) or 0,
        dailyBonus = tonumber(cfg.DailyRouteCompletionBonus) or 0,
        dailyRepBonus = tonumber(cfg.DailyRouteRepBonus) or 0,
        dailyDate = GetDateKey(),
        dailyRouteKey = dailyOption and dailyOption.key or nil,
        dailyRouteLabel = dailyOption and dailyOption.label or nil,
        dailyRouteSelectedAt = profile.daily_route_selected_at,
        dailyRouteCanChange = canChange,
        dailyRouteChangeAvailableAt = changeAt and os.date('%Y-%m-%d %H:%M', changeAt) or nil,
        dailyRouteChangeRemaining = remaining or 0,
        dailyRouteCompleted = Contractors.IsDatabaseTrue(profile.daily_route_completed) and dailyOption ~= nil,
        dailyRoutes = BuildDailyRouteOptions(playerRank),
        vehicles = vehicles,
        market = BuildVehicleMarket(citizenid, playerRank, vehicleRows),
        board = BuildBoard(citizenid, playerRank, profile, vehicles),
        maxOwnedVehicles = tonumber(cfg.MaxOwnedVehicles) or 6
    }
end

function Contractors.AddRep(citizenid, amount)
    amount = tonumber(amount) or 0
    if amount == 0 then return end
    EnsureProfile(citizenid)
    MySQL.update.await('UPDATE trucking_contractor_profiles SET contractor_rep = GREATEST(contractor_rep + ?, 0) WHERE citizenid = ?', { amount, citizenid })
end

function Contractors.GetDailyBonus(citizenid, active, markComplete)
    if not active or not active.contractor then return 0, 0 end

    local cfg = Contractors.GetConfig()
    local profile = Contractors.GetProfile(citizenid)
    local dateKey = GetDateKey()
    if profile.daily_route_date ~= dateKey or profile.daily_route_key ~= active.contractorDailyRouteKey or Contractors.IsDatabaseTrue(profile.daily_route_completed) then
        return 0, 0
    end

    local payoutBonus = tonumber(cfg.DailyRouteCompletionBonus) or 0
    local repBonus = tonumber(cfg.DailyRouteRepBonus) or 0
    if markComplete ~= false then
        MySQL.update.await('UPDATE trucking_contractor_profiles SET daily_route_completed = 1, contractor_rep = GREATEST(contractor_rep + ?, 0) WHERE citizenid = ?', { repBonus, citizenid })
    end
    return payoutBonus, repBonus
end

local function VehicleConditionPercent(engineHealth, bodyHealth)
    engineHealth = math.max(0.0, math.min(1000.0, tonumber(engineHealth) or 0.0))
    bodyHealth = math.max(0.0, math.min(1000.0, tonumber(bodyHealth) or 0.0))
    return math.max(0, math.min(100, math.floor((math.min(engineHealth, bodyHealth) / 10.0) + 0.5)))
end

local function StartDatabaseWarmup()
    if startupStarted then return end
    startupStarted = true

    CreateThread(function()
        Wait(1500)
        if not Contractors.IsEnabled() then return end

        for attempt = 1, 6 do
            local ok, err = pcall(EnsureTables)
            if ok then return end
            if Config.Debug then
                print(('[ls_trucking] Contractor startup cleanup attempt %s failed: %s'):format(attempt, err))
            end
            Wait(2500)
        end
    end)
end

function Contractors.ConfigureServer(context)
    serverContext = context or {}
    StartDatabaseWarmup()
end

function Contractors.RegisterServer(context)
    if context then Contractors.ConfigureServer(context) end
    if serverRegistered then return end
    serverRegistered = true

    local ctx = Ctx()

    lib.callback.register('ls_trucking:server:purchaseContractorLicense', function(src)
        if not ctx.CheckRateLimit(src, 'contractorLicense', ctx.GetSecurityCooldown('Contract', 2000)) then return ctx.RateLimitResponse() end
        local access, accessMessage = RequireWorkAccess(ctx, src)
        if not access then return { success = false, message = accessMessage } end
        if not Contractors.IsEnabled() then return { success = false, message = T('contractor.disabled') } end

        local citizenid = ctx.GetCitizenId(src)
        local profile = Contractors.GetProfile(citizenid)
        if Contractors.IsDatabaseTrue(profile.licensed) then return { success = true, message = T('contractor.license_active') } end

        local playerRank = ctx.GetPlayerTruckingRank(src)
        local unlockRank = tonumber(Contractors.GetConfig().UnlockRank) or 1
        if not ctx.CheckRankRequirement(playerRank, unlockRank) then
            return { success = false, message = T('contractor.license_rank_required', { rank = unlockRank }) }
        end

        local price = tonumber(Contractors.GetConfig().LicenseCost) or 0
        if not ctx.RemoveMoney(src, price, 'ls-trucking-contractor-license') then
            return { success = false, message = T('contractor.license_cost', { price = price }) }
        end

        MySQL.update.await('UPDATE trucking_contractor_profiles SET licensed = 1, license_purchased_at = CURRENT_TIMESTAMP WHERE citizenid = ?', { citizenid })
        return { success = true, message = T('contractor.license_purchased') }
    end)

    lib.callback.register('ls_trucking:server:selectContractorDailyRoute', function(src, routeKey)
        if not ctx.CheckRateLimit(src, 'contractorDailyRoute', ctx.GetSecurityCooldown('Contract', 1500)) then return ctx.RateLimitResponse() end
        local access, accessMessage = RequireWorkAccess(ctx, src)
        if not access then return { success = false, message = accessMessage } end
        if ctx.ActiveContracts[src] then return { success = false, message = T('contractor.active_route_daily') } end

        local citizenid = ctx.GetCitizenId(src)
        local profile = Contractors.GetProfile(citizenid)
        if not Contractors.IsDatabaseTrue(profile.licensed) then return { success = false, message = T('contractor.license_required') } end

        local route = GetDailyRouteOption(routeKey)
        if not route then return { success = false, message = T('contractor.invalid_daily_route') } end

        local playerRank = ctx.GetPlayerTruckingRank(src)
        local minRank = tonumber(route.minRank) or tonumber(Contractors.GetConfig().UnlockRank) or 1
        if not ctx.CheckRankRequirement(playerRank, minRank) then
            return { success = false, message = T('contractor.daily_rank_required', { rank = minRank }) }
        end

        if profile.daily_route_key and profile.daily_route_key ~= '' and profile.daily_route_key == route.key then
            return { success = true, message = T('contractor.daily_already_assigned', { route = route.label or route.key }) }
        end

        local canChange, changeAt, remaining = GetDailyRouteChangeStatus(profile)
        if not canChange then
            local days = math.max(1, math.ceil((remaining or 0) / 86400))
            local dateText = changeAt and os.date('%Y-%m-%d', changeAt) or 'later'
            return { success = false, message = T('contractor.daily_cooldown', { days = days, plural = days == 1 and '' or 's', date = dateText }) }
        end

        MySQL.update.await('UPDATE trucking_contractor_profiles SET daily_route_key = ?, daily_route_selected_at = CURRENT_TIMESTAMP, daily_route_date = ?, daily_route_completed = 0 WHERE citizenid = ?', { route.key, GetDateKey(), citizenid })
        return { success = true, message = T('contractor.daily_selected', { route = route.label or route.key }) }
    end)

    lib.callback.register('ls_trucking:server:purchaseContractorVehicle', function(src, vehicleType, vehicleIndex)
        if not ctx.CheckRateLimit(src, 'contractorBuyVehicle', ctx.GetSecurityCooldown('Contract', 2000)) then return ctx.RateLimitResponse() end
        local access, accessMessage = RequireWorkAccess(ctx, src)
        if not access then return { success = false, message = accessMessage } end
        if not Contractors.IsEnabled() then return { success = false, message = T('contractor.disabled') } end

        local citizenid = ctx.GetCitizenId(src)
        local profile = Contractors.GetProfile(citizenid)
        if not Contractors.IsDatabaseTrue(profile.licensed) then return { success = false, message = T('contractor.license_required') } end

        vehicleIndex = tonumber(vehicleIndex) or 1
        local vehicleData, resolvedIndex = ctx.GetVehicleConfig(vehicleType, vehicleIndex)
        if not vehicleData then return { success = false, message = T('contractor.invalid_vehicle') } end
        if not TableHasValue(Contractors.GetConfig().VehicleTypes or {}, vehicleType) then
            return { success = false, message = T('contractor.vehicle_type_unavailable') }
        end

        local options = GetVehicleOptions(vehicleData)
        if not options.enabled then return { success = false, message = T('contractor.vehicle_unavailable') } end

        local playerRank = ctx.GetPlayerTruckingRank(src)
        local minRank = tonumber(options.minRank) or tonumber(vehicleData.minRank) or 1
        if not ctx.CheckRankRequirement(playerRank, minRank) then
            return { success = false, message = T('contractor.vehicle_rank_required', { rank = minRank }) }
        end

        local ownedCountRow = MySQL.single.await('SELECT COUNT(*) AS count FROM trucking_contractor_vehicles WHERE citizenid = ?', { citizenid }) or {}
        local maxOwned = tonumber(Contractors.GetConfig().MaxOwnedVehicles) or 6
        if (tonumber(ownedCountRow.count) or 0) >= maxOwned then
            return { success = false, message = T('contractor.fleet_limit', { max = maxOwned }) }
        end

        local duplicate = MySQL.single.await('SELECT id FROM trucking_contractor_vehicles WHERE citizenid = ? AND vehicle_type = ? AND vehicle_index = ? LIMIT 1', { citizenid, vehicleType, resolvedIndex })
        if duplicate then return { success = false, message = T('contractor.already_own_vehicle') } end

        local price = GetVehiclePrice(vehicleType, resolvedIndex, vehicleData)
        if not ctx.RemoveMoney(src, price, 'ls-trucking-contractor-vehicle') then
            return { success = false, message = T('contractor.vehicle_cost', { price = price }) }
        end

        MySQL.insert.await([[INSERT INTO trucking_contractor_vehicles (citizenid, vehicle_type, vehicle_index, vehicle_label, vehicle_model, plate, props, fuel, engine_health, body_health, original_price, mileage, stored, out_state) VALUES (?, ?, ?, ?, ?, ?, NULL, ?, 1000, 1000, ?, 0, 1, 0)]], {
            citizenid,
            vehicleType,
            resolvedIndex,
            vehicleData.label,
            ctx.GetGarageVehicleModel(vehicleType, vehicleData),
            ctx.GeneratePlate(vehicleData.platePrefix),
            tonumber(vehicleData.fuel) or 100,
            price
        })

        return { success = true, message = T('contractor.vehicle_purchased', { vehicle = vehicleData.label or 'contractor vehicle' }) }
    end)

    lib.callback.register('ls_trucking:server:sellContractorVehicle', function(src, vehicleId)
        if not ctx.CheckRateLimit(src, 'contractorSellVehicle', ctx.GetSecurityCooldown('Contract', 2000)) then return ctx.RateLimitResponse() end
        local access, accessMessage = RequireWorkAccess(ctx, src)
        if not access then return { success = false, message = accessMessage } end
        if not Contractors.IsEnabled() then return { success = false, message = T('contractor.disabled') } end
        if ctx.ActiveContracts[src] then return { success = false, message = T('contractor.active_contract_sell') } end

        local citizenid = ctx.GetCitizenId(src)
        local row = Contractors.GetVehicleById(citizenid, vehicleId)
        if not row then return { success = false, message = T('contractor.vehicle_not_found') } end
        if not Contractors.IsDatabaseTrue(row.stored) or Contractors.IsDatabaseTrue(row.out_state) then
            return { success = false, message = T('contractor.store_before_sale') }
        end

        local vehicleData = Config.JobVehicles[row.vehicle_type] and Config.JobVehicles[row.vehicle_type][tonumber(row.vehicle_index) or 1] or {}
        local resalePrice, originalPrice, mileage, depreciationPerMile = GetVehicleResale(row, vehicleData)
        local reserved = MySQL.update.await('UPDATE trucking_contractor_vehicles SET stored = 2 WHERE citizenid = ? AND id = ? AND stored = 1 AND out_state = 0', { citizenid, row.id }) or 0
        if reserved < 1 then return { success = false, message = T('contractor.sale_failed_refresh') } end

        if resalePrice > 0 and not ctx.AddMoney(src, resalePrice, 'ls-trucking-contractor-vehicle-sale') then
            MySQL.update.await('UPDATE trucking_contractor_vehicles SET stored = 1 WHERE citizenid = ? AND id = ? AND stored = 2', { citizenid, row.id })
            return { success = false, message = T('contractor.sale_payment_failed') }
        end

        MySQL.update.await('DELETE FROM trucking_contractor_vehicles WHERE citizenid = ? AND id = ? AND stored = 2', { citizenid, row.id })
        return {
            success = true,
            resalePrice = resalePrice,
            originalPrice = originalPrice,
            mileage = mileage,
            depreciationPerMile = depreciationPerMile,
            message = T('contractor.vehicle_sold', { vehicle = row.vehicle_label or 'contractor vehicle', price = resalePrice })
        }
    end)

    lib.callback.register('ls_trucking:server:createContractorContract', function(src, vehicleId, priorityKey, requestedRouteIndex, state, requestedDailyRouteKey)
        if not ctx.CheckRateLimit(src, 'createContractorContract', ctx.GetSecurityCooldown('Contract', 2000)) then return ctx.RateLimitResponse() end
        local access, accessMessage = RequireWorkAccess(ctx, src)
        if not access then return { success = false, message = accessMessage } end
        if not Contractors.IsEnabled() then return { success = false, message = T('contractor.disabled') } end

        local citizenid = ctx.GetCitizenId(src)
        local profile = Contractors.GetProfile(citizenid)
        if not Contractors.IsDatabaseTrue(profile.licensed) then return { success = false, message = T('contractor.license_required') } end

        vehicleId = tonumber(vehicleId)
        local row = vehicleId and vehicleId > 0 and Contractors.GetVehicleById(citizenid, vehicleId) or nil
        if not row then row = Contractors.GetOutVehicle(citizenid) end
        if not row then return { success = false, message = T('contractor.vehicle_not_found') } end
        if Contractors.IsDatabaseTrue(row.stored) and not Contractors.IsDatabaseTrue(row.out_state) then
            return { success = false, message = T('contractor.spawn_before_contract') }
        end

        state = type(state) == 'table' and state or {}
        local currentPlate = ctx.ClampText(state.plate or row.plate, 16)
        if ctx.NormalizePlateText(currentPlate) ~= ctx.NormalizePlateText(row.plate) then
            return { success = false, message = T('contractor.plate_mismatch') }
        end

        local fuel = math.max(0.0, math.min(100.0, tonumber(state.fuel) or tonumber(row.fuel) or 0.0))
        local engineHealth = math.max(0.0, math.min(1000.0, tonumber(state.engineHealth) or tonumber(row.engine_health) or 1000.0))
        local bodyHealth = math.max(0.0, math.min(1000.0, tonumber(state.bodyHealth) or tonumber(row.body_health) or 1000.0))
        local condition = VehicleConditionPercent(engineHealth, bodyHealth)
        local minFuel = tonumber(Contractors.GetConfig().MinFuel) or 0
        local minCondition = tonumber(Contractors.GetConfig().MinCondition) or 0

        if fuel < minFuel then return { success = false, message = T('contractor.min_fuel', { fuel = minFuel }) } end
        if condition < minCondition then return { success = false, message = T('contractor.min_condition', { condition = minCondition }) } end

        MySQL.update.await('UPDATE trucking_contractor_vehicles SET fuel = ?, engine_health = ?, body_health = ? WHERE citizenid = ? AND id = ?', { fuel, engineHealth, bodyHealth, citizenid, row.id })

        local routeContractType = row.vehicle_type
        local selectedDailyRouteKey = requestedDailyRouteKey and tostring(requestedDailyRouteKey) or nil
        if selectedDailyRouteKey == '' then selectedDailyRouteKey = nil end

        local startDailyRoute = false
        local routeOption = nil
        local resolvedPriorityKey = priorityKey or 'standard'
        local resolvedRouteIndex = tonumber(requestedRouteIndex)

        if selectedDailyRouteKey then
            routeOption = GetSelectedDailyRoute(profile)
            if not routeOption or routeOption.key ~= selectedDailyRouteKey then
                return { success = false, message = T('contractor.daily_unavailable') }
            end
            if profile.daily_route_date ~= GetDateKey() or Contractors.IsDatabaseTrue(profile.daily_route_completed) then
                return { success = false, message = T('contractor.daily_completed') }
            end

            routeContractType = routeOption.type or (routeOption.types and routeOption.types[1])
            if row.vehicle_type ~= routeContractType then
                return { success = false, message = T('contractor.daily_vehicle_type') }
            end

            resolvedPriorityKey = routeOption.priorityKey or 'standard'
            resolvedRouteIndex = tonumber(routeOption.routeIndex)
            startDailyRoute = true
        end

        local routePool = ctx.GetRoutePool(routeContractType, resolvedPriorityKey)
        resolvedRouteIndex = resolvedRouteIndex and math.floor(resolvedRouteIndex) or nil
        if not resolvedRouteIndex and routePool and #routePool > 0 then
            local indexes = GetBoardRouteIndexes(citizenid, routeContractType, resolvedPriorityKey, #routePool, 1)
            resolvedRouteIndex = indexes[1] or math.random(1, #routePool)
        end
        if not routePool or not resolvedRouteIndex or not routePool[resolvedRouteIndex] then
            return { success = false, message = T('contractor.route_unavailable') }
        end

        return ctx.CreateContractForPlayer(src, row.vehicle_type, tonumber(row.vehicle_index) or 1, true, row.plate, resolvedPriorityKey, resolvedRouteIndex, {
            contractor = true,
            contractorVehicleId = row.id,
            dailyRouteKey = startDailyRoute and selectedDailyRouteKey or nil,
            reuseCandidate = {
                type = row.vehicle_type,
                index = tonumber(row.vehicle_index) or 1,
                plate = row.plate,
                label = row.vehicle_label,
                vehicleLabel = row.vehicle_label
            },
            skipSpawnDistance = true,
            plate = row.plate,
            payoutMultiplier = tonumber(Contractors.GetConfig().PayoutMultiplier) or 1.0,
            xpMultiplier = tonumber(Contractors.GetConfig().XpMultiplier) or 1.0,
            repBonus = tonumber(Contractors.GetConfig().RepBonus) or 0,
            cancelFee = tonumber(Contractors.GetConfig().CancelFee) or 0,
            vehicleSource = 'contractor-contract'
        })
    end)
end

LS_Trucking.Contractors = Contractors
