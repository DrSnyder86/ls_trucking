LS_Trucking = LS_Trucking or {}

local Cargo = {}
local serverContext = {}
local serverRegistered = false

local function Ctx(ctx)
    return ctx or serverContext or {}
end

function Cargo.ConfigureServer(ctx)
    serverContext = ctx or {}
end

function Cargo.GetCargoConfig(contractType, cargoType)
    cargoType = cargoType or (Config.DefaultCargoType and Config.DefaultCargoType[contractType])

    if cargoType and Config.CargoTypes and Config.CargoTypes[cargoType] then
        return Config.CargoTypes[cargoType], cargoType
    end

    local fallback = Config.CargoItems and Config.CargoItems[contractType]
    return fallback, cargoType or contractType
end

function Cargo.NormalizeCargoPool(contractType, cargoPool)
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
    local pool = Cargo.NormalizeCargoPool(contractType, cargoPool)
    if #pool == 0 then return nil, nil end

    local cargoType = pool[math.random(1, #pool)]
    return Config.CargoTypes[cargoType], cargoType
end

function Cargo.GetManifestEntryForStop(active, stopIndex, deliveredAtStop)
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

function Cargo.BuildPackageManifest(contractId, routeLabel, route, contractType, cargoPool)
    local manifest = {}
    local dropoffs = route and route.dropoffs or {}

    for stopIndex, stop in ipairs(dropoffs) do
        local amount = stop.unload or 1

        for _ = 1, amount do
            local cargoConfig, cargoType = PickCargoFromPool(contractType, stop.cargoTypes or stop.cargoType or cargoPool)

            if cargoConfig and cargoConfig.item then
                manifest[#manifest + 1] = {
                    stop = stopIndex,
                    receiver = stop.receiver or stop.label or ('Stop %s'):format(stopIndex),
                    dropoff = stop.label or ('Stop %s'):format(stopIndex),
                    instructions = stop.instructions or ('Deliver to %s.'):format(stop.label or ('Stop %s'):format(stopIndex)),
                    contract = contractId,
                    route = routeLabel,
                    cargoType = cargoType,
                    cargoItem = cargoConfig.item,
                    cargoLabel = cargoConfig.label or 'Delivery Cargo'
                }
            end
        end
    end

    return manifest
end

local function BuildCargoMetadata(active, manifestEntry, cargo, packageNumber)
    local receiver = manifestEntry.receiver or 'Route Receiver'
    local dropoff = manifestEntry.dropoff or receiver
    local instructions = manifestEntry.instructions or ('Deliver to %s.'):format(dropoff)

    return {
        contract = active.id,
        type = active.type,
        cargoType = manifestEntry.cargoType,
        label = cargo.label,
        receiver = receiver,
        dropoff = dropoff,
        stop = manifestEntry.stop,
        packageNumber = packageNumber,
        route = active.routeLabel,
        description = ('Receiver: %s\nDropoff: %s\nRoute: %s\nInstructions: %s'):format(receiver, dropoff, active.routeLabel or 'Route', instructions)
    }
end

function Cargo.ManifestText(manifest)
    if not manifest or #manifest == 0 then return 'No manifest entries.' end

    local groupedStops = {}
    local orderedStops = {}

    for _, entry in ipairs(manifest) do
        local stopKey = entry.stop or entry.dropoff or entry.receiver or (#orderedStops + 1)

        if not groupedStops[stopKey] then
            groupedStops[stopKey] = {
                stop = entry.stop or (#orderedStops + 1),
                receiver = entry.receiver or entry.dropoff or 'Receiver',
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
        local cargoParts = {}
        for cargoLabel, amount in pairs(stop.cargo or {}) do
            cargoParts[#cargoParts + 1] = ('%s x%s'):format(cargoLabel, amount)
        end
        table.sort(cargoParts)
        lines[#lines + 1] = ('  Packages: %s'):format(table.concat(cargoParts, ', '))
    end

    return table.concat(lines, '\n')
end

function Cargo.GiveContractManifest(ctx, src, active)
    ctx = Ctx(ctx)
    local manifestConfig = Config.Manifest or {}
    if manifestConfig.Enabled == false or not active then return end
    if not ctx.AddPlayerItem then return end

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

        ctx.AddPlayerItem(src, item, 1, {
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

    ctx.AddPlayerItem(src, item, 1, {
        contract = active.id,
        route = active.routeLabel,
        cargo = active.cargoLabel,
        description = Cargo.ManifestText(active.cargoManifest)
    })
end

function Cargo.RemoveContractManifests(ctx, src)
    ctx = Ctx(ctx)
    local manifestConfig = Config.Manifest or {}
    if manifestConfig.Enabled == false or manifestConfig.RemoveOnComplete == false then return end
    if not ctx.GetInventoryItemCount or not ctx.RemovePlayerItem then return end

    for _, item in ipairs({ manifestConfig.PackageManifestItem, manifestConfig.TrailerManifestItem }) do
        if item then
            local count = ctx.GetInventoryItemCount(src, item)
            if count > 0 then ctx.RemovePlayerItem(src, item, count) end
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
        local cargo = Cargo.GetCargoConfig(contractType, cargoType)
        if cargo and cargo.item then items[cargo.item] = true end
    end

    return items
end

function Cargo.RemoveAllPlayerCargo(ctx, src, contractType, cargoType, manifest)
    ctx = Ctx(ctx)
    if not ctx.GetInventoryItemCount or not ctx.RemovePlayerItem then return end

    local items = CargoItemsFromManifestOrType(contractType, cargoType, manifest)
    for item in pairs(items) do
        local count = ctx.GetInventoryItemCount(src, item)
        if count > 0 then ctx.RemovePlayerItem(src, item, count) end
    end
end

function Cargo.RemoveAllTrunkCargo(ctx, plate, contractType, cargoType, manifest)
    ctx = Ctx(ctx)
    if not plate or not ctx.GetInventoryItemCount or not ctx.GetTrunkId or not ctx.RemoveTrunkItem then return end

    local items = CargoItemsFromManifestOrType(contractType, cargoType, manifest)
    for item in pairs(items) do
        local count = ctx.GetInventoryItemCount(ctx.GetTrunkId(plate), item)
        if count > 0 then ctx.RemoveTrunkItem(plate, item, count) end
    end
end

function Cargo.CleanupContractCargo(ctx, src)
    ctx = Ctx(ctx)
    local active = ctx.ActiveContracts and ctx.ActiveContracts[src]
    if not active then return end

    Cargo.RemoveAllPlayerCargo(ctx, src, active.type, active.cargoType, active.cargoManifest)
    Cargo.RemoveAllTrunkCargo(ctx, active.plate, active.type, active.cargoType, active.cargoManifest)
    Cargo.RemoveContractManifests(ctx, src)

    if active.plate and ctx.ClearVirtualTrunk then
        ctx.ClearVirtualTrunk(active.plate)
    end
end

local function PickupCargoOne(ctx, src)
    if not ctx.CheckRateLimit(src, 'pickupCargo', ctx.GetSecurityCooldown('Cargo', 750)) then return ctx.RateLimitResponse() end
    local active = ctx.ActiveContracts[src]
    if not active then return { success = false, message = 'You do not have an active contract.' } end
    if active.type == 'trailer' then return { success = false, message = 'Trailer hauling does not use cargo items.' } end
    local handoff = Config.FreightHandoff or {}
    if handoff.Enabled ~= false and handoff.RequirePickupSignature ~= false and not active.pickupManifestSigned then
        return { success = false, message = 'Sign the pickup manifest with the freight clerk before collecting cargo.' }
    end
    if active.cargoPickedUp >= active.requiredCargo then return { success = false, message = 'You already picked up all cargo for this route.' } end
    if active.cargoInHand then return { success = false, message = 'Load the cargo you already collected before picking up another item.' } end
    if (active.cargoPickedUp or 0) > (active.loadedCargo or 0) then return { success = false, message = 'Load your current cargo before collecting another item.' } end

    local near, nearMessage = ctx.RequireServerNear(src, ctx.GetContractPickupCoords(active), ctx.GetDistanceLimit('Pickup', 12.0), 'You need to be closer to the pickup worker.')
    if not near then return { success = false, message = nearMessage } end

    local nextIndex = active.cargoPickedUp + 1
    local manifestEntry = active.cargoManifest and active.cargoManifest[nextIndex] or nil
    if not manifestEntry then return { success = false, message = 'Could not find the next manifest item.' } end

    local cargo = Cargo.GetCargoConfig(active.type, manifestEntry.cargoType)
    if not cargo or not cargo.item then return { success = false, message = 'Invalid cargo type.' } end

    local receiver = manifestEntry.receiver or 'Route Receiver'
    local metadata = BuildCargoMetadata(active, manifestEntry, cargo, nextIndex)

    local added = ctx.AddPlayerItem(src, cargo.item, 1, metadata)
    if not added then return { success = false, message = 'Could not add cargo. Check your inventory space.' } end

    active.cargoPickedUp = active.cargoPickedUp + 1
    active.cargoInHand = true
    active.stage = 'Carry cargo to vehicle'

    return { success = true, item = cargo.item, label = cargo.label, cargoType = manifestEntry.cargoType, receiver = receiver, pickedUp = active.cargoPickedUp, required = active.requiredCargo }
end

local function LoadCargoOne(ctx, src)
    if not ctx.CheckRateLimit(src, 'loadCargo', ctx.GetSecurityCooldown('Cargo', 750)) then return ctx.RateLimitResponse() end
    local active = ctx.ActiveContracts[src]
    if not active then return { success = false, message = 'You do not have an active contract.' } end
    if active.type == 'trailer' then return { success = false, message = 'Trailer hauling does not use cargo items.' } end
    if active.loadedCargo >= active.requiredCargo then return { success = false, message = 'Vehicle already has all required cargo.' } end
    if not active.cargoInHand then return { success = false, message = 'Collect route cargo before loading the vehicle.' } end
    if (active.cargoPickedUp or 0) <= (active.loadedCargo or 0) then return { success = false, message = 'There is no picked-up cargo waiting to be loaded.' } end

    local manifestEntry = active.cargoManifest and active.cargoManifest[active.loadedCargo + 1] or nil
    if not manifestEntry then return { success = false, message = 'Could not find the cargo item to load.' } end

    local cargo = Cargo.GetCargoConfig(active.type, manifestEntry.cargoType)
    if not cargo or not cargo.item then return { success = false, message = 'Invalid cargo type.' } end

    if ctx.GetInventoryItemCount(src, cargo.item) < 1 then return { success = false, message = ('You need a %s in your inventory.'):format(cargo.label) } end
    if not ctx.RemovePlayerItem(src, cargo.item, 1) then return { success = false, message = 'Could not remove cargo from your inventory.' } end

    local metadata = BuildCargoMetadata(active, manifestEntry, cargo, active.loadedCargo + 1)
    local added = ctx.AddTrunkItem(active.plate, cargo.item, 1, metadata)
    if not added then ctx.AddPlayerItem(src, cargo.item, 1, metadata) return { success = false, message = 'Could not add cargo to the vehicle trunk.' } end

    active.loadedCargo = active.loadedCargo + 1
    active.cargoInHand = false
    local ready = active.loadedCargo >= active.requiredCargo

    if ready then
        active.stage = 'Verify loaded cargo'
        active.cargoVerified = false
    else
        active.stage = 'Load cargo into vehicle'
    end

    return { success = true, loaded = active.loadedCargo, required = active.requiredCargo, ready = ready, verified = active.cargoVerified == true, currentStop = active.currentStop }
end

local function VerifyLoadedCargo(ctx, src)
    if not ctx.CheckRateLimit(src, 'verifyCargo', ctx.GetSecurityCooldown('Cargo', 750)) then return ctx.RateLimitResponse() end
    local active = ctx.ActiveContracts[src]
    if not active then return { success = false, message = 'You do not have an active contract.' } end
    if active.type == 'trailer' then return { success = false, message = 'Trailer hauling does not use cargo boxes.' } end
    if (active.loadedCargo or 0) < (active.requiredCargo or 0) or (active.cargoPickedUp or 0) < (active.requiredCargo or 0) then
        return { success = false, message = 'Load all route cargo before verifying.' }
    end
    if active.cargoInHand then return { success = false, message = 'Load the cargo you are carrying before verifying.' } end

    local near, nearMessage = ctx.RequireServerNear(
        src,
        ctx.GetContractPickupCoords(active),
        ctx.GetDistanceLimit('LoadVerification', 20.0),
        'You need to be near the loaded vehicle at the pickup location.'
    )
    if not near then return { success = false, message = nearMessage } end

    local requiredByItem = {}
    for _, entry in ipairs(active.cargoManifest or {}) do
        if entry.cargoItem then
            requiredByItem[entry.cargoItem] = (requiredByItem[entry.cargoItem] or 0) + 1
        end
    end

    if next(requiredByItem) == nil then
        return { success = false, message = 'Cargo verification failed. Invalid route manifest.' }
    end

    for item, required in pairs(requiredByItem) do
        local trunkCount = ctx.GetInventoryItemCount(ctx.GetTrunkId(active.plate), item)
        if trunkCount < required then
            return { success = false, message = ('Cargo verification failed. Trunk has %s/%s %s.'):format(trunkCount, required, item) }
        end
    end

    active.cargoVerified = true
    active.stage = 'Deliver cargo'
    active.currentStop = 1
    active.routeStartedAt = os.time()

    return { success = true, loaded = active.loadedCargo, required = active.requiredCargo, currentStop = active.currentStop }
end

local function GrabCargoFromVehicle(ctx, src)
    if not ctx.CheckRateLimit(src, 'grabCargo', ctx.GetSecurityCooldown('Cargo', 750)) then return ctx.RateLimitResponse() end
    local active = ctx.ActiveContracts[src]
    if not active then return { success = false, message = 'You do not have an active contract.' } end
    if active.type == 'trailer' then return { success = false, message = 'Trailer cargo cannot be grabbed this way.' } end
    if not active.cargoVerified then return { success = false, message = 'Verify the loaded cargo before starting deliveries.' } end
    if active.cargoInHand then return { success = false, message = 'Deliver the cargo you are carrying before grabbing another item.' } end
    if (active.currentStop or 0) < 1 or (active.currentStop or 0) > (active.totalStops or 0) then return { success = false, message = 'There is no active delivery stop.' } end

    local manifestEntry = Cargo.GetManifestEntryForStop(active, active.currentStop, active.deliveredAtStop)
    if not manifestEntry then return { success = false, message = 'Could not find the next delivery item for this stop.' } end

    local cargo = Cargo.GetCargoConfig(active.type, manifestEntry.cargoType)
    if not cargo or not cargo.item then return { success = false, message = 'Invalid cargo type.' } end

    if ctx.GetInventoryItemCount(ctx.GetTrunkId(active.plate), cargo.item) < 1 then return { success = false, message = ('There is no %s in the vehicle trunk.'):format(cargo.label) } end
    if not ctx.RemoveTrunkItem(active.plate, cargo.item, 1) then return { success = false, message = 'Could not remove cargo from vehicle trunk.' } end

    local receiver = manifestEntry.receiver or 'Route Receiver'
    local metadata = BuildCargoMetadata(active, manifestEntry, cargo, active.deliveredCargo + 1)

    local added = ctx.AddPlayerItem(src, cargo.item, 1, metadata)
    if not added then ctx.AddTrunkItem(active.plate, cargo.item, 1, metadata) return { success = false, message = 'Could not add cargo to your inventory.' } end
    active.cargoInHand = true
    return { success = true, label = cargo.label, cargoType = manifestEntry.cargoType, receiver = receiver }
end

local function DeliverCargoOne(ctx, src)
    if not ctx.CheckRateLimit(src, 'deliverCargo', ctx.GetSecurityCooldown('Cargo', 750)) then return ctx.RateLimitResponse() end
    local active = ctx.ActiveContracts[src]
    if not active then return { success = false, message = 'You do not have an active contract.' } end
    if active.type == 'trailer' then return { success = false, message = 'Trailer jobs are finalized with the receiver.' } end
    if not active.cargoVerified then return { success = false, message = 'Verify the loaded cargo before making deliveries.' } end
    if not active.cargoInHand then return { success = false, message = 'Grab cargo from the vehicle before delivering.' } end

    local routeData = active.routeData or (Config.Contracts[active.type] and Config.Contracts[active.type].routes and Config.Contracts[active.type].routes[active.routeIndex])
    local publicContract = ctx.GetPublicContractData(active.type, routeData)
    local stop = publicContract.dropoffs and publicContract.dropoffs[active.currentStop]
    if not stop then return { success = false, message = 'Invalid delivery stop.' } end

    local near, nearMessage = ctx.RequireServerNear(src, stop.coords, ctx.GetDistanceLimit('Dropoff', 14.0), 'You need to be closer to the active delivery stop.')
    if not near then return { success = false, message = nearMessage } end

    local manifestEntry = Cargo.GetManifestEntryForStop(active, active.currentStop, active.deliveredAtStop)
    if not manifestEntry then return { success = false, message = 'Could not find the next delivery item for this stop.' } end

    local cargo = Cargo.GetCargoConfig(active.type, manifestEntry.cargoType)
    if not cargo or not cargo.item then return { success = false, message = 'Invalid cargo type.' } end

    if ctx.GetInventoryItemCount(src, cargo.item) < 1 then return { success = false, message = ('You need to grab a %s from the vehicle first.'):format(cargo.label) } end
    if not ctx.RemovePlayerItem(src, cargo.item, 1) then return { success = false, message = 'Could not remove cargo from your inventory.' } end

    active.deliveredCargo = active.deliveredCargo + 1
    active.deliveredAtStop = active.deliveredAtStop + 1
    active.loadedCargo = math.max(active.loadedCargo - 1, 0)
    active.cargoInHand = false

    local requiredAtStop = stop.unload or 1
    local stopComplete = active.deliveredAtStop >= requiredAtStop
    if stopComplete then active.currentStop = active.currentStop + 1 active.deliveredAtStop = 0 end

    local routeComplete = active.currentStop > active.totalStops
    active.stage = routeComplete and 'Route complete' or (stopComplete and 'Deliver cargo' or 'Continue unloading current stop')

    return { success = true, delivered = active.deliveredCargo, loaded = active.loadedCargo, currentStop = active.currentStop, totalStops = active.totalStops, deliveredAtStop = active.deliveredAtStop, requiredAtStop = requiredAtStop, stopComplete = stopComplete, routeComplete = routeComplete }
end

function Cargo.RegisterServer(ctx)
    if serverRegistered then return end
    serverRegistered = true
    Cargo.ConfigureServer(ctx)
    ctx = Ctx()

    lib.callback.register('ls_trucking:server:pickupCargoOne', function(src)
        return PickupCargoOne(ctx, src)
    end)

    lib.callback.register('ls_trucking:server:loadCargoOne', function(src)
        return LoadCargoOne(ctx, src)
    end)

    lib.callback.register('ls_trucking:server:verifyLoadedCargo', function(src)
        return VerifyLoadedCargo(ctx, src)
    end)

    lib.callback.register('ls_trucking:server:grabCargoFromVehicle', function(src)
        return GrabCargoFromVehicle(ctx, src)
    end)

    lib.callback.register('ls_trucking:server:deliverCargoOne', function(src)
        return DeliverCargoOne(ctx, src)
    end)
end

LS_Trucking.Cargo = Cargo
