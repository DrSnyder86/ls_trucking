local ActiveContracts = {}
local CheckedOutVehicles = {}
local ReusableVehicles = {}
local PlayerCooldowns = {}
local PlayerDutyStates = {}
local RouteSummary = LS_Trucking and LS_Trucking.RouteSummary or {}
local Ids = LS_Trucking and LS_Trucking.Ids or {}
local FrameworkBridge = LS_Trucking and LS_Trucking.Framework or {}
local Contractors = LS_Trucking and LS_Trucking.Contractors or {}
local DepotVehicles = LS_Trucking and LS_Trucking.DepotVehicles or {}
local Cargo = LS_Trucking and LS_Trucking.Cargo or {}
local Routes = LS_Trucking and LS_Trucking.Routes or {}
local Admin = LS_Trucking and LS_Trucking.Admin or {}
local DispatchData = LS_Trucking and LS_Trucking.DispatchData or {}
local JobBlips = LS_Trucking and LS_Trucking.JobBlips or {}
local ServiceBay = LS_Trucking and LS_Trucking.ServiceBay or {}
local DepotVehicleServerContext = nil
local CargoServerContext = nil
local RouteServerContext = nil
local AdminServerContext = nil
local DispatchDataServerContext = nil
local JobBlipsServerContext = nil
local ContractorServerContext = nil
local ServiceBayServerContext = nil
local CreateContractForPlayer = nil

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

local Framework = FrameworkBridge.Init and FrameworkBridge.Init() or 'standalone'

local function GetPlayer(src)
    return FrameworkBridge.GetPlayer and FrameworkBridge.GetPlayer(src) or nil
end

local function GetCitizenId(src)
    return FrameworkBridge.GetIdentifier and FrameworkBridge.GetIdentifier(src) or ('source:%s'):format(src)
end

local function GetCharacterName(src)
    return FrameworkBridge.GetCharacterName and FrameworkBridge.GetCharacterName(src) or GetPlayerName(src) or 'Driver'
end


local function GetPlayerJobInfo(src)
    return FrameworkBridge.GetJobInfo and FrameworkBridge.GetJobInfo(src) or {
        name = 'unemployed',
        label = 'Unemployed',
        gradeName = 'None',
        gradeLevel = 0,
        text = 'Unemployed - None'
    }
end

local function HasRequiredJob(src)
    return FrameworkBridge.HasRequiredJob and FrameworkBridge.HasRequiredJob(src) == true
end

local function IsDutyRequired()
    return Config.RequireJob == true and Config.RequireDuty ~= false
end

local function GetPlayerDutyState(src)
    if not IsDutyRequired() then return true, 'disabled' end

    local jobInfo = GetPlayerJobInfo(src)
    if jobInfo and jobInfo.onDuty ~= nil then
        return jobInfo.onDuty == true, 'framework'
    end

    return PlayerDutyStates[src] == true, 'internal'
end

local function GetWorkAccessFailure(src)
    if not HasRequiredJob(src) then
        return T('error.not_trucker', { job = Config.JobName or 'the required job' })
    end

    if IsDutyRequired() then
        local onDuty = GetPlayerDutyState(src)
        if not onDuty then
            return T('error.must_clock_in')
        end
    end

    return nil
end

local function RequireWorkAccess(src)
    local message = GetWorkAccessFailure(src)
    if message then return false, message end
    return true
end

local function GetDutyTargetCoords()
    local duty = Config.DutyTarget or Config.DutyLocation or {}
    return duty.coords or (Config.DispatchPed and Config.DispatchPed.coords) or (Config.Depot and Config.Depot.terminal)
end

local function AddMoney(src, amount, reason)
    return FrameworkBridge.AddMoney and FrameworkBridge.AddMoney(src, amount, reason) == true
end

local function RemoveMoney(src, amount, reason, accountOverride)
    return FrameworkBridge.RemoveMoney and FrameworkBridge.RemoveMoney(src, amount, reason, accountOverride) == true
end

local function GetSecurityConfig()
    return Config.Security or {}
end

local function IsAdmin(src)
    return FrameworkBridge.IsAdmin and FrameworkBridge.IsAdmin(src) == true
end

local function HasAdminCommandPermission(src)
    return IsAdmin(src)
end

local function GetSecurityCooldown(name, fallback)
    local cfg = GetSecurityConfig()
    local cooldowns = cfg.Cooldowns or {}
    return tonumber(cooldowns[name]) or fallback or 1000
end

local function CheckRateLimit(src, action, cooldownMs)
    if not src or src == 0 then return true end

    local now = GetGameTimer()
    PlayerCooldowns[src] = PlayerCooldowns[src] or {}

    local last = PlayerCooldowns[src][action]
    if last and now - last < (cooldownMs or 1000) then
        return false
    end

    PlayerCooldowns[src][action] = now
    return true
end

local function RateLimitResponse()
    return { success = false, message = T('error.wait_moment') }
end

local DatabaseMigrationsReady = false
local DatabaseMigrationsRunning = false

local function EnsureBaseTables()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS player_trucking (
            citizenid VARCHAR(64) NOT NULL,
            driver_name VARCHAR(96) NULL DEFAULT NULL,
            xp INT NOT NULL DEFAULT 0,
            reputation INT NOT NULL DEFAULT 0,
            jobs_completed INT NOT NULL DEFAULT 0,
            completed_route_streak INT NOT NULL DEFAULT 0,
            total_earned INT NOT NULL DEFAULT 0,
            total_routes_cancelled INT NOT NULL DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (citizenid)
        )
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS trucking_history (
            id INT AUTO_INCREMENT PRIMARY KEY,
            citizenid VARCHAR(64) NOT NULL,
            contract_id VARCHAR(64) NOT NULL,
            contract_type VARCHAR(32) NOT NULL,
            route_label VARCHAR(128) NOT NULL,
            vehicle_label VARCHAR(128) NOT NULL,
            payout INT NOT NULL DEFAULT 0,
            xp INT NOT NULL DEFAULT 0,
            reputation INT NOT NULL DEFAULT 0,
            completed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS trucking_garage (
            id INT AUTO_INCREMENT PRIMARY KEY,
            citizenid VARCHAR(64) NOT NULL,
            vehicle_type VARCHAR(32) NOT NULL,
            vehicle_index INT NOT NULL DEFAULT 1,
            vehicle_label VARCHAR(128) NOT NULL,
            vehicle_model VARCHAR(64) NOT NULL,
            plate VARCHAR(16) NOT NULL,
            props LONGTEXT NULL,
            stored TINYINT(1) NOT NULL DEFAULT 1,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            UNIQUE KEY unique_trucking_garage_vehicle (citizenid, vehicle_type, vehicle_index)
        )
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS trucking_contractor_profiles (
            citizenid VARCHAR(64) NOT NULL,
            licensed TINYINT(1) NOT NULL DEFAULT 0,
            license_purchased_at TIMESTAMP NULL DEFAULT NULL,
            contractor_rep INT NOT NULL DEFAULT 0,
            daily_route_key VARCHAR(64) NULL DEFAULT NULL,
            daily_route_selected_at TIMESTAMP NULL DEFAULT NULL,
            daily_route_date VARCHAR(16) NULL DEFAULT NULL,
            daily_route_completed TINYINT(1) NOT NULL DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (citizenid)
        )
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS trucking_contractor_vehicles (
            id INT AUTO_INCREMENT PRIMARY KEY,
            citizenid VARCHAR(64) NOT NULL,
            vehicle_type VARCHAR(32) NOT NULL,
            vehicle_index INT NOT NULL DEFAULT 1,
            vehicle_label VARCHAR(128) NOT NULL,
            vehicle_model VARCHAR(64) NOT NULL,
            plate VARCHAR(16) NOT NULL,
            props LONGTEXT NULL,
            fuel FLOAT NOT NULL DEFAULT 100,
            engine_health FLOAT NOT NULL DEFAULT 1000,
            body_health FLOAT NOT NULL DEFAULT 1000,
            original_price INT NOT NULL DEFAULT 0,
            mileage FLOAT NOT NULL DEFAULT 0,
            stored TINYINT(1) NOT NULL DEFAULT 1,
            out_state TINYINT(1) NOT NULL DEFAULT 0,
            purchased_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            UNIQUE KEY unique_trucking_contractor_plate (plate),
            KEY index_trucking_contractor_owner (citizenid)
        )
    ]])
end

local function DatabaseColumnExists(tableName, columnName)
    local row = MySQL.single.await([[
        SELECT COUNT(*) AS count
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
            AND TABLE_NAME = ?
            AND COLUMN_NAME = ?
    ]], { tableName, columnName }) or {}

    return (tonumber(row.count) or 0) > 0
end

local function EnsureDatabaseColumn(tableName, columnName, definition)
    if DatabaseColumnExists(tableName, columnName) then return false end
    MySQL.query.await(('ALTER TABLE `%s` ADD COLUMN `%s` %s'):format(tableName, columnName, definition))
    return true
end

local function RestoreVehicleStorageStateOnStartup()
    local restoredCompanyVehicles = MySQL.update.await('UPDATE trucking_garage SET stored = 1 WHERE stored = 0') or 0
    local restoredContractorVehicles = MySQL.update.await('UPDATE trucking_contractor_vehicles SET stored = 1, out_state = 0 WHERE stored = 0 OR out_state = 1') or 0

    if Config.Debug and (restoredCompanyVehicles > 0 or restoredContractorVehicles > 0) then
        print(('[ls_trucking] Stored %s company vehicle(s) and %s contractor vehicle(s) after resource start.'):format(restoredCompanyVehicles, restoredContractorVehicles))
    end
end

