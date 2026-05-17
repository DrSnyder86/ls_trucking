Config = {}

Config.ConfigVersion = '1.0.0'
Config.Debug = false
Config.Framework = 'auto' -- auto, qb, qbox
Config.Command = 'trucking'
Config.MiniUIToggleCommand = 'truckui'
Config.CancelCommand = 'canceltrucking'
Config.RequireJob = false
Config.JobName = 'trucker'
Config.UsePed = true
Config.UseBlip = true
Config.UseTerminalTargetZone = false

-- Target system: 'auto', 'ox', or 'qb'
Config.TargetSystem = 'auto'

-- Locations, depots, and dispatch
Config.DispatchPed = {
    model = `s_m_m_dockwork_01`,
    coords = vector4(1196.75, -3253.85, 7.10, 92.0),
    scenario = 'WORLD_HUMAN_CLIPBOARD'
}

Config.DispatchBlip = {
    coords = vector3(1196.75, -3253.85, 7.10),
    sprite = 477,
    color = 5,
    scale = 0.75,
    label = 'Los Santos Freight Co.'
}

Config.Depot = {
    terminal = vector3(1196.75, -3253.85, 7.10),
    vehicleSpawn = vector4(1185.65, -3246.52, 6.03, 91.5),
    garageSpawn = vector4(1185.65, -3246.52, 6.03, 91.5),
    vehicleReturn = vector3(1196.75, -3253.85, 7.10)
}

Config.TrailerDepots = {
    docks = {
        label = 'Docks Trailer Yard',
        pickup = vector3(1244.30, -3184.92, 5.90),
        spawns = {
            vector4(1271.85, -3224.09, 5.90, 90.42),
            vector4(1271.36, -3202.27, 5.90, 90.51),
            vector4(1271.83, -3202.1, 5.90, 91.49),
            vector4(1272.41, -3193.0, 5.90, 89.84)
        }
    },

    harmony = {
        label = 'Harmony Freight Depot',
        pickup = vector3(195.43, 2747.35, 43.43),
        spawns = {
            vector4(205.28, 2749.38, 43.43, 113.86),
            vector4(159.97, 2762.62, 43.26, 260.48),
            vector4(161.07, 2752.78, 43.37, 275.82)
        }
    },

    lsport = {
        label = 'Post OP Depository',
        pickup = vector3(-481.64, -2828.94, 6.0),
        spawns = {
            vector4(-482.52, -2825.57, 6.0, 47.29),
            vector4(-477.69, -2821.69, 6.0, 45.63),
            vector4(-486.43, -2830.37, 6.0, 46.17),
            vector4(-495.9, -2839.4, 6.0, 49.71),
            vector4(-500.16, -2844.19, 6.0, 42.84)
        }
    },
    -- add more depots
}

