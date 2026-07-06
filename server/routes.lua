LS_Trucking = LS_Trucking or {}

local Routes = {}
local serverRegistered = false

local function GetRouteCompletionIssue(active)
    if not active then return T('error.no_active_contract') end

    if active.type == 'trailer' then
        if not active.trailerHooked then return T('route.trailer_load_not_cleared') end
        if not active.trailerDropped then return T('route.trailer_drop_not_confirmed') end
        if active.stage ~= 'Route complete' then return T('route.trailer_not_finalized') end
        if (active.loadedCargo or 0) > 0 then return T('route.trailer_cargo_not_cleared') end
        return nil
    end

    if not active.cargoVerified then return T('route.cargo_not_verified') end
    if (active.deliveredCargo or 0) < (active.requiredCargo or 0) then return T('route.not_all_cargo_delivered') end
    if (active.loadedCargo or 0) > 0 then return T('route.cargo_still_in_vehicle') end
    if (active.currentStop or 0) <= (active.totalStops or 0) then return T('route.not_complete') end
    if active.cargoInHand then return T('route.deliver_current_before_complete') end

    return nil
end

local function CompleteRouteForPlayer(ctx, src, contractId)
    local activeContracts = ctx.ActiveContracts
    local active = activeContracts[src]

    if not active or active.id ~= contractId then return { success = false, message = T('route.no_matching_contract') } end
    if active.routeCompleted then return { success = false, message = T('route.already_completed') } end

    local issue = GetRouteCompletionIssue(active)
    if issue then return { success = false, message = issue } end

    local near, nearMessage = ctx.RequireServerNear(src, ctx.GetCompletionCoords(active), ctx.GetDistanceLimit('Completion', 35.0), T('route.too_far_completion'))
    if not near then return { success = false, message = nearMessage } end

    local paidRoute = nil

    if Config.PayWhenRouteComplete and not active.paid then
        local citizenid = ctx.GetCitizenId(src)
        local payoutResult = ctx.BuildPayoutResult(active)
        local finalPayout = payoutResult.payout
        local routeRep = active.rep
        local dailyBonus = 0
        local dailyRepBonus = 0

        if active.contractor then
            dailyBonus, dailyRepBonus = ctx.GetContractorDailyBonus(citizenid, active, false)
            if dailyBonus > 0 then finalPayout = finalPayout + dailyBonus end
            routeRep = routeRep + dailyRepBonus
        end

        if not ctx.AddMoney(src, finalPayout, 'ls-trucking-route-complete') then
            return { success = false, message = T('error.payment_unavailable') }
        end

        active.paid = true

        if active.contractor then
            ctx.AddContractorRep(citizenid, active.rep)
            ctx.GetContractorDailyBonus(citizenid, active, true)
        end

        local jobInfo = ctx.GetPlayerJobInfo(src)
        paidRoute = {
            citizenid = citizenid,
            payoutResult = payoutResult,
            finalPayout = finalPayout,
            routeRep = routeRep,
            dailyBonus = dailyBonus,
            dailyRepBonus = dailyRepBonus,
            jobText = jobInfo.text
        }
    end

    active.routeCompleted = true
    ctx.RemoveAllPlayerCargo(src, active.type, active.cargoType, active.cargoManifest)
    ctx.RemoveAllTrunkCargo(active.plate, active.type, active.cargoType, active.cargoManifest)
    ctx.RemoveContractManifests(src)

    if paidRoute then
        ctx.AddTruckingStats(paidRoute.citizenid, active.xp, paidRoute.routeRep, paidRoute.finalPayout)
        MySQL.insert.await([[INSERT INTO trucking_history (citizenid, contract_id, contract_type, route_label, vehicle_label, payout, xp, reputation) VALUES (?, ?, ?, ?, ?, ?, ?, ?)]], {
            paidRoute.citizenid,
            active.id,
            active.type,
            ((active.priorityLabel and (active.priorityLabel .. ' - ') or '') .. (active.routeLabel or 'Route')),
            active.vehicleLabel or 'Company Vehicle',
            paidRoute.finalPayout,
            active.xp,
            paidRoute.routeRep
        })
        TriggerClientEvent('ls_trucking:client:routePaid', src, ctx.RouteSummary.BuildCompletedPayload(src, active, paidRoute, ctx.GetCharacterName))
    end

    if active.contractor then
        ctx.ReusableVehicles[src] = nil
        ctx.TrackCheckedOutVehicle(src, active.type, active.vehicleIndex or 1, active.plate, 'contractor-completed')
    else
        ctx.ReusableVehicles[src] = {
            type = active.type,
            index = active.vehicleIndex or 1,
            plate = active.plate,
            label = active.vehicleLabel or active.label or 'Company Vehicle',
            vehicleLabel = active.vehicleLabel or 'Company Vehicle'
        }
        ctx.TrackCheckedOutVehicle(src, active.type, active.vehicleIndex or 1, active.plate, 'completed-route')
    end

    activeContracts[src] = nil

    return { success = true }
