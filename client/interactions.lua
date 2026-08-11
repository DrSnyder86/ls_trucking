LS_Trucking = LS_Trucking or {}

local Interactions = {}
local nativeEntities = {}
local nativeZones = {}
local promptVisible = false
local promptText = nil
local interactionPending = false
local diagnosticUntil = 0

local function ResourceStarted(resource)
    return type(resource) == 'string' and resource ~= '' and GetResourceState(resource) == 'started'
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
    if not lib or not lib.showTextUI then return false end

    local isOpen, currentText = GetTextUIState()
    if isOpen and promptVisible and currentText ~= promptText then
        promptVisible = false
        promptText = nil
    end

    if isOpen and currentText == text then
        promptVisible = true
        promptText = text
        return true
    end

    if promptVisible and promptText == text and isOpen == nil then return true end

    if promptVisible then HidePrompt() end
    local ok = pcall(lib.showTextUI, text, {
        icon = icon,
        position = 'left-center'
    })

    if ok then
        promptVisible = true
        promptText = text
    end

    return ok
end

local function OptionDistance(option)
    return math.max(0.5, tonumber(option and option.distance) or tonumber(Config.TargetDistance) or 2.5)
end

local function CanInteract(option, entity, distance, coords)
    if type(option.canInteract) ~= 'function' then return true end
    local ok, allowed = pcall(option.canInteract, entity, distance, { coords = coords })
    return ok and allowed == true
end