-- Company garage vehicles and route trailers
Config.JobVehicles = {
    van = {
        { label = 'Speedo Cargo Van', minRank = 1, model = 'speedo', photo = 'https://docs.fivem.net/vehicles/speedo.webp', platePrefix = 'LSV', livery = 0, fuel = 100, extras = { [1] = true, [2] = true, [3] = false, [4] = false } },
        { label = 'Rumpo Delivery Van', minRank = 1, model = 'rumpo', photo = 'https://docs.fivem.net/vehicles/rumpo.webp', platePrefix = 'LSV', livery = 0, fuel = 100, extras = { [1] = true, [2] = false, [3] = false } },
        { label = 'Burrito Delivery Van', minRank = 1, model = 'burrito', photo = 'https://docs.fivem.net/vehicles/burrito.webp', platePrefix = 'LSV', livery = 0, fuel = 100, extras = { [1] = true, [2] = true } },

        { label = 'Speedo Priority Van', minRank = 2, model = 'speedo4', photo = 'https://docs.fivem.net/vehicles/speedo4.webp', platePrefix = 'LSV', livery = 0, fuel = 100, extras = { [1] = true, [2] = true, [3] = true } },
        { label = 'Rumpo Priority Van', minRank = 2, model = 'rumpo2', photo = 'https://docs.fivem.net/vehicles/rumpo2.webp', platePrefix = 'LSV', livery = 0, fuel = 100, extras = { [1] = true, [2] = true } },
        { label = 'Burrito Priority Van', minRank = 2, model = 'burrito3', photo = 'https://docs.fivem.net/vehicles/burrito3.webp', platePrefix = 'LSV', livery = 0, fuel = 100, extras = { [1] = true, [2] = true } }
    },

    boxtruck = {
        { label = 'Mule Box Truck', minRank = 1, model = 'mule2', photo = 'https://docs.fivem.net/vehicles/mule.webp', platePrefix = 'LSB', livery = 0, fuel = 100, extras = { [1] = true, [2] = true, [3] = false } },
        { label = 'Benson Delivery Truck', minRank = 1, model = 'benson', photo = 'https://docs.fivem.net/vehicles/benson.webp', platePrefix = 'LSB', livery = 0, fuel = 100, extras = { [1] = true, [2] = false } },
        { label = 'Benson Delivery Truck', minRank = 2, model = 'benson2', photo = 'https://docs.fivem.net/vehicles/benson2.webp', platePrefix = 'LSB', livery = 0, fuel = 100, extras = { [1] = true, [2] = false } },
        { label = 'Pounder Box Truck', minRank = 3, model = 'pounder', photo = 'https://docs.fivem.net/vehicles/pounder.webp', platePrefix = 'LSB', livery = 0, fuel = 100, extras = { [1] = true, [2] = true, [3] = true } },
        { label = 'Mule Custom Box Truck', minRank = 3, model = 'mule4', photo = 'https://docs.fivem.net/vehicles/mule4.webp', platePrefix = 'LSB', livery = 0, fuel = 100, extras = { [1] = true, [2] = true, [3] = true } },
        { label = 'Pounder Custom Box Truck', minRank = 4, model = 'pounder2', photo = 'https://docs.fivem.net/vehicles/pounder2.webp', platePrefix = 'LSB', livery = 0, fuel = 100, extras = { [1] = true, [2] = true, [3] = true } }
    },

    trailer = {
        { label = 'Phantom Tractor', minRank = 1, model = 'phantom', photo = 'https://docs.fivem.net/vehicles/phantom.webp', platePrefix = 'LST', truckLivery = 0, fuel = 100, truckExtras = { [1] = true, [2] = true } },
        { label = 'Hauler Tractor', minRank = 3, model = 'hauler', photo = 'https://docs.fivem.net/vehicles/hauler.webp', platePrefix = 'LST', truckLivery = 0, fuel = 100, truckExtras = { [1] = true, [2] = false } },
        { label = 'Packer Tractor', minRank = 3, model = 'packer', photo = 'https://docs.fivem.net/vehicles/packer.webp', platePrefix = 'LST', truckLivery = 0, fuel = 100, truckExtras = { [1] = true, [2] = true } },
        { label = 'Phantom Custom Tractor', minRank = 4, model = 'phantom3', photo = 'https://docs.fivem.net/vehicles/phantom3.webp', platePrefix = 'LST', truckLivery = 0, fuel = 100, truckExtras = { [1] = true, [2] = true } },
        { label = 'Hauler Custom Tractor', minRank = 4, model = 'hauler2', photo = 'https://docs.fivem.net/vehicles/hauler2.webp', platePrefix = 'LST', truckLivery = 0, fuel = 100, truckExtras = { [1] = true, [2] = true } },
        { label = 'Barracks Tractor', minRank = 3, model = 'barracks2', photo = 'https://docs.fivem.net/vehicles/barracks2.webp', platePrefix = 'LST', truckLivery = 0, fuel = 100, truckExtras = { [1] = true } }
    }
}

