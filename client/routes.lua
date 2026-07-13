LS_Trucking = LS_Trucking or {}

local Routes = {}
local clientContext = {}

local function Ctx()
    return clientContext or {}
end

local function Notify(message, notifyType)
    local ctx = Ctx()
    if ctx.Notify then ctx.Notify(message, notifyType) end
end

local function SetActiveContract(value)
    local ctx = Ctx()
    if ctx.SetActiveContract then ctx.SetActiveContract(value) end
end

local function GetActiveContract()
    local ctx = Ctx()
    return ctx.GetActiveContract and ctx.GetActiveContract() or nil
end

local function Call(name, ...)
    local fn = Ctx()[name]
    if fn then return fn(...) end
    return nil
end

local function CleanupPendingContractStart()
    local result = Call('CleanupPendingContractStart')
    if result and result.success == false and result.message then
        Notify(result.message, 'error')
    end
end

function Routes.GetTrailerHookStage(routeTrailer)
    if routeTrailer and routeTrailer.label then
        return ('Hook up %s'):format(routeTrailer.label)
    end

    if routeTrailer and routeTrailer.model then
        return ('Hook up %s'):format(routeTrailer.model)
    end

    return 'Hook up trailer'
end

local function BuildActiveContract(data, vehicleLabel, trailerHookStage)
    local contract, contractType = data.contract, data.contractType
    local assistedLoading = Config.CargoLoading and tostring(Config.CargoLoading.Mode or 'manual'):lower() == 'assisted'
    local notice = assistedLoading
        and 'Go to the pickup worker and sign for the handoff. After release, return to your assigned vehicle for dock loading.'
        or 'Go to the pickup worker. Collect one item, carry it to your vehicle, open the trunk, and load it.'
    local loaded, loadedCargo = false, 0

    if contractType == 'trailer' then
        notice = ('Drive to %s and hook up the assigned trailer: %s. After hooking up, complete the load checklist to start the route.'):format(contract.trailerDepot and contract.trailerDepot.label or 'the trailer yard', trailerHookStage:gsub('^Hook up%s+', ''))
        loadedCargo = 1
    end

    return {
        contractId = data.contractId,
        type = contractType,
        label = contract.label,
        priorityLabel = contract.priorityLabel,
        routeLabel = contract.routeLabel,
        routeLength = contract.routeLength,
        routeIndex = data.routeIndex,
        cargo = contract.cargo,
        payout = data.payout,
        plate = data.plate,
        vehicleIndex = data.vehicleIndex,
        contractor = data.contractor == true,
        contractorVehicleId = data.contractorVehicleId,
        stage = contractType == 'trailer' and trailerHookStage or 'Talk to pickup worker',
        notice = notice,
        pickup = contract.pickup,
        dropoffs = contract.dropoffs,
        trailerDrop = contract.trailerDrop,
        receiverPed = contract.receiverPed,
        currentStop = 0,
        totalStops = contract.dropoffs and #contract.dropoffs or 1,
        loaded = loaded,
        loadedCargo = loadedCargo,
        requiredCargo = contract.requiredCargo or 1,
        destination = contract.pickup.label,
        vehicleLabel = vehicleLabel,
        trailerAttached = false,
        trailerHooked = false,
        trailerDropped = false,
        loadChecklist = { truckSecure = false, trailerSecure = false },
        estimatedSeconds = contract.estimatedSeconds,
        estimatedTime = contract.estimatedTime,
        randomEvent = contract.randomEvent,
        routeTrailer = contract.routeTrailer,
        trailerDepot = contract.trailerDepot,
        trailerLabel = contract.routeTrailer and contract.routeTrailer.label or nil,
        trailerPhoto = contract.routeTrailer and contract.routeTrailer.photo or nil,
        trailerContents = contract.routeTrailer and contract.routeTrailer.contents or nil,
        trailerInstructions = contract.routeTrailer and contract.routeTrailer.instructions or nil,
        safeSpeed = contract.routeTrailer and contract.routeTrailer.safeSpeed or (Config.SpeedRisk and Config.SpeedRisk.DefaultSafeSpeed) or 75.0,
        cargoType = contract.cargoType,
        cargoItem = contract.cargoItem,
        cargoLabel = contract.cargoLabel,
        cargoConfig = contract.cargoType and Config.CargoTypes and Config.CargoTypes[contract.cargoType] or nil,
        manifest = contract.manifest,
        cargoReady = false,
        verifiedCargo = false,
        autoLoadActive = false,
        autoLoadPaused = false,
        autoLoadLoaded = loadedCargo,
        autoLoadTotal = contract.requiredCargo or 1,
        autoLoadLabel = ''
    }
