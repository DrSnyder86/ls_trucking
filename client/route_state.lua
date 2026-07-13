LS_Trucking = LS_Trucking or {}

local RouteState = {}
local clientContext = {}

local function Ctx()
    return clientContext or {}
end

local function ClampReceiverPercent(value)
    value = tonumber(value) or 0
    return math.max(0, math.min(100, math.floor(value + 0.5)))
end

local function BuildReceiverVehicleTelemetry()
    local ctx = Ctx()
    local vehicle = ctx.GetSpawnedVehicle and ctx.GetSpawnedVehicle() or 0
    vehicle = vehicle and DoesEntityExist(vehicle) and vehicle or 0

    if vehicle == 0 then
        return {
            fuel = nil,
            fuelLabel = 'N/A',
            conditionScore = nil,
            conditionLabel = 'No vehicle',
            conditionLevel = 'none'
        }
    end

    local fuel
    if Config.GetVehicleFuel then
        fuel = Config.GetVehicleFuel(vehicle)
    end
    if fuel == nil then
        fuel = GetVehicleFuelLevel(vehicle)
    end

    fuel = ClampReceiverPercent(fuel)

    local bodyHealth = math.max(0.0, math.min(1000.0, tonumber(GetVehicleBodyHealth(vehicle)) or 0.0))
    local engineHealth = math.max(0.0, math.min(1000.0, tonumber(GetVehicleEngineHealth(vehicle)) or 0.0))
    local conditionScore = ClampReceiverPercent(math.min(bodyHealth, engineHealth) / 10.0)
    local conditionLabel = 'Good'
    local conditionLevel = 'good'

    if conditionScore <= 15 then
        conditionLabel = 'Critical'
        conditionLevel = 'critical'
    elseif conditionScore <= 35 then
        conditionLabel = 'Damaged'
        conditionLevel = 'damaged'
    elseif conditionScore <= 60 then
        conditionLabel = 'Worn'
        conditionLevel = 'worn'
    elseif conditionScore <= 85 then
        conditionLabel = 'Used'
        conditionLevel = 'used'
    end

    return {
        fuel = fuel,
        fuelLabel = ('%s%%'):format(fuel),
        conditionScore = conditionScore,
        conditionLabel = ('%s (%s%%)'):format(conditionLabel, conditionScore),
        conditionLevel = conditionLevel
    }
end

local function BuildReceiverPlayerInfo()
    local ctx = Ctx()
    local info = ctx.GetCurrentDriverInfo and ctx.GetCurrentDriverInfo() or {}

    return {
        name = info.name or GetPlayerName(PlayerId()) or 'Driver',
        rank = info.rank,
        rankLabel = info.rankLabel,
        xp = info.xp,
        nextRankXp = info.nextRankXp,
        reputation = info.reputation,
        jobText = info.jobText or info.jobLabel
    }
end

function RouteState.BuildPriorityOptions(contractType)
    local priorities = contractType and Config.PriorityLoads and Config.PriorityLoads[contractType] or nil
    if not priorities then return {} end

    local order = { 'standard', 'priority', 'government', 'military' }
    local used = {}
    local options = {}

    local function AddPriority(key, priority)
        if not key or used[key] or type(priority) ~= 'table' then return end
        used[key] = true
        options[#options + 1] = {
            key = key,
            order = priority.order or 99,
            label = priority.label or key,
            shortLabel = priority.shortLabel or priority.label or key,
            minRank = priority.minRank or 1,
            payoutMultiplier = priority.payoutMultiplier or 1.0,
            xpMultiplier = priority.xpMultiplier or 1.0,
            badge = priority.badge,
            description = priority.description
        }
    end

    for _, key in ipairs(order) do AddPriority(key, priorities[key]) end
    for key, priority in pairs(priorities) do AddPriority(key, priority) end

    table.sort(options, function(a, b)
        if (a.order or 99) ~= (b.order or 99) then return (a.order or 99) < (b.order or 99) end
        return tostring(a.label or a.key) < tostring(b.label or b.key)
    end)

    return options
end

function RouteState.BuildCurrentJob(activeContract)
    if not activeContract then return nil end

    return {
        id = activeContract.contractId,
        type = activeContract.type,
        label = activeContract.priorityLabel and (activeContract.priorityLabel .. ' - ' .. activeContract.label) or activeContract.label,
        routeLabel = activeContract.routeLabel or activeContract.label,
        priorityLabel = activeContract.priorityLabel,
        stage = activeContract.stage,
        notice = activeContract.notice,
        payout = activeContract.payout,
        loadedCargo = activeContract.loadedCargo,
        requiredCargo = activeContract.requiredCargo,
        currentStop = activeContract.currentStop,
        totalStops = activeContract.totalStops,
        cargo = activeContract.cargo,
        cargoConditionLabel = activeContract.cargoConditionLabel or 'CARGO STABLE',
        cargoConditionNote = activeContract.cargoConditionNote,
        destination = activeContract.destination,
        destinationAddress = activeContract.destinationAddress,
        pickup = activeContract.pickup and activeContract.pickup.label or nil,
        routeLength = activeContract.routeLength,
        estimatedTime = activeContract.estimatedTime,
        expectedCompletion = activeContract.expectedCompletion,
        vehicleLabel = activeContract.vehicleLabel,
        plate = activeContract.plate,
        contractor = activeContract.contractor == true
    }
