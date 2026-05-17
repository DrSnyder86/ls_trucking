local ActiveContracts = {}

-- ls_trucking random route seed: keeps route selection from repeating the same first route after resource starts.
CreateThread(function()
    Wait(500)
    math.randomseed(os.time() + GetGameTimer())
    for _ = 1, 8 do math.random() end
end)


local function TrimString(value)
    value = tostring(value or '')
    return value:match('^%s*(.-)%s*$') or value
end

local function NormalizeVersion(value)
    value = TrimString(value)
    value = value:gsub('^v', ''):gsub('^V', '')
    return value
end

local function CompareVersions(current, latest)
    current = NormalizeVersion(current)
    latest = NormalizeVersion(latest)

    local currentParts = {}
    local latestParts = {}

    for part in current:gmatch('[^%.]+') do
        currentParts[#currentParts + 1] = tonumber(part:match('%d+')) or 0
    end

    for part in latest:gmatch('[^%.]+') do
        latestParts[#latestParts + 1] = tonumber(part:match('%d+')) or 0
    end

    local maxParts = math.max(#currentParts, #latestParts, 3)

    for i = 1, maxParts do
        local a = currentParts[i] or 0
        local b = latestParts[i] or 0

        if a < b then return -1 end
        if a > b then return 1 end
    end

    return 0
end

local function ParseVersionResponse(body)
    body = TrimString(body)
    if body == '' then return nil end

    local decoded = nil

    if body:sub(1, 1) == '{' then
        local ok, result = pcall(json.decode, body)
        if ok and type(result) == 'table' then
            decoded = result
        end
    end

    if decoded then
        return {
            version = decoded.version or decoded.latest or decoded.tag or decoded.name,
            download = decoded.download or decoded.downloadUrl or decoded.url or decoded.release,
            changelog = decoded.changelog or decoded.notes or decoded.description
        }
    end

    local firstLine = body:match('([^\r\n]+)')
    return {
        version = firstLine
    }
end

local function ParseNamedVersionResponse(body, keys)
    body = TrimString(body)
    if body == '' then return nil end

    if body:sub(1, 1) == '{' then
        local ok, decoded = pcall(json.decode, body)
        if ok and type(decoded) == 'table' then
            for _, key in ipairs(keys or {}) do
                if decoded[key] then
                    return NormalizeVersion(decoded[key])
                end
            end
            if decoded.version then
                return NormalizeVersion(decoded.version)
            end
        end
    end

    for _, key in ipairs(keys or {}) do
        local luaPattern = key .. "%s*=%s*['\"]([^'\"]+)['\"]"
        local found = body:match(luaPattern)
        if found then
            return NormalizeVersion(found)
        end
    end

    local firstLine = body:match('([^\r\n]+)')
    if firstLine then
        local quoted = firstLine:match("['\"]([^'\"]+)['\"]")
        return NormalizeVersion(quoted or firstLine)
    end

    return nil
end

local function RunNamedVersionCheck(label, currentVersion, url, keys, settings)
    url = TrimString(url or '')
    if url == '' then return end

    PerformHttpRequest(url, function(statusCode, body)
        if statusCode ~= 200 or not body then
            print(('^1[ls_trucking]^7 %s version check failed. HTTP %s'):format(label, statusCode or 'unknown'))
            return
        end

        local latestVersion = ParseNamedVersionResponse(body, keys)
        if not latestVersion or latestVersion == '' then
            print(('^1[ls_trucking]^7 %s version check failed. Could not read remote version.'):format(label))
            return
        end

        local compare = CompareVersions(currentVersion, latestVersion)
        if compare < 0 then
            print(('^3[ls_trucking]^7 %s config update available: ^1%s^7 -> ^2%s^7'):format(label, currentVersion, latestVersion))
        elseif compare > 0 then
            print(('^5[ls_trucking]^7 Local %s config version %s is newer than remote %s.'):format(label, currentVersion, latestVersion))
        elseif not settings or settings.PrintUpToDate ~= false then
            print(('^2[ls_trucking]^7 %s config is up to date: %s'):format(label, currentVersion))
        end
    end, 'GET', '', {
        ['Cache-Control'] = 'no-cache',
        ['User-Agent'] = 'ls_trucking-config-version-check'
    })
end

local function RunVersionCheck()
    local settings = Config.VersionCheck or {}
    if settings.Enabled == false then return end

    local url = TrimString(settings.GitHubRawVersionUrl or settings.Url or settings.URL or '')
    if url == '' then
        print('^3[ls_trucking]^7 Version checker is ready. Set Config.VersionCheck.GitHubRawVersionUrl after uploading to GitHub.')
        return
    end

    local currentVersion = GetResourceMetadata(GetCurrentResourceName(), 'version', 0) or '0.0.0'

    PerformHttpRequest(url, function(statusCode, body)
        if statusCode ~= 200 or not body then
            print(('^1[ls_trucking]^7 Version check failed. HTTP %s'):format(statusCode or 'unknown'))
            return
        end

        local remote = ParseVersionResponse(body)

        if not remote or not remote.version then
            print('^1[ls_trucking]^7 Version check failed. Could not read remote version.')
            return
        end

        local latestVersion = NormalizeVersion(remote.version)
        local compare = CompareVersions(currentVersion, latestVersion)

        if compare < 0 then
            print('^3============================================================^7')
            print(('^3[ls_trucking]^7 Update available: ^1%s^7 -> ^2%s^7'):format(currentVersion, latestVersion))

            if remote.download and TrimString(remote.download) ~= '' then
                print(('^3[ls_trucking]^7 Download: ^5%s^7'):format(remote.download))
            end

            if remote.changelog and TrimString(remote.changelog) ~= '' then
                print(('^3[ls_trucking]^7 Notes: ^5%s^7'):format(remote.changelog))
            end

            print('^3============================================================^7')
        elseif compare > 0 then
            print(('^5[ls_trucking]^7 Local version %s is newer than remote %s.'):format(currentVersion, latestVersion))
        elseif settings.PrintUpToDate ~= false then
            print(('^2[ls_trucking]^7 You are running the latest version: %s'):format(currentVersion))
        end
    end, 'GET', '', {
        ['Cache-Control'] = 'no-cache',
        ['User-Agent'] = 'ls_trucking-version-check'
    })
end

CreateThread(function()
    Wait((Config.VersionCheck and Config.VersionCheck.CheckDelay) or 5000)
    RunVersionCheck()

    local settings = Config.VersionCheck or {}
    if settings.Enabled ~= false then
        RunNamedVersionCheck('Main', Config.ConfigVersion or '0.0.0', settings.ConfigRawVersionUrl, { 'config_version', 'configVersion', 'ConfigVersion', 'Config.ConfigVersion' }, settings)
        RunNamedVersionCheck('Contracts', Config.ContractsVersion or '0.0.0', settings.ContractsRawVersionUrl, { 'contracts_version', 'contractsVersion', 'ContractsVersion', 'Config.ContractsVersion' }, settings)
    end
end)

local QBCore = nil

local function DetectFramework()
    if Config.Framework == 'qb' then return 'qb' end
    if Config.Framework == 'qbox' then return 'qbox' end
    if Config.Framework == 'standalone' then return 'standalone' end
    if GetResourceState('qbx_core') == 'started' then return 'qbox' end
    if GetResourceState('qb-core') == 'started' then return 'qb' end
    return 'standalone'
end

local Framework = DetectFramework()

CreateThread(function()
    if Framework == 'qb' then
        QBCore = exports['qb-core']:GetCoreObject()
    end
end)

local function GetPlayer(src)
    if Framework == 'qb' and QBCore then return QBCore.Functions.GetPlayer(src) end
    if Framework == 'qbox' and GetResourceState('qbx_core') == 'started' then return exports.qbx_core:GetPlayer(src) end
    return nil
end

local function GetCitizenId(src)
    local player = GetPlayer(src)
    if player then
        if player.PlayerData and player.PlayerData.citizenid then return player.PlayerData.citizenid end
        if player.citizenid then return player.citizenid end
    end
    return ('source:%s'):format(src)
end

local function GetCharacterName(src)
    local player = GetPlayer(src)
    if player and player.PlayerData and player.PlayerData.charinfo then
        local c = player.PlayerData.charinfo
        return ('%s %s'):format(c.firstname or 'Unknown', c.lastname or 'Driver')
    end
    return GetPlayerName(src) or 'Driver'
end


local function GetPlayerJobInfo(src)
    local player = GetPlayer(src)
    local job = nil

    if player then
        if player.PlayerData and player.PlayerData.job then
            job = player.PlayerData.job
        elseif player.job then
            job = player.job
        end
    end

    if not job then
        return {
            name = 'unemployed',
            label = 'Unemployed',
            gradeName = 'None',
            gradeLevel = 0,
            text = 'Unemployed - None'
        }
    end

    local jobName = job.name or 'unemployed'
    local jobLabel = job.label or jobName
    local gradeName = 'None'
    local gradeLevel = 0

    if type(job.grade) == 'table' then
        gradeName = job.grade.name or job.grade.label or tostring(job.grade.level or job.grade.grade or job.grade.value or 'None')
        gradeLevel = tonumber(job.grade.level or job.grade.grade or job.grade.value or 0) or 0
    elseif job.grade ~= nil then
        gradeLevel = tonumber(job.grade) or 0
        gradeName = tostring(job.grade)
    end

    if job.grade_name then gradeName = job.grade_name end
    if job.grade_label then gradeName = job.grade_label end
    if job.grade_level then gradeLevel = tonumber(job.grade_level) or gradeLevel end

    return {
        name = jobName,
        label = jobLabel,
        gradeName = gradeName,
        gradeLevel = gradeLevel,
        text = ('%s - %s'):format(jobLabel, gradeName)
    }
end

local function HasRequiredJob(src)
    if not Config.RequireJob then return true end
    local player = GetPlayer(src)
    if not player then return false end
    local job = player.PlayerData and player.PlayerData.job or player.job
    return job and job.name == Config.JobName
end

local function AddMoney(src, amount, reason)
    local account = Config.PayToBank and 'bank' or 'cash'
    local player = GetPlayer(src)
    if player and player.Functions and player.Functions.AddMoney then
        player.Functions.AddMoney(account, amount, reason or 'ls-trucking-payment')
        return true
    end
    if Framework == 'qbox' and GetResourceState('qbx_core') == 'started' then
        exports.qbx_core:AddMoney(src, account, amount, reason or 'ls-trucking-payment')
        return true
    end
    return true
end

local function GenerateContractId(src) return ('LSFC-%s-%s'):format(src, math.random(10000, 99999)) end
local function GeneratePlate(prefix) return ('%s%s'):format(prefix or 'LSF', math.random(100, 999)) end

local function GetVehicleConfig(contractType, vehicleIndex)
    local vehicles = Config.JobVehicles[contractType]
    if not vehicles then return nil end
    vehicleIndex = tonumber(vehicleIndex) or 1
    if not vehicles[vehicleIndex] then vehicleIndex = 1 end
    return vehicles[vehicleIndex], vehicleIndex
end

local function GetGarageVehicleModel(contractType, vehicleData)
    -- Trailer hauling vehicles now only need model defined.
    -- truck is kept as a fallback for older configs.
    return vehicleData.model or vehicleData.truck
end

local function GetRankFromXp(xp)
    local current = Config.Ranks[1]
    for _, rank in ipairs(Config.Ranks) do
        if xp >= rank.xp then current = rank end
    end
    local nextRankXp = current.xp
    for _, rank in ipairs(Config.Ranks) do
        if rank.xp > xp then nextRankXp = rank.xp break end
    end
    return current.rank, current.label, nextRankXp
end

local function EnsureTruckingStats(citizenid)
    MySQL.insert.await([[INSERT IGNORE INTO player_trucking (citizenid, xp, reputation, jobs_completed, total_earned, total_routes_cancelled) VALUES (?, 0, 0, 0, 0, 0)]], { citizenid })
end

local function GetTruckingStats(citizenid)
    EnsureTruckingStats(citizenid)
    local row = MySQL.single.await('SELECT * FROM player_trucking WHERE citizenid = ?', { citizenid }) or {}
    local xp = row.xp or 0
    local rank, rankLabel, nextRankXp = GetRankFromXp(xp)
    return { xp = xp, reputation = row.reputation or 0, jobsCompleted = row.jobs_completed or 0, totalEarned = row.total_earned or 0, totalCancelled = row.total_routes_cancelled or 0, rank = rank, rankLabel = rankLabel, nextRankXp = nextRankXp }
end

local function AddTruckingStats(citizenid, xp, reputation, payout)
    EnsureTruckingStats(citizenid)
    MySQL.update.await([[UPDATE player_trucking SET xp = xp + ?, reputation = reputation + ?, jobs_completed = jobs_completed + 1, total_earned = total_earned + ? WHERE citizenid = ?]], { xp or 0, reputation or 0, payout or 0, citizenid })
end

local function AddCancelledRoute(citizenid, repLoss)
    EnsureTruckingStats(citizenid)
    repLoss = tonumber(repLoss) or 1
    if repLoss < 0 then repLoss = 0 end

    MySQL.update.await([[UPDATE player_trucking SET reputation = GREATEST(reputation - ?, 0), total_routes_cancelled = total_routes_cancelled + 1 WHERE citizenid = ?]], {
        repLoss,
        citizenid
    })
end

local function GetTrunkId(plate) return Config.GetTrunkInventoryId(plate) end
local function GetInventoryItemCount(inventory, item) return exports.ox_inventory:GetItemCount(inventory, item) or 0 end
local function AddPlayerItem(src, item, amount, metadata) return exports.ox_inventory:AddItem(src, item, amount or 1, metadata or {}) end
local function RemovePlayerItem(src, item, amount) return exports.ox_inventory:RemoveItem(src, item, amount or 1) end
local function AddTrunkItem(plate, item, amount, metadata) return exports.ox_inventory:AddItem(GetTrunkId(plate), item, amount or 1, metadata or {}) end
local function RemoveTrunkItem(plate, item, amount) return exports.ox_inventory:RemoveItem(GetTrunkId(plate), item, amount or 1) end

local function GetCargoConfig(contractType, cargoType)
    cargoType = cargoType or (Config.DefaultCargoType and Config.DefaultCargoType[contractType])

    if cargoType and Config.CargoTypes and Config.CargoTypes[cargoType] then
        return Config.CargoTypes[cargoType], cargoType
    end

    local fallback = Config.CargoItems and Config.CargoItems[contractType]
    return fallback, cargoType or contractType
end

local function NormalizeCargoPool(contractType, cargoPool)
    local pool = {}

    if type(cargoPool) == 'table' then
        for _, cargoType in ipairs(cargoPool) do
            if cargoType and Config.CargoTypes and Config.CargoTypes[cargoType] then
                pool[#pool + 1] = cargoType
            end
        end
    elseif cargoPool and Config.CargoTypes and Config.CargoTypes[cargoPool] then
        pool[#pool + 1] = cargoPool
    end

    if #pool == 0 then
        local defaultCargo = Config.DefaultCargoType and Config.DefaultCargoType[contractType]
        if defaultCargo and Config.CargoTypes and Config.CargoTypes[defaultCargo] then
            pool[#pool + 1] = defaultCargo
        end
    end

    return pool
end

local function PickCargoFromPool(contractType, cargoPool)
    local pool = NormalizeCargoPool(contractType, cargoPool)
    if #pool == 0 then return nil, nil end

    local cargoType = pool[math.random(1, #pool)]
    return Config.CargoTypes[cargoType], cargoType
end

local function GetManifestEntryForStop(active, stopIndex, deliveredAtStop)
    if not active or not active.cargoManifest then return nil end

    local target = (deliveredAtStop or 0) + 1
    local count = 0

    for _, entry in ipairs(active.cargoManifest) do
        if entry.stop == stopIndex then
            count = count + 1
            if count == target then
                return entry
            end
        end
    end

    return nil
end

local function BuildPackageManifest(contractId, routeLabel, route, contractType, cargoPool)
    local manifest = {}
    local dropoffs = route and route.dropoffs or {}

    for stopIndex, stop in ipairs(dropoffs) do
        local amount = stop.unload or 1

        for i = 1, amount do
            local cargoConfig, cargoType = PickCargoFromPool(contractType, stop.cargoTypes or stop.cargoType or cargoPool)

            manifest[#manifest + 1] = {
                stop = stopIndex,
                receiver = stop.receiver or stop.label or ('Stop %s'):format(stopIndex),
                dropoff = stop.label or ('Stop %s'):format(stopIndex),
                instructions = stop.instructions or ('Deliver to %s.'):format(stop.label or ('Stop %s'):format(stopIndex)),
                contract = contractId,
                route = routeLabel,
                cargoType = cargoType,
                cargoItem = cargoConfig and cargoConfig.item or nil,
                cargoLabel = cargoConfig and cargoConfig.label or 'Delivery Cargo'
            }
        end
    end

    return manifest
end

local function ManifestText(manifest)
    if not manifest or #manifest == 0 then return 'No manifest entries.' end

    local groupedStops = {}
    local orderedStops = {}

    for _, entry in ipairs(manifest) do
        local stopKey = entry.stop or entry.dropoff or entry.receiver or (#orderedStops + 1)

        if not groupedStops[stopKey] then
            groupedStops[stopKey] = {
                stop = entry.stop or (#orderedStops + 1),
                receiver = entry.receiver or entry.dropoff or 'Receiver',
                dropoff = entry.dropoff or entry.receiver or 'Dropoff',
                count = 0,
                cargo = {}
            }

            orderedStops[#orderedStops + 1] = stopKey
        end

        groupedStops[stopKey].count = groupedStops[stopKey].count + 1
        local cargoLabel = entry.cargoLabel or 'Delivery Cargo'
        groupedStops[stopKey].cargo[cargoLabel] = (groupedStops[stopKey].cargo[cargoLabel] or 0) + 1
    end

    table.sort(orderedStops, function(a, b)
        local left = groupedStops[a] and groupedStops[a].stop or 0
        local right = groupedStops[b] and groupedStops[b].stop or 0
        return left < right
    end)

    local lines = {
        ('Route: %s'):format((manifest[1] and manifest[1].route) or 'Delivery Route'),
        'Delivery Stops:'
    }

    for index, stopKey in ipairs(orderedStops) do
        local stop = groupedStops[stopKey]
        lines[#lines + 1] = ('- Stop %s: %s'):format(index, stop.receiver)
        lines[#lines + 1] = ('  Dropoff: %s'):format(stop.dropoff)
        local cargoParts = {}
        for cargoLabel, amount in pairs(stop.cargo or {}) do
            cargoParts[#cargoParts + 1] = ('%s x%s'):format(cargoLabel, amount)
        end
        table.sort(cargoParts)
        lines[#lines + 1] = ('  Packages: %s'):format(table.concat(cargoParts, ', '))
    end

    return table.concat(lines, '\n')
end

local function GiveContractManifest(src, active)
    local manifestConfig = Config.Manifest or {}
    if manifestConfig.Enabled == false or not active then return end

    if active.type == 'trailer' then
        local item = manifestConfig.TrailerManifestItem
        if not item then return end

        local contents = active.trailerContents or (active.routeTrailer and active.routeTrailer.contents) or active.trailerLabel or 'Trailer Freight'
        local instructions = active.trailerInstructions or (active.routeTrailer and active.routeTrailer.instructions) or { 'Complete the trailer load checklist before departure.' }
        if type(instructions) == 'string' then instructions = { instructions } end

        local lines = {
            ('Contract: %s'):format(active.id),
            ('Route: %s'):format(active.routeLabel or 'Trailer Route'),
            ('Pickup Depot: %s'):format(active.trailerDepot and active.trailerDepot.label or 'Trailer Pickup Yard'),
            ('Trailer: %s'):format(active.trailerLabel or 'Assigned Trailer'),
            ('Contents: %s'):format(contents),
            ('Dropoff: %s'):format(active.routeData and active.routeData.trailerDrop and active.routeData.trailerDrop.label or 'Receiving Yard'),
            ('Safe Speed: %s MPH'):format(active.safeSpeed or (Config.SpeedRisk and Config.SpeedRisk.DefaultSafeSpeed) or 75),
            'Instructions:'
        }

        for _, instruction in ipairs(instructions) do
            lines[#lines + 1] = ('- %s'):format(instruction)
        end

        local text = table.concat(lines, '\n')

        AddPlayerItem(src, item, 1, {
            contract = active.id,
            route = active.routeLabel,
            trailer = active.trailerLabel,
            contents = contents,
            description = text
        })

        return
    end

    local item = manifestConfig.PackageManifestItem
    if not item then return end

    AddPlayerItem(src, item, 1, {
        contract = active.id,
        route = active.routeLabel,
        cargo = active.cargoLabel,
        description = ManifestText(active.cargoManifest)
    })
end

local function RemoveContractManifests(src)
    local manifestConfig = Config.Manifest or {}
    if manifestConfig.Enabled == false or manifestConfig.RemoveOnComplete == false then return end

    for _, item in ipairs({ manifestConfig.PackageManifestItem, manifestConfig.TrailerManifestItem }) do
        if item then
            local count = GetInventoryItemCount(src, item)
            if count > 0 then RemovePlayerItem(src, item, count) end
        end
    end
end

local function CargoItemsFromManifestOrType(contractType, cargoType, manifest)
    local items = {}

    if manifest then
        for _, entry in ipairs(manifest) do
            if entry.cargoItem then
                items[entry.cargoItem] = true
            elseif entry.cargoType and Config.CargoTypes and Config.CargoTypes[entry.cargoType] then
                items[Config.CargoTypes[entry.cargoType].item] = true
            end
        end
    end

    if next(items) == nil then
        local cargo = GetCargoConfig(contractType, cargoType)
        if cargo and cargo.item then items[cargo.item] = true end
    end

    return items
end

local function RemoveAllPlayerCargo(src, contractType, cargoType, manifest)
    local items = CargoItemsFromManifestOrType(contractType, cargoType, manifest)
    for item in pairs(items) do
        local count = GetInventoryItemCount(src, item)
        if count > 0 then RemovePlayerItem(src, item, count) end
    end
end

local function RemoveAllTrunkCargo(plate, contractType, cargoType, manifest)
    if not plate then return end
    local items = CargoItemsFromManifestOrType(contractType, cargoType, manifest)
    for item in pairs(items) do
        local count = GetInventoryItemCount(GetTrunkId(plate), item)
        if count > 0 then RemoveTrunkItem(plate, item, count) end
    end
end

local function CleanupContractCargo(src)
    local active = ActiveContracts[src]
    if not active then return end
    RemoveAllPlayerCargo(src, active.type, active.cargoType, active.cargoManifest)
    RemoveAllTrunkCargo(active.plate, active.type, active.cargoType, active.cargoManifest)
    RemoveContractManifests(src)
end

local function GetPriorityConfig(contractType, priorityKey)
    local priorities = Config.PriorityLoads and Config.PriorityLoads[contractType]
    if not priorities then return nil, 'standard' end

    priorityKey = priorityKey or 'standard'

    if not priorities[priorityKey] then
        priorityKey = 'standard'
    end

    return priorities[priorityKey], priorityKey
end

local function PickRoute(contractType, priorityKey)
    local contract = Config.Contracts[contractType]
    if not contract then return nil, 1 end

    local priority = GetPriorityConfig(contractType, priorityKey)
    local routePool = priority and priority.routes or contract.routes

    if not routePool or #routePool == 0 then
        routePool = contract.routes
    end

    if not routePool or #routePool == 0 then return nil, 1 end

    local index = math.random(1, #routePool)
    return routePool[index], index
end


local function ResolveRouteTrailer(route, priority)
    if not Config.RouteTrailers then return nil end

    local trailerKey = route and route.trailerKey or nil

    if not trailerKey and priority then
        trailerKey = priority.defaultTrailerKey
    end

    trailerKey = trailerKey or 'dryvan'

    local trailer = Config.RouteTrailers[trailerKey] or Config.RouteTrailers.dryvan
    if not trailer then return nil end

    local contents = route and route.trailerContents or trailer.contents or trailer.label or 'Trailer Freight'
    local instructions = route and route.trailerInstructions or trailer.instructions or { 'Complete the trailer load checklist before departure.' }
    local safeSpeed = route and route.safeSpeed or trailer.safeSpeed or (Config.SpeedRisk and Config.SpeedRisk.DefaultSafeSpeed) or 75.0

    return {
        key = trailerKey,
        label = trailer.label or trailer.model or trailerKey,
        model = trailer.model,
        photo = trailer.photo,
        livery = trailer.livery,
        extras = trailer.extras,
        contents = contents,
        instructions = instructions,
        safeSpeed = safeSpeed
    }
end

local function ResolveTrailerDepot(route)
    local depots = Config.TrailerDepots or {}
    local depotKey = route and route.pickupDepot or 'docks'
    local depot = depots[depotKey] or depots.docks

    if not depot then
        return {
            key = 'default',
            label = 'Trailer Pickup Yard',
            pickup = Config.Contracts and Config.Contracts.trailer and Config.Contracts.trailer.pickup and Config.Contracts.trailer.pickup.coords or vector3(1244.30, -3184.92, 5.90),
            spawns = {
                vector4(1244.30, -3184.92, 5.90, 90.0)
            }
        }
    end

    return {
        key = depotKey,
        label = depot.label or 'Trailer Pickup Yard',
        pickup = depot.pickup,
        spawns = depot.spawns
    }
end

local function GetPublicContractData(contractType, route, priority, priorityKey)
    local contract = Config.Contracts[contractType]
    local copy = {}
    for k, v in pairs(contract) do if k ~= 'routes' then copy[k] = v end end
    if route then
        copy.routeLabel = route.label
        copy.routeLength = route.routeLength
        copy.dropoffs = route.dropoffs
        copy.trailerDrop = route.trailerDrop
        copy.receiverPed = route.receiverPed
        if contractType == 'trailer' then
            copy.routeTrailer = ResolveRouteTrailer(route, priority)
            copy.trailerDepot = ResolveTrailerDepot(route)
            if copy.trailerDepot and copy.trailerDepot.pickup then
                copy.pickup = {
                    label = copy.trailerDepot.label or 'Trailer Pickup Yard',
                    coords = copy.trailerDepot.pickup
                }
            end
        end
    end
    if priority then
        copy.priorityKey = priorityKey or 'standard'
        copy.priorityLabel = priority.label
        copy.priorityShortLabel = priority.shortLabel or priority.label
        copy.priorityDescription = priority.description
        copy.priorityBadge = priority.badge
        copy.priorityMinRank = priority.minRank or 1
    end
    return copy
end

local function GetPlayerTruckingRank(src)
    local citizenid = GetCitizenId(src)
    local stats = GetTruckingStats(citizenid)
    return stats.rank or 1, stats
end

local function CheckRankRequirement(playerRank, requiredRank)
    return (playerRank or 1) >= (requiredRank or 1)
end


local function ParseRouteMiles(routeLength)
    if not routeLength then return nil end
    if type(routeLength) == 'number' then return routeLength end
    local miles = tostring(routeLength):match('([%d%.]+)')
    return miles and tonumber(miles) or nil
end

local function GetEstimatedSeconds(contractType, priorityKey, route)
    if route and route.estimatedSeconds then
        return tonumber(route.estimatedSeconds) or 0
    end

    local timing = Config.DeliveryTiming or {}
    local miles = route and ParseRouteMiles(route.routeLength)

    if miles and miles > 0 then
        local baseMinutes = timing.BaseMinutes and timing.BaseMinutes[contractType] or 5
        local minutesPerMile = timing.MinutesPerMile and timing.MinutesPerMile[contractType] or 2.0
        return math.max(300, math.floor((baseMinutes + (miles * minutesPerMile)) * 60))
    end

    local defaults = timing.Defaults or {}
    local typeDefaults = defaults[contractType] or {}
    return typeDefaults[priorityKey or 'standard'] or typeDefaults.standard or 900
end

local function FormatSeconds(seconds)
    seconds = tonumber(seconds) or 0
    local minutes = math.floor(seconds / 60)
    local secs = seconds % 60
    return ('%02d:%02d'):format(minutes, secs)
end

local function MatchesRandomEvent(event, contractType, priorityKey)
    if not event then return false end

    if event.types then
        local ok = false
        for _, t in ipairs(event.types) do
            if t == contractType then ok = true break end
        end
        if not ok then return false end
    end

    if event.priorities then
        local ok = false
        for _, p in ipairs(event.priorities) do
            if p == priorityKey then ok = true break end
        end
        if not ok then return false end
    end

    return true
end

local function PickRandomDeliveryEvent(contractType, priorityKey)
    local cfg = Config.RandomDeliveryEvents
    if not cfg or not cfg.Enabled then return nil end
    if math.random() > (cfg.Chance or 0.0) then return nil end

    local pool = {}
    for _, event in ipairs(cfg.Events or {}) do
        if MatchesRandomEvent(event, contractType, priorityKey) then
            pool[#pool + 1] = event
        end
    end

    if #pool == 0 then return nil end
    local picked = pool[math.random(1, #pool)]

    return {
        id = picked.id,
        label = picked.label,
        description = picked.description,
        estimateDeltaSeconds = picked.estimateDeltaSeconds or 0,
        payoutPercent = picked.payoutPercent or 0.0,
        latePenaltyBonusPercent = picked.latePenaltyBonusPercent or 0.0,
        repBonus = picked.repBonus or 0
    }
end

local function PublicRandomEvent(event)
    if not event then return nil end
    return {
        id = event.id,
        label = event.label,
        description = event.description,
        estimateDeltaSeconds = event.estimateDeltaSeconds or 0,
        payoutPercent = event.payoutPercent or 0.0,
        repBonus = event.repBonus or 0
    }
end

local function GetTrailerDamageAdjustment(damagePercent)
    local cfg = Config.TrailerDamagePenalties
    if not cfg or not cfg.Enabled then
        return { percent = 0.0, label = 'No trailer damage adjustment', damagePercent = damagePercent or 0.0 }
    end

    damagePercent = tonumber(damagePercent) or 0.0

    if damagePercent <= (cfg.CleanThresholdPercent or 0.0) and (cfg.CleanBonusPercent or 0.0) > 0.0 then
        return {
            percent = cfg.CleanBonusPercent,
            label = 'Clean trailer bonus',
            damagePercent = damagePercent
        }
    end

    for _, level in ipairs(cfg.Levels or {}) do
        if damagePercent >= (level.minDamagePercent or 0.0) then
            return {
                percent = -(level.penaltyPercent or 0.0),
                label = level.label or 'Trailer damage penalty',
                damagePercent = damagePercent
            }
        end
    end

    return { percent = 0.0, label = 'No trailer damage penalty', damagePercent = damagePercent }
end

local function CalculateTimeAdjustment(active)
    local timing = Config.DeliveryTiming
    if not timing or not timing.Enabled then
        return { percent = 0.0, label = 'No time adjustment', elapsedSeconds = 0, estimatedSeconds = active.estimatedSeconds or 0, status = 'none' }
    end

    local elapsed = math.max(0, os.time() - (active.routeStartedAt or active.startedAt or os.time()))
    local estimated = active.estimatedSeconds or 0
    local grace = timing.GraceSeconds or 0
    local earlyWindow = timing.EarlyBonusWindowSeconds or 0
    local latePenalty = timing.LatePenaltyPercent or 0.0
    local earlyBonus = timing.EarlyBonusPercent or 0.0

    if estimated > 0 and elapsed <= math.max(0, estimated - earlyWindow) then
        return { percent = earlyBonus, label = 'Early delivery bonus', elapsedSeconds = elapsed, estimatedSeconds = estimated, status = 'early' }
    end

    if estimated > 0 and elapsed > estimated + grace then
        local extra = (active.randomEvent and active.randomEvent.latePenaltyBonusPercent or 0.0)
        return { percent = -(latePenalty + extra), label = 'Late delivery penalty', elapsedSeconds = elapsed, estimatedSeconds = estimated, status = 'late' }
    end

    return { percent = 0.0, label = 'On-time delivery', elapsedSeconds = elapsed, estimatedSeconds = estimated, status = 'on_time' }
end

local function BuildPayoutResult(active)
    local base = active.basePayout or active.payout or 0
    local minimum = math.floor(base * ((Config.DeliveryTiming and Config.DeliveryTiming.MinimumFinalPayoutPercent) or 0.45))
    local adjustments = {}
    local totalPercent = 0.0

    local timeAdj = CalculateTimeAdjustment(active)
    if timeAdj and timeAdj.percent ~= 0.0 then
        totalPercent = totalPercent + timeAdj.percent
    end
    adjustments[#adjustments + 1] = timeAdj

    if active.randomEvent and (active.randomEvent.payoutPercent or 0.0) ~= 0.0 then
        local eventAdj = {
            percent = active.randomEvent.payoutPercent or 0.0,
            label = active.randomEvent.label or 'Dispatch event',
            description = active.randomEvent.description
        }
        totalPercent = totalPercent + eventAdj.percent
        adjustments[#adjustments + 1] = eventAdj
    end

    if active.type == 'trailer' then
        local damageAdj = GetTrailerDamageAdjustment(active.trailerDamagePercent or 0.0)
        if damageAdj.percent ~= 0.0 then
            totalPercent = totalPercent + damageAdj.percent
        end
        adjustments[#adjustments + 1] = damageAdj
    end

    local final = math.floor(base * (1.0 + totalPercent))
    if final < minimum then final = minimum end

    return {
        basePayout = base,
        payout = final,
        totalPercent = totalPercent,
        adjustments = adjustments,
        time = timeAdj,
        damagePercent = active.trailerDamagePercent or 0.0,
        randomEvent = PublicRandomEvent(active.randomEvent)
    }
end

local function EnsureGarageVehicle(citizenid, vehicleType, vehicleIndex)
    local vehicleData = Config.JobVehicles[vehicleType] and Config.JobVehicles[vehicleType][vehicleIndex]
    if not vehicleData then return nil end
    local row = MySQL.single.await('SELECT * FROM trucking_garage WHERE citizenid = ? AND vehicle_type = ? AND vehicle_index = ?', { citizenid, vehicleType, vehicleIndex })
    if not row then
        MySQL.insert.await([[INSERT INTO trucking_garage (citizenid, vehicle_type, vehicle_index, vehicle_label, vehicle_model, plate, props, stored) VALUES (?, ?, ?, ?, ?, ?, NULL, 1)]], {
            citizenid, vehicleType, vehicleIndex, vehicleData.label, GetGarageVehicleModel(vehicleType, vehicleData), GeneratePlate(vehicleData.platePrefix)
        })
        row = MySQL.single.await('SELECT * FROM trucking_garage WHERE citizenid = ? AND vehicle_type = ? AND vehicle_index = ?', { citizenid, vehicleType, vehicleIndex })
    end
    return row
end

local function GetGarageList(citizenid)
    local list = {}
    for vehicleType, vehicles in pairs(Config.JobVehicles) do
        for index, vehicleData in ipairs(vehicles) do
            local row = EnsureGarageVehicle(citizenid, vehicleType, index)
            list[#list + 1] = {
                type = vehicleType,
                index = index,
                label = vehicleData.label,
                model = GetGarageVehicleModel(vehicleType, vehicleData),
                plate = row and row.plate or '',
                stored = row and row.stored == 1 or true,
                props = row and row.props or nil,
                photo = vehicleData.photo,
                trailerPhoto = nil,
                minRank = vehicleData.minRank or 1
            }
        end
    end
    return list
end

lib.callback.register('ls_trucking:server:getDispatchData', function(src)
    if not HasRequiredJob(src) then return { allowed = false, message = 'You are not employed as a trucker.' } end
    local citizenid = GetCitizenId(src)
    local stats = GetTruckingStats(citizenid)
    local jobInfo = GetPlayerJobInfo(src)
    local currentJob = nil
    if ActiveContracts[src] then
        local a = ActiveContracts[src]
        currentJob = { id = a.id, type = a.type, label = a.label, stage = a.stage or 'Active', payout = a.payout, loadedCargo = a.loadedCargo or 0, requiredCargo = a.requiredCargo or 0, currentStop = a.currentStop or 0, totalStops = a.totalStops or 0 }
    end
    return {
        allowed = true,
        player = { name = GetCharacterName(src), citizenid = citizenid, job = jobInfo, jobName = jobInfo.name, jobLabel = jobInfo.label, jobGradeName = jobInfo.gradeName, jobGradeLevel = jobInfo.gradeLevel, jobText = jobInfo.text, rank = stats.rank, rankLabel = stats.rankLabel, xp = stats.xp, nextRankXp = stats.nextRankXp, jobsCompleted = stats.jobsCompleted, reputation = stats.reputation, wallet = stats.totalEarned, totalCancelled = stats.totalCancelled },
        ranks = Config.Ranks,
        contracts = Config.Contracts,
        payouts = Config.Payouts,
        vehicles = Config.JobVehicles,
        priorityLoads = Config.PriorityLoads or {},
        routeTrailers = Config.RouteTrailers or {},
        garage = GetGarageList(citizenid),
        currentJob = currentJob,
        radioFrequency = Config.RadioFrequency
    }
end)

lib.callback.register('ls_trucking:server:spawnGarageVehicle', function(src, vehicleType, vehicleIndex)
    if not HasRequiredJob(src) then return { success = false, message = 'You are not employed as a trucker.' } end
    vehicleIndex = tonumber(vehicleIndex) or 1
    local vehicleData, resolvedIndex = GetVehicleConfig(vehicleType, vehicleIndex)
    if not vehicleData then return { success = false, message = 'Invalid garage vehicle.' } end
    local playerRank = GetPlayerTruckingRank(src)
    if not CheckRankRequirement(playerRank, vehicleData.minRank) then
        return { success = false, message = ('This company vehicle requires trucking rank %s.'):format(vehicleData.minRank or 1) }
    end
    local citizenid = GetCitizenId(src)
    local row = EnsureGarageVehicle(citizenid, vehicleType, resolvedIndex)
    if not row then return { success = false, message = 'Could not load garage vehicle.' } end
    MySQL.update.await('UPDATE trucking_garage SET stored = 0 WHERE citizenid = ? AND vehicle_type = ? AND vehicle_index = ?', { citizenid, vehicleType, resolvedIndex })
    return { success = true, vehicleType = vehicleType, vehicleIndex = resolvedIndex, vehicle = vehicleData, plate = row.plate, props = row.props }
end)

lib.callback.register('ls_trucking:server:returnGarageVehicle', function(src, vehicleType, vehicleIndex, plate, props)
    if not HasRequiredJob(src) then return { success = false, message = 'You are not employed as a trucker.' } end
    vehicleIndex = tonumber(vehicleIndex) or 1
    local citizenid = GetCitizenId(src)
    local row = EnsureGarageVehicle(citizenid, vehicleType, vehicleIndex)
    if not row then return { success = false, message = 'Could not save garage vehicle.' } end
    MySQL.update.await([[UPDATE trucking_garage SET plate = ?, props = ?, stored = 1 WHERE citizenid = ? AND vehicle_type = ? AND vehicle_index = ?]], { plate or row.plate, props, citizenid, vehicleType, vehicleIndex })
    return { success = true }
end)

lib.callback.register('ls_trucking:server:createContract', function(src, contractType, vehicleIndex, reuseVehicle, currentPlate, priorityKey)
    if not HasRequiredJob(src) then return { success = false, message = 'You are not employed as a trucker.' } end
    if ActiveContracts[src] then return { success = false, message = 'You already have an active contract.' } end
    if not Config.Contracts[contractType] then return { success = false, message = 'Invalid contract type.' } end

    local playerRank = GetPlayerTruckingRank(src)
    local selectedVehicle, resolvedVehicleIndex = GetVehicleConfig(contractType, vehicleIndex)
    if not selectedVehicle then return { success = false, message = 'Invalid vehicle selected.' } end

    if not CheckRankRequirement(playerRank, selectedVehicle.minRank) then
        return { success = false, message = ('This vehicle requires trucking rank %s.'):format(selectedVehicle.minRank or 1) }
    end

    local priority, resolvedPriorityKey = GetPriorityConfig(contractType, priorityKey)
    priority = priority or { label = 'Standard Commercial Route', shortLabel = 'Standard', minRank = 1, payoutMultiplier = 1.0, xpMultiplier = 1.0, repBonus = 0 }

    if not CheckRankRequirement(playerRank, priority.minRank) then
        return { success = false, message = ('This priority load requires trucking rank %s.'):format(priority.minRank or 1) }
    end

    local route, routeIndex = PickRoute(contractType, resolvedPriorityKey)
    if not route then return { success = false, message = 'No route configured for this contract type.' } end

    local randomEvent = PickRandomDeliveryEvent(contractType, resolvedPriorityKey)
    local estimatedSeconds = GetEstimatedSeconds(contractType, resolvedPriorityKey, route)

    if randomEvent and randomEvent.estimateDeltaSeconds then
        estimatedSeconds = math.max(300, estimatedSeconds + randomEvent.estimateDeltaSeconds)
    end

    local publicContract = GetPublicContractData(contractType, route, priority, resolvedPriorityKey)
    publicContract.estimatedSeconds = estimatedSeconds
    publicContract.estimatedTime = FormatSeconds(estimatedSeconds)
    publicContract.randomEvent = PublicRandomEvent(randomEvent)

    local payoutData = Config.Payouts[contractType]
    local payoutMultiplier = priority.payoutMultiplier or 1.0
    local xpMultiplier = priority.xpMultiplier or 1.0
    local payout = math.floor(math.random(payoutData.min, payoutData.max) * payoutMultiplier)
    local xp = math.floor((payoutData.xp or 0) * xpMultiplier)
    local rep = (payoutData.rep or 0) + (priority.repBonus or 0) + (randomEvent and randomEvent.repBonus or 0)

    local plate = currentPlate
    if not reuseVehicle or not plate or plate == '' then
        local garage = EnsureGarageVehicle(GetCitizenId(src), contractType, resolvedVehicleIndex)
        plate = garage and garage.plate or GeneratePlate(selectedVehicle.platePrefix)
    end

    local totalStops = publicContract.dropoffs and #publicContract.dropoffs or 1
    local contractId = GenerateContractId(src)

    local cargoPool = route.cargoTypes or priority.cargoTypes or route.cargoType or priority.cargoType or (Config.DefaultCargoType and Config.DefaultCargoType[contractType])
    local cargoType = nil
    local cargoConfig = nil
    local cargoManifest = nil

    if contractType ~= 'trailer' then
        cargoManifest = BuildPackageManifest(contractId, route.label, route, contractType, cargoPool)
        if not cargoManifest or #cargoManifest == 0 then
            return { success = false, message = 'Invalid cargo manifest for this contract.' }
        end

        cargoType = cargoManifest[1].cargoType
        cargoConfig = GetCargoConfig(contractType, cargoType)

        publicContract.cargoType = cargoType
        publicContract.cargoItem = cargoManifest[1].cargoItem
        publicContract.cargoLabel = #NormalizeCargoPool(contractType, cargoPool) > 1 and 'Mixed Delivery Cargo' or cargoManifest[1].cargoLabel
        publicContract.cargoTypes = NormalizeCargoPool(contractType, cargoPool)
        publicContract.manifest = cargoManifest
    end

    local active = {
        id = contractId,
        type = contractType,
        label = publicContract.label,
        routeLabel = route.label,
        routeLength = route.routeLength,
        priorityKey = resolvedPriorityKey,
        priorityLabel = priority.label,
        payout = payout,
        basePayout = payout,
        xp = xp,
        rep = rep,
        estimatedSeconds = estimatedSeconds,
        randomEvent = randomEvent,
        routeTrailer = publicContract.routeTrailer,
        trailerDepot = publicContract.trailerDepot,
        trailerLabel = publicContract.routeTrailer and publicContract.routeTrailer.label or nil,
        trailerDamagePercent = 0.0,
        safeSpeed = publicContract.routeTrailer and publicContract.routeTrailer.safeSpeed or (Config.SpeedRisk and Config.SpeedRisk.DefaultSafeSpeed) or 75.0,
        vehicleLabel = selectedVehicle.label,
        plate = plate,
        vehicleIndex = resolvedVehicleIndex,
        reuseVehicle = reuseVehicle == true,
        routeIndex = routeIndex,
        routeData = route,
        startedAt = os.time(),
        routeCompleted = false,
        paid = false,
        cargoPickedUp = 0,
        loadedCargo = contractType == 'trailer' and 1 or 0,
        deliveredCargo = 0,
        deliveredAtStop = 0,
        requiredCargo = publicContract.requiredCargo or 1,
        currentStop = 0,
        totalStops = totalStops,
        stage = contractType == 'trailer' and 'Hook up trailer' or 'Talk to pickup worker',
        trailerHooked = false,
        cargoType = cargoType,
        cargoItem = cargoConfig and cargoConfig.item or nil,
        cargoLabel = cargoConfig and cargoConfig.label or nil,
        cargoManifest = cargoManifest,
        cargoVerified = false,
        trailerContents = route.trailerContents or (publicContract.routeTrailer and publicContract.routeTrailer.contents) or nil,
        trailerInstructions = route.trailerInstructions or (publicContract.routeTrailer and publicContract.routeTrailer.instructions) or nil
    }

    ActiveContracts[src] = active
    GiveContractManifest(src, active)

    return {
        success = true,
        contractId = contractId,
        contractType = contractType,
        vehicleIndex = resolvedVehicleIndex,
        routeIndex = routeIndex,
        reuseVehicle = reuseVehicle == true,
        payout = payout,
        xp = xp,
        rep = rep,
        plate = plate,
        contract = publicContract,
        vehicle = selectedVehicle
    }
end)


lib.callback.register('ls_trucking:server:pickupCargoOne', function(src)
    local a = ActiveContracts[src]
    if not a then return { success = false, message = 'You do not have an active contract.' } end
    if a.type == 'trailer' then return { success = false, message = 'Trailer hauling does not use cargo items.' } end
    if a.cargoPickedUp >= a.requiredCargo then return { success = false, message = 'You already picked up all cargo for this route.' } end

    local nextIndex = a.cargoPickedUp + 1
    local manifestEntry = a.cargoManifest and a.cargoManifest[nextIndex] or nil
    if not manifestEntry then return { success = false, message = 'Could not find the next manifest item.' } end

    local cargo = GetCargoConfig(a.type, manifestEntry.cargoType)
    if not cargo then return { success = false, message = 'Invalid cargo type.' } end

    local receiver = manifestEntry.receiver or 'Route Receiver'
    local dropoff = manifestEntry.dropoff or receiver
    local instructions = manifestEntry.instructions or ('Deliver to %s.'):format(dropoff)

    local metadata = {
        contract = a.id,
        type = a.type,
        cargoType = manifestEntry.cargoType,
        label = cargo.label,
        receiver = receiver,
        dropoff = dropoff,
        stop = manifestEntry.stop,
        packageNumber = nextIndex,
        route = a.routeLabel,
        description = ('Receiver: %s\nDropoff: %s\nRoute: %s\nInstructions: %s'):format(receiver, dropoff, a.routeLabel or 'Route', instructions)
    }

    local added = AddPlayerItem(src, cargo.item, 1, metadata)
    if not added then return { success = false, message = 'Could not add cargo. Check your inventory space.' } end

    a.cargoPickedUp = a.cargoPickedUp + 1
    a.stage = 'Carry cargo to vehicle'

    return { success = true, item = cargo.item, label = cargo.label, cargoType = manifestEntry.cargoType, receiver = receiver, pickedUp = a.cargoPickedUp, required = a.requiredCargo }
end)

lib.callback.register('ls_trucking:server:loadCargoOne', function(src)
    local a = ActiveContracts[src]
    if not a then return { success = false, message = 'You do not have an active contract.' } end
    if a.type == 'trailer' then return { success = false, message = 'Trailer hauling does not use cargo items.' } end
    if a.loadedCargo >= a.requiredCargo then return { success = false, message = 'Vehicle already has all required cargo.' } end

    local manifestEntry = a.cargoManifest and a.cargoManifest[a.loadedCargo + 1] or nil
    if not manifestEntry then return { success = false, message = 'Could not find the cargo item to load.' } end

    local cargo = GetCargoConfig(a.type, manifestEntry.cargoType)
    if not cargo then return { success = false, message = 'Invalid cargo type.' } end

    if GetInventoryItemCount(src, cargo.item) < 1 then return { success = false, message = ('You need a %s in your inventory.'):format(cargo.label) } end
    if not RemovePlayerItem(src, cargo.item, 1) then return { success = false, message = 'Could not remove cargo from your inventory.' } end

    local added = AddTrunkItem(a.plate, cargo.item, 1, { contract = a.id, type = a.type, cargoType = manifestEntry.cargoType, label = cargo.label, receiver = manifestEntry.receiver, stop = manifestEntry.stop })
    if not added then AddPlayerItem(src, cargo.item, 1) return { success = false, message = 'Could not add cargo to the vehicle trunk.' } end

    a.loadedCargo = a.loadedCargo + 1
    local ready = a.loadedCargo >= a.requiredCargo

    if ready then
        a.stage = 'Verify loaded cargo'
        a.cargoVerified = false
    else
        a.stage = 'Load cargo into vehicle'
    end

    return { success = true, loaded = a.loadedCargo, required = a.requiredCargo, ready = ready, verified = a.cargoVerified == true, currentStop = a.currentStop }
end)

lib.callback.register('ls_trucking:server:verifyLoadedCargo', function(src)
    local a = ActiveContracts[src]
    if not a then return { success = false, message = 'You do not have an active contract.' } end
    if a.type == 'trailer' then return { success = false, message = 'Trailer hauling does not use cargo boxes.' } end

    local requiredByItem = {}
    for _, entry in ipairs(a.cargoManifest or {}) do
        if entry.cargoItem then
            requiredByItem[entry.cargoItem] = (requiredByItem[entry.cargoItem] or 0) + 1
        end
    end

    local totalLoaded = 0
    for item, required in pairs(requiredByItem) do
        local trunkCount = GetInventoryItemCount(GetTrunkId(a.plate), item)
        if trunkCount < required then
            return { success = false, message = ('Cargo verification failed. Trunk has %s/%s %s.'):format(trunkCount, required, item) }
        end
        totalLoaded = totalLoaded + trunkCount
    end

    a.cargoVerified = true
    a.stage = 'Deliver cargo'
    a.currentStop = 1
    a.routeStartedAt = os.time()

    return { success = true, loaded = totalLoaded, required = a.requiredCargo, currentStop = a.currentStop }
end)

lib.callback.register('ls_trucking:server:grabCargoFromVehicle', function(src)
    local a = ActiveContracts[src]
    if not a then return { success = false, message = 'You do not have an active contract.' } end
    if a.type == 'trailer' then return { success = false, message = 'Trailer cargo cannot be grabbed this way.' } end
    if not a.cargoVerified then return { success = false, message = 'Verify the loaded cargo before starting deliveries.' } end

    local manifestEntry = GetManifestEntryForStop(a, a.currentStop, a.deliveredAtStop)
    if not manifestEntry then return { success = false, message = 'Could not find the next delivery item for this stop.' } end

    local cargo = GetCargoConfig(a.type, manifestEntry.cargoType)
    if not cargo then return { success = false, message = 'Invalid cargo type.' } end

    if GetInventoryItemCount(GetTrunkId(a.plate), cargo.item) < 1 then return { success = false, message = ('There is no %s in the vehicle trunk.'):format(cargo.label) } end
    if not RemoveTrunkItem(a.plate, cargo.item, 1) then return { success = false, message = 'Could not remove cargo from vehicle trunk.' } end

    local receiver = manifestEntry.receiver or 'Route Receiver'
    local metadata = {
        contract = a.id,
        type = a.type,
        cargoType = manifestEntry.cargoType,
        label = cargo.label,
        receiver = receiver,
        dropoff = manifestEntry.dropoff or receiver,
        route = a.routeLabel,
        stop = manifestEntry.stop,
        description = ('Receiver: %s\nDropoff: %s\nRoute: %s'):format(receiver, manifestEntry.dropoff or receiver, a.routeLabel or 'Route')
    }

    local added = AddPlayerItem(src, cargo.item, 1, metadata)
    if not added then AddTrunkItem(a.plate, cargo.item, 1) return { success = false, message = 'Could not add cargo to your inventory.' } end
    return { success = true, label = cargo.label, cargoType = manifestEntry.cargoType, receiver = receiver }
end)

lib.callback.register('ls_trucking:server:deliverCargoOne', function(src)
    local a = ActiveContracts[src]
    if not a then return { success = false, message = 'You do not have an active contract.' } end
    if a.type == 'trailer' then return { success = false, message = 'Trailer jobs are finalized with the receiver.' } end
    if not a.cargoVerified then return { success = false, message = 'Verify the loaded cargo before making deliveries.' } end

    local publicContract = GetPublicContractData(a.type, a.routeData or Config.Contracts[a.type].routes[a.routeIndex])
    local stop = publicContract.dropoffs and publicContract.dropoffs[a.currentStop]
    if not stop then return { success = false, message = 'Invalid delivery stop.' } end

    local manifestEntry = GetManifestEntryForStop(a, a.currentStop, a.deliveredAtStop)
    if not manifestEntry then return { success = false, message = 'Could not find the next delivery item for this stop.' } end

    local cargo = GetCargoConfig(a.type, manifestEntry.cargoType)
    if not cargo then return { success = false, message = 'Invalid cargo type.' } end

    if GetInventoryItemCount(src, cargo.item) < 1 then return { success = false, message = ('You need to grab a %s from the vehicle first.'):format(cargo.label) } end
    if not RemovePlayerItem(src, cargo.item, 1) then return { success = false, message = 'Could not remove cargo from your inventory.' } end

    a.deliveredCargo = a.deliveredCargo + 1
    a.deliveredAtStop = a.deliveredAtStop + 1
    a.loadedCargo = math.max(a.loadedCargo - 1, 0)

    local requiredAtStop = stop.unload or 1
    local stopComplete = a.deliveredAtStop >= requiredAtStop
    if stopComplete then a.currentStop = a.currentStop + 1 a.deliveredAtStop = 0 end

    local routeComplete = a.currentStop > a.totalStops
    a.stage = routeComplete and 'Route complete' or (stopComplete and 'Deliver cargo' or 'Continue unloading current stop')

    return { success = true, delivered = a.deliveredCargo, loaded = a.loadedCargo, currentStop = a.currentStop, totalStops = a.totalStops, deliveredAtStop = a.deliveredAtStop, requiredAtStop = requiredAtStop, stopComplete = stopComplete, routeComplete = routeComplete }
end)

lib.callback.register('ls_trucking:server:markTrailerHooked', function(src)
    local a = ActiveContracts[src]
    if not a then return { success = false, message = 'You do not have an active contract.' } end
    if a.type ~= 'trailer' then return { success = false, message = 'This is not a trailer contract.' } end
    if a.trailerHooked then return { success = true, alreadyHooked = true } end
    a.stage = 'Deliver trailer'
    a.trailerHooked = true
    a.routeStartedAt = os.time()
    return { success = true }
end)

lib.callback.register('ls_trucking:server:finalizeTrailerDelivery', function(src, damageData)
    local a = ActiveContracts[src]
    if not a then return { success = false, message = 'You do not have an active contract.' } end
    if a.type ~= 'trailer' then return { success = false, message = 'This is not a trailer contract.' } end

    if type(damageData) == 'table' then
        local startHealth = tonumber(damageData.startBody) or 1000.0
        local endHealth = tonumber(damageData.endBody) or startHealth
        if startHealth <= 0.0 then startHealth = 1000.0 end
        local loss = math.max(0.0, startHealth - endHealth)
        a.trailerDamagePercent = math.min(100.0, (loss / startHealth) * 100.0)
    end

    a.loadedCargo = 0
    a.stage = 'Route complete'
    return { success = true }
end)

RegisterNetEvent('ls_trucking:server:routeComplete', function(contractId)
    local src = source
    local a = ActiveContracts[src]
    if not a or a.id ~= contractId or a.routeCompleted then return end
    a.routeCompleted = true
    RemoveAllPlayerCargo(src, a.type, a.cargoType, a.cargoManifest)
    RemoveAllTrunkCargo(a.plate, a.type, a.cargoType, a.cargoManifest)
    RemoveContractManifests(src)
    if Config.PayWhenRouteComplete and not a.paid then
        a.paid = true
        local citizenid = GetCitizenId(src)
        local payoutResult = BuildPayoutResult(a)
        local finalPayout = payoutResult.payout

        AddMoney(src, finalPayout, 'ls-trucking-route-complete')
        AddTruckingStats(citizenid, a.xp, a.rep, finalPayout)
        MySQL.insert.await([[INSERT INTO trucking_history (citizenid, contract_id, contract_type, route_label, vehicle_label, payout, xp, reputation) VALUES (?, ?, ?, ?, ?, ?, ?, ?)]], { citizenid, a.id, a.type, ((a.priorityLabel and (a.priorityLabel .. ' - ') or '') .. (a.routeLabel or 'Route')), 'Company Vehicle', finalPayout, a.xp, a.rep })
        local jobInfo = GetPlayerJobInfo(src)
        TriggerClientEvent('ls_trucking:client:routePaid', src, { payout = finalPayout, basePayout = payoutResult.basePayout, xp = a.xp, rep = a.rep, adjustments = payoutResult.adjustments, time = payoutResult.time, randomEvent = payoutResult.randomEvent, damagePercent = payoutResult.damagePercent, contractId = a.id, contractType = a.type, contractLabel = a.label, priorityLabel = a.priorityLabel, routeLabel = a.routeLabel, routeLength = a.routeLength, vehicleLabel = a.type == 'trailer' and ((a.vehicleLabel or 'Truck') .. ' + ' .. (a.trailerLabel or 'Assigned Trailer')) or (a.vehicleLabel or 'Company Vehicle'), estimatedSeconds = a.estimatedSeconds, deliveredCargo = a.deliveredCargo, requiredCargo = a.requiredCargo, totalStops = a.totalStops, trailerContents = a.trailerContents, safeSpeed = a.safeSpeed, driverName = GetCharacterName(src), jobText = jobInfo.text, completedAt = os.date('%Y-%m-%d %H:%M:%S') })
        ActiveContracts[src] = nil
    end
end)

RegisterNetEvent('ls_trucking:server:returnVehicleBonus', function()
    local src = source
    if not Config.ReturnVehicleBonusEnabled then return end
    AddMoney(src, Config.ReturnVehicleBonus, 'ls-trucking-return-bonus')
    TriggerClientEvent('ls_trucking:client:returnBonusPaid', src, Config.ReturnVehicleBonus)
end)

RegisterNetEvent('ls_trucking:server:cancelContract', function(reason)
    local src = source
    local a = ActiveContracts[src]

    if a then
        if reason == '__system_cleanup' then
            CleanupContractCargo(src)
            ActiveContracts[src] = nil
            return
        end

        local repLoss = 1

        if Config.CancelPenalty and Config.CancelPenalty.Enabled then
            repLoss = tonumber(Config.CancelPenalty.ReputationLoss) or 1
        end

        AddCancelledRoute(GetCitizenId(src), repLoss)
        CleanupContractCargo(src)
        ActiveContracts[src] = nil

        TriggerClientEvent('ls_trucking:client:contractCancelled', src, {
            repLoss = repLoss,
            reason = reason or 'Not specified'
        })
    end
end)

AddEventHandler('playerDropped', function()
    ActiveContracts[source] = nil
end)