local function EnsureDatabaseMigrations()
    if DatabaseMigrationsReady then return end

    if DatabaseMigrationsRunning then
        while DatabaseMigrationsRunning do Wait(50) end
        return
    end

    DatabaseMigrationsRunning = true
    local ok, err = pcall(function()
        EnsureBaseTables()
        EnsureDatabaseColumn('player_trucking', 'driver_name', 'VARCHAR(96) NULL DEFAULT NULL')
        EnsureDatabaseColumn('player_trucking', 'total_routes_cancelled', 'INT NOT NULL DEFAULT 0')
        EnsureDatabaseColumn('player_trucking', 'completed_route_streak', 'INT NOT NULL DEFAULT 0')
        EnsureDatabaseColumn('trucking_garage', 'stored', 'TINYINT(1) NOT NULL DEFAULT 1')
        EnsureDatabaseColumn('trucking_contractor_profiles', 'license_purchased_at', 'TIMESTAMP NULL DEFAULT NULL')
        EnsureDatabaseColumn('trucking_contractor_profiles', 'contractor_rep', 'INT NOT NULL DEFAULT 0')
        EnsureDatabaseColumn('trucking_contractor_profiles', 'daily_route_key', 'VARCHAR(64) NULL DEFAULT NULL')
        EnsureDatabaseColumn('trucking_contractor_profiles', 'daily_route_selected_at', 'TIMESTAMP NULL DEFAULT NULL')
        EnsureDatabaseColumn('trucking_contractor_profiles', 'daily_route_date', 'VARCHAR(16) NULL DEFAULT NULL')
        EnsureDatabaseColumn('trucking_contractor_profiles', 'daily_route_completed', 'TINYINT(1) NOT NULL DEFAULT 0')
        EnsureDatabaseColumn('trucking_contractor_vehicles', 'props', 'LONGTEXT NULL')
        EnsureDatabaseColumn('trucking_contractor_vehicles', 'fuel', 'FLOAT NOT NULL DEFAULT 100')
        EnsureDatabaseColumn('trucking_contractor_vehicles', 'engine_health', 'FLOAT NOT NULL DEFAULT 1000')
        EnsureDatabaseColumn('trucking_contractor_vehicles', 'body_health', 'FLOAT NOT NULL DEFAULT 1000')
        EnsureDatabaseColumn('trucking_contractor_vehicles', 'original_price', 'INT NOT NULL DEFAULT 0')
        EnsureDatabaseColumn('trucking_contractor_vehicles', 'mileage', 'FLOAT NOT NULL DEFAULT 0')
        EnsureDatabaseColumn('trucking_contractor_vehicles', 'stored', 'TINYINT(1) NOT NULL DEFAULT 1')
        EnsureDatabaseColumn('trucking_contractor_vehicles', 'out_state', 'TINYINT(1) NOT NULL DEFAULT 0')
        RestoreVehicleStorageStateOnStartup()
        DatabaseMigrationsReady = true
    end)
    DatabaseMigrationsRunning = false

    if not ok then error(err) end
end

local function NormalizePlateText(plate)
    return TrimString(plate):upper():gsub('%s+', '')
end

local function CanonicalPlateText(plate)
    local normalized = NormalizePlateText(plate)
    if #normalized > 8 then normalized = normalized:sub(1, 8) end
    return normalized
end

local function ClampText(value, maxLength)
    value = TrimString(value)
    maxLength = maxLength or 128
    if #value > maxLength then value = value:sub(1, maxLength) end
    return value
end

local function SanitizeVehicleProps(props, canonicalPlate)
    if props == nil or props == '' then return nil end

    if type(props) == 'table' then
        props = json.encode(props)
    else
        props = tostring(props)
    end

    local maxLength = tonumber((Config.Security and Config.Security.MaxSavedPropsLength) or 24000) or 24000
    if #props > maxLength then
        return nil, T('error.vehicle_props_too_large')
    end

    local ok, decoded = pcall(json.decode, props)
    if not ok or type(decoded) ~= 'table' then
        return nil, T('error.vehicle_props_invalid')
    end

    if canonicalPlate and canonicalPlate ~= '' then
        decoded.plate = CanonicalPlateText(canonicalPlate)
        props = json.encode(decoded)
        if #props > maxLength then
            return nil, T('error.vehicle_props_too_large')
        end
    end

    return props
end

local function TrackCheckedOutVehicle(src, vehicleType, vehicleIndex, plate, sourceLabel)
    if not src or src <= 0 or not plate or plate == '' then return end
    local canonicalPlate = CanonicalPlateText(plate)
    if canonicalPlate == '' then return end

    CheckedOutVehicles[src] = {
        type = vehicleType,
        index = tonumber(vehicleIndex) or 1,
        plate = canonicalPlate,
        source = sourceLabel or 'company',
        bonusPaid = false
    }

    if Config.Keys and Config.Keys.OwnerOnly ~= false then
        TriggerClientEvent('ls_trucking:client:syncVehicleKeyOwner', -1, canonicalPlate, src, sourceLabel or 'company')
    end

    if JobBlips.QueueUpdate then JobBlips.QueueUpdate() end
end

local function ClearVehicleSession(src)
    CheckedOutVehicles[src] = nil
    ReusableVehicles[src] = nil

    if JobBlips.QueueUpdate then JobBlips.QueueUpdate() end
end

local function GetReusableVehicle(src)
    return ReusableVehicles[src] or CheckedOutVehicles[src]
end

local function GetConfigCoord3(coords)
    if not coords or not coords.x or not coords.y or not coords.z then return nil end
    return vector3(coords.x + 0.0, coords.y + 0.0, coords.z + 0.0)
end

local function GetSourceCoords(src)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return nil end

    local ok, coords = pcall(GetEntityCoords, ped)
    if ok and coords then return coords end
    return nil
end

local function GetDistanceLimit(key, fallback)
    local cfg = GetSecurityConfig()
    local distances = cfg.DistanceChecks or {}
    return tonumber(distances[key]) or fallback or 15.0
end

local function RequireServerNear(src, coords, distance, message)
    local cfg = GetSecurityConfig()
    if cfg.ServerDistanceChecks == false then return true end

    local targetCoords = GetConfigCoord3(coords)
    if not targetCoords then return true end

    local playerCoords = GetSourceCoords(src)
    if not playerCoords then
        return false, T('error.position_unverified')
    end

    if #(playerCoords - targetCoords) <= (distance or 15.0) then
        return true
    end

    return false, message or T('error.too_far')
end

local function GetContractPickupCoords(active)
    local contract = active and Config.Contracts and Config.Contracts[active.type]
    return contract and contract.pickup and contract.pickup.coords or nil
end