local function AvailableEntityOptions(entry, playerCoords, distance)
    local available = {}
    for _, option in ipairs(entry.options or {}) do
        if distance <= OptionDistance(option) and CanInteract(option, entry.entity, distance, playerCoords) then
            available[#available + 1] = option
        end
    end
    return available
end

local function AvailableZoneOptions(entry, playerCoords, distance)
    local available = {}
    if distance > entry.radius then return available end

    for _, option in ipairs(entry.options or {}) do
        if CanInteract(option, nil, distance, playerCoords) then
            available[#available + 1] = option
        end
    end
    return available
end

local function FindInteraction(playerCoords)
    local closest = nil
    local closestDistance = math.huge

    for entity, entry in pairs(nativeEntities) do
        if not DoesEntityExist(entity) then
            nativeEntities[entity] = nil
        else
            local coords = GetEntityCoords(entity)
            local distance = #(playerCoords - coords)
            local options = AvailableEntityOptions(entry, playerCoords, distance)
            if #options > 0 and distance < closestDistance then
                closestDistance = distance
                closest = { entity = entity, coords = coords, distance = distance, options = options }
            end
        end
    end

    for _, entry in pairs(nativeZones) do
        local distance = #(playerCoords - entry.coords)
        local options = AvailableZoneOptions(entry, playerCoords, distance)
        if #options > 0 and distance < closestDistance then
            closestDistance = distance
            closest = { coords = entry.coords, distance = distance, options = options }
        end
    end

    return closest
end

local function ExecuteOption(option, interaction)
    if not option or interactionPending then return end
    interactionPending = true
    HidePrompt()

    local ok, err = pcall(function()
        if type(option.onSelect) == 'function' then
            option.onSelect({ entity = interaction.entity, coords = interaction.coords })
        elseif type(option.action) == 'function' then
            option.action(interaction.entity)
        end
    end)

    interactionPending = false
    if not ok and Config.Debug then
        print(('[ls_trucking:interactions] %s'):format(err))
    end
end

local function OpenOptionMenu(interaction)
    if not lib or not lib.registerContext or not lib.showContext then
        ExecuteOption(interaction.options[1], interaction)
        return
    end

    local options = {}
    for _, option in ipairs(interaction.options) do
        local selectedOption = option
        options[#options + 1] = {
            title = selectedOption.label or selectedOption.name or 'Interact',
            icon = selectedOption.icon,
            onSelect = function() ExecuteOption(selectedOption, interaction) end
        }
    end

    lib.registerContext({
        id = 'ls_trucking_native_interactions',
        title = (Config.Notifications and Config.Notifications.Title) or 'Los Santos Freight Co.',
        options = options
    })
    lib.showContext('ls_trucking_native_interactions')
end

function Interactions.GetSystem()
    local configured = tostring(Config.TargetSystem or (Config.Target and Config.Target.System) or 'auto'):lower()

    if configured == 'ox' or configured == 'ox_target' then
        return ResourceStarted('ox_target') and 'ox' or 'native'
    end

    if configured == 'qb' or configured == 'qb-target' then
        return ResourceStarted('qb-target') and 'qb' or 'native'
    end

    if configured == 'native' or configured == 'textui' or configured == 'ox_lib' or configured == 'none' then
        return 'native'
    end

    if ResourceStarted('ox_target') then return 'ox' end
    if ResourceStarted('qb-target') then return 'qb' end
    return 'native'
end

function Interactions.AddEntity(entity, options)
    if not entity or entity == 0 then return nil end
    nativeEntities[entity] = { entity = entity, options = options or {} }
    return entity
end

function Interactions.RemoveEntity(entity)
    if entity then nativeEntities[entity] = nil end
end

function Interactions.AddSphereZone(name, coords, radius, options)
    if not name or not coords then return nil end
    nativeZones[name] = {
        name = name,
        coords = vector3(coords.x, coords.y, coords.z),
        radius = math.max(0.5, tonumber(radius) or 2.0),
        options = options or {}
    }
    return name
end

function Interactions.RemoveZone(name)
    if name then nativeZones[name] = nil end
end

function Interactions.Clear()
    nativeEntities = {}
    nativeZones = {}
    HidePrompt()
end

local function CountEntries(entries)
    local count = 0
    for _ in pairs(entries) do count = count + 1 end
    return count
end

local function GetBlockedReason(ped)
    if IsEntityDead(ped) then return 'player dead' end
    if IsPedInAnyVehicle(ped, false) then return 'player in vehicle' end
    if IsPauseMenuActive() then return 'pause menu active' end
    if IsNuiFocused and IsNuiFocused() then return 'NUI focused' end
    return 'none'
end

function Interactions.RunDiagnostic()
    local ped = PlayerPedId()
    local playerCoords = GetEntityCoords(ped)
    local nearest = FindInteraction(playerCoords)
    local isOpen, currentText = GetTextUIState()
    local configured = tostring(Config.TargetSystem or (Config.Target and Config.Target.System) or 'auto'):lower()
    local hasTextUI = lib and type(lib.showTextUI) == 'function' and type(lib.hideTextUI) == 'function'
    local status = table.concat({
        ('configured=%s'):format(configured),
        ('active=%s'):format(Interactions.GetSystem()),
        ('textui=%s'):format(hasTextUI and 'ready' or 'missing'),
        ('entities=%s'):format(CountEntries(nativeEntities)),
        ('zones=%s'):format(CountEntries(nativeZones)),
        ('blocked=%s'):format(GetBlockedReason(ped)),
        ('nearest=%s'):format(nearest and ('%.2fm/%s option(s)'):format(nearest.distance, #nearest.options) or 'none'),
        ('openText=%s'):format(isOpen and tostring(currentText) or 'none')
    }, ' | ')

    print(('[ls_trucking:interactions] %s'):format(status))
    TriggerEvent('chat:addMessage', {
        color = { 87, 242, 135 },
        args = { 'LSFC Interaction Test', status }
    })

    if lib and lib.notify then
        lib.notify({
            title = 'LSFC Interaction Test',
            description = status,
            type = hasTextUI and 'inform' or 'error',
            duration = 10000
        })
    end

    if not hasTextUI then return false end

    diagnosticUntil = GetGameTimer() + 5000
    HidePrompt()

    local testText = '[E] LSFC TextUI diagnostic'
    local ok, err = pcall(lib.showTextUI, testText, {
        icon = 'truck-fast',
        position = 'left-center'
    })

    if not ok then
        print(('[ls_trucking:interactions] TextUI call failed: %s'):format(err))
        return false
    end

    promptVisible = true
    promptText = testText
    SetTimeout(5000, function()
        if promptText == testText then HidePrompt() end
    end)
    return true
end

CreateThread(function()
    while true do
        local sleep = 500

        if diagnosticUntil > GetGameTimer() then
            sleep = 100
        elseif Interactions.GetSystem() == 'native' and (next(nativeEntities) or next(nativeZones)) then
            local ped = PlayerPedId()
            local blocked = IsEntityDead(ped)
                or IsPedInAnyVehicle(ped, false)
                or IsPauseMenuActive()
                or (IsNuiFocused and IsNuiFocused())

            if not blocked then
                local interaction = FindInteraction(GetEntityCoords(ped))
                if interaction then
                    local option = interaction.options[1]
                    local text = #interaction.options == 1
                        and T('interactions.prompt', { label = option.label or option.name or T('interactions.action') })
                        or T('interactions.multiple')

                    if ShowPrompt(text, option.icon or 'hand-pointer') then
                        sleep = 0
                        DisableControlAction(0, 38, true)
                        if IsDisabledControlJustReleased(0, 38) then
                            if #interaction.options == 1 then
                                ExecuteOption(option, interaction)
                            else
                                HidePrompt()
                                OpenOptionMenu(interaction)
                            end
                        end
                    else
                        sleep = 100
                    end
                else
                    HidePrompt()
                    sleep = 200
                end
            else
                HidePrompt()
                sleep = 100
            end
        else
            HidePrompt()
        end

        Wait(sleep)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    Interactions.Clear()
end)

LS_Trucking.Interactions = Interactions

RegisterCommand('lsinteractiontest', function()
    Interactions.RunDiagnostic()
end, false)

CreateThread(function()
    Wait(1000)
    local configured = tostring(Config.TargetSystem or (Config.Target and Config.Target.System) or 'auto'):lower()
    local hasTextUI = lib and type(lib.showTextUI) == 'function' and 'ready' or 'missing'
    print(('[ls_trucking:interactions] Provider loaded | configured=%s | active=%s | ox_lib TextUI=%s'):format(
        configured,
        Interactions.GetSystem(),
        hasTextUI
    ))
end)
