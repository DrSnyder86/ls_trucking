LS_Trucking = LS_Trucking or {}

local DepotVehicles = {}
local serverRegistered = false

local function AddCoord(list, coords)
    if coords then list[#list + 1] = coords end
end

local function BuildDepotRequestCoords()
    local depot = Config.Depot or {}
    local coords = {}
    AddCoord(coords, depot.request or depot.terminal)
    AddCoord(coords, depot.terminal)
    AddCoord(coords, depot.garageSpawn)
    AddCoord(coords, depot.vehicleSpawn)
    return coords
end

local function GetDepotRequestDistanceLimit(ctx)
    local depot = Config.Depot or {}
    if depot.requestRadius then
        return tonumber(depot.requestRadius) or 35.0
    end

    return ctx.GetDistanceLimit and ctx.GetDistanceLimit('Depot', 35.0) or 35.0
end

local function IsServerDistanceDisabled(ctx)
    if ctx.GetSecurityConfig then
        local cfg = ctx.GetSecurityConfig() or {}
        return cfg.ServerDistanceChecks == false
    end

    return false
end

local function RequireWorkAccess(ctx, src)
    if ctx.RequireWorkAccess then
        return ctx.RequireWorkAccess(src)
    end

    if ctx.HasRequiredJob and not ctx.HasRequiredJob(src) then
        return false, T('error.not_trucker', { job = Config.JobName or 'the required job' })
    end

    return true
end

function DepotVehicles.RequireNearDepotRequest(ctx, src, message)
    ctx = ctx or {}
    if IsServerDistanceDisabled(ctx) then return true end

    local playerCoords = ctx.GetSourceCoords and ctx.GetSourceCoords(src) or nil
    if not playerCoords then
        return false, T('error.position_unverified')
    end

    local hasTarget = false
    for _, coords in ipairs(BuildDepotRequestCoords()) do
        local targetCoords = ctx.GetConfigCoord3 and ctx.GetConfigCoord3(coords) or nil
        if targetCoords then
            hasTarget = true

            if #(playerCoords - targetCoords) <= GetDepotRequestDistanceLimit(ctx) then
                return true
            end
        end
    end

    if not hasTarget then return true end
    return false, message or T('error.too_far')
end

local function ClampVehicleHealth(value, fallback)
    value = tonumber(value)
    if not value then return fallback or 1000.0 end
    return math.max(0.0, math.min(1000.0, value))
end

local function ReleaseStaleVehicleCheckout(ctx, src)
    if ctx.ActiveContracts[src] then
        return { success = false, message = T('contractor.clear_active_job_first') }
    end

    local citizenid = ctx.GetCitizenId(src)
    local checkedOut = ctx.CheckedOutVehicles[src] or ctx.ReusableVehicles[src]
    local released = false

    if checkedOut then
        if checkedOut.source == 'contractor' then
            MySQL.update.await('UPDATE trucking_contractor_vehicles SET stored = 1, out_state = 0 WHERE citizenid = ? AND plate = ?', {
                citizenid,
                checkedOut.plate
            })
        elseif checkedOut.type and checkedOut.index then
            MySQL.update.await('UPDATE trucking_garage SET stored = 1 WHERE citizenid = ? AND vehicle_type = ? AND vehicle_index = ?', {
                citizenid,
                checkedOut.type,
                tonumber(checkedOut.index) or 1
            })
        end

        ctx.ClearVehicleSession(src)
        released = true
    end

    local garageReleased = MySQL.update.await('UPDATE trucking_garage SET stored = 1 WHERE citizenid = ? AND stored = 0', { citizenid }) or 0
    local contractorReleased = MySQL.update.await('UPDATE trucking_contractor_vehicles SET stored = 1, out_state = 0 WHERE citizenid = ? AND (stored = 0 OR out_state = 1)', { citizenid }) or 0

    if garageReleased > 0 or contractorReleased > 0 then
        released = true
    end

    return { success = true, released = released }
end

function DepotVehicles.RegisterServer(ctx)
    if serverRegistered then return end
    serverRegistered = true
    ctx = ctx or {}

    lib.callback.register('ls_trucking:server:spawnGarageVehicle', function(src, vehicleType, vehicleIndex)
        if not ctx.CheckRateLimit(src, 'spawnGarageVehicle', ctx.GetSecurityCooldown('Contract', 2000)) then return ctx.RateLimitResponse() end
        local access, accessMessage = RequireWorkAccess(ctx, src)
        if not access then return { success = false, message = accessMessage } end
        if ctx.ActiveContracts[src] then return { success = false, message = T('garage.active_job_spawn') } end
        if ctx.CheckedOutVehicles[src] or ctx.ReusableVehicles[src] then return { success = false, message = T('garage.company_checked_out') } end

        local near, nearMessage = DepotVehicles.RequireNearDepotRequest(ctx, src, T('garage.need_area'))
        if not near then return { success = false, message = nearMessage } end

        vehicleIndex = tonumber(vehicleIndex) or 1
        local vehicleData, resolvedIndex = ctx.GetVehicleConfig(vehicleType, vehicleIndex)
        if not vehicleData then return { success = false, message = T('garage.invalid_vehicle') } end

        local playerRank = ctx.GetPlayerTruckingRank(src)
        if not ctx.CheckRankRequirement(playerRank, vehicleData.minRank) then
            return { success = false, message = T('garage.rank_required', { rank = vehicleData.minRank or 1 }) }
        end

        local citizenid = ctx.GetCitizenId(src)
        local row = ctx.EnsureGarageVehicle(citizenid, vehicleType, resolvedIndex)
        if not row then return { success = false, message = T('garage.load_failed') } end

        MySQL.update.await('UPDATE trucking_garage SET stored = 0 WHERE citizenid = ? AND vehicle_type = ? AND vehicle_index = ?', { citizenid, vehicleType, resolvedIndex })
        ctx.TrackCheckedOutVehicle(src, vehicleType, resolvedIndex, row.plate, 'garage')
        return { success = true, vehicleType = vehicleType, vehicleIndex = resolvedIndex, vehicle = vehicleData, plate = row.plate, props = row.props }
    end)

    lib.callback.register('ls_trucking:server:returnGarageVehicle', function(src, vehicleType, vehicleIndex, plate, props)
        if not ctx.CheckRateLimit(src, 'returnGarageVehicle', ctx.GetSecurityCooldown('ReturnVehicle', 2000)) then return ctx.RateLimitResponse() end
        if ctx.HasRequiredJob and not ctx.HasRequiredJob(src) then return { success = false, message = T('error.not_trucker', { job = Config.JobName or 'the required job' }) } end
        if ctx.ActiveContracts[src] then return { success = false, message = T('garage.active_job_return') } end

        local near, nearMessage = ctx.RequireServerNear(src, Config.Depot and (Config.Depot.vehicleReturn or Config.Depot.terminal), ctx.GetDistanceLimit('VehicleReturn', 35.0), T('garage.need_return_point'))
        if not near then return { success = false, message = nearMessage } end

        vehicleIndex = tonumber(vehicleIndex) or 1
        local citizenid = ctx.GetCitizenId(src)
        local row = ctx.EnsureGarageVehicle(citizenid, vehicleType, vehicleIndex)
        if not row then return { success = false, message = T('garage.save_failed') } end

        local safePlate = ctx.ClampText(plate or row.plate, 16)
        if ctx.NormalizePlateText(safePlate) ~= ctx.NormalizePlateText(row.plate) then
            return { success = false, message = T('garage.plate_mismatch') }
        end

        local savedProps, propsError = ctx.SanitizeVehicleProps(props)
        if propsError then return { success = false, message = propsError } end

        local bonus = 0
        local checkedOut = ctx.CheckedOutVehicles[src]
        if Config.ReturnVehicleBonusEnabled and checkedOut and not checkedOut.bonusPaid then
            local sameVehicle = checkedOut.type == vehicleType
                and tonumber(checkedOut.index or 1) == vehicleIndex
                and ctx.NormalizePlateText(checkedOut.plate) == ctx.NormalizePlateText(safePlate)

            if sameVehicle and checkedOut.source == 'completed-route' then
                bonus = tonumber(Config.ReturnVehicleBonus) or 0
                if bonus > 0 then
                    if not ctx.AddMoney(src, bonus, 'ls-trucking-return-bonus') then
                        bonus = 0
                        TriggerClientEvent('ls_trucking:client:notify', src, T('garage.return_bonus_failed'), 'error')
                    end
                end
                checkedOut.bonusPaid = true
            end
        end

        MySQL.update.await([[UPDATE trucking_garage SET plate = ?, props = ?, stored = 1 WHERE citizenid = ? AND vehicle_type = ? AND vehicle_index = ?]], { safePlate, savedProps, citizenid, vehicleType, vehicleIndex })
        ctx.ClearVehicleSession(src)
        return { success = true, bonus = bonus }
    end)

    lib.callback.register('ls_trucking:server:spawnContractorVehicle', function(src, vehicleId)
        if not ctx.CheckRateLimit(src, 'contractorSpawnVehicle', ctx.GetSecurityCooldown('Contract', 2000)) then return ctx.RateLimitResponse() end
        local access, accessMessage = RequireWorkAccess(ctx, src)
        if not access then return { success = false, message = accessMessage } end
        if ctx.ActiveContracts[src] then return { success = false, message = T('contractor.active_job_spawn') } end
        if ctx.CheckedOutVehicles[src] or ctx.ReusableVehicles[src] then return { success = false, message = T('contractor.vehicle_checked_out') } end

        local near, nearMessage = DepotVehicles.RequireNearDepotRequest(ctx, src, T('contractor.need_pickup_area'))
        if not near then return { success = false, message = nearMessage } end

        local citizenid = ctx.GetCitizenId(src)
        local profile = ctx.GetContractorProfile(citizenid)
        if not ctx.IsDatabaseTrue(profile.licensed) then return { success = false, message = T('contractor.license_required') } end

        local row = ctx.GetContractorVehicleById(citizenid, vehicleId)
        if not row then return { success = false, message = T('contractor.vehicle_not_found') } end

        local outRow = ctx.GetContractorOutVehicle(citizenid)
        if outRow and tonumber(outRow.id) ~= tonumber(row.id) then
            return { success = false, message = T('contractor.only_one_out') }
        end

        local vehicleData = Config.JobVehicles[row.vehicle_type] and Config.JobVehicles[row.vehicle_type][tonumber(row.vehicle_index) or 1]
        if not vehicleData then return { success = false, message = T('contractor.config_missing') } end

        local hasSavedProps = row.props ~= nil and tostring(row.props) ~= '' and tostring(row.props) ~= 'null'
        local engineHealth = ClampVehicleHealth(row.engine_health, 1000.0)
        local bodyHealth = ClampVehicleHealth(row.body_health, 1000.0)
        if not hasSavedProps and engineHealth < 100.0 then engineHealth = 1000.0 end
        if not hasSavedProps and bodyHealth < 100.0 then bodyHealth = 1000.0 end

        if engineHealth ~= tonumber(row.engine_health) or bodyHealth ~= tonumber(row.body_health) then
            MySQL.update.await('UPDATE trucking_contractor_vehicles SET engine_health = ?, body_health = ? WHERE citizenid = ? AND id = ?', {
                engineHealth,
                bodyHealth,
                citizenid,
                row.id
            })
        end

        MySQL.update.await('UPDATE trucking_contractor_vehicles SET stored = 0, out_state = 1 WHERE citizenid = ? AND id = ?', { citizenid, row.id })
        ctx.TrackCheckedOutVehicle(src, row.vehicle_type, tonumber(row.vehicle_index) or 1, row.plate, 'contractor')

        return {
            success = true,
            vehicleId = row.id,
            vehicleType = row.vehicle_type,
            vehicleIndex = tonumber(row.vehicle_index) or 1,
            vehicle = vehicleData,
            plate = row.plate,
            props = row.props,
            fuel = tonumber(row.fuel) or tonumber(vehicleData.fuel) or 100,
            engineHealth = engineHealth,
            bodyHealth = bodyHealth,
            mileage = math.max(0.0, tonumber(row.mileage) or 0.0)
        }
    end)

    lib.callback.register('ls_trucking:server:storeContractorVehicle', function(src, vehicleId, plate, props, fuel, engineHealth, bodyHealth, mileage)
        if not ctx.CheckRateLimit(src, 'contractorStoreVehicle', ctx.GetSecurityCooldown('ReturnVehicle', 2000)) then return ctx.RateLimitResponse() end
        if ctx.HasRequiredJob and not ctx.HasRequiredJob(src) then return { success = false, message = T('error.not_trucker', { job = Config.JobName or 'the required job' }) } end
        if ctx.ActiveContracts[src] then return { success = false, message = T('contractor.active_job_store') } end

        local near, nearMessage = ctx.RequireServerNear(src, Config.Depot and (Config.Depot.vehicleReturn or Config.Depot.terminal), ctx.GetDistanceLimit('VehicleReturn', 35.0), T('contractor.need_return_point'))
        if not near then return { success = false, message = nearMessage } end

        local citizenid = ctx.GetCitizenId(src)
        local row = ctx.GetContractorVehicleById(citizenid, vehicleId)
        if not row then return { success = false, message = T('contractor.vehicle_not_found') } end

        local safePlate = ctx.ClampText(plate or row.plate, 16)
        if ctx.NormalizePlateText(safePlate) ~= ctx.NormalizePlateText(row.plate) then
            return { success = false, message = T('contractor.fleet_plate_mismatch') }
        end

        local savedProps, propsError = ctx.SanitizeVehicleProps(props)
        if propsError then return { success = false, message = propsError } end

        fuel = math.max(0.0, math.min(100.0, tonumber(fuel) or tonumber(row.fuel) or 0.0))
        engineHealth = ClampVehicleHealth(engineHealth, tonumber(row.engine_health) or 1000.0)
        bodyHealth = ClampVehicleHealth(bodyHealth, tonumber(row.body_health) or 1000.0)
        local storedMileage = math.max(0.0, tonumber(row.mileage) or 0.0)
        local reportedMileage = math.max(storedMileage, tonumber(mileage) or storedMileage)
        mileage = math.min(reportedMileage, storedMileage + 10000.0)

        MySQL.update.await([[UPDATE trucking_contractor_vehicles SET plate = ?, props = ?, fuel = ?, engine_health = ?, body_health = ?, mileage = ?, stored = 1, out_state = 0 WHERE citizenid = ? AND id = ?]], {
            safePlate,
            savedProps,
            fuel,
            engineHealth,
            bodyHealth,
            mileage,
            citizenid,
            row.id
        })

        ctx.ClearVehicleSession(src)
        return { success = true, mileage = mileage, message = T('contractor.stored') }
    end)

    lib.callback.register('ls_trucking:server:releaseStaleVehicleCheckout', function(src)
        if not ctx.CheckRateLimit(src, 'releaseStaleVehicleCheckout', ctx.GetSecurityCooldown('ReturnVehicle', 2000)) then return ctx.RateLimitResponse() end
        if ctx.HasRequiredJob and not ctx.HasRequiredJob(src) then return { success = false, message = T('error.not_trucker', { job = Config.JobName or 'the required job' }) } end

        return ReleaseStaleVehicleCheckout(ctx, src)
    end)
end

LS_Trucking.DepotVehicles = DepotVehicles