end

function Routes.StartLocalContract(data, reuseVehicle)
    if not data or not data.contract then
        Notify('Unable to start contract: route data missing.', 'error')
        CleanupPendingContractStart()
        return false
    end

    local ctx = Ctx()
    local contract, contractType = data.contract, data.contractType
    local vehicleLabel = data.vehicle and data.vehicle.label or 'Company Vehicle'
    local trailerHookStage = Routes.GetTrailerHookStage(contract.routeTrailer)

    Call('SetReceiverDockUserHidden', false)

    if reuseVehicle then
        if not Call('CanReuseVehicle', contractType, data.contractor == true) then
            Notify('You cannot reuse your current vehicle for this contract.', 'error')
            CleanupPendingContractStart()
            return false
        end

        Call('ClearRouteBlip')

        if contractType == 'trailer' then
            if not Call('SpawnTrailerOnly', data.vehicle, contract.routeTrailer, contract.trailerDepot) then
                Notify('Unable to spawn new trailer.', 'error')
                CleanupPendingContractStart()
                return false
            end
        else
            Call('AddVehicleCargoTarget')
        end

    else
        if Config.DeleteOldVehicleOnNewContract then Call('CleanupJobVehicle') end
        if not Call('SpawnJobVehicle', data) then
            Notify('Unable to spawn selected job vehicle.', 'error')
            Call('CleanupJobVehicle')
            CleanupPendingContractStart()
            return false
        end

        Call('SetGarageVehicle', {
            type = contractType,
            index = data.vehicleIndex,
            plate = data.plate,
            label = vehicleLabel,
            vehicleLabel = vehicleLabel
        })
    end

    Call('SetReusableVehicle', nil)

    local activeContract = BuildActiveContract(data, vehicleLabel, trailerHookStage)
    SetActiveContract(activeContract)
    if contractType == 'trailer' then Call('RegisterAssignedTrailer', activeContract.contractId) end

    Call('ResetCargoCondition')
    Call('SetupActiveContractPeds')
    Call('SetActiveDestination', contract.pickup.label, contract.pickup.coords)
    Call('SetupRouteTargets')
    Call('CreateRouteBlip', contract.pickup.coords, contract.pickup.label, 'pickup')
    if contractType == 'trailer' then
        Call('CreateRouteAreaBlip', contract.pickup.coords, contract.trailerDepot and contract.trailerDepot.radius, 'TrailerPickup')
    end

    if contract.randomEvent then
        Call('DispatchChatter', ('%s - %s'):format(contract.randomEvent.label or 'Route Update', contract.randomEvent.description or 'Route conditions changed.'), 'inform', 'alert')
    end

    Call('UpdateMiniUI')
    TriggerServerEvent('ls_trucking:server:confirmContractStarted', data.contractId)
    return true
end

function Routes.BuildCancelReasonOptions()
    local options = {}
    local reasons = Config.CancelPenalty and Config.CancelPenalty.Reasons or nil

    if reasons and #reasons > 0 then
        for _, reason in ipairs(reasons) do
            options[#options + 1] = {
                value = reason.value or reason.label,
                label = reason.label or reason.value
            }
        end
    else
        options = {
            { value = 'vehicle_damaged', label = 'Vehicle / trailer damaged' },
            { value = 'wrong_vehicle', label = 'Wrong vehicle selected' },
            { value = 'route_issue', label = 'Route issue / blocked destination' },
            { value = 'out_of_time', label = 'Out of time' },
            { value = 'player_choice', label = 'Changed my mind' },
            { value = 'other', label = 'Other' }
        }
    end

    return options
