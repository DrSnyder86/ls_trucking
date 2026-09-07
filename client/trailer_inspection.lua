LS_Trucking = LS_Trucking or {}

local Inspection = {}
local ctx = {}
local session
local sequence = 0
local submitting = false

local function Text(key)
    return T('inspection.' .. key)
end

local function ValidContract(contract)
    return contract and ctx.GetActiveContract() == contract and contract.type == 'trailer'
end

local function Reconnecting(contract)
    return contract.trailerHooked == true and contract.trailerConnectionLost == true
end

local function VehicleReady(contract)
    local truck, trailer = ctx.GetVehicle(), ctx.GetTrailer()
    return ValidContract(contract)
        and truck and trailer and DoesEntityExist(truck) and DoesEntityExist(trailer)
        and ctx.IsAssignedTrailerAttached()
        and GetEntitySpeed(truck) <= 0.5 and GetEntitySpeed(trailer) <= 0.5
        and not IsEntityDead(PlayerPedId())
end

local function ValidSession(current)
    return session == current and VehicleReady(current.contract)
        and not IsPedInAnyVehicle(PlayerPedId(), false)
        and #(GetEntityCoords(PlayerPedId()) - current.origin) <= 4.0
        and #(GetEntityCoords(ctx.GetVehicle()) - current.truckOrigin) <= 2.0
end