end

function RouteState.BuildReceiverPayload(minimal)
    local ctx = Ctx()
    local activeContract = ctx.GetActiveContract and ctx.GetActiveContract() or nil
    local signalStrength, signalLabel, gpsLocked = 4, 'Dispatch signal locked', true

    if ctx.GetMiniSignalData then
        signalStrength, signalLabel, gpsLocked = ctx.GetMiniSignalData()
    end

    local reuseData = ctx.BuildReceiverReuseData and ctx.BuildReceiverReuseData() or { available = false }
    local includeFull = minimal ~= true
    local vehicleTelemetry = BuildReceiverVehicleTelemetry()
    local playerInfo = BuildReceiverPlayerInfo()
    local routeHistory = includeFull and ctx.GetRouteHistory and ctx.GetRouteHistory() or nil
    local dockHidden = ctx.GetReceiverDockUserHidden and ctx.GetReceiverDockUserHidden() or false
    local lastRadioChatter = ctx.GetLastRadioChatter and ctx.GetLastRadioChatter() or nil
    local lastRadioDirection = ctx.GetLastRadioDirection and ctx.GetLastRadioDirection() or 'rx'
    local radioHistory = ctx.GetRadioHistory and ctx.GetRadioHistory() or {}
    local contractRequestPending = ctx.IsContractRequestPending and ctx.IsContractRequestPending() or false

    if not activeContract then
        return {
            type = 'standby',
            vehicleType = reuseData.type,
            label = contractRequestPending and 'DISPATCH REVIEW' or 'DISPATCH STANDBY',
            stage = contractRequestPending and 'Route request pending' or 'No active route',
            notice = contractRequestPending and (lastRadioChatter or 'Dispatch is reviewing route availability.') or 'No freight route assigned. Open dispatch to select a contract.',
            currentStop = 0,
            totalStops = 0,
            payout = 0,
            cargo = 'No active load',
            destination = contractRequestPending and 'Awaiting Dispatch' or 'LS Freight Dispatch',
            destinationAddress = contractRequestPending and 'CONTRACT REVIEW' or 'TERMINAL STANDBY',
            vehicle = reuseData.available and (reuseData.vehicleLabel or reuseData.label) or 'Handheld Receiver',
            loadedCargo = 0,
            requiredCargo = 0,
            contractId = '',
            priorityLabel = '',
            routeLength = '',
            plate = reuseData.plate or '',
            pickupLabel = 'LS Freight Dispatch',
            manifest = includeFull and {} or nil,
            loadChecklist = { truckSecure = false, trailerSecure = false },
            cargoReady = false,
            verifiedCargo = false,
            loaded = false,
            autoLoadActive = false,
            autoLoadPaused = false,
            autoLoadLoaded = 0,
            autoLoadTotal = 0,
            autoLoadLabel = '',
            estimatedTime = '',
            expectedCompletion = '',
            radioFrequency = Config.RadioFrequency,
            logo = Config.UI and Config.UI.MiniLogo or nil,
            lastUpdate = nil,
            signalStrength = signalStrength,
            signalLabel = signalLabel,
            gpsLocked = gpsLocked,
            dockEnabled = true,
            dockVisible = not dockHidden and contractRequestPending,
            dockUserHidden = dockHidden,
            radioChatter = lastRadioChatter or 'Dispatch standby. No active route assigned.',
            radioDirection = lastRadioDirection,
            radioHistory = radioHistory,
            contractRequestPending = contractRequestPending,
            loadVerificationMode = Config.LoadVerificationMode or 'receiver',
            cargoConditionLabel = contractRequestPending and 'REQUEST PENDING' or 'NO ACTIVE LOAD',
            cargoConditionLevel = 'stable',
            vehicleFuel = vehicleTelemetry.fuel,
            vehicleFuelLabel = vehicleTelemetry.fuelLabel,
            vehicleConditionScore = vehicleTelemetry.conditionScore,
            vehicleConditionLabel = vehicleTelemetry.conditionLabel,
            vehicleConditionLevel = vehicleTelemetry.conditionLevel,
            reuseVehicle = reuseData,
            priorityOptions = includeFull and RouteState.BuildPriorityOptions(reuseData.type) or nil,
            canStartCurrentVehicleJob = reuseData.contractor == true or Config.AllowVehicleReuseAfterRoute ~= false,
            player = playerInfo,
            playerRank = playerInfo.rank,
            routeHistory = routeHistory,
            hasActiveRoute = false
        }
    end

    return {
        type = activeContract.type,
        label = activeContract.routeLabel or activeContract.label,
        stage = activeContract.stage,
        notice = activeContract.notice or '',
        currentStop = activeContract.currentStop or 0,
        totalStops = activeContract.totalStops or 0,
        payout = activeContract.payout,
        cargo = activeContract.cargo,
        destination = activeContract.destination or 'N/A',
        destinationAddress = activeContract.destinationAddress or nil,
        vehicle = activeContract.vehicleLabel or 'Company Vehicle',
        vehicleSource = activeContract.contractor and 'contractor' or 'company',
        contractor = activeContract.contractor == true,
        contractorVehicleId = activeContract.contractorVehicleId,
        loadedCargo = activeContract.loadedCargo or 0,
        requiredCargo = activeContract.requiredCargo or 0,
        contractId = activeContract.contractId,
        priorityLabel = activeContract.priorityLabel,
        routeLength = activeContract.routeLength,
        plate = activeContract.plate,
        pickupLabel = activeContract.pickup and activeContract.pickup.label or nil,
        manifest = includeFull and (activeContract.manifest or {}) or nil,
        pickupSignature = includeFull and activeContract.pickupSignature or nil,
        deliverySignature = includeFull and activeContract.deliverySignature or nil,
        loadChecklist = activeContract.loadChecklist or { truckSecure = false, trailerSecure = false },
        cargoReady = activeContract.cargoReady == true,
        verifiedCargo = activeContract.verifiedCargo == true,
        loaded = activeContract.loaded == true,
        autoLoadActive = activeContract.autoLoadActive == true,
        autoLoadPaused = activeContract.autoLoadPaused == true,
        autoLoadLoaded = activeContract.autoLoadLoaded or activeContract.loadedCargo or 0,
        autoLoadTotal = activeContract.autoLoadTotal or activeContract.requiredCargo or 0,
        autoLoadLabel = activeContract.autoLoadLabel or '',
        trailerAttached = activeContract.trailerAttached == true,
        trailerHooked = activeContract.trailerHooked == true,
        trailerDropped = activeContract.trailerDropped == true,
        trailerLabel = activeContract.trailerLabel,
        trailerPhoto = activeContract.trailerPhoto or activeContract.routeTrailer and activeContract.routeTrailer.photo or nil,
        trailerContents = activeContract.trailerContents,
        trailerInstructions = includeFull and activeContract.trailerInstructions or nil,
        trailerDepotLabel = activeContract.trailerDepot and activeContract.trailerDepot.label or nil,
        trailerDropLabel = activeContract.trailerDrop and activeContract.trailerDrop.label or nil,
        safeSpeed = activeContract.safeSpeed,
        estimatedTime = activeContract.estimatedTime or '',
        expectedCompletion = activeContract.expectedCompletion or '',
        radioFrequency = Config.RadioFrequency,
        logo = Config.UI and Config.UI.MiniLogo or nil,
        lastUpdate = nil,
        signalStrength = signalStrength,
        signalLabel = signalLabel,
        gpsLocked = gpsLocked,
        dockEnabled = true,
        dockVisible = not dockHidden,
        dockUserHidden = dockHidden,
        radioChatter = activeContract.radioChatter or lastRadioChatter,
        radioDirection = activeContract.radioDirection or lastRadioDirection,
        radioHistory = radioHistory,
        receiverLoadAction = activeContract.receiverLoadAction,
        contractRequestPending = contractRequestPending,
        loadVerificationMode = Config.LoadVerificationMode or 'receiver',
        cargoConditionLabel = activeContract.cargoConditionLabel or 'CARGO STABLE',
        cargoConditionLevel = activeContract.cargoConditionLevel or 'stable',
        cargoConditionNote = activeContract.cargoConditionNote,
        vehicleFuel = vehicleTelemetry.fuel,
        vehicleFuelLabel = vehicleTelemetry.fuelLabel,
        vehicleConditionScore = vehicleTelemetry.conditionScore,
        vehicleConditionLabel = vehicleTelemetry.conditionLabel,
        vehicleConditionLevel = vehicleTelemetry.conditionLevel,
        randomEventLabel = activeContract.randomEvent and activeContract.randomEvent.label or nil,
        contractAlert = activeContract.randomEvent and {
            label = activeContract.randomEvent.label or 'Dispatch Alert',
            description = activeContract.randomEvent.description or 'Route conditions changed.'
        } or nil,
        reuseVehicle = reuseData,
        priorityOptions = includeFull and RouteState.BuildPriorityOptions(activeContract.type) or nil,
        canStartCurrentVehicleJob = Config.AllowVehicleReuseAfterRoute ~= false,
        player = playerInfo,
        playerRank = playerInfo.rank,
        routeHistory = routeHistory,
        hasActiveRoute = true
    }
end

function RouteState.ConfigureClient(context)
    clientContext = context or {}
end

LS_Trucking.RouteState = RouteState