Config.RouteTrailers = {
    dryvan = { label = 'Reefer Trailer', model = 'trailers2', photo = 'https://docs.fivem.net/vehicles/trailers2.webp', livery = 0, extras = { [1] = true, [2] = false }, contents = 'General Freight', safeSpeed = 75.0, instructions = { 'Keep load sealed until receiver signoff.', 'Avoid heavy collision damage.' } },
    freight = { label = 'Freight Trailer', model = 'trailers', photo = 'https://docs.fivem.net/vehicles/trailers.webp', livery = 0, extras = { [1] = true }, contents = 'Retail Freight', safeSpeed = 75.0, instructions = { 'Verify seal number before departure.', 'Receiver must sign off at the yard.' } },
    long = { label = 'Enclosed Cargo Trailer', model = 'trailers3', photo = 'https://docs.fivem.net/vehicles/trailers3.webp', livery = 0, extras = { [1] = true, [2] = true }, contents = 'Long-Haul Freight', safeSpeed = 72.0, instructions = { 'Maintain extra stopping distance.', 'Check trailer clearance on tight roads.' } },
    commercial = { label = 'Commercial Freight Trailer', model = 'trailers4', photo = 'https://docs.fivem.net/vehicles/trailers4.webp', livery = 0, extras = { [1] = true }, contents = 'Commercial Freight', safeSpeed = 72.0, instructions = { 'Commercial load. Check seal before departure.', 'Use wide turns and avoid low-clearance roads.' } },
    container = { label = 'Container Trailer', model = 'docktrailer', photo = 'https://docs.fivem.net/vehicles/docktrailer.webp', livery = 0, extras = { [1] = true }, contents = 'Sealed Shipping Container', safeSpeed = 68.0, instructions = { 'Sealed port container.', 'Do not break the seal.', 'Use freight yard drop zones only.' } },
    flatbed = { label = 'Flatbed Trailer', model = 'trflat', photo = 'https://docs.fivem.net/vehicles/trflat.webp', livery = 0, extras = { [1] = true }, contents = 'Secured Flatbed Cargo', safeSpeed = 68.0, instructions = { 'Check straps before departure.', 'Avoid sudden lane changes.', 'Report any load shift.' } },
    logs = { label = 'Logging Trailer', model = 'trailerlogs', photo = 'https://docs.fivem.net/vehicles/trailerlogs.webp', livery = 0, extras = { [1] = true }, contents = 'Timber Logs', safeSpeed = 62.0, instructions = { 'Heavy log load.', 'Keep speed controlled on hills.', 'Avoid sharp high-speed turns.' } },
    tanker = { label = 'Fuel Tanker', model = 'tanker', photo = 'https://docs.fivem.net/vehicles/tanker.webp', livery = 0, extras = { [1] = true }, contents = 'Diesel Fuel', safeSpeed = 65.0, instructions = { 'Keep speed under 65 MPH.', 'Avoid sudden braking and major impacts.', 'Report leaks immediately.' } },
    chemical_tanker = { label = 'Chemical Tanker', model = 'tanker2', photo = 'https://docs.fivem.net/vehicles/tanker2.webp', livery = 0, extras = { [1] = true }, contents = 'Industrial Chemicals', safeSpeed = 60.0, instructions = { 'Hazardous contents.', 'Keep speed under 60 MPH.', 'Avoid collisions and report leaks immediately.' } },
    tv = { label = 'Exhibition Trailer', model = 'tvtrailer', photo = 'https://docs.fivem.net/vehicles/tvtrailer.webp', livery = 0, extras = { [1] = true }, contents = 'Event Equipment', safeSpeed = 70.0, instructions = { 'High-value event equipment.', 'Avoid damage and arrive on schedule.' } },
    military = { label = 'Military Trailer', model = 'armytrailer', photo = 'https://docs.fivem.net/vehicles/armytrailer.webp', livery = 0, extras = { [1] = true }, contents = 'Restricted Military Equipment', safeSpeed = 70.0, instructions = { 'Restricted cargo. Do not open trailer.', 'Stay within approved route corridors.', 'Military receiver signoff required.' } },
    heavy_tanker = { label = 'Heavy Military Tanker', model = 'armytanker', photo = 'https://docs.fivem.net/vehicles/armytanker.webp', livery = 0, extras = { [1] = true }, contents = 'Jet Fuel', safeSpeed = 65.0, instructions = { 'Hazardous restricted cargo.', 'Keep speed under 65 MPH.', 'Avoid off-road travel unless ordered.' } },
    heavy_military = { label = 'Heavy Military Trailer', model = 'armytrailer2', photo = 'https://docs.fivem.net/vehicles/armytrailer2.webp', livery = 0, extras = { [1] = true }, contents = 'Heavy Military Equipment', safeSpeed = 65.0, instructions = { 'Heavy restricted cargo.', 'Keep speed under 65 MPH.', 'Avoid off-road travel unless ordered.' } },
    cartrailer = { label = 'Car Trailer', model = 'tr2', photo = 'https://docs.fivem.net/vehicles/tr2.webp', livery = 0, extras = { [1] = true }, contents = 'Empty Car Hauler', safeSpeed = 75.0, instructions = { 'Check straps before departure.', 'Avoid sudden lane changes.', 'Report any load shift.' } },
    cartrailer2 = { label = 'Boat Trailer', model = 'tr3', photo = 'https://docs.fivem.net/vehicles/tr3.webp', livery = 0, extras = { [1] = true }, contents = 'High Value Luxury Sailboat', safeSpeed = 65.0, instructions = { 'Check straps before departure.', 'Avoid sudden lane changes.', 'Report any load shift.' } },
    cartrailer3 = { label = 'Car Trailer', model = 'tr4', photo = 'https://docs.fivem.net/vehicles/tr4.webp', livery = 0, extras = { [1] = true }, contents = 'High Value Luxury Vehicles', safeSpeed = 68.0, instructions = { 'Check straps before departure.', 'Avoid sudden lane changes.', 'Report any load shift.' } },
    mobileop = { label = 'Mobile Operations', model = 'trailerlarge', photo = 'https://docs.fivem.net/vehicles/trailerlarge.webp', livery = 0, extras = { [1] = true }, contents = 'Military Mobile Command Center', safeSpeed = 70.0, instructions = { 'Restricted cargo. Do not open trailer.', 'Stay within approved route corridors.', 'Military receiver signoff required.' } },
    -- add more trailers
}