end

function Routes.GetCancelReasonLabel(value)
    for _, option in ipairs(Routes.BuildCancelReasonOptions()) do
        if option.value == value then
            return option.label
        end
    end

    return tostring(value or 'Not specified')
end

function Routes.ConfirmCancelContract()
    local activeContract = GetActiveContract()
    local repLoss = 0

    if Config.CancelPenalty and Config.CancelPenalty.Enabled then
        repLoss = tonumber(Config.CancelPenalty.ReputationLoss) or 0
    end

    if activeContract and activeContract.contractor and Config.PrivateContractor then
        repLoss = repLoss + (tonumber(Config.PrivateContractor.CancelRepLoss) or 0)
    end

    local ctx = Ctx()
    return ctx.ShowFreightCancelDialog and ctx.ShowFreightCancelDialog(repLoss, Routes.BuildCancelReasonOptions()) or nil
end

local function CleanupCancelledRoute()
    Call('ResetAssistedCargoLoading')
    Call('ClearRouteBlip')
    Call('RemoveAllZones')
    Call('CleanupActiveContractPeds', true)
    Call('DeleteCarryProp')
    SetActiveContract(nil)
    Call('UpdateMiniUI')
end

function Routes.CancelActiveContract(options)
    options = options or {}

    local activeContract = GetActiveContract()
    if not activeContract then
        Notify('You do not have an active contract.', 'error')
        return false
    end

    local routeName = activeContract.routeLabel or activeContract.label or 'Active Route'
    local contractId = activeContract.contractId or 'N/A'
    local reason = Routes.ConfirmCancelContract()

    if not reason then
        Notify('Route cancellation aborted.', 'inform')
        return false
    end

    if options.fromReceiver then
        Call('DispatchChatter', ('Cancel route request sent for %s and Contract #%s.'):format(routeName, contractId), 'warning', 'alert', { direction = 'tx' })
        Wait(1250)

        if not GetActiveContract() then return true end

        Call('DispatchChatter', 'Dispatch Request Confirmed - Route Cancelled', 'error', 'secure', { direction = 'rx' })
        Wait(900)
    end

    TriggerServerEvent('ls_trucking:server:cancelContract', Routes.GetCancelReasonLabel(reason))
    CleanupCancelledRoute()
    return true
end

function Routes.CompleteRoute()
    local activeContract = GetActiveContract()
    if not activeContract then return end

    Call('SetLastCompletedCargoCondition', {
        label = activeContract.cargoConditionLabel,
        note = activeContract.cargoConditionNote
    })

    local result = lib.callback.await('ls_trucking:server:completeRoute', false, activeContract.contractId)
    if not result or not result.success then
        Notify(result and result.message or 'Unable to complete route.', 'error')
        return
    end

    if activeContract.contractor then
        Call('SetReusableVehicle', nil)
    else
        local garageVehicle = Call('GetGarageVehicle')
        Call('SetReusableVehicle', {
            type = activeContract.type,
            index = activeContract.vehicleIndex or (garageVehicle and garageVehicle.index) or 1,
            label = activeContract.priorityLabel and (activeContract.priorityLabel .. ' - ' .. activeContract.label) or activeContract.label,
            vehicleLabel = activeContract.vehicleLabel
        })
    end

    activeContract.stage = 'Route complete'
    activeContract.notice = activeContract.contractor and 'Route closed out. Store your contractor vehicle when ready.' or 'Return the vehicle to the dispatcher or start another job with the same vehicle.'
    Call('SetActiveDestination', activeContract.contractor and 'Store contractor vehicle' or 'Return vehicle or start another job', Config.Depot.vehicleReturn)
    Call('UpdateMiniUI')
    Call('ResetAssistedCargoLoading')
    Call('ClearRouteBlip')
    Call('RemoveAllZones')
    Call('CleanupActiveContractPeds', true)
    SetActiveContract(nil)
    SetTimeout(5000, function() Call('UpdateMiniUI') end)
end

function Routes.ConfigureClient(context)
    clientContext = context or {}
end

LS_Trucking.Routes = Routes
