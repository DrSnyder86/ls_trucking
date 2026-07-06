LS_Trucking = LS_Trucking or {}

local Admin = {}
local serverRegistered = false

local function HasPermission(ctx, src)
    return ctx.HasAdminCommandPermission and ctx.HasAdminCommandPermission(src) == true
end

local function Notify(src, message, notifyType)
    if src and src > 0 then
        TriggerClientEvent('ls_trucking:client:notify', src, message, notifyType or 'inform')
    else
        print(('[ls_trucking] %s'):format(message))
    end
end

local function ResolveCommandTarget(src, args, usage)
    local target = src
    local value = args and args[1] or nil

    if src == 0 then
        target = args and tonumber(args[1]) or 0
        value = args and args[2] or nil
    elseif args and args[2] then
        target = tonumber(args[1]) or src
        value = args[2]
    end

    if not target or target <= 0 then
        print(('[ls_trucking] %s'):format(T('admin.console_usage', { usage = usage })))
        return nil, nil
    end

    return target, value
end

local function FindRank(rank)
    rank = tonumber(rank) or 1
    local selected = (Config.Ranks or {})[1] or { rank = rank, label = ('Rank %s'):format(rank), xp = 0 }

    for _, rankData in ipairs(Config.Ranks or {}) do
        if tonumber(rankData.rank) == rank then
            selected = rankData
            break
        end
    end

    return selected, rank
end

local function RegisterDebugGiveItems(ctx)
    RegisterNetEvent('ls_trucking:server:debugGiveItems', function()
        local src = source
        if not HasPermission(ctx, src) then return end

        local active = ctx.ActiveContracts and ctx.ActiveContracts[src]
        if not active then
            Notify(src, T('admin.no_active_contract'), 'error')
            return
        end

        if active.type == 'trailer' then
            if Config.Manifest and Config.Manifest.Enabled and Config.Manifest.TrailerManifestItem then
                ctx.AddPlayerItem(src, Config.Manifest.TrailerManifestItem, 1, {
                    contract = active.id,
                    route = active.routeLabel,
                    description = ('Debug trailer manifest for %s.'):format(active.routeLabel or 'active route')
                })
            end

            Notify(src, T('admin.trailer_manifest_added'), 'success')
            return
        end

        local added = 0
        for _, entry in ipairs(active.cargoManifest or {}) do
            if entry.cargoType then
                local cargo = ctx.GetCargoConfig and ctx.GetCargoConfig(active.type, entry.cargoType) or nil
                if cargo and cargo.item then
                    ctx.AddPlayerItem(src, cargo.item, 1, {
                        contract = active.id,
                        type = active.type,
                        cargoType = entry.cargoType,
                        label = cargo.label,
                        receiver = entry.receiver,
                        dropoff = entry.dropoff,
                        route = active.routeLabel,
                        stop = entry.stop,
                        description = ('Debug cargo for %s.'):format(entry.dropoff or active.routeLabel or 'active route')
                    })

                    added = added + 1
                end
            end
        end

        Notify(src, T('admin.cargo_items_added', { count = added }), added > 0 and 'success' or 'error')
    end)
end

local function RegisterRankCommand(ctx)
    RegisterCommand('lstruck_rank', function(src, args)
        if not HasPermission(ctx, src) then return end

        local target, rankArg = ResolveCommandTarget(src, args, 'lstruck_rank <playerId> <rank>')
        if not target then return end

        local selected, requestedRank = FindRank(rankArg)
        local citizenid = ctx.GetCitizenId(target)
        ctx.EnsureTruckingStats(citizenid)

        MySQL.update.await('UPDATE player_trucking SET xp = ? WHERE citizenid = ?', {
            selected.xp or 0,
            citizenid
        })

        Notify(target, T('admin.rank_set', { rank = selected.label or selected.rank or requestedRank }), 'success')
    end, false)
end

local function RegisterRepCommand(ctx)
    RegisterCommand('lstruck_rep', function(src, args)
        if not HasPermission(ctx, src) then return end

        local target, repArg = ResolveCommandTarget(src, args, 'lstruck_rep <playerId> <amount>')
        if not target then return end

        local amount = tonumber(repArg) or 0
        local citizenid = ctx.GetCitizenId(target)
        ctx.EnsureTruckingStats(citizenid)

        MySQL.update.await('UPDATE player_trucking SET reputation = GREATEST(reputation + ?, 0) WHERE citizenid = ?', {
            amount,
            citizenid
        })

        Notify(target, T('admin.rep_adjusted', { amount = amount }), 'success')
    end, false)
end

local function RegisterResetStatsCommand(ctx)
    RegisterCommand('lstruck_resetstats', function(src, args)
        if not HasPermission(ctx, src) then return end

        local target = src
        if src == 0 and args and args[1] then target = tonumber(args[1]) or 0 end

        if not target or target <= 0 then
            print(('[ls_trucking] %s'):format(T('admin.console_usage', { usage = 'lstruck_resetstats <playerId>' })))
            return
        end

        local citizenid = ctx.GetCitizenId(target)
        ctx.EnsureTruckingStats(citizenid)

        MySQL.update.await('UPDATE player_trucking SET xp = 0, reputation = 0, jobs_completed = 0, total_earned = 0, total_routes_cancelled = 0 WHERE citizenid = ?', {
            citizenid
        })

        Notify(target, T('admin.stats_reset'), 'success')
    end, false)
end

function Admin.RegisterServer(ctx)
    if serverRegistered then return end
    serverRegistered = true
    ctx = ctx or {}

    lib.callback.register('ls_trucking:server:canUseAdminCommand', function(src)
        return HasPermission(ctx, src)
    end)

    RegisterDebugGiveItems(ctx)
    RegisterRankCommand(ctx)
    RegisterRepCommand(ctx)
    RegisterResetStatsCommand(ctx)
end

LS_Trucking.Admin = Admin