local function Publish(current)
    if session ~= current then return end
    local checklist = current.contract.loadChecklist or {}
    local ready = checklist.truckSecure == true and checklist.trailerSecure == true
    local receiver = (Config.LoadVerificationMode or 'receiver') == 'receiver'
    local rows = {}
    for _, step in ipairs({ { 'truckSecure', 'connection' }, { 'trailerSecure', 'cargo' } }) do
        if not current.reconnecting or step[1] == 'truckSecure' then
            local state = checklist[step[1]] and 'complete' or current.step == step[1] and 'running' or 'pending'
            rows[#rows + 1] = { label = Text(step[2]), state = state, status = Text(state) }
        end
    end
    SendNUIMessage({
        action = 'showTrailerInspection', locale = Config.Locale or 'en', token = current.token,
        title = Text('title'), trailer = current.contract.trailerLabel or Text('assigned'),
        rows = rows, busy = current.busy == true,
        message = current.message or (ready and receiver and Text('receiver_ready') or Text('intro')),
        primaryAction = ready and not current.reconnecting and (receiver and 'close' or 'submit') or 'begin',
        primaryLabel = ready and not current.reconnecting and (receiver and Text('close') or Text('submit')) or Text('begin'),
        closeLabel = current.busy and Text('cancel') or Text('close')
    })
end

function Inspection.IsOpen()
    return session ~= nil
end

local function InvalidateDisconnectedLoad(contract)
    if not ValidContract(contract) or ctx.IsAssignedTrailerAttached() then return end
    local checklist = contract.loadChecklist or {}
    local changed = checklist.truckSecure == true or contract.trailerAttached ~= false
    checklist.truckSecure = false
    contract.trailerAttached = false
    if contract.trailerHooked then contract.trailerConnectionLost = true end
    if changed then
        contract.stage = 'Reconnect trailer'
        contract.notice = Text('reconnect')
        ctx.UpdateMiniUI()
    end
end

function Inspection.Close()
    local current = session
    if not current then return end
    InvalidateDisconnectedLoad(current.contract)
    session = nil
    if current.progress and lib.progressActive() then lib.cancelProgress() end
    SendNUIMessage({ action = 'hideFreightDialog' })
    ctx.ReleaseFocus()
end

function Inspection.CanInspect()
    local contract = ctx.GetActiveContract()
    return not session and not submitting and not lib.progressActive() and contract ~= nil and contract.type == 'trailer'
        and (not contract.trailerHooked or Reconnecting(contract))
        and ctx.IsAssignedTrailerAttached()
end

function Inspection.Open()
    if not Inspection.CanInspect() then return false end
    local contract = ctx.GetActiveContract()
    if not VehicleReady(contract) or IsPedInAnyVehicle(PlayerPedId(), false) then
        ctx.Notify(Text('unavailable'), 'error')
        return false
    end
    sequence = sequence + 1
    contract.loadChecklist = contract.loadChecklist or { truckSecure = false, trailerSecure = false }
    local current = {
        token = sequence, contract = contract, origin = GetEntityCoords(PlayerPedId()),
        truckOrigin = GetEntityCoords(ctx.GetVehicle()),
        reconnecting = Reconnecting(contract)
    }
    session = current
    ctx.TakeFocus()
    Publish(current)
    CreateThread(function()
        while session == current do
            if not ValidSession(current) then
                Inspection.Close()
                ctx.Notify(Text('interrupted'), 'warning')
                break
            end
            Wait(150)
        end
    end)
    return true
end

local function RunProgress(current, label, duration, anim, prop)
    if not ValidSession(current) or lib.progressActive() then return false end
    current.progress = true
    local completed = ctx.Progress(label, duration, anim, prop)
    current.progress = false
    InvalidateDisconnectedLoad(current.contract)
    return completed == true and ValidSession(current)
end

local function RunChecks(current)
    current.busy = true
    current.message = Text('working')
    for _, step in ipairs({
        { key = 'truckSecure', label = 'connection', duration = Config.Progress.secureTruckLoad or 3000 },
        { key = 'trailerSecure', label = 'cargo', duration = Config.Progress.secureTrailerLoad or 3000 }
    }) do
        if not current.contract.loadChecklist[step.key] and (not current.reconnecting or step.key == 'truckSecure') then
            current.step = step.key
            Publish(current)
            if not RunProgress(current, Text(step.label), step.duration, { dict = 'mini@repair', clip = 'fixing_a_ped' }) then
                current.busy, current.step = false, nil
                current.message = Text('interrupted')
                Publish(current)
                return false
            end
            current.contract.loadChecklist[step.key] = true
            current.step = nil
            ctx.PlayUISound(step.key == 'truckSecure' and 'trailerConnect' or 'secure')
            ctx.UpdateMiniUI()
            Publish(current)
        end
    end
    if not ValidSession(current) then return false end
    local contract = current.contract
    if current.reconnecting then
        contract.trailerConnectionLost = false
        contract.trailerAttached, contract.loaded = true, true
        contract.stage = 'Deliver trailer'
        contract.notice = Text('reconnected')
        ctx.SetActiveDestination(contract.trailerDrop.label, contract.trailerDrop.coords)
        ctx.DispatchChatter(Text('reconnected'), 'success', 'secure', { notify = false })
        Inspection.Close()
    else
        contract.stage = 'Complete load checklist'
        contract.notice = Text((Config.LoadVerificationMode or 'receiver') == 'receiver' and 'receiver_ready' or 'target_ready')
        ctx.SetActiveDestination(Text('submit'))
        ctx.DispatchChatter(contract.notice, 'success', 'secure', { notify = false })
        current.busy, current.step = false, nil
        current.message = contract.notice
        Publish(current)
    end
    ctx.UpdateMiniUI()
    return true
end

function Inspection.Submit(fromReceiver)
    local contract = ctx.GetActiveContract()
    local current = not fromReceiver and session or nil
    if submitting or (session and (fromReceiver or session.busy)) then return false end
    if not VehicleReady(contract) or contract.trailerHooked
        or (not fromReceiver and (not current or not ValidSession(current))) then
        ctx.Notify(Text('unavailable'), 'error')
        return false
    end
    if fromReceiver and #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(ctx.GetVehicle())) > 8.0 then return false end
    local checklist = contract.loadChecklist or {}
    if not checklist.truckSecure or not checklist.trailerSecure then
        ctx.Notify(Text('incomplete'), 'error')
        return false
    end
    submitting = true
    if current then
        current.busy, current.message = true, Text('submitting')
        Publish(current)
    end

    local function Finish(success)
        submitting = false
        if current and session == current then
            current.busy = false
            if success then Inspection.Close() else
                current.message = Text('submit_failed')
                Publish(current)
            end
        end
        return success
    end

    if fromReceiver then
        ctx.DispatchChatter(Text('submitting'), 'inform', 'secure', { direction = 'tx', notify = false })
        local exchange = Config.DispatchExchange or {}
        if exchange.Enabled ~= false then Wait(math.max(0, tonumber(exchange.RequestDelay) or 1250)) end
    elseif not RunProgress(current, Text('submitting'), Config.Progress.completeLoadChecklist or 2500,
        { dict = 'missheistdockssetup1clipboard@base', clip = 'base' },
        { model = GetHashKey('p_amb_clipboard_01'), bone = 18905, pos = vec3(0.10, 0.02, 0.08), rot = vec3(-80.0, 0.0, 0.0) }) then
        return Finish(false)
    end

    if not VehicleReady(contract) or (current and not ValidSession(current))
        or not contract.loadChecklist.truckSecure or not contract.loadChecklist.trailerSecure then return Finish(false) end
    local result = lib.callback.await('ls_trucking:server:markTrailerHooked', false, contract.contractId)
    if not ValidContract(contract) then return Finish(false) end
    if not result or not result.success then
        ctx.Notify(result and result.message or Text('submit_failed'), 'error')
        return Finish(false)
    end

    -- Record accepted server clearance even if the UI closed while the callback was pending.
    local attached = ctx.IsAssignedTrailerAttached() and contract.loadChecklist.truckSecure == true
    contract.trailerHooked, contract.loaded = true, true
    contract.trailerAttached, contract.trailerConnectionLost = attached, not attached
    if not attached then contract.loadChecklist.truckSecure = false end
    contract.stage = attached and 'Deliver trailer' or 'Reconnect trailer'
    contract.notice = Text(attached and 'cleared' or 'reconnect')
    ctx.SetExpectedCompletionTime()
    ctx.SetActiveDestination(contract.trailerDrop.label, contract.trailerDrop.coords)
    ctx.CreateRouteBlip(contract.trailerDrop.coords, contract.trailerDrop.label, 'trailer')
    ctx.CreateRouteAreaBlip(contract.trailerDrop.coords, contract.trailerDrop.radius, 'TrailerDrop')
    ctx.DispatchChatter(contract.notice, 'inform', 'secure', { notify = false })
    ctx.UpdateMiniUI()
    return Finish(true)
end

RegisterNUICallback('trailerInspectionAction', function(data, cb)
    local current = session
    if not current or type(data) ~= 'table' or data.token ~= current.token then cb(false) return end
    if data.action == 'close' then Inspection.Close() cb(true) return end
    if current.busy or submitting or not ValidSession(current) then cb(false) return end
    if data.action ~= 'begin' and data.action ~= 'submit' then cb(false) return end
    if data.action == 'submit' and (Config.LoadVerificationMode or 'receiver') ~= 'target' then cb(false) return end
    cb(true)
    -- Set busy synchronously so duplicate NUI clicks cannot start a second sequence.
    if data.action == 'begin' then
        current.busy = true
        CreateThread(function() RunChecks(current) end)
    else
        Inspection.Submit(false)
    end
end)

function Inspection.ConfigureClient(context)
    ctx = context
end

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then Inspection.Close() end
end)

LS_Trucking.TrailerInspection = Inspection
