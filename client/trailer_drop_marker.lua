LS_Trucking = LS_Trucking or {}

local TrailerDropMarker = {}
local clientContext = {}
local settleStartedAt = 0
local confirmPending = false
local retryAfter = 0

local function Ctx()
    return clientContext or {}
end

local function Call(name, ...)
    local fn = Ctx()[name]
    if fn then return fn(...) end
    return nil
end

local function HorizontalDistance(left, right)
    local dx = (left.x or 0.0) - (right.x or 0.0)
    local dy = (left.y or 0.0) - (right.y or 0.0)
    return math.sqrt((dx * dx) + (dy * dy))
end

local function MarkerColor(state)
    local colors = (Config.TrailerDropMarker or {}).Colors or {}
    if state == 'detached' then return colors.Detached or { r = 235, g = 240, b = 238 } end
    if state == 'centered' then return colors.Centered or { r = 76, g = 220, b = 105 } end
    if state == 'inside' then return colors.Inside or { r = 242, g = 180, b = 45 } end
    return colors.Outside or { r = 220, g = 55, b = 48 }
end

local function ResetPlacementState()
    settleStartedAt = 0
    confirmPending = false
end

local function IsTrailerAtReleasePoint(active, trailer)
    if not active or not trailer or not DoesEntityExist(trailer) then return false end
    if not active.trailerDrop or not active.trailerDrop.coords then return false end

    local marker = Config.TrailerDropMarker or {}
    local trailerCoords = GetEntityCoords(trailer)
    local distance = HorizontalDistance(trailerCoords, active.trailerDrop.coords)
    return distance <= math.max(0.5, tonumber(marker.PositionTolerance) or 1.40)
end

local function ConfirmPlacedTrailer(active, trailer)
    if confirmPending or GetGameTimer() < retryAfter then return end
    confirmPending = true

    local netId = NetworkGetNetworkIdFromEntity(trailer)
    local result = lib.callback.await('ls_trucking:server:confirmTrailerDropped', false, netId)

    if not result or not result.success then
        confirmPending = false
        settleStartedAt = 0
        retryAfter = GetGameTimer() + 4000
        Call('Notify', result and result.message or 'The receiving yard could not verify the trailer placement.', 'error')
        return
    end

    if not active or active ~= Call('GetActiveContract') then
        ResetPlacementState()
        return
    end

    active.trailerDropped = true
    active.stage = 'Talk to receiver'
    active.notice = 'Trailer placement accepted. Talk to the receiving yard worker to finalize the delivery.'

    local receiver = active.receiverPed
    if receiver and receiver.coords then
        local receiverCoords = vector3(receiver.coords.x, receiver.coords.y, receiver.coords.z)
        Call('SetActiveDestination', receiver.label or 'Receiving Clerk', receiverCoords)
        Call('CreateRouteBlip', receiverCoords, receiver.label or 'Receiving Clerk', 'receiver')
    end

    Call('Notify', 'Trailer placement accepted. Complete the receiver paperwork.', 'success')
    Call('DispatchChatter', 'Trailer detached and accepted by the receiving yard. Receiver paperwork is ready for signature.', 'inform', 'secure', { direction = 'rx' })
    Call('UpdateMiniUI')
    ResetPlacementState()
end

