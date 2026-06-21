LS_Trucking = LS_Trucking or {}

local RouteSummary = {}

function RouteSummary.BuildCompletedPayload(src, active, paidRoute, getCharacterName)
    active = active or {}
    paidRoute = paidRoute or {}
    local payoutResult = paidRoute.payoutResult or {}

    local vehicleLabel = active.vehicleLabel or 'Company Vehicle'
    if active.type == 'trailer' then
        vehicleLabel = ((active.vehicleLabel or 'Truck') .. ' + ' .. (active.trailerLabel or 'Assigned Trailer'))
    end

    local driverName = 'Driver'
    if type(getCharacterName) == 'function' then
        driverName = getCharacterName(src) or driverName
    end

    return {
        payout = paidRoute.finalPayout or 0,
        basePayout = payoutResult.basePayout,
        contractBasePayout = payoutResult.contractBasePayout,
        mileageBonus = payoutResult.mileageBonus,
        routeMiles = payoutResult.routeMiles,
        mileageRate = payoutResult.mileageRate,
        xp = active.xp or 0,
        rep = paidRoute.routeRep or 0,
        adjustments = payoutResult.adjustments,
        time = payoutResult.time,
        randomEvent = payoutResult.randomEvent,
        damagePercent = payoutResult.damagePercent,
        contractId = active.id,
        contractType = active.type,
        contractLabel = active.label,
        priorityLabel = active.priorityLabel,
        routeLabel = active.routeLabel,
        routeLength = active.routeLength,
        pickupLabel = active.pickupLabel,
        pickupDepotLabel = active.pickupDepotLabel or (active.trailerDepot and active.trailerDepot.label) or active.pickupLabel,
        trailerDepotLabel = active.trailerDepot and active.trailerDepot.label or nil,
        vehicleLabel = vehicleLabel,
        estimatedSeconds = active.estimatedSeconds,
        deliveredCargo = active.deliveredCargo,
        requiredCargo = active.requiredCargo,
        totalStops = active.totalStops,
        cargo = active.cargoLabel,
        cargoType = active.cargoType,
        trailerContents = active.trailerContents,
        pickupSignature = active.pickupSignature,
        deliverySignature = active.deliverySignature,
        safeSpeed = active.safeSpeed,
        driverName = driverName,
        jobText = paidRoute.jobText,
        completedAt = os.date('%Y-%m-%d %H:%M:%S'),
        contractor = active.contractor == true,
        contractorDailyBonus = paidRoute.dailyBonus,
        contractorDailyRepBonus = paidRoute.dailyRepBonus
    }
end

LS_Trucking.RouteSummary = RouteSummary
