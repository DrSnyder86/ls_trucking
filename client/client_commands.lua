LS_Trucking = LS_Trucking or {}

local function EnsureInteractionProvider()
    if LS_Trucking.Interactions then return true end

    local file = 'client/interactions.lua'
    local source = LoadResourceFile(GetCurrentResourceName(), file)
    if not source or source == '' then
        print(('[ls_trucking:client] Unable to load %s from the resource packfile.'):format(file))
        return false
    end

    local chunk, compileError = load(source, ('@%s/%s'):format(GetCurrentResourceName(), file), 't', _ENV)
    if not chunk then
        print(('[ls_trucking:client] Interaction provider compile error: %s'):format(compileError))
        return false
    end

    local ok, runtimeError = pcall(chunk)
    if not ok then
        print(('[ls_trucking:client] Interaction provider startup error: %s'):format(runtimeError))
        return false
    end

    print('[ls_trucking:client] Interaction provider loaded through client bootstrap.')
    return LS_Trucking.Interactions ~= nil
end

EnsureInteractionProvider()

local ClientCommands = {}
local clientContext = {}
local commandSuggestions = {}
local registered = false

local function Ctx()
    return clientContext or {}
end

local function Notify(message, notifyType)
    local ctx = Ctx()
    if ctx.Notify then ctx.Notify(message, notifyType) end
end

local function HasAdminPermission()
    local allowed = lib.callback.await('ls_trucking:server:canUseAdminCommand', false)
    if allowed then return true end

    Notify('You need admin permissions to use this LS Freight command.', 'error')
    return false
end

local function AddCommandSuggestion(command, help, params)
    command = tostring(command or ''):gsub('^/', '')
    if command == '' or commandSuggestions[command] then return end

    commandSuggestions[command] = true
    TriggerEvent('chat:addSuggestion', ('/%s'):format(command), help, params or {})
end

local function RegisterCommandSuggestions()
    AddCommandSuggestion(Config.Command or 'trucking', 'Open the Los Santos Freight Co. dispatch tablet.')

    local receiverCommand = Config.FullReceiverCommand or 'truckreceiver'
    AddCommandSuggestion(receiverCommand, 'Toggle the LS Freight handheld receiver.')

    if Config.MiniUIToggleCommand and Config.MiniUIToggleCommand ~= receiverCommand then
        AddCommandSuggestion(Config.MiniUIToggleCommand, 'Toggle the compact LS Freight route dock.')
    end

    AddCommandSuggestion(Config.CancelCommand or 'canceltrucking', 'Cancel your active LS Freight route.')
    AddCommandSuggestion('lsinteractiontest', 'Test the LSFC client interaction provider and ox_lib TextUI.')

    local showAdminCommands = lib.callback.await('ls_trucking:server:canUseAdminCommand', false) == true
    if not showAdminCommands then return end

    AddCommandSuggestion('lstruck_resetjob', 'Admin: force reset your active trucking job.')
    AddCommandSuggestion('lstruck_clearpeds', 'Admin: clear active contract worker peds.')
    AddCommandSuggestion('lstruck_giveitems', 'Admin: give yourself cargo items for the active route.')
    AddCommandSuggestion('lstruck_summary', 'Admin: open a route state summary.')
    AddCommandSuggestion('lstraileredit', 'Admin: open the trailer cargo prop editor.', {
        { name = 'trailerKey', help = 'Config.RouteTrailers key, for example flatbed_crates' }
    })
    AddCommandSuggestion('lstrailertest', 'Admin: spawn a configured trailer without starting a contract.', {
        { name = 'trailerKey', help = 'Config.RouteTrailers key, for example flatbed_crates' }
    })
    AddCommandSuggestion('lstrailerclear', 'Admin: remove the currently spawned trailer test unit.')
    AddCommandSuggestion('lstrolleytest', 'Admin: attach a freight trolley with a configured crate.', {
        { name = 'cargoType', help = 'Config.CargoTypes key, for example freight_crate' }
    })
    AddCommandSuggestion('lstrolleyclear', 'Admin: remove the trolley test unit.')
    AddCommandSuggestion('lstruck_rank', 'Admin: set trucking rank XP.', {
        { name = 'rank', help = 'Rank number to apply' }
    })
    AddCommandSuggestion('lstruck_rep', 'Admin: adjust trucking reputation.', {
        { name = 'amount', help = 'Reputation amount to add or remove' }
    })
    AddCommandSuggestion('lstruck_resetstats', 'Admin: reset your trucking stats.')
end