-- Cargo, inventory, and manifests
Config.GetTrunkInventoryId = function(plate)
    return ('trunk%s'):format(plate)
end

Config.CargoItems = {
    van = {
        item = 'ls_package',
        label = 'Delivery Package',
        prop = `hei_prop_heist_box`,
        carryOffset = { bone = 60309, pos = vec3(0.025, 0.08, 0.255), rot = vec3(-145.0, 290.0, 0.0) }
    },
    boxtruck = {
        item = 'ls_crate',
        label = 'Freight Crate',
        prop = `prop_box_wood02a_pu`,
        carryOffset = { bone = 60309, pos = vec3(0.025, 0.08, 0.255), rot = vec3(-145.0, 290.0, 0.0) }
    }
}

Config.DefaultCargoType = {
    van = 'standard_package',
    boxtruck = 'freight_crate'
}

Config.CargoTypes = {
    standard_package = {
        item = 'ls_package',
        label = 'Delivery Package',
        prop = `hei_prop_heist_box`,
        carryOffset = { bone = 60309, pos = vec3(0.025, 0.08, 0.255), rot = vec3(-145.0, 290.0, 0.0) }
    },

    standard_package2 = {
        item = 'ls_package2',
        label = 'Delivery Package',
        prop = `prop_cardbordbox_05a`,
        carryOffset = { bone = 60309, pos = vec3(0.025, 0.08, 0.255), rot = vec3(-145.0, 290.0, 0.0) }
    },

    standard_package3 = {
        item = 'ls_package3',
        label = 'Delivery Package',
        prop = `prop_cs_package_01`,
        carryOffset = { bone = 60309, pos = vec3(0.025, 0.08, 0.255), rot = vec3(-145.0, 290.0, 0.0) }
    },

    standard_package4 = {
        item = 'ls_package4',
        label = 'Delivery Package',
        prop = `prop_cs_rub_box_02`,
        carryOffset = { bone = 60309, pos = vec3(0.025, 0.08, 0.255), rot = vec3(-145.0, 290.0, 0.0) }
    },

    gift_package = {
        item = 'ls_gift_package',
        label = 'Gift Package',
        prop = `xm3_prop_xm3_present_01a`,
        carryOffset = { bone = 28422, pos = vec3(0.00, -0.18, -0.16), rot = vec3(0.00, 0.00, 0.00) }
    },

    freight_crate = {
        item = 'ls_crate',
        label = 'Freight Crate',
        prop = `prop_box_wood02a`,
        carryOffset = { bone = 60309, pos = vec3(0.025, 0.08, 0.255), rot = vec3(-145.0, 290.0, 0.0) }
    },

    ammo_crate = {
        item = 'ls_ammo_crate',
        label = 'Ammo Crate',
        prop = `prop_box_ammo03a`,
        carryOffset = { bone = 60309, pos = vec3(0.025, 0.08, 0.255), rot = vec3(-145.0, 290.0, 0.0) }
    },

    secure_crate = {
        item = 'ls_secure_crate',
        label = 'Secure Government Crate',
        prop = `prop_box_wood02a_pu`,
        carryOffset = { bone = 60309, pos = vec3(0.025, 0.08, 0.255), rot = vec3(-145.0, 290.0, 0.0) }
    },

    military_crate = {
        item = 'ls_military_crate',
        label = 'Merryweather Crate',
        prop = `prop_box_wood02a_mws`,
        carryOffset = { bone = 60309, pos = vec3(0.025, 0.08, 0.255), rot = vec3(-145.0, 290.0, 0.0) }
    },

    military_crate2 = {
        item = 'ls_military_crate2',
        label = 'Military Crate',
        prop = `prop_mil_crate_01`,
        carryOffset = { bone = 60309, pos = vec3(0.025, 0.08, 0.255), rot = vec3(-145.0, 290.0, 0.0) }
    }
}