local function GetCompletionCoords(active)
    if not active then return nil end

    if active.type == 'trailer' then
        return active.routeData and active.routeData.receiverPed and active.routeData.receiverPed.coords
            or active.routeData and active.routeData.trailerDrop and active.routeData.trailerDrop.coords
    end

    local dropoffs = active.routeData and active.routeData.dropoffs
    return dropoffs and dropoffs[active.totalStops or #dropoffs] and dropoffs[active.totalStops or #dropoffs].coords or nil
end

local function NotifySecurityFailure(src, message)
    if src and src > 0 and message and message ~= '' then
        TriggerClientEvent('ls_trucking:client:notify', src, message, 'error')
    end
end

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
    EnsureDatabaseMigrations()
    MySQL.insert.await([[INSERT IGNORE INTO player_trucking (citizenid, xp, reputation, jobs_completed, total_earned, total_routes_cancelled) VALUES (?, 0, 0, 0, 0, 0)]], { citizenid })
end

local function UpdateTruckingDriverName(citizenid, name)
    local driverName = TrimString(name)
    if citizenid == nil or citizenid == '' or driverName == '' then return end

    MySQL.update.await('UPDATE player_trucking SET driver_name = ? WHERE citizenid = ?', {
        driverName:sub(1, 96),
        citizenid
    })
end

local function GetTruckingStats(citizenid)
    EnsureTruckingStats(citizenid)
    local row = MySQL.single.await('SELECT * FROM player_trucking WHERE citizenid = ?', { citizenid }) or {}
    local xp = row.xp or 0
    local rank, rankLabel, nextRankXp = GetRankFromXp(xp)
    return { xp = xp, reputation = row.reputation or 0, jobsCompleted = row.jobs_completed or 0, completedRouteStreak = row.completed_route_streak or 0, totalEarned = row.total_earned or 0, totalCancelled = row.total_routes_cancelled or 0, rank = rank, rankLabel = rankLabel, nextRankXp = nextRankXp }
end

local function BuildPlayerPayload(src)
    local citizenid = GetCitizenId(src)
    local stats = GetTruckingStats(citizenid)
    local jobInfo = GetPlayerJobInfo(src)
    local characterName = GetCharacterName(src)
    local onDuty = GetPlayerDutyState(src)
    UpdateTruckingDriverName(citizenid, characterName)

    return {
        name = characterName,
        citizenid = citizenid,
        job = jobInfo,
        jobName = jobInfo.name,
        jobLabel = jobInfo.label,
        jobGradeName = jobInfo.gradeName,
        jobGradeLevel = jobInfo.gradeLevel,
        jobText = jobInfo.text,
        onDuty = onDuty == true,
        rank = stats.rank,
        rankLabel = stats.rankLabel,
        xp = stats.xp,
        nextRankXp = stats.nextRankXp,
        jobsCompleted = stats.jobsCompleted,
        completedRouteStreak = stats.completedRouteStreak,
        reputation = stats.reputation,
        wallet = stats.totalEarned,
        totalCancelled = stats.totalCancelled
    }
end

local function GetUIAccess(src)
    local access, message = RequireWorkAccess(src)
    if not access then
        return { allowed = false, message = message }
    end

    return {
        allowed = true,
        player = BuildPlayerPayload(src)
    }
end

lib.callback.register('ls_trucking:server:toggleDuty', function(src)
    if not HasRequiredJob(src) then
        return {
            success = false,
            message = T('error.not_trucker', { job = Config.JobName or 'the required job' })
        }
    end

    local dutyConfig = Config.DutyTarget or Config.DutyLocation or {}
    if dutyConfig.enabled == false then
        return { success = false, message = T('duty.disabled') }
    end

    local ok, distanceMessage = RequireServerNear(
        src,
        GetDutyTargetCoords(),
        GetDistanceLimit('Duty', tonumber(dutyConfig.radius) or 5.0),
        T('duty.need_dispatch')
    )

    if not ok then
        return { success = false, message = distanceMessage or T('duty.need_dispatch') }
    end

    local currentDuty, source = GetPlayerDutyState(src)
    local nextDuty = not currentDuty

    if source == 'framework' then
        if FrameworkBridge.SetDuty and FrameworkBridge.SetDuty(src, nextDuty) then
            if JobBlips.QueueUpdate then JobBlips.QueueUpdate() end

            return {
                success = true,
                onDuty = nextDuty,
                message = nextDuty and T('duty.on') or T('duty.off')
            }
        end

        return {
            success = false,
            message = T('duty.change_failed')
        }
    end

    PlayerDutyStates[src] = nextDuty
    if JobBlips.QueueUpdate then JobBlips.QueueUpdate() end

    return {
        success = true,
        onDuty = nextDuty,
        message = nextDuty and T('duty.on') or T('duty.off')
    }
end)

AddEventHandler('playerDropped', function()
    PlayerDutyStates[source] = nil
    if JobBlips.QueueUpdate then JobBlips.QueueUpdate() end
end)

local function AddTruckingStats(citizenid, xp, reputation, payout)
    EnsureTruckingStats(citizenid)
    MySQL.update.await([[UPDATE player_trucking SET xp = xp + ?, reputation = reputation + ?, jobs_completed = jobs_completed + 1, completed_route_streak = completed_route_streak + 1, total_earned = total_earned + ? WHERE citizenid = ?]], { xp or 0, reputation or 0, payout or 0, citizenid })
end

local function AddCancelledRoute(citizenid, repLoss)
    EnsureTruckingStats(citizenid)
    repLoss = tonumber(repLoss) or 1
    if repLoss < 0 then repLoss = 0 end

    MySQL.update.await([[UPDATE player_trucking SET reputation = GREATEST(reputation - ?, 0), total_routes_cancelled = total_routes_cancelled + 1, completed_route_streak = 0 WHERE citizenid = ?]], {
        repLoss,
        citizenid
    })
end

local function BuildCompanyStatsPayload(citizenid)
    EnsureDatabaseMigrations()

    local function databaseTrue(value)
        return value == true or value == 1 or value == '1'
    end

    local onlineNames = {}
    for _, playerId in ipairs(GetPlayers()) do
        local playerSource = tonumber(playerId)
        if playerSource then
            local id = GetCitizenId(playerSource)
            if id and id ~= '' then
                local name = TrimString(GetCharacterName(playerSource))
                if name ~= '' then onlineNames[id] = name:sub(1, 96) end
            end
        end
    end

    local function driverLabel(id, storedName)
        local name = TrimString(onlineNames[id] or storedName)
        if name ~= '' then return name end
        if id == citizenid then return 'You' end
        return id or 'Unknown'
    end

    local function publicDriver(row, rank)
        row = row or {}
        local id = row.citizenid or 'Unknown'
        local driverRank, driverRankLabel = GetRankFromXp(tonumber(row.xp) or 0)
        return {
            rank = rank,
            citizenid = id,
            label = driverLabel(id, row.driver_name),
            driverRank = driverRank,
            driverRankLabel = driverRankLabel,
            xp = tonumber(row.xp) or 0,
            reputation = tonumber(row.reputation) or 0,
            jobsCompleted = tonumber(row.jobs_completed) or 0,
            totalEarned = tonumber(row.total_earned) or 0,
            totalCancelled = tonumber(row.total_routes_cancelled) or 0
        }
    end

    local function publicContractor(row, rank)
        row = row or {}
        local id = row.citizenid or 'Unknown'
        return {
            rank = rank,
            citizenid = id,
            label = driverLabel(id, row.driver_name),
            contractorRep = tonumber(row.contractor_rep) or 0,
            licensed = databaseTrue(row.licensed)
        }
    end

    local topDrivers = {}
    local topRows = MySQL.query.await([[
        SELECT citizenid, driver_name, xp, reputation, jobs_completed, total_earned, total_routes_cancelled
        FROM player_trucking
        ORDER BY xp DESC, reputation DESC, jobs_completed DESC
        LIMIT 5
    ]]) or {}

    for index, row in ipairs(topRows) do
        topDrivers[#topDrivers + 1] = publicDriver(row, index)
    end

    local mostDeliveries = {}
    local deliveryRows = MySQL.query.await([[
        SELECT citizenid, driver_name, xp, reputation, jobs_completed, total_earned, total_routes_cancelled
        FROM player_trucking
        ORDER BY jobs_completed DESC, total_earned DESC, reputation DESC
        LIMIT 5
    ]]) or {}

    for index, row in ipairs(deliveryRows) do
        mostDeliveries[#mostDeliveries + 1] = publicDriver(row, index)
    end

    local contractorRep = {}
    local contractorRows = MySQL.query.await([[
        SELECT c.citizenid, c.licensed, c.contractor_rep, p.driver_name
        FROM trucking_contractor_profiles c
        LEFT JOIN player_trucking p ON p.citizenid = c.citizenid
        WHERE c.licensed = 1 OR c.contractor_rep > 0
        ORDER BY c.contractor_rep DESC, c.licensed DESC
        LIMIT 5
    ]]) or {}

    for index, row in ipairs(contractorRows) do
        contractorRep[#contractorRep + 1] = publicContractor(row, index)
    end

    return {
        topDrivers = topDrivers,
        mostDeliveries = mostDeliveries,
        contractorRep = contractorRep
    }
end

local function GetTrunkId(plate)
    local canonicalPlate = CanonicalPlateText(plate)
    if Config.GetTrunkInventoryId then return Config.GetTrunkInventoryId(canonicalPlate) end
    local prefix = (Config.Inventory and Config.Inventory.TrunkPrefix) or 'trunk'
    return ('%s%s'):format(prefix, canonicalPlate)
end

local VirtualTrunks = {}

local function ResolveInventorySystem()
    local configured = (Config.Inventory and Config.Inventory.System) or Config.InventorySystem or 'auto'
    if configured and configured ~= 'auto' then return configured end
    local candidates = { 'ox_inventory', 'qb-inventory', 'lj-inventory', 'ps-inventory', 'qs-inventory' }
    for _, resource in ipairs(candidates) do
        if GetResourceState(resource) == 'started' then return resource end
    end
    return 'ox_inventory'
end

local InventorySystem = ResolveInventorySystem()

local function InventoryDebug(message)
    if Config.Inventory and Config.Inventory.Debug then
        print(('^3[ls_trucking:inventory]^7 %s'):format(message))
    end
end

local function SafeExport(resource, exportName, ...)
    if GetResourceState(resource) ~= 'started' then return false, nil end
    local args = { ... }
    local ok, result = pcall(function()
        return exports[resource][exportName](exports[resource], table.unpack(args))
    end)
    if ok then return true, result end

    ok, result = pcall(function()
        return exports[resource][exportName](table.unpack(args))
    end)
    return ok, result
end

local function GetVirtualTrunkCount(plate, item)
    plate = CanonicalPlateText(plate)
    local trunk = VirtualTrunks[plate]
    if not trunk then return 0 end
    return trunk[item] or 0
end

local function AddVirtualTrunkItem(plate, item, amount)
    amount = tonumber(amount) or 1
    plate = CanonicalPlateText(plate)
    if plate == '' then return false end
    VirtualTrunks[plate] = VirtualTrunks[plate] or {}
    VirtualTrunks[plate][item] = (VirtualTrunks[plate][item] or 0) + amount
    return true
end

local function RemoveVirtualTrunkItem(plate, item, amount)
    amount = tonumber(amount) or 1
    plate = CanonicalPlateText(plate)
    local trunk = VirtualTrunks[plate]
    if not trunk or (trunk[item] or 0) < amount then return false end
    trunk[item] = trunk[item] - amount
    if trunk[item] <= 0 then trunk[item] = nil end
    return true
end

local function ClearVirtualTrunk(plate)
    plate = CanonicalPlateText(plate)
    if plate ~= '' then VirtualTrunks[plate] = nil end
end

local function GetInventoryItemCount(inventory, item)
    if not item then return 0 end

    if InventorySystem == 'ox_inventory' and GetResourceState('ox_inventory') == 'started' then
        local ok, count = SafeExport('ox_inventory', 'GetItemCount', inventory, item)
        if ok then return tonumber(count) or 0 end
    end

    local resource = InventorySystem

    if resource == 'qs-inventory' then
        local ok, count = SafeExport(resource, 'GetItemTotalAmount', inventory, item)
        if ok and count ~= nil then return tonumber(count) or 0 end
        ok, count = SafeExport(resource, 'GetItemCount', inventory, item)
        if ok and count ~= nil then return tonumber(count) or 0 end
    else
        local ok, count = SafeExport(resource, 'GetItemCount', inventory, item)
        if ok and count ~= nil then return tonumber(count) or 0 end
        ok, count = SafeExport(resource, 'GetItemByName', inventory, item)
        if ok and type(count) == 'table' then return tonumber(count.amount or count.count) or 0 end
    end

    -- Internal fallback only applies to vehicle job trunks. Player counts cannot be safely guessed.
    if type(inventory) == 'string' and Config.Inventory and Config.Inventory.UseInternalTrunkFallback ~= false then
        for plate in pairs(VirtualTrunks) do
            if inventory == GetTrunkId(plate) then return GetVirtualTrunkCount(plate, item) end
        end
    end

    return 0
end

local function AddPlayerItem(src, item, amount, metadata)
    amount = tonumber(amount) or 1
    metadata = metadata or {}

    if InventorySystem == 'ox_inventory' and GetResourceState('ox_inventory') == 'started' then
        local ok, result = SafeExport('ox_inventory', 'AddItem', src, item, amount, metadata)
        if ok then return result ~= false end
    end

    local resource = InventorySystem
    local info = metadata

    local attempts = {
        { resource, 'AddItem', src, item, amount, false, info, 'ls-trucking' },
        { resource, 'AddItem', src, item, amount, nil, info, 'ls-trucking' },
        { resource, 'AddItem', src, item, amount, info },
    }

    for _, attempt in ipairs(attempts) do
        local res, exportName = attempt[1], attempt[2]
        table.remove(attempt, 1)
        table.remove(attempt, 1)
        local ok, result = SafeExport(res, exportName, table.unpack(attempt))
        if ok then return result ~= false end
    end

    InventoryDebug(('Failed to add player item %s x%s using %s'):format(item, amount, resource))
    return false
end

local function RemovePlayerItem(src, item, amount)
    amount = tonumber(amount) or 1

    if InventorySystem == 'ox_inventory' and GetResourceState('ox_inventory') == 'started' then
        local ok, result = SafeExport('ox_inventory', 'RemoveItem', src, item, amount)
        if ok then return result ~= false end
    end

    local resource = InventorySystem
    local attempts = {
        { resource, 'RemoveItem', src, item, amount, false, 'ls-trucking' },
        { resource, 'RemoveItem', src, item, amount, nil, 'ls-trucking' },
        { resource, 'RemoveItem', src, item, amount },
    }

    for _, attempt in ipairs(attempts) do
        local res, exportName = attempt[1], attempt[2]
        table.remove(attempt, 1)
        table.remove(attempt, 1)
        local ok, result = SafeExport(res, exportName, table.unpack(attempt))
        if ok then return result ~= false end
    end

    InventoryDebug(('Failed to remove player item %s x%s using %s'):format(item, amount, resource))
    return false
end

local function AddTrunkItem(plate, item, amount, metadata)
    amount = tonumber(amount) or 1
    metadata = metadata or {}

    if InventorySystem == 'ox_inventory' and GetResourceState('ox_inventory') == 'started' then
        local ok, result = SafeExport('ox_inventory', 'AddItem', GetTrunkId(plate), item, amount, metadata)
        if ok then return result ~= false end
    end

    if Config.Inventory and Config.Inventory.UseInternalTrunkFallback ~= false then
        return AddVirtualTrunkItem(plate, item, amount)
    end

    local resource = InventorySystem
    local ok, result = SafeExport(resource, 'AddItem', GetTrunkId(plate), item, amount, false, metadata, 'ls-trucking')
    if ok then return result ~= false end
    return false
end

local function RemoveTrunkItem(plate, item, amount)
    amount = tonumber(amount) or 1

    if InventorySystem == 'ox_inventory' and GetResourceState('ox_inventory') == 'started' then
        local ok, result = SafeExport('ox_inventory', 'RemoveItem', GetTrunkId(plate), item, amount)
        if ok then return result ~= false end
    end

    if Config.Inventory and Config.Inventory.UseInternalTrunkFallback ~= false then
        return RemoveVirtualTrunkItem(plate, item, amount)
    end

    local resource = InventorySystem
    local ok, result = SafeExport(resource, 'RemoveItem', GetTrunkId(plate), item, amount, false, 'ls-trucking')
    if ok then return result ~= false end
    return false
end

local function GetCargoConfig(contractType, cargoType)
    if Cargo.GetCargoConfig then
        return Cargo.GetCargoConfig(contractType, cargoType)
    end

    return nil, cargoType or contractType
end

local function NormalizeCargoPool(contractType, cargoPool)
    return Cargo.NormalizeCargoPool and Cargo.NormalizeCargoPool(contractType, cargoPool) or {}
end

local function GetManifestEntryForStop(active, stopIndex, deliveredAtStop)
    return Cargo.GetManifestEntryForStop and Cargo.GetManifestEntryForStop(active, stopIndex, deliveredAtStop) or nil
end

local function BuildPackageManifest(contractId, routeLabel, route, contractType, cargoPool)
    return Cargo.BuildPackageManifest and Cargo.BuildPackageManifest(contractId, routeLabel, route, contractType, cargoPool) or {}
end

local function ManifestText(manifest)
    return Cargo.ManifestText and Cargo.ManifestText(manifest) or 'No manifest entries.'
end

local function GiveContractManifest(src, active)
    if Cargo.GiveContractManifest then
        Cargo.GiveContractManifest(CargoServerContext, src, active)
    end
end

local function RemoveContractManifests(src)
    if Cargo.RemoveContractManifests then
        Cargo.RemoveContractManifests(CargoServerContext, src)
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
    if Cargo.RemoveAllPlayerCargo then
        Cargo.RemoveAllPlayerCargo(CargoServerContext, src, contractType, cargoType, manifest)
        return
    end

    local items = CargoItemsFromManifestOrType(contractType, cargoType, manifest)
    for item in pairs(items) do
        local count = GetInventoryItemCount(src, item)
        if count > 0 then RemovePlayerItem(src, item, count) end
    end
end

local function RemoveAllTrunkCargo(plate, contractType, cargoType, manifest)
    if Cargo.RemoveAllTrunkCargo then
        Cargo.RemoveAllTrunkCargo(CargoServerContext, plate, contractType, cargoType, manifest)
        return
    end

    if not plate then return end
    local items = CargoItemsFromManifestOrType(contractType, cargoType, manifest)
    for item in pairs(items) do
        local count = GetInventoryItemCount(GetTrunkId(plate), item)
        if count > 0 then RemoveTrunkItem(plate, item, count) end
    end
end

local function CleanupContractCargo(src)
    if Cargo.CleanupContractCargo then
        Cargo.CleanupContractCargo(CargoServerContext, src)
        return
    end

    local active = ActiveContracts[src]
    if not active then return end
    RemoveAllPlayerCargo(src, active.type, active.cargoType, active.cargoManifest)
    RemoveAllTrunkCargo(active.plate, active.type, active.cargoType, active.cargoManifest)
    RemoveContractManifests(src)
    if active.plate then ClearVirtualTrunk(active.plate) end
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

local function GetRoutePool(contractType, priorityKey)
    local contract = Config.Contracts[contractType]
    if not contract then return nil, nil, 'standard', nil end

    local priority, resolvedPriorityKey = GetPriorityConfig(contractType, priorityKey)
    local routePool = priority and priority.routes or contract.routes

    if not routePool or #routePool == 0 then
        routePool = contract.routes
    end

    return routePool, priority, resolvedPriorityKey, contract
end

local function PickRoute(contractType, priorityKey, requestedRouteIndex)
    local routePool = GetRoutePool(contractType, priorityKey)
    local contract = Config.Contracts[contractType]
    if not contract then return nil, 1 end

    if not routePool or #routePool == 0 then return nil, 1 end

    -- If the NUI preview already selected a randomized route, honor that index
    -- so the contract started matches the route shown in the preview.
    local index = tonumber(requestedRouteIndex)
    if not index or index < 1 or index > #routePool then
        index = math.random(1, #routePool)
    else
        index = math.floor(index)
    end

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
        cargoProps = trailer.cargoProps,
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
            radius = Config.AreaBlips and Config.AreaBlips.TrailerPickup and Config.AreaBlips.TrailerPickup.radius or nil,
            spawns = {
                vector4(1244.30, -3184.92, 5.90, 90.0)
            }
        }
    end

    return {
        key = depotKey,
        label = depot.label or 'Trailer Pickup Yard',
        pickup = depot.pickup,
        radius = depot.radius,
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

local function HasConfigCoords(coords)
    return coords and coords.x ~= nil and coords.y ~= nil and coords.z ~= nil
end

local function AddConfigIssue(issues, level, message)
    issues[#issues + 1] = { level = level, message = message }
end

local function ValidateResourceConfig()
    if Config.Security and Config.Security.ValidateConfig == false then return end

    local issues = {}
    local contractTypes = { 'van', 'boxtruck', 'trailer' }

    if not Config.Depot or not HasConfigCoords(Config.Depot.terminal) then
        AddConfigIssue(issues, 'error', 'Config.Depot.terminal is missing coordinates.')
    end

    if not Config.Ranks or #Config.Ranks == 0 then
        AddConfigIssue(issues, 'error', 'Config.Ranks must contain at least one rank.')
    end

    for _, contractType in ipairs(contractTypes) do
        local contract = Config.Contracts and Config.Contracts[contractType]
        local payout = Config.Payouts and Config.Payouts[contractType]
        local vehicles = Config.JobVehicles and Config.JobVehicles[contractType]

        if not contract then
            AddConfigIssue(issues, 'error', ('Missing Config.Contracts.%s.'):format(contractType))
        else
            if not contract.routes or #contract.routes == 0 then
                AddConfigIssue(issues, 'error', ('Config.Contracts.%s has no routes.'):format(contractType))
            end

            if contractType ~= 'trailer' and (not contract.pickup or not HasConfigCoords(contract.pickup.coords)) then
                AddConfigIssue(issues, 'error', ('Config.Contracts.%s.pickup.coords is missing.'):format(contractType))
            end

            for routeIndex, route in ipairs(contract.routes or {}) do
                if contractType == 'trailer' then
                    if route.pickupDepot and not (Config.TrailerDepots and Config.TrailerDepots[route.pickupDepot]) then
                        AddConfigIssue(issues, 'warning', ('Trailer route "%s" references unknown pickupDepot "%s".'):format(route.label or routeIndex, route.pickupDepot))
                    end

                    if route.trailerKey and not (Config.RouteTrailers and Config.RouteTrailers[route.trailerKey]) then
                        AddConfigIssue(issues, 'warning', ('Trailer route "%s" references unknown trailerKey "%s".'):format(route.label or routeIndex, route.trailerKey))
                    end

                    if not route.trailerDrop or not HasConfigCoords(route.trailerDrop.coords) then
                        AddConfigIssue(issues, 'error', ('Trailer route "%s" is missing trailerDrop.coords.'):format(route.label or routeIndex))
                    end

                    if not route.receiverPed or not HasConfigCoords(route.receiverPed.coords) then
                        AddConfigIssue(issues, 'error', ('Trailer route "%s" is missing receiverPed.coords.'):format(route.label or routeIndex))
                    end
                else
                    if not route.dropoffs or #route.dropoffs == 0 then
                        AddConfigIssue(issues, 'error', ('%s route "%s" has no dropoffs.'):format(contractType, route.label or routeIndex))
                    end

                    for stopIndex, stop in ipairs(route.dropoffs or {}) do
                        if not HasConfigCoords(stop.coords) then
                            AddConfigIssue(issues, 'error', ('%s route "%s" stop %s is missing coords.'):format(contractType, route.label or routeIndex, stopIndex))
                        end

                        local cargoPool = stop.cargoTypes or stop.cargoType
                        if cargoPool then
                            local cargoTypes = type(cargoPool) == 'table' and cargoPool or { cargoPool }
                            for _, cargoType in ipairs(cargoTypes) do
                                if not (Config.CargoTypes and Config.CargoTypes[cargoType]) then
                                    AddConfigIssue(issues, 'warning', ('%s route "%s" references unknown cargo type "%s".'):format(contractType, route.label or routeIndex, tostring(cargoType)))
                                end
                            end
                        end
                    end
                end
            end
        end

        if not payout or not payout.min or not payout.max then
            AddConfigIssue(issues, 'error', ('Config.Payouts.%s needs min and max values.'):format(contractType))
        end

        if not vehicles or #vehicles == 0 then
            AddConfigIssue(issues, 'error', ('Config.JobVehicles.%s needs at least one vehicle.'):format(contractType))
        else
            for vehicleIndex, vehicle in ipairs(vehicles) do
                if not (vehicle.model or vehicle.truck) then
                    AddConfigIssue(issues, 'error', ('Config.JobVehicles.%s[%s] is missing a model.'):format(contractType, vehicleIndex))
                end
            end
        end
    end

    for contractType, cargoType in pairs(Config.DefaultCargoType or {}) do
        if not (Config.CargoTypes and Config.CargoTypes[cargoType]) then
            AddConfigIssue(issues, 'warning', ('Config.DefaultCargoType.%s references unknown cargo type "%s".'):format(contractType, cargoType))
        end
    end

    local targetSystem = Config.TargetSystem or (Config.Target and Config.Target.System) or 'auto'
    local oxTargetStarted = GetResourceState('ox_target') == 'started'
    local qbTargetStarted = GetResourceState('qb-target') == 'started'
    if targetSystem == 'auto' and not oxTargetStarted and not qbTargetStarted then
        AddConfigIssue(issues, 'warning', 'No supported target resource is started. Install/start ox_target or qb-target for interaction zones.')
    elseif targetSystem == 'ox' and not oxTargetStarted then
        AddConfigIssue(issues, 'warning', 'Config.TargetSystem is set to ox, but ox_target is not started.')
    elseif targetSystem == 'qb' and not qbTargetStarted then
        AddConfigIssue(issues, 'warning', 'Config.TargetSystem is set to qb, but qb-target is not started.')
    end

    local errors, warnings = 0, 0
    for _, issue in ipairs(issues) do
        if issue.level == 'error' then errors = errors + 1 else warnings = warnings + 1 end
    end

    if errors == 0 and warnings == 0 then
        print('^2[ls_trucking]^7 Config validation passed.')
        return
    end

    print(('^3[ls_trucking]^7 Config validation found %s error(s), %s warning(s).'):format(errors, warnings))
    for _, issue in ipairs(issues) do
        local color = issue.level == 'error' and '^1' or '^3'
        print(('%s[ls_trucking:%s]^7 %s'):format(color, issue.level, issue.message))
    end
end

local function PrintStartupSummary()
    if Config.Security and Config.Security.PrintStartupSummary == false then return end

    local resourceName = GetCurrentResourceName()
    local version = GetResourceMetadata(resourceName, 'version', 0) or 'dev'
    local target = 'none detected'
    if GetResourceState('ox_target') == 'started' then
        target = 'ox_target'
    elseif GetResourceState('qb-target') == 'started' then
        target = 'qb-target'
    end

    local fuel = Config.Fuel and Config.Fuel.System or 'auto'
    local keys = Config.Keys and Config.Keys.System or 'auto'

    print('^3+------------------------------------------------------------+^7')
    print('^3|^7                 LOS SANTOS FREIGHT CO.                     ^3|^7')
    print('^3+------------------------------------------------------------+^7')
    print(('^3|^7 Resource  ^5%-18s^7 Version ^2%-22s^3|^7'):format(resourceName, version))
    print(('^3|^7 Framework ^2%-18s^7 Inventory ^2%-20s^3|^7'):format(Framework, InventorySystem))
    print(('^3|^7 Target    ^2%-18s^7 Fuel     ^2%-20s^3|^7'):format(target, fuel))
    print(('^3|^7 Keys      ^2%-45s^3|^7'):format(keys))
    print('^3+------------------------------------------------------------+^7')
end

CreateThread(function()
    Wait(1000)
    PrintStartupSummary()
    ValidateResourceConfig()
end)

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

local function GetMileagePayout(routeLength)
    local config = Config.MileagePayout or {}
    local miles = ParseRouteMiles(routeLength) or 0
    local rate = math.max(0, tonumber(config.RatePerMile) or 100)

    if config.Enabled == false or miles <= 0 then
        return 0, miles, rate
    end

    return math.floor((miles * rate) + 0.5), miles, rate
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
    local penaltyMultiplier = 1.0

    if active.contractor then
        penaltyMultiplier = tonumber(Contractors.GetConfig().PenaltyMultiplier) or 1.0
    end

    local timeAdj = CalculateTimeAdjustment(active)
    if timeAdj and (timeAdj.percent or 0.0) < 0.0 then
        timeAdj.percent = timeAdj.percent * penaltyMultiplier
    end
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
        if eventAdj.percent < 0.0 then eventAdj.percent = eventAdj.percent * penaltyMultiplier end
        totalPercent = totalPercent + eventAdj.percent
        adjustments[#adjustments + 1] = eventAdj
    end

    if active.type == 'trailer' then
        local damageAdj = GetTrailerDamageAdjustment(active.trailerDamagePercent or 0.0)
        if damageAdj.percent < 0.0 then damageAdj.percent = damageAdj.percent * penaltyMultiplier end
        if damageAdj.percent ~= 0.0 then
            totalPercent = totalPercent + damageAdj.percent
        end
        adjustments[#adjustments + 1] = damageAdj
    end

    local final = math.floor(base * (1.0 + totalPercent))
    if final < minimum then final = minimum end

    return {
        basePayout = base,
        contractBasePayout = active.contractBasePayout or math.max(0, base - (active.mileageBonus or 0)),
        mileageBonus = active.mileageBonus or 0,
        routeMiles = active.routeMiles or ParseRouteMiles(active.routeLength) or 0,
        mileageRate = active.mileageRate or tonumber((Config.MileagePayout or {}).RatePerMile) or 100,
        payout = final,
        totalPercent = totalPercent,
        adjustments = adjustments,
        time = timeAdj,
        damagePercent = active.trailerDamagePercent or 0.0,
        randomEvent = PublicRandomEvent(active.randomEvent)
    }
end

local function StoredVehiclePlateConflict(plate, garageId, contractorId)
    plate = CanonicalPlateText(plate)
    if plate == '' then return false end
    garageId = tonumber(garageId) or 0
    contractorId = tonumber(contractorId) or 0

    local garage = MySQL.single.await([[SELECT id FROM trucking_garage WHERE UPPER(LEFT(REPLACE(plate, ' ', ''), 8)) = ? AND id <> ? LIMIT 1]], { plate, garageId })
    if garage then return true end

    local contractor = MySQL.single.await([[SELECT id FROM trucking_contractor_vehicles WHERE UPPER(LEFT(REPLACE(plate, ' ', ''), 8)) = ? AND id <> ? LIMIT 1]], { plate, contractorId })
    return contractor ~= nil
end

local function StoredVehiclePlateExists(plate)
    return StoredVehiclePlateConflict(plate, 0, 0)
end

local function GenerateUniqueVehiclePlate(prefix)
    for _ = 1, 50 do
        local plate = CanonicalPlateText(Ids.GeneratePlate(prefix))
        if plate ~= '' and not StoredVehiclePlateExists(plate) then return plate end
    end

    return CanonicalPlateText(Ids.GeneratePlate(prefix))
end

local function EnsureGarageVehicle(citizenid, vehicleType, vehicleIndex)
    local vehicleData = Config.JobVehicles[vehicleType] and Config.JobVehicles[vehicleType][vehicleIndex]
    if not vehicleData then return nil end
    local row = MySQL.single.await('SELECT * FROM trucking_garage WHERE citizenid = ? AND vehicle_type = ? AND vehicle_index = ?', { citizenid, vehicleType, vehicleIndex })
    if not row then
        MySQL.insert.await([[INSERT INTO trucking_garage (citizenid, vehicle_type, vehicle_index, vehicle_label, vehicle_model, plate, props, stored) VALUES (?, ?, ?, ?, ?, ?, NULL, 1)]], {
            citizenid, vehicleType, vehicleIndex, vehicleData.label, GetGarageVehicleModel(vehicleType, vehicleData), GenerateUniqueVehiclePlate(vehicleData.platePrefix)
        })
        row = MySQL.single.await('SELECT * FROM trucking_garage WHERE citizenid = ? AND vehicle_type = ? AND vehicle_index = ?', { citizenid, vehicleType, vehicleIndex })
    end
    if row then
        local canonicalPlate = CanonicalPlateText(row.plate)
        local needsRepair = canonicalPlate == '' or canonicalPlate ~= tostring(row.plate or '') or StoredVehiclePlateConflict(canonicalPlate, row.id, 0)

        if needsRepair then
            local repairedPlate = canonicalPlate ~= '' and not StoredVehiclePlateConflict(canonicalPlate, row.id, 0)
                and canonicalPlate
                or GenerateUniqueVehiclePlate(vehicleData.platePrefix)
            local repairedProps = row.props
            local sanitizedProps, propsError = SanitizeVehicleProps(row.props, repairedPlate)
            if not propsError then repairedProps = sanitizedProps end

            MySQL.update.await('UPDATE trucking_garage SET plate = ?, props = ? WHERE id = ?', { repairedPlate, repairedProps, row.id })
            row.plate = repairedPlate
            row.props = repairedProps
        end
    end
    return row
end

lib.callback.register('ls_trucking:server:canUseReceiver', function(src)
    return GetUIAccess(src)
end)

CargoServerContext = {
    ActiveContracts = ActiveContracts,
    CheckRateLimit = CheckRateLimit,
    GetSecurityCooldown = GetSecurityCooldown,
    RateLimitResponse = RateLimitResponse,
    RequireServerNear = RequireServerNear,
    GetDistanceLimit = GetDistanceLimit,
    GetContractPickupCoords = GetContractPickupCoords,
    GetPublicContractData = GetPublicContractData,
    GetTrunkId = GetTrunkId,
    GetInventoryItemCount = GetInventoryItemCount,
    AddPlayerItem = AddPlayerItem,
    RemovePlayerItem = RemovePlayerItem,
    AddTrunkItem = AddTrunkItem,
    RemoveTrunkItem = RemoveTrunkItem,
    ClearVirtualTrunk = ClearVirtualTrunk
}

if Cargo.RegisterServer then
    Cargo.RegisterServer(CargoServerContext)
end

AdminServerContext = {
    ActiveContracts = ActiveContracts,
    HasAdminCommandPermission = HasAdminCommandPermission,
    GetCargoConfig = GetCargoConfig,
    AddPlayerItem = AddPlayerItem,
    GetCitizenId = GetCitizenId,
    EnsureTruckingStats = EnsureTruckingStats
}

if Admin.RegisterServer then
    Admin.RegisterServer(AdminServerContext)
end

ContractorServerContext = {
    ActiveContracts = ActiveContracts,
    EnsureDatabaseMigrations = EnsureDatabaseMigrations,
    CheckRateLimit = CheckRateLimit,
    GetSecurityCooldown = GetSecurityCooldown,
    RateLimitResponse = RateLimitResponse,
    HasRequiredJob = HasRequiredJob,
    RequireWorkAccess = RequireWorkAccess,
    GetCitizenId = GetCitizenId,
    GetPlayerTruckingRank = GetPlayerTruckingRank,
    CheckRankRequirement = CheckRankRequirement,
    GetRoutePool = GetRoutePool,
    ResolveRouteTrailer = ResolveRouteTrailer,
    ResolveTrailerDepot = ResolveTrailerDepot,
    GetMileagePayout = GetMileagePayout,
    GetGarageVehicleModel = GetGarageVehicleModel,
    GetVehicleConfig = GetVehicleConfig,
    RemoveMoney = RemoveMoney,
    AddMoney = AddMoney,
    ClampText = ClampText,
    NormalizePlateText = NormalizePlateText,
    CanonicalPlateText = CanonicalPlateText,
    GeneratePlate = GenerateUniqueVehiclePlate,
    CreateContractForPlayer = function(...) return CreateContractForPlayer(...) end
}

if Contractors.ConfigureServer then
    Contractors.ConfigureServer(ContractorServerContext)
end

DispatchDataServerContext = {
    ActiveContracts = ActiveContracts,
    CheckRateLimit = CheckRateLimit,
    GetSecurityCooldown = GetSecurityCooldown,
    HasRequiredJob = HasRequiredJob,
    GetUIAccess = GetUIAccess,
    GetCitizenId = GetCitizenId,
    BuildPlayerPayload = BuildPlayerPayload,
    BuildContractorPayload = Contractors.BuildPayload,
    BuildCompanyStatsPayload = BuildCompanyStatsPayload,
    EnsureGarageVehicle = EnsureGarageVehicle,
    RequireServerNear = RequireServerNear,
    GetDistanceLimit = GetDistanceLimit,
    GetGarageVehicleModel = GetGarageVehicleModel,
    IsDatabaseTrue = Contractors.IsDatabaseTrue
}

if DispatchData.RegisterServer then
    DispatchData.RegisterServer(DispatchDataServerContext)
end



JobBlipsServerContext = {
    ActiveContracts = ActiveContracts,
    CheckedOutVehicles = CheckedOutVehicles,
    ReusableVehicles = ReusableVehicles,
    HasRequiredJob = HasRequiredJob,
    GetPlayerDutyState = GetPlayerDutyState,
    GetCharacterName = GetCharacterName
}

if JobBlips.RegisterServer then
    JobBlips.RegisterServer(JobBlipsServerContext)
end

DepotVehicleServerContext = {
    ActiveContracts = ActiveContracts,
    CheckedOutVehicles = CheckedOutVehicles,
    ReusableVehicles = ReusableVehicles,
    CheckRateLimit = CheckRateLimit,
    GetSecurityCooldown = GetSecurityCooldown,
    RateLimitResponse = RateLimitResponse,
    HasRequiredJob = HasRequiredJob,
    RequireWorkAccess = RequireWorkAccess,
    GetSecurityConfig = GetSecurityConfig,
    GetSourceCoords = GetSourceCoords,
    GetConfigCoord3 = GetConfigCoord3,
    GetVehicleConfig = GetVehicleConfig,
    GetPlayerTruckingRank = GetPlayerTruckingRank,
    CheckRankRequirement = CheckRankRequirement,
    GetCitizenId = GetCitizenId,
    EnsureGarageVehicle = EnsureGarageVehicle,
    RequireServerNear = RequireServerNear,
    GetDistanceLimit = GetDistanceLimit,
    TrackCheckedOutVehicle = TrackCheckedOutVehicle,
    NormalizePlateText = NormalizePlateText,
    CanonicalPlateText = CanonicalPlateText,
    ClampText = ClampText,
    SanitizeVehicleProps = SanitizeVehicleProps,
    AddMoney = AddMoney,
    ClearVehicleSession = ClearVehicleSession,
    GetContractorProfile = Contractors.GetProfile,
    IsDatabaseTrue = Contractors.IsDatabaseTrue,
    GetContractorVehicleById = Contractors.GetVehicleById,
    GetContractorOutVehicle = Contractors.GetOutVehicle
}

if DepotVehicles.RegisterServer then
    DepotVehicles.RegisterServer(DepotVehicleServerContext)
end


ServiceBayServerContext = {
    CheckRateLimit = CheckRateLimit,
    GetSecurityCooldown = GetSecurityCooldown,
    RateLimitResponse = RateLimitResponse,
    GetUIAccess = GetUIAccess,
    GetCitizenId = GetCitizenId,
    GetTruckingStats = GetTruckingStats,
    RemoveMoney = RemoveMoney,
    NormalizePlateText = NormalizePlateText,
    CanonicalPlateText = CanonicalPlateText,
    SanitizeVehicleProps = SanitizeVehicleProps,
    EnsureGarageVehicle = EnsureGarageVehicle,
    RequireServerNear = RequireServerNear,
    GetDistanceLimit = GetDistanceLimit,
    IsDatabaseTrue = Contractors.IsDatabaseTrue,
    GetContractorProfile = Contractors.GetProfile,
    GetContractorVehicleById = Contractors.GetVehicleById
}

if ServiceBay.RegisterServer then
    ServiceBay.RegisterServer(ServiceBayServerContext)
end
RouteServerContext = {
    ActiveContracts = ActiveContracts,
    ReusableVehicles = ReusableVehicles,
    RouteSummary = RouteSummary,
    CheckRateLimit = CheckRateLimit,
    GetSecurityCooldown = GetSecurityCooldown,
    RateLimitResponse = RateLimitResponse,
    RequireServerNear = RequireServerNear,
    GetDistanceLimit = GetDistanceLimit,
    GetCompletionCoords = GetCompletionCoords,
    GetCitizenId = GetCitizenId,
    BuildPayoutResult = BuildPayoutResult,
    AddMoney = AddMoney,
    RemoveMoney = RemoveMoney,
    AddTruckingStats = AddTruckingStats,
    AddCancelledRoute = AddCancelledRoute,
    AddContractorRep = Contractors.AddRep,
    GetContractorConfig = Contractors.GetConfig,
    GetContractorDailyBonus = Contractors.GetDailyBonus,
    GetPlayerJobInfo = GetPlayerJobInfo,
    GetCharacterName = GetCharacterName,
    RemoveAllPlayerCargo = RemoveAllPlayerCargo,
    RemoveAllTrunkCargo = RemoveAllTrunkCargo,
    RemoveContractManifests = RemoveContractManifests,
    CleanupContractCargo = CleanupContractCargo,
    TrackCheckedOutVehicle = TrackCheckedOutVehicle,
    ClearVehicleSession = ClearVehicleSession,
    ClampText = ClampText,
    NotifySecurityFailure = NotifySecurityFailure
}

if Routes.RegisterServer then
    Routes.RegisterServer(RouteServerContext)
end

local function RequireServerNearDepotRequest(src, message)
    if DepotVehicles.RequireNearDepotRequest then
        return DepotVehicles.RequireNearDepotRequest(DepotVehicleServerContext, src, message)
    end

    return RequireServerNear(src, Config.Depot and (Config.Depot.request or Config.Depot.terminal), GetDistanceLimit('Depot', 35.0), message)
end

CreateContractForPlayer = function(src, contractType, vehicleIndex, reuseVehicle, currentPlate, priorityKey, requestedRouteIndex, options)
    options = options or {}
    if ActiveContracts[src] then return { success = false, message = T('error.already_active_contract') } end
    if not Config.Contracts[contractType] then return { success = false, message = T('error.invalid_contract_type') } end
    if not reuseVehicle and (CheckedOutVehicles[src] or ReusableVehicles[src]) then
        return { success = false, message = T('error.return_or_reuse_vehicle') }
    end

    if not reuseVehicle and not options.skipSpawnDistance then
        local near, nearMessage = RequireServerNearDepotRequest(src, T('error.need_company_spawn_area'))
        if not near then return { success = false, message = nearMessage } end
    end

    local playerRank = GetPlayerTruckingRank(src)
    local selectedVehicle, resolvedVehicleIndex = GetVehicleConfig(contractType, vehicleIndex)
    if not selectedVehicle then return { success = false, message = T('error.invalid_vehicle') } end

    local reuseCandidate = nil
    if reuseVehicle then
        reuseCandidate = options.reuseCandidate or GetReusableVehicle(src)
        if not reuseCandidate then
            return { success = false, message = options.contractor and T('error.no_contractor_vehicle') or T('error.no_reusable_vehicle') }
        end

        if Config.RequireSameTypeForVehicleReuse and reuseCandidate.type ~= contractType then
            return { success = false, message = T('error.vehicle_reuse_type') }
        end

        if CanonicalPlateText(currentPlate) ~= CanonicalPlateText(reuseCandidate.plate) then
            return { success = false, message = T('error.dispatch_plate_mismatch') }
        end

        local reusedVehicle, reusedIndex = GetVehicleConfig(contractType, reuseCandidate.index or vehicleIndex)
        if reusedVehicle then
            selectedVehicle = reusedVehicle
            resolvedVehicleIndex = reusedIndex
        end
    end

    if not CheckRankRequirement(playerRank, selectedVehicle.minRank) then
        return { success = false, message = T('error.vehicle_rank_required', { rank = selectedVehicle.minRank or 1 }) }
    end

    local priority, resolvedPriorityKey = GetPriorityConfig(contractType, priorityKey)
    priority = priority or { label = 'Standard Commercial Route', shortLabel = 'Standard', minRank = 1, payoutMultiplier = 1.0, xpMultiplier = 1.0, repBonus = 0 }

    if not CheckRankRequirement(playerRank, priority.minRank) then
        return { success = false, message = T('error.priority_rank_required', { rank = priority.minRank or 1 }) }
    end

    local route, routeIndex = PickRoute(contractType, resolvedPriorityKey, requestedRouteIndex)
    if not route then return { success = false, message = T('error.no_route_configured') } end

    local randomEvent = PickRandomDeliveryEvent(contractType, resolvedPriorityKey)
    local estimatedSeconds = GetEstimatedSeconds(contractType, resolvedPriorityKey, route)

    if randomEvent and randomEvent.estimateDeltaSeconds then
        estimatedSeconds = math.max(300, estimatedSeconds + randomEvent.estimateDeltaSeconds)
    end

    local publicContract = GetPublicContractData(contractType, route, priority, resolvedPriorityKey)
    publicContract.estimatedSeconds = estimatedSeconds
    publicContract.estimatedTime = FormatSeconds(estimatedSeconds)
    publicContract.randomEvent = PublicRandomEvent(randomEvent)

    if not publicContract.pickup or not publicContract.pickup.coords then
        return { success = false, message = T('error.route_pickup_missing') }
    end

    if contractType == 'trailer' then
        if not publicContract.trailerDrop or not publicContract.trailerDrop.coords then
            return { success = false, message = T('error.trailer_delivery_missing') }
        end

        if not publicContract.trailerDepot or not publicContract.trailerDepot.pickup then
            return { success = false, message = T('error.trailer_depot_missing') }
        end
    elseif not publicContract.dropoffs or not publicContract.dropoffs[1] or not publicContract.dropoffs[1].coords then
        return { success = false, message = T('error.route_dropoff_missing') }
    end

    local payoutData = Config.Payouts[contractType]
    local payoutMultiplier = (priority.payoutMultiplier or 1.0) * (tonumber(options.payoutMultiplier) or 1.0)
    local xpMultiplier = (priority.xpMultiplier or 1.0) * (tonumber(options.xpMultiplier) or 1.0)
    local contractBasePayout = math.floor(math.random(payoutData.min, payoutData.max) * payoutMultiplier)
    local mileageBonus, routeMiles, mileageRate = GetMileagePayout(route.routeLength)
    local payout = contractBasePayout + mileageBonus
    local xp = math.floor((payoutData.xp or 0) * xpMultiplier)
    local rep = (payoutData.rep or 0) + (priority.repBonus or 0) + (randomEvent and randomEvent.repBonus or 0) + (tonumber(options.repBonus) or 0)

    publicContract.payout = payout
    publicContract.contractBasePayout = contractBasePayout
    publicContract.mileageBonus = mileageBonus
    publicContract.routeMiles = routeMiles
    publicContract.mileageRate = mileageRate

    local plate = options.plate or currentPlate
    if not reuseVehicle or not plate or plate == '' then
        local garage = EnsureGarageVehicle(GetCitizenId(src), contractType, resolvedVehicleIndex)
        plate = garage and garage.plate or GenerateUniqueVehiclePlate(selectedVehicle.platePrefix)
    else
        plate = reuseCandidate and reuseCandidate.plate or plate
    end
    plate = CanonicalPlateText(plate)

    local totalStops = publicContract.dropoffs and #publicContract.dropoffs or 1
    local contractId = Ids.GenerateContractId(src)

    local cargoPool = route.cargoTypes or priority.cargoTypes or route.cargoType or priority.cargoType or (Config.DefaultCargoType and Config.DefaultCargoType[contractType])
    local cargoType = nil
    local cargoConfig = nil
    local cargoManifest = nil

    if contractType ~= 'trailer' then
        cargoManifest = BuildPackageManifest(contractId, route.label, route, contractType, cargoPool)
        if not cargoManifest or #cargoManifest == 0 then
            return { success = false, message = T('error.invalid_cargo_manifest') }
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
        contractBasePayout = contractBasePayout,
        mileageBonus = mileageBonus,
        routeMiles = routeMiles,
        mileageRate = mileageRate,
        xp = xp,
        rep = rep,
        estimatedSeconds = estimatedSeconds,
        randomEvent = randomEvent,
        routeTrailer = publicContract.routeTrailer,
        trailerDepot = publicContract.trailerDepot,
        pickupLabel = publicContract.pickup and publicContract.pickup.label or nil,
        pickupDepotLabel = publicContract.trailerDepot and publicContract.trailerDepot.label or (publicContract.pickup and publicContract.pickup.label) or nil,
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
        pendingClientStartUntil = os.time() + 30,
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
        trailerDropped = false,
        cargoType = cargoType,
        cargoItem = cargoConfig and cargoConfig.item or nil,
        cargoLabel = publicContract.cargoLabel or (cargoConfig and cargoConfig.label or nil),
        cargoManifest = cargoManifest,
        loadedCargoItems = {},
        cargoInHand = false,
        cargoVerified = false,
        pickupManifestSigned = false,
        pickupSignature = nil,
        deliverySignature = nil,
        trailerContents = route.trailerContents or (publicContract.routeTrailer and publicContract.routeTrailer.contents) or nil,
        trailerInstructions = route.trailerInstructions or (publicContract.routeTrailer and publicContract.routeTrailer.instructions) or nil,
        contractor = options.contractor == true,
        contractorVehicleId = options.contractorVehicleId,
        contractorDailyRouteKey = options.dailyRouteKey,
        contractorCancelFee = tonumber(options.cancelFee) or 0
    }

    ActiveContracts[src] = active
    TrackCheckedOutVehicle(src, contractType, resolvedVehicleIndex, plate, options.vehicleSource or (reuseVehicle and 'reused-contract' or 'contract'))
    ReusableVehicles[src] = nil
    GiveContractManifest(src, active)

    return {
        success = true,
        contractId = contractId,
        contractType = contractType,
        vehicleIndex = resolvedVehicleIndex,
        routeIndex = routeIndex,
        reuseVehicle = reuseVehicle == true,
        payout = payout,
        contractBasePayout = contractBasePayout,
        mileageBonus = mileageBonus,
        routeMiles = routeMiles,
        mileageRate = mileageRate,
        xp = xp,
        rep = rep,
        plate = plate,
        contract = publicContract,
        vehicle = selectedVehicle,
        contractor = active.contractor,
        contractorVehicleId = active.contractorVehicleId
    }
end

lib.callback.register('ls_trucking:server:createContract', function(src, contractType, vehicleIndex, reuseVehicle, currentPlate, priorityKey, requestedRouteIndex)
    if not CheckRateLimit(src, 'createContract', GetSecurityCooldown('Contract', 2000)) then return RateLimitResponse() end
    local access, accessMessage = RequireWorkAccess(src)
    if not access then return { success = false, message = accessMessage } end

    return CreateContractForPlayer(src, contractType, vehicleIndex, reuseVehicle, currentPlate, priorityKey, requestedRouteIndex)
end)

if Contractors.RegisterServer then
    Contractors.RegisterServer()
end

local function IsFreightHandoffRequired(requirement)
    local handoff = Config.FreightHandoff or {}
    return handoff.Enabled ~= false and handoff[requirement] ~= false
end

local function BuildFreightSignature(src, active, locationLabel)
    return {
        name = ClampText(GetCharacterName(src) or GetPlayerName(src) or 'Assigned Driver', 64),
        signedAt = os.date('%Y-%m-%d %H:%M:%S'),
        location = ClampText(locationLabel or 'LS Freight Handoff', 96),
        contractId = active and active.id or nil
    }
end

local function ResolveAssignedTrailerEntity(src, active, providedNetId)
    local trackedNetId = tonumber(active and active.trailerNetId)
    providedNetId = tonumber(providedNetId)

    if trackedNetId and providedNetId and trackedNetId ~= providedNetId then
        return nil, T('trailer.net_id_mismatch')
    end

    local netId = trackedNetId or providedNetId
    if not netId or netId <= 0 then return nil, T('trailer.telemetry_unavailable') end

    local entity = NetworkGetEntityFromNetworkId(netId)
    if not entity or entity == 0 or not DoesEntityExist(entity) then
        return nil, T('trailer.not_found_yard')
    end

    local expectedModel = active and active.routeTrailer and active.routeTrailer.model
    if expectedModel then
        local expectedHash = type(expectedModel) == 'number' and expectedModel or joaat(expectedModel)
        if GetEntityModel(entity) ~= expectedHash then
            return nil, T('trailer.incorrect_marker')
        end
    end

    active.trailerNetId = netId
    return entity
end

local function ValidateTrailerMarkerPlacement(src, active, providedNetId)
    local marker = Config.TrailerDropMarker or {}
    if marker.Enabled == false then return true end

    local entity, entityMessage = ResolveAssignedTrailerEntity(src, active, providedNetId)
    if not entity then return false, entityMessage end

    local drop = active.routeData and active.routeData.trailerDrop
    local dropCoords = drop and drop.coords
    if not dropCoords then return false, T('trailer.invalid_placement_marker') end

    local trailerCoords = GetEntityCoords(entity)
    local dx = trailerCoords.x - dropCoords.x
    local dy = trailerCoords.y - dropCoords.y
    local distance = math.sqrt((dx * dx) + (dy * dy))
    local tolerance = math.max(0.5, tonumber(marker.PositionTolerance) or 2.75)
        + math.max(0.0, tonumber(marker.ServerTolerance) or 0.75)

    if distance > tolerance then
        return false, T('trailer.position_marker', { distance = ('%.1f'):format(distance) })
    end

    if GetEntitySpeed and GetEntitySpeed(entity) > (math.max(0.01, tonumber(marker.MaxSettleSpeed) or 0.15) + 0.10) then
        return false, T('trailer.must_be_stationary')
    end

    return true
end

RegisterNetEvent('ls_trucking:server:registerAssignedTrailer', function(contractId, trailerNetId)
    local src = source
    if not CheckRateLimit(src, 'registerAssignedTrailer', GetSecurityCooldown('Trailer', 1000)) then return end
    local active = ActiveContracts[src]
    if not active or active.type ~= 'trailer' or tostring(active.id or '') ~= tostring(contractId or '') then return end

    local entity = ResolveAssignedTrailerEntity(src, active, trailerNetId)
    if entity then active.trailerNetId = tonumber(trailerNetId) end
end)

lib.callback.register('ls_trucking:server:authorizePickupHandoff', function(src, signatureData)
    if not CheckRateLimit(src, 'pickupHandoff', GetSecurityCooldown('Cargo', 1000)) then return RateLimitResponse() end

    local active = ActiveContracts[src]
    if not active then return { success = false, message = T('error.no_active_contract') } end
    if active.type == 'trailer' then return { success = false, message = T('freight.trailer_depot_checklist') } end

    if type(signatureData) ~= 'table' or tostring(signatureData.contractId or '') ~= tostring(active.id or '') then
        return { success = false, message = T('freight.manifest_mismatch') }
    end

    if active.pickupManifestSigned and active.pickupSignature then
        return { success = true, alreadySigned = true, signature = active.pickupSignature }
    end

    if IsFreightHandoffRequired('RequirePickupSignature') and signatureData.signatureAccepted ~= true then
        return { success = false, message = T('freight.pickup_signature_required') }
    end

    local near, nearMessage = RequireServerNear(src, GetContractPickupCoords(active), GetDistanceLimit('Pickup', 12.0), T('cargo.need_pickup_worker'))
    if not near then return { success = false, message = nearMessage } end

    active.pickupManifestSigned = true
    active.pickupSignature = BuildFreightSignature(src, active, active.pickupLabel or 'Cargo Pickup')
    return { success = true, signature = active.pickupSignature }
end)

local function ConfirmTrailerDropState(src, active, trailerNetId)
    if not active then return false, T('error.no_active_contract') end
    if active.type ~= 'trailer' then return false, T('trailer.not_contract') end
    if not active.trailerHooked then return false, T('trailer.not_cleared') end
    if active.trailerDropped then return true end

    local drop = active.routeData and active.routeData.trailerDrop
    local dropCoords = drop and drop.coords
    local distance = math.max(GetDistanceLimit('TrailerDrop', 35.0), tonumber(drop and drop.radius) or 0.0)
    local nearDrop, nearMessage = RequireServerNear(src, dropCoords, distance, T('trailer.need_receiving_yard'))
    if not nearDrop then return false, nearMessage end

    local placed, placementMessage = ValidateTrailerMarkerPlacement(src, active, trailerNetId)
    if not placed then return false, placementMessage end

    active.trailerDropped = true
    active.stage = 'Talk to receiver'
    return true
end

lib.callback.register('ls_trucking:server:markTrailerHooked', function(src)
    if not CheckRateLimit(src, 'markTrailerHooked', GetSecurityCooldown('Trailer', 1000)) then return RateLimitResponse() end
    local a = ActiveContracts[src]
    if not a then return { success = false, message = T('error.no_active_contract') } end
    if a.type ~= 'trailer' then return { success = false, message = T('trailer.not_contract') } end
    if a.trailerHooked then return { success = true, alreadyHooked = true } end

    local near, nearMessage = RequireServerNear(src, a.trailerDepot and a.trailerDepot.pickup, GetDistanceLimit('TrailerPickup', 120.0), T('trailer.need_depot'))
    if not near then return { success = false, message = nearMessage } end

    a.stage = 'Deliver trailer'
    a.trailerHooked = true
    a.routeStartedAt = os.time()
    return { success = true }
end)

lib.callback.register('ls_trucking:server:confirmTrailerDropped', function(src, trailerNetId)
    if not CheckRateLimit(src, 'confirmTrailerDropped', GetSecurityCooldown('Trailer', 1000)) then return RateLimitResponse() end

    local a = ActiveContracts[src]
    if not a then return { success = false, message = T('error.no_active_contract') } end
    if a.type ~= 'trailer' then return { success = false, message = T('trailer.not_contract') } end

    local dropped, dropMessage = ConfirmTrailerDropState(src, a, trailerNetId)
    if not dropped then return { success = false, message = dropMessage } end

    return { success = true }
end)

lib.callback.register('ls_trucking:server:finalizeTrailerDelivery', function(src, damageData, signatureData)
    if not CheckRateLimit(src, 'finalizeTrailer', GetSecurityCooldown('Trailer', 1000)) then return RateLimitResponse() end
    local a = ActiveContracts[src]
    if not a then return { success = false, message = T('error.no_active_contract') } end
    if a.type ~= 'trailer' then return { success = false, message = T('trailer.not_contract') } end
    if not a.trailerHooked then return { success = false, message = T('trailer.hook_before_finalize') } end

    local dropped, dropMessage = ConfirmTrailerDropState(src, a)
    if not dropped then return { success = false, message = dropMessage or T('trailer.confirm_drop_first') } end

    if a.stage == 'Route complete' then return { success = true, alreadyFinalized = true, signature = a.deliverySignature } end

    local receiverCoords = a.routeData and a.routeData.receiverPed and a.routeData.receiverPed.coords
    local nearReceiver, nearMessage = RequireServerNear(src, receiverCoords, GetDistanceLimit('Receiver', 14.0), T('trailer.need_receiver'))
    if not nearReceiver then return { success = false, message = nearMessage } end

    if IsFreightHandoffRequired('RequireTrailerSignature') and not a.deliverySignature then
        if type(signatureData) ~= 'table' or tostring(signatureData.contractId or '') ~= tostring(a.id or '') then
            return { success = false, message = T('trailer.manifest_mismatch') }
        end

        if signatureData.signatureAccepted ~= true then
            return { success = false, message = T('trailer.signature_required_close') }
        end

        local receiverLabel = a.routeData and a.routeData.receiverPed and a.routeData.receiverPed.label
            or a.routeData and a.routeData.trailerDrop and a.routeData.trailerDrop.label
            or 'Trailer Receiver'
        a.deliverySignature = BuildFreightSignature(src, a, receiverLabel)
    end

    if type(damageData) == 'table' then
        local startHealth = tonumber(damageData.startBody) or 1000.0
        local endHealth = tonumber(damageData.endBody) or startHealth
        if startHealth <= 0.0 then startHealth = 1000.0 end
        endHealth = math.max(0.0, math.min(startHealth, endHealth))
        local loss = math.max(0.0, startHealth - endHealth)
        a.trailerDamagePercent = math.min(100.0, (loss / startHealth) * 100.0)
    end

    a.loadedCargo = 0
    a.stage = 'Route complete'
    return { success = true, signature = a.deliverySignature }
end)

RegisterNetEvent('ls_trucking:server:returnVehicleBonus', function()
    local src = source
    if not CheckRateLimit(src, 'returnVehicleBonusEvent', GetSecurityCooldown('ReturnVehicle', 2000)) then return end
    NotifySecurityFailure(src, 'Return bonuses are paid automatically when a valid company vehicle is returned.')
end)


AddEventHandler('playerDropped', function()
    local src = source
    CleanupContractCargo(src)
    ActiveContracts[src] = nil
    ClearVehicleSession(src)
    PlayerCooldowns[src] = nil
end)