local function RegisterPublicCommands()
    local ctx = Ctx()
    local dispatchCommand = Config.Command or 'trucking'
    local receiverCommand = Config.FullReceiverCommand or 'truckreceiver'
    local cancelCommand = Config.CancelCommand or 'canceltrucking'

    RegisterCommand(dispatchCommand, function()
        if ctx.OpenDispatch then ctx.OpenDispatch() end
    end, false)

    RegisterCommand(receiverCommand, function()
        if ctx.ToggleFullReceiver then ctx.ToggleFullReceiver() end
    end, false)

    if Config.MiniUIToggleCommand and Config.MiniUIToggleCommand ~= receiverCommand then
        RegisterCommand(Config.MiniUIToggleCommand, function()
            if ctx.ToggleReceiverDock then ctx.ToggleReceiverDock() end
        end, false)
    end

    RegisterCommand(cancelCommand, function()
        if ctx.CancelActiveContract then ctx.CancelActiveContract() end
    end, false)

    RegisterCommand('lsinteractiontest', function()
        local interactions = LS_Trucking.Interactions or {}
        print(('[ls_trucking:client] Interaction command reached | provider=%s | textui=%s'):format(
            interactions.RunDiagnostic and 'ready' or 'missing',
            lib and type(lib.showTextUI) == 'function' and 'ready' or 'missing'
        ))

        if interactions.RunDiagnostic then
            interactions.RunDiagnostic()
            return
        end

        if not lib or type(lib.showTextUI) ~= 'function' then
            Notify('LSFC provider and ox_lib TextUI are unavailable.', 'error')
            return
        end

        local text = '[E] Direct ox_lib TextUI test'
        lib.showTextUI(text, { icon = 'truck-fast', position = 'left-center' })
        Notify('LSFC provider is missing. Running a direct ox_lib TextUI test for 5 seconds.', 'warning')
        SetTimeout(5000, function()
            local isOpen, currentText = lib.isTextUIOpen()
            if isOpen and currentText == text then lib.hideTextUI() end
        end)
    end, false)

    if RegisterKeyMapping and Config.DispatchKey then
        RegisterKeyMapping(dispatchCommand, 'Open Los Santos Freight dispatch', 'keyboard', Config.DispatchKey)
    end

    if RegisterKeyMapping and Config.FullReceiverKey then
        RegisterKeyMapping(receiverCommand, 'Toggle LS Freight handheld receiver', 'keyboard', Config.FullReceiverKey)
    end
end

local function RegisterAdminCommands()
    RegisterCommand('lstruck_resetjob', function()
        if not HasAdminPermission() then return end
        local ctx = Ctx()
        if ctx.ForceJobCleanup then
            ctx.ForceJobCleanup('Admin: active trucking job has been force reset.', false)
        end
    end, false)

    RegisterCommand('lstruck_clearpeds', function()
        if not HasAdminPermission() then return end
        local ctx = Ctx()
        if ctx.CleanupActiveContractPeds then ctx.CleanupActiveContractPeds(false) end
        Notify('Admin: active contract peds cleared.', 'success')
    end, false)

    RegisterCommand('lstruck_giveitems', function()
        if not HasAdminPermission() then return end
        TriggerServerEvent('ls_trucking:server:debugGiveItems')
    end, false)

    RegisterCommand('lstruck_summary', function()
        if not HasAdminPermission() then return end

        local ctx = Ctx()
        local activeContract = ctx.GetActiveContract and ctx.GetActiveContract() or nil
        if not activeContract then
            if ctx.ShowFreightDialog then
                ctx.ShowFreightDialog('Admin Route Summary', 'No active trucking contract.', 'Close')
            end
            return
        end

        if ctx.ShowFreightDialog then
            ctx.ShowFreightDialog('Admin Route Summary', {
                ('Contract ID: %s'):format(activeContract.contractId or 'N/A'),
                ('Type: %s'):format(activeContract.type or 'N/A'),
                ('Route: %s'):format(activeContract.routeLabel or activeContract.label or 'N/A'),
                ('Stage: %s'):format(activeContract.stage or 'N/A'),
                ('Vehicle: %s'):format(activeContract.vehicleLabel or 'N/A'),
                ('Plate: %s'):format(activeContract.plate or 'N/A'),
                ('Cargo: %s/%s'):format(activeContract.loadedCargo or 0, activeContract.requiredCargo or 0),
                ('Stop: %s/%s'):format(activeContract.currentStop or 0, activeContract.totalStops or 0),
                ('Trailer Hooked: %s'):format(tostring(activeContract.trailerHooked == true)),
                ('Trailer Dropped: %s'):format(tostring(activeContract.trailerDropped == true))
            }, 'Close')
        end
    end, false)

    RegisterCommand('lstraileredit', function(_, args)
        if not HasAdminPermission() then return end

        local trailerKey = args and args[1] or 'flatbed_crates'
        local editor = LS_Trucking.TrailerCargoEditor or {}
        if editor.Open then
            editor.Open(trailerKey)
        else
            Notify('Trailer cargo editor is unavailable.', 'error')
        end
    end, false)

    RegisterCommand('lstrailertest', function(_, args)
        if not HasAdminPermission() then return end

        local trailerKey = args and args[1] or 'flatbed_crates'
        local tester = LS_Trucking.TrailerCargoTester or {}
        if tester.Spawn then
            tester.Spawn(trailerKey)
        else
            Notify('Trailer test spawner is unavailable.', 'error')
        end
    end, false)

    RegisterCommand('lstrailerclear', function()
        if not HasAdminPermission() then return end

        local tester = LS_Trucking.TrailerCargoTester or {}
        if tester.Clear then
            tester.Clear(false)
        else
            Notify('Trailer test spawner is unavailable.', 'error')
        end
    end, false)

    RegisterCommand('lstrolleytest', function(_, args)
        if not HasAdminPermission() then return end
        local trolley = LS_Trucking.BoxTruckTrolley or {}
        if trolley.SpawnTest then trolley.SpawnTest(args and args[1] or 'freight_crate') end
    end, false)

    RegisterCommand('lstrolleyclear', function()
        if not HasAdminPermission() then return end
        local trolley = LS_Trucking.BoxTruckTrolley or {}
        if trolley.ClearTest then trolley.ClearTest() end
    end, false)
end

function ClientCommands.RegisterClient(context)
    clientContext = context or {}
    if registered then return end
    registered = true

    RegisterPublicCommands()
    RegisterAdminCommands()

    CreateThread(function()
        Wait(750)
        RegisterCommandSuggestions()
    end)
end

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    for command in pairs(commandSuggestions) do
        TriggerEvent('chat:removeSuggestion', ('/%s'):format(command))
    end
end)

LS_Trucking.ClientCommands = ClientCommands