Config.Manifest = {
    Enabled = true,
    PackageManifestItem = 'ls_delivery_manifest',
    TrailerManifestItem = 'ls_trailer_manifest',
    RemoveOnComplete = true
}

-- Ranks, payouts, and interaction timing
Config.Ranks = {
    { rank = 1, label = 'New Hire', xp = 0 },
    { rank = 2, label = 'Courier', xp = 5000 },
    { rank = 3, label = 'Route Driver', xp = 10000 },
    { rank = 4, label = 'Freight Driver', xp = 25000 },
    { rank = 5, label = 'Road Captain', xp = 50000 },
    { rank = 6, label = 'Logistics Veteran', xp = 100000 }
}

Config.Payouts = {
    van = { min = 1200, max = 2200, xp = 120, rep = 2 },
    boxtruck = { min = 2400, max = 4200, xp = 250, rep = 4 },
    trailer = { min = 5000, max = 9500, xp = 500, rep = 7 }
}

Config.Progress = {
    collectCargo = 2500,
    loadCargo = 3000,
    verifyLoadedCargo = 2500,
    grabCargo = 2500,
    deliverCargo = 3500,
    finalizeTrailer = 5000,
    confirmTrailerDrop = 2500,
    confirmTrailerLoad = 3500,
    secureTruckLoad = 3000,
    secureTrailerLoad = 3000,
    completeLoadChecklist = 2500,
    returnVehicle = 3500,
    spawnGarageVehicle = 2500
}

-- Job flow and payment behavior
Config.AllowVehicleReuseAfterRoute = true
Config.RequireSameTypeForVehicleReuse = true
Config.DeleteOldVehicleOnNewContract = true
Config.PayWhenRouteComplete = true
Config.ReturnVehicleBonusEnabled = true
Config.ReturnVehicleBonus = 250
Config.PayToBank = true
Config.TargetDistance = 2.5
Config.TrailerAutoDetectInterval = 750
Config.TrailerDespawnAfterDelivery = 10000 -- milliseconds after receiver signoff

-- Delivery timing, damage, random events, cancellation, and trailer speed risk
Config.DeliveryTiming = {
    Enabled = true,
    GraceSeconds = 60,
    EarlyBonusWindowSeconds = 120,
    EarlyBonusPercent = 0.08,
    LatePenaltyPercent = 0.12,
    MinimumFinalPayoutPercent = 0.45,

    -- Used when a route does not have a custom estimatedSeconds value.
    Defaults = {
        van = { standard = 600, priority = 540, government = 720, military = 780 },
        boxtruck = { standard = 900, priority = 780, government = 1020, military = 1200 },
        trailer = { standard = 900, priority = 1260, government = 1320, military = 1500 }
    },

    -- If routeLength is a string like "15.7 mi", this is used to create a realistic estimate.
    MinutesPerMile = {
        van = 1.65,
        boxtruck = 1.85,
        trailer = 2.15
    },

    BaseMinutes = {
        van = 4,
        boxtruck = 6,
        trailer = 8
    }
}

Config.TrailerDamagePenalties = {
    Enabled = true,
    CleanBonusPercent = 0.04, -- under CleanThresholdPercent damage gives a small bonus
    CleanThresholdPercent = 2.5,
    Levels = {
        { minDamagePercent = 35.0, penaltyPercent = 0.30, label = 'Heavy trailer damage' },
        { minDamagePercent = 20.0, penaltyPercent = 0.18, label = 'Moderate trailer damage' },
        { minDamagePercent = 8.0, penaltyPercent = 0.08, label = 'Light trailer damage' }
    }
}