CreateThread(function()
    while true do
        local waitTime = 750
        local marker = Config.TrailerDropMarker or {}
        local active = Call('GetActiveContract')

        if marker.Enabled ~= false
            and active
            and active.type == 'trailer'
            and active.trailerHooked
            and not active.trailerDropped
            and active.trailerDrop
            and active.trailerDrop.coords then
            local dropCoords = active.trailerDrop.coords
            local playerCoords = GetEntityCoords(PlayerPedId())
            local playerDistance = #(playerCoords - vector3(dropCoords.x, dropCoords.y, dropCoords.z))
            local drawDistance = math.max(20.0, tonumber(marker.DrawDistance) or 120.0)

            if playerDistance <= drawDistance then
                waitTime = 0

                local trailer = Call('GetSpawnedTrailer')
                local state = 'outside'

                if trailer and DoesEntityExist(trailer) then
                    local trailerCoords = GetEntityCoords(trailer)
                    local markerDistance = HorizontalDistance(trailerCoords, dropCoords)
                    local inside = markerDistance <= (math.max(1.0, tonumber(marker.Size) or 6.0) * 0.5)
                    local centered = markerDistance <= math.max(0.5, tonumber(marker.PositionTolerance) or 1.40)

                    if inside then
                        state = 'inside'
                    end

                    if centered then
                        local attached = Call('IsAssignedTrailerAttached') == true
                        local moving = GetEntitySpeed(trailer) > math.max(0.01, tonumber(marker.MaxSettleSpeed) or 0.15)
                        state = attached and 'centered' or 'detached'

                        if not attached and not moving then
                            if settleStartedAt == 0 then settleStartedAt = GetGameTimer() end
                            if GetGameTimer() - settleStartedAt >= math.max(250, tonumber(marker.SettleTime) or 2000) then
                                ConfirmPlacedTrailer(active, trailer)
                            end
                        else
                            settleStartedAt = 0
                        end
                    else
                        settleStartedAt = 0
                    end
                else
                    settleStartedAt = 0
                end

                local color = MarkerColor(state)
                local size = math.max(1.0, tonumber(marker.Size) or 6.0)
                DrawMarker(
                    tonumber(marker.MarkerType) or 1,
                    dropCoords.x, dropCoords.y, dropCoords.z + (tonumber(marker.ZOffset) or -0.65),
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    size, size, math.max(0.05, tonumber(marker.Height) or 0.24),
                    color.r or 255, color.g or 255, color.b or 255, tonumber(marker.Alpha) or 115,
                    false, false, 2, false, nil, nil, false
                )
            else
                ResetPlacementState()
                waitTime = 350
            end
        else
            ResetPlacementState()
        end

        Wait(waitTime)
    end
end)

-- GTA uses the headlight control's hold action to detach trailers. Once the
-- contract connection is secured, release is handled by the yard target only.
CreateThread(function()
    while true do
        local waitTime = 350
        local marker = Config.TrailerDropMarker or {}
        local active = Call('GetActiveContract')
        local checklist = active and active.loadChecklist or {}

        if marker.Enabled ~= false
            and active
            and active.type == 'trailer'
            and not active.trailerDropped
            and checklist.truckSecure == true
            and Call('IsAssignedTrailerAttached') == true then
            DisableControlAction(0, 74, true)
            DisableControlAction(2, 74, true)
            waitTime = 0
        end

        Wait(waitTime)
    end
end)

function TrailerDropMarker.CanDisconnectTrailer()
    local marker = Config.TrailerDropMarker or {}
    local active = Call('GetActiveContract')
    local checklist = active and active.loadChecklist or {}
    local trailer = Call('GetSpawnedTrailer')

    return marker.Enabled ~= false
        and active ~= nil
        and active.type == 'trailer'
        and active.trailerHooked == true
        and active.trailerDropped ~= true
        and active.trailerConnectionLost ~= true
        and checklist.truckSecure == true
        and Call('IsAssignedTrailerAttached') == true
        and IsTrailerAtReleasePoint(active, trailer)
end

function TrailerDropMarker.DisconnectTrailer()
    if not TrailerDropMarker.CanDisconnectTrailer() then
        Call('Notify', 'Position the secured trailer inside the receiving marker before disconnecting.', 'error')
        return false
    end

    local vehicle = Call('GetSpawnedVehicle')
    if not vehicle or not DoesEntityExist(vehicle) then
        Call('Notify', 'The assigned contract vehicle could not be found.', 'error')
        return false
    end

    DetachVehicleFromTrailer(vehicle)
    return true
end

function TrailerDropMarker.ConfigureClient(context)
    clientContext = context or {}
end

LS_Trucking.TrailerDropMarker = TrailerDropMarker
