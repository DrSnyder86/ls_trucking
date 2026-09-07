LS_Trucking = LS_Trucking or {}

local ContractorUI = {}
local clientContext = {}
local callbacksRegistered = false

local function Ctx()
    return clientContext or {}
end

local function Notify(message, notifyType)
    local ctx = Ctx()
    if ctx.Notify then ctx.Notify(message, notifyType) end
end

function ContractorUI.RegisterClient(context)
    clientContext = context or {}
    if callbacksRegistered then return end
    callbacksRegistered = true

    RegisterNUICallback('purchaseContractorLicense', function(_, cb)
        local result = lib.callback.await('ls_trucking:server:purchaseContractorLicense', false)
        Notify(result and result.message or 'Contractor license request processed.', result and result.success and 'success' or 'error')
        Ctx().RefreshDispatchUI(650, 2)
        cb(result or { success = false })
    end)

    RegisterNUICallback('selectContractorDailyRoute', function(data, cb)
        local result = lib.callback.await('ls_trucking:server:selectContractorDailyRoute', false, data and data.routeKey)
        Notify(result and result.message or 'Dedicated route request processed.', result and result.success and 'success' or 'error')
        Ctx().RefreshDispatchUI(650, 2)
        cb(result or { success = false })
    end)

    RegisterNUICallback('purchaseContractorVehicle', function(data, cb)
        local vehicleType = data and tostring(data.vehicleType or '') or ''
        local vehicleIndex = data and tonumber(data.vehicleIndex) or 0
        if vehicleType == '' or vehicleIndex <= 0 then cb({ success = false }) return end

        local confirmed = data and data.confirmed == true
        if not confirmed then
            local fleetCount = math.max(0, tonumber(data and data.fleetCount) or 0)
            local fleetMax = math.max(fleetCount, tonumber(data and data.fleetMax) or fleetCount)
            confirmed = Ctx().ShowFreightConfirm(
                T('contractor.purchase_confirm_title'),
                T('contractor.purchase_confirm_body', {
                    vehicle = data and data.vehicleLabel or 'Contractor Vehicle',
                    type = data and data.vehicleTypeLabel or vehicleType,
                    price = math.max(0, math.floor(tonumber(data and data.price) or 0)),
                    rank = math.max(1, math.floor(tonumber(data and data.minRank) or 1)),
                    fleet = ('%d / %d'):format(fleetCount, fleetMax)
                }),
                T('contractor.purchase_confirm_accept'),
                T('contractor.purchase_confirm_cancel')
            )
        end

        if not confirmed then cb({ success = false, cancelled = true }) return end

        local result = lib.callback.await('ls_trucking:server:purchaseContractorVehicle', false, vehicleType, vehicleIndex)
        Notify(result and result.message or 'Contractor vehicle purchase processed.', result and result.success and 'success' or 'error')
        Ctx().RefreshDispatchUI(650, 2)
        cb(result or { success = false })
    end)

    RegisterNUICallback('sellContractorVehicle', function(data, cb)
        local vehicleId = data and tonumber(data.vehicleId) or 0
        if vehicleId <= 0 then cb({ success = false }) return end

        local confirmed = data and data.confirmed == true
        if not confirmed then
            confirmed = Ctx().ShowFreightConfirm(
                T('contractor.sale_confirm_title'),
                T('contractor.sale_confirm_body', {
                    original = data and data.originalPrice or 0,
                    mileage = ('%.1f'):format(data and tonumber(data.mileage) or 0),
                    resale = data and data.resalePrice or 0
                }),
                T('contractor.sale_confirm_accept'),
                T('contractor.sale_confirm_cancel')
            )
        end

        if not confirmed then cb({ success = false, cancelled = true }) return end

        local result = lib.callback.await('ls_trucking:server:sellContractorVehicle', false, vehicleId)
        Notify(result and result.message or 'Contractor vehicle sale could not be completed.', result and result.success and 'success' or 'error')
        Ctx().RefreshDispatchUI(250, 2)
        cb(result or { success = false })
    end)

    RegisterNUICallback('spawnContractorVehicle', function(data, cb)
        local ctx = Ctx()
        if ctx.GetActiveContract() then Notify('You cannot spawn a contractor vehicle while on a job.', 'error') cb({ success = false }) return end

        local spawnedVehicle = ctx.GetSpawnedVehicle()
        if spawnedVehicle and DoesEntityExist(spawnedVehicle) then Notify('You already have a vehicle out. Store or return it first.', 'error') cb({ success = false }) return end
        if not data or not data.vehicleId then cb({ success = false }) return end
        if not ctx.RequireNearDepotRequestArea('You need to be closer to the contractor vehicle pickup area.') then cb({ success = false }) return end
        if not ctx.Progress('Requesting contractor vehicle...', Config.Progress.spawnGarageVehicle, { dict = 'missheistdockssetup1clipboard@base', clip = 'base' }) then cb({ success = false }) return end

        local result = lib.callback.await('ls_trucking:server:spawnContractorVehicle', false, data.vehicleId)
        if (not result or not result.success) and ctx.IsStaleVehicleCheckoutMessage(result) and ctx.TryReleaseStaleVehicleCheckout() then
            result = lib.callback.await('ls_trucking:server:spawnContractorVehicle', false, data.vehicleId)
        end
        if not result or not result.success then Notify(result and result.message or 'Unable to spawn contractor vehicle.', 'error') cb({ success = false }) return end

        if not ctx.SpawnContractorVehicle(result) then
            lib.callback.await('ls_trucking:server:releaseStaleVehicleCheckout', false)
            cb({ success = false })
            return
        end

        ctx.CloseDispatch()
        cb({ success = true })
    end)

    RegisterNUICallback('storeContractorVehicle', function(_, cb)
        local ctx = Ctx()
        ctx.CloseDispatch()
        ctx.StoreContractorVehicle()
        cb(true)
    end)

    RegisterNUICallback('startContractorContract', function(data, cb)
        local ctx = Ctx()
        if ctx.GetActiveContract() then Notify('You already have an active job. Cancel it from the Current Job panel first.', 'error') cb({ success = false }) return end

        local contractorVehicle = ctx.GetContractorVehicle()
        local spawnedVehicle = ctx.GetSpawnedVehicle()
        if not contractorVehicle or not contractorVehicle.id or not spawnedVehicle or not DoesEntityExist(spawnedVehicle) then
            Notify('Spawn your contractor vehicle before accepting private contracts.', 'error')
            cb({ success = false })
            return
        end

        local state = ctx.BuildCurrentVehicleState()
        if not state then Notify('Could not read contractor vehicle state.', 'error') cb({ success = false }) return end

        local vehicleId = data and tonumber(data.vehicleId) or nil
        if not vehicleId or vehicleId <= 0 then vehicleId = contractorVehicle.id end

        local routeIndex = data and tonumber(data.routeIndex) or nil
        if routeIndex and routeIndex <= 0 then routeIndex = nil end

        if not ctx.BeginContractRequest('Private contract request transmitted. Dispatch is validating unit condition, authority, and route availability.') then cb({ success = false }) return end
        local result = lib.callback.await('ls_trucking:server:createContractorContract', false, vehicleId, data and data.priorityKey or 'standard', routeIndex, state, data and data.dailyRouteKey, data and data.pickupDepotKey)
        ctx.ResolveContractRequest(result, result and result.success and ('Dispatch approved %s. Private contract %s confirmed. GPS authorized.'):format(result.contract and result.contract.routeLabel or 'the selected route', result.contractId or 'pending') or nil)
        if not result or not result.success then cb({ success = false }) return end

        if not ctx.StartLocalContract(result, true) then
            ctx.RefreshDispatchUI(650, 2)
            cb({ success = false })
            return
        end

        ctx.CloseDispatch()
        cb({ success = true })
    end)
end

LS_Trucking.ContractorUI = ContractorUI