end

local function CancelContractForPlayer(ctx, src, reason)
    local activeContracts = ctx.ActiveContracts
    local active = activeContracts[src]
    if not active then return end

    local clearVehicleAfterCancel = false

    if reason == '__system_cleanup' then
        if active.pendingClientStartUntil and os.time() <= active.pendingClientStartUntil then
            ctx.CleanupContractCargo(src)
            activeContracts[src] = nil
            ctx.ClearVehicleSession(src)
            return
        end

        reason = 'System cleanup requested'
        clearVehicleAfterCancel = true
    end

    local citizenid = ctx.GetCitizenId(src)
    local repLoss = 1
    local cancelFee = 0

    if Config.CancelPenalty and Config.CancelPenalty.Enabled then
        repLoss = tonumber(Config.CancelPenalty.ReputationLoss) or 1
    end

    if active.contractor then
        local contractorRepLoss = tonumber(ctx.GetContractorConfig().CancelRepLoss) or 0
        cancelFee = tonumber(active.contractorCancelFee) or tonumber(ctx.GetContractorConfig().CancelFee) or 0
        repLoss = repLoss + contractorRepLoss

        if cancelFee > 0 then
            if not ctx.RemoveMoney(src, cancelFee, 'ls-trucking-contractor-cancel') then
                cancelFee = 0
                TriggerClientEvent('ls_trucking:client:notify', src, T('route.cancel_fee_unavailable'), 'error')
            end
        end

        if contractorRepLoss > 0 then
            ctx.AddContractorRep(citizenid, -contractorRepLoss)
        end
    end

    ctx.AddCancelledRoute(citizenid, repLoss)
    ctx.CleanupContractCargo(src)
    activeContracts[src] = nil

    if clearVehicleAfterCancel then
        ctx.ClearVehicleSession(src)
    end

    TriggerClientEvent('ls_trucking:client:contractCancelled', src, {
        repLoss = repLoss,
        fee = cancelFee,
        reason = ctx.ClampText(reason or 'Not specified', 96)
    })
end

local function CleanupPendingContractStart(ctx, src)
    local active = ctx.ActiveContracts[src]

    if not active then
        return { success = true, cleaned = false }
    end

    if not active.pendingClientStartUntil then
        return { success = false, message = T('route.already_started_cancel_normally') }
    end

    ctx.CleanupContractCargo(src)
    ctx.ActiveContracts[src] = nil
    ctx.ClearVehicleSession(src)

    return { success = true, cleaned = true }
end

function Routes.RegisterServer(ctx)
    if serverRegistered then return end
    serverRegistered = true
    ctx = ctx or {}

    lib.callback.register('ls_trucking:server:completeRoute', function(src, contractId)
        if not ctx.CheckRateLimit(src, 'completeRoute', ctx.GetSecurityCooldown('CompleteRoute', 2000)) then return ctx.RateLimitResponse() end
        return CompleteRouteForPlayer(ctx, src, contractId)
    end)

    RegisterNetEvent('ls_trucking:server:routeComplete', function(contractId)
        local src = source
        if not ctx.CheckRateLimit(src, 'completeRouteEvent', ctx.GetSecurityCooldown('CompleteRoute', 2000)) then return end

        local result = CompleteRouteForPlayer(ctx, src, contractId)
        if not result or not result.success then
            ctx.NotifySecurityFailure(src, result and result.message or T('route.complete_failed'))
        end
    end)

    RegisterNetEvent('ls_trucking:server:cancelContract', function(reason)
        local src = source
        if not ctx.CheckRateLimit(src, 'cancelContract', ctx.GetSecurityCooldown('Cancel', 1500)) then return end
        CancelContractForPlayer(ctx, src, reason)
    end)

    lib.callback.register('ls_trucking:server:cleanupPendingContractStart', function(src)
        if not ctx.CheckRateLimit(src, 'cleanupPendingContractStart', ctx.GetSecurityCooldown('Contract', 2000)) then return ctx.RateLimitResponse() end
        return CleanupPendingContractStart(ctx, src)
    end)

    RegisterNetEvent('ls_trucking:server:confirmContractStarted', function(contractId)
        local src = source
        local active = ctx.ActiveContracts[src]

        if active and active.id == contractId then
            active.pendingClientStartUntil = nil
        end
    end)
end

LS_Trucking.Routes = Routes
