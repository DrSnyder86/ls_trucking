LS_Trucking = LS_Trucking or {}

local DeliveryInteraction = {}
local clientContext = {}
local promptVisible = false
local promptText = nil
local deliveryPending = false

local function Ctx()
    return clientContext or {}
end

local function Call(name, ...)
    local fn = Ctx()[name]
    if fn then return fn(...) end
    return nil
end

local function GetTextUIState()
    if not lib or not lib.isTextUIOpen then return nil, nil end

    local ok, isOpen, text = pcall(lib.isTextUIOpen)
    if not ok then return nil, nil end
    return isOpen == true, text
end

local function HidePrompt()
    if not promptVisible then return end

    local ownedText = promptText
    promptVisible = false
    promptText = nil

    if not lib or not lib.hideTextUI then return end

    local isOpen, currentText = GetTextUIState()
    if isOpen == nil or (isOpen and currentText == ownedText) then
        pcall(lib.hideTextUI)
    end
end

local function ShowPrompt(text, icon)
    if not lib or not lib.showTextUI then return end

    local isOpen, currentText = GetTextUIState()
    if promptVisible and promptText == text and (isOpen == nil or (isOpen and currentText == text)) then return end

    if isOpen and currentText ~= text then
        promptVisible = false
        promptText = nil
        return
    end

    local ok = pcall(lib.showTextUI, text, {
        icon = icon,
        position = 'left-center'
    })

    if ok then
        promptVisible = true
        promptText = text
    end
end

local function DrawDeliveryMarker(marker, actionable)
    local cfg = Config.DropoffTarget or {}
    local size = math.max(0.5, tonumber(cfg.MarkerSize) or 1.35)
    local color = actionable
        and { r = 76, g = 220, b = 105 }
        or { r = 242, g = 180, b = 45 }

    DrawMarker(
        tonumber(cfg.MarkerType) or 1,
        marker.coords.x, marker.coords.y, marker.coords.z + (tonumber(cfg.MarkerZOffset) or -0.65),
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        size, size, math.max(0.05, tonumber(cfg.MarkerHeight) or 0.18),
        color.r, color.g, color.b, tonumber(cfg.MarkerAlpha) or 145,
        false, false, 2, false, nil, nil, false
    )
end

local function BuildMarkerState()
    local active = Call('GetActiveContract')
    if not active then return nil end

    if active.type == 'van' or active.type == 'boxtruck' then
        if active.loaded ~= true then return nil end

        local stop = active.dropoffs and active.dropoffs[tonumber(active.currentStop) or 0]
        if not stop or not stop.coords then return nil end

        local cfg = Config.DropoffTarget or {}
        local canDeliver = Call('CanDeliverCargo') == true
        local coords = vector3(
            stop.coords.x + 0.0,
            stop.coords.y + 0.0,
            stop.coords.z + 0.0
        )
        return {
            coords = coords,
            drawDistance = math.max(15.0, tonumber(cfg.MarkerDrawDistance) or 55.0),
            interactionDistance = math.max(1.0, tonumber(cfg.Distance) or tonumber(cfg.Radius) or 3.5),
            canDeliver = canDeliver,
            prompt = active.type == 'boxtruck'
                and T('delivery_interaction.unload_crate')
                or T('delivery_interaction.deliver_package'),
            promptIcon = active.type == 'boxtruck' and 'dolly' or 'box'
        }
    end

    return nil
end

CreateThread(function()
    while true do
        local sleep = 500
        local marker = BuildMarkerState()

        if marker then
            local playerCoords = GetEntityCoords(PlayerPedId())
            local distance = #(playerCoords - marker.coords)
            local uiBlocked = Call('IsDeliveryInteractionBlocked') == true
                or (IsNuiFocused and IsNuiFocused())
            local blocked = uiBlocked or IsPedInAnyVehicle(PlayerPedId(), false)
            local actionable = marker.canDeliver
                and not blocked
                and distance <= marker.interactionDistance

            if distance <= marker.drawDistance and not uiBlocked then
                sleep = 0
                DrawDeliveryMarker(marker, actionable)
            end

            if actionable then
                sleep = 0
                ShowPrompt(marker.prompt, marker.promptIcon)
                DisableControlAction(0, 38, true)

                if not deliveryPending and IsDisabledControlJustReleased(0, 38) then
                    deliveryPending = true
                    HidePrompt()
                    Call('DeliverCurrentCargo')
                    deliveryPending = false
                end
            else
                HidePrompt()
            end
        else
            HidePrompt()
        end

        Wait(sleep)
    end
end)

function DeliveryInteraction.ConfigureClient(context)
    clientContext = context or {}
end

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    HidePrompt()
end)

LS_Trucking.DeliveryInteraction = DeliveryInteraction