Config.RandomDeliveryEvents = {
    Enabled = true,
    Chance = 0.28,
    Events = {
        {
            id = 'dock_delay',
            label = 'Dock Delay Cleared',
            description = 'Dispatch cleared a dock delay. Your route window was extended slightly.',
            types = { 'van', 'boxtruck', 'trailer' },
            estimateDeltaSeconds = 120,
            payoutPercent = 0.00,
            repBonus = 0
        },
        {
            id = 'rush_order',
            label = 'Rush Order Bonus',
            description = 'Dispatch marked this load urgent. Deliver clean and on time for a bonus.',
            types = { 'van', 'boxtruck', 'trailer' },
            estimateDeltaSeconds = -60,
            payoutPercent = 0.07,
            repBonus = 1
        },
        {
            id = 'receiver_audit',
            label = 'Receiver Audit',
            description = 'The receiver is checking paperwork closely. Late arrivals are less forgiving.',
            types = { 'boxtruck', 'trailer' },
            estimateDeltaSeconds = 0,
            payoutPercent = 0.04,
            latePenaltyBonusPercent = 0.05,
            repBonus = 1
        },
        {
            id = 'restricted_checkpoint',
            label = 'Restricted Route Checkpoint',
            description = 'Security requested careful handling through a checkpoint. Payout increased.',
            types = { 'trailer' },
            priorities = { 'government', 'military' },
            estimateDeltaSeconds = 180,
            payoutPercent = 0.10,
            repBonus = 2
        },
        {
            id = 'traffic_reroute',
            label = 'Traffic Reroute',
            description = 'A traffic reroute was issued. You have a little extra time, but no payout change.',
            types = { 'van', 'boxtruck', 'trailer' },
            estimateDeltaSeconds = 180,
            payoutPercent = 0.00,
            repBonus = 0
        }
    }
}

Config.SpeedRisk = {
    Enabled = true,
    CheckInterval = 5000,
    WarningAfter = 10000,
    RiskAfter = 20000,
    DefaultSafeSpeed = 75.0,
    TireBlowoutChance = 3, -- percent per check after RiskAfter
    EngineFailureChance = 1, -- percent per check after RiskAfter
    EngineDamageAmount = 120.0,
    MinimumEngineHealth = 350.0,
    WarningMessage = 'Dispatch: Reduce speed. Cargo stability warning.'
}

Config.CancelPenalty = {
    Enabled = true,
    ReputationLoss = 3,
    Reasons = {
        { value = 'vehicle_damaged', label = 'Vehicle / trailer damaged' },
        { value = 'wrong_vehicle', label = 'Wrong vehicle selected' },
        { value = 'route_issue', label = 'Route issue / blocked destination' },
        { value = 'out_of_time', label = 'Out of time' },
        { value = 'player_choice', label = 'Changed my mind' },
        { value = 'other', label = 'Other' }
    }
}

-- UI, notifications, sounds, blips, and radio
Config.UI = {
    Sounds = true,
    SoundVolume = 0.22,
    SoundsPath = 'sounds/',
    ClickSound = 'click.wav',
    ConfirmSound = 'confirm.wav',
    ErrorSound = 'error.wav',
    AlertSound = 'alert.wav',
    DestinationSound = 'destination.wav',
    SecureSound = 'secure.wav'
}

Config.Notifications = {
    Enabled = false,
    Title = 'Los Santos Freight Co.',
    Duration = 8500
}

Config.Blips = {
    Pickup = { sprite = 478, color = 2, scale = 0.80 },
    PackageDelivery = { sprite = 478, color = 5, scale = 0.82 },
    CrateDelivery = { sprite = 478, color = 3, scale = 0.82 },
    TrailerDelivery = { sprite = 479, color = 47, scale = 0.88 },
    Receiver = { sprite = 280, color = 5, scale = 0.80 },
    ReturnVehicle = { sprite = 477, color = 5, scale = 0.82 },
    Default = { sprite = 1, color = 5, scale = 0.85 }
}

Config.RadioFrequency = 'CH. 68.9'

Config.MiniUIEnabled = true

Config.VersionCheck = {
    Enabled = true,
    GitHubRawVersionUrl = 'https://github.com/DrSnyder86/ls_trucking/blob/main/version.json', 
    ConfigRawVersionUrl = 'https://github.com/DrSnyder86/ls_trucking/blob/main/config/contracts.lua', 
    ContractsRawVersionUrl = '', 
    PrintUpToDate = true,
    CheckDelay = 5000
}
