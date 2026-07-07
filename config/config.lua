Config = {}

Config.Locale = 'en'
Config.ConfigVersion = '1.2.0'

Config.Debug = false  -- Enables debug visuals/logging. Admin commands are available to admins even when this is false.
Config.Framework = 'auto' -- auto, qb, qbox, esx, nd, standalone
Config.Command = 'trucking'
Config.DispatchKey = 'F3'
Config.MiniUIToggleCommand = 'truckui'
Config.FullReceiverCommand = 'truckreceiver'
Config.FullReceiverKey = 'F2'
Config.CancelCommand = 'canceltrucking'
Config.RequireJob = true
Config.JobName = 'trucker'
Config.RequireDuty = true -- Only applies when RequireJob is true. Framework duty is used when available, otherwise LSFC session duty is used.
Config.UsePed = true
Config.UseBlip = true
Config.UseTerminalTargetZone = false
Config.RadioFrequency = '68.9'
Config.MiniUIEnabled = true
Config.ReceiverDockEnabled = true
Config.FullReceiverEnabled = true
Config.ReceiverRefreshInterval = 15000 -- milliseconds between passive receiver/signal refreshes
Config.AllowVehicleReuseAfterRoute = true
Config.RequireSameTypeForVehicleReuse = true
Config.DeleteOldVehicleOnNewContract = true
Config.PayWhenRouteComplete = true
Config.ReturnVehicleBonusEnabled = true
Config.ReturnVehicleBonus = 250
Config.PayToBank = false
Config.TargetDistance = 2.5
Config.DropoffTarget = { Radius = 3.5, Distance = 3.5, HeightOffset = 0.75 } -- larger/easier package delivery target zones
Config.TrailerAutoDetectInterval = 750
Config.TrailerCoupleNoticeDelay = 500
Config.TrailerDespawnAfterDelivery = 10000 -- milliseconds after receiver signoff

-- Core integrations and route interaction modes
-- Target system: 'auto', 'ox', or 'qb'. Auto prefers ox_target, then qb-target.
Config.TargetSystem = 'auto'
Config.LoadVerificationMode = 'receiver' -- 'receiver' or 'target'

Config.Inventory = {
    System = 'auto', -- auto, ox_inventory, qb-inventory, lj-inventory, ps-inventory, qs-inventory, or custom
    Debug = false,
    UseInternalTrunkFallback = true,
    TrunkPrefix = 'trunk'
}

Config.Fuel = {
    System = 'auto', -- auto, ox_fuel, LegacyFuel, ps-fuel, cdn-fuel, lj-fuel, qb-fuel, BigDaddy-Fuel, or none
    DefaultFuel = 100.0
}

Config.Keys = {
    System = 'auto', -- auto, qb-vehiclekeys, qbx_vehiclekeys, Renewed-Vehiclekeys, MrNewbVehicleKeys, wasabi_carlock, cd_garage, or none
    GiveOnSpawn = true,
    RemoveOnReturn = false,
    OwnerOnly = true
}

-- Primary dispatch, duty, and company vehicle locations
Config.DispatchPed = {
    model = `s_m_m_dockwork_01`,
    coords = vector4(-41.54, -2513.28, 6.16, 311.58),
    scenario = 'WORLD_HUMAN_CLIPBOARD'
}

Config.DutyTarget = {
    enabled = true,
    useDispatchPed = true,
    coords = nil,
    radius = 2.0,
    label = 'Clock In / Out',
    icon = 'fa-solid fa-clock'
}

Config.DispatchBlip = {
    coords = vector3(-41.54, -2513.28, 6.16),
    sprite = 477,
    color = 5,
    scale = 0.55,
    label = 'Los Santos Freight Co.'
}

Config.Depot = {
    terminal = vector3(-41.54, -2513.28, 6.16), -- -60.101368,-2517.431152,7.297539
    request = vector3(-41.54, -2513.28, 6.16),
    requestRadius = 120.0,
    vehicleSpawn = vector4(-46.58, -2503.58, 6.01, 237.01),
    garageSpawn = vector4(-46.58, -2503.58, 6.01, 237.01),
    vehicleReturn = vector3(-41.54, -2513.28, 6.16)
}
-- Active route world behavior
Config.ActiveContractPeds = {
    SpawnDistance = 100.0,
    DespawnDistance = 130.0,
    CheckInterval = 750
}

Config.TrailerDropMarker = {
    Enabled = true,
    DrawDistance = 120.0,
    MarkerType = 1,
    Size = 6.0,
    Height = 0.24,
    ZOffset = -0.65,
    PositionTolerance = 1.40,
    ServerTolerance = 0.75,
    MaxSettleSpeed = 0.15,
    SettleTime = 2000,
    Alpha = 115,
    Colors = {
        Outside = { r = 220, g = 55, b = 48 },
        Inside = { r = 242, g = 180, b = 45 },
        Centered = { r = 76, g = 220, b = 105 },
        Detached = { r = 235, g = 240, b = 238 }
    }
}

Config.SpawnOccupancy = {
    Enabled = true,
    VehicleRadius = 4.0,
    TrailerRadius = 6.0
}

Config.JobBlips = {
    enabled = true,
    updateInterval = 7500,
    minMoveDistance = 25.0,
    showSelf = false,
    requireDuty = true,
    shortRange = true,
    label = 'LSFC Unit',
    scale = 0.72,

    sprites = {
        foot = 1,
        van = 67,
        boxtruck = 477,
        trailer = 477,
        unknown = 1
    },

    colors = {
        idle = 5,
        activeRoute = 2,
        contractor = 46
    }
}

-- Server-side hardening and install diagnostics
Config.Security = {
    ServerDistanceChecks = true,
    ValidateConfig = true,
    PrintStartupSummary = true,
    AdminAces = { 'ls_trucking.admin', 'ls_trucking.debug' }, -- Optional fallback ACEs. Framework admin/god permissions and common admin ACEs are checked first.
    MaxSavedPropsLength = 24000,

    Cooldowns = {
        Dispatch = 500,
        Contract = 2000,
        Cargo = 750,
        Trailer = 1000,
        ReturnVehicle = 2000,
        CompleteRoute = 2000,
        Cancel = 1500
    },

    DistanceChecks = {
        Depot = 35.0,
        Pickup = 12.0,
        Dropoff = 14.0,
        LoadVerification = 20.0,
        TrailerPickup = 120.0,
        TrailerDrop = 35.0,
        Duty = 5.0,
        Receiver = 14.0,
        VehicleReturn = 35.0,
        Completion = 35.0
    }
}

Config.DispatchExchange = {
    Enabled = true,
    RequestDelay = 1250,
    ResponseDelay = 900,
    ChecklistStepDelay = 700
}

Config.FreightHandoff = {
    Enabled = true,
    RequirePickupSignature = true,
    RequireTrailerSignature = true,
    ResponseDelay = 900,
    PedGreeting = true,
    GreetingCooldown = 15000,
    GreetingSpeech = { 'GENERIC_HI', 'GENERIC_HOWS_IT_GOING' },
    SpeechParams = 'SPEECH_PARAMS_FORCE_NORMAL_CLEAR'
}

Config.RadioMessageAudio = {
    Enabled = true,
    NativeInJobVehicle = true,
    DriverOnly = true,
    StartSound = 'Start_Squelch',
    EndSound = 'End_Squelch',
    SoundSet = 'CB_RADIO_SFX',
    EndDelay = 575,
    Cooldown = 225
}

Config.DispatchHome = {
    -- To use an actual San Andreas map, add your map image to /images and set this to '../images/your-map.webp'.
    -- Markers use GTA world coords against these bounds, so a north-up full-island image will line up best.
    MapImage = '../images/photos/locations/MapImage.webp',
    MapBounds = {
        minX = -6000,
        maxX = 7000,
        minY = -4200,
        maxY = 8800
    },
    MapZoom = 1.0,
    MapZoomMin = 1.0,
    MapZoomMax = 2.8,
    MapZoomStep = 0.25,
    Photos = {
        -- Use URLs or local NUI paths such as '../images/photos/locations/terminal.webp'.
        terminal = '../images/photos/locations/terminal.webp',
        vehicleSpawn = '../images/photos/locations/vehicleSpawn.webp',
        garageSpawn = '../images/photos/locations/garageSpawn.webp',
        vanPickup = '../images/photos/locations/vanPickup.webp',
        boxTruckPickup = '../images/photos/locations/boxTruckPickup.webp',
        trailerDepot = '../images/photos/locations/trailerDepot.webp',
        trailerDepots = {
            docks = '../images/photos/locations/docks.webp',
            harmony = '../images/photos/locations/harmony.webp',
            lsport = '../images/photos/locations/lsport.webp',
        }
    }
}

-- Assign depots to trailer contracts using depot table names (pickupDepot = 'docks')
Config.TrailerDepots = {
    docks = {
        label = "Jetsam Terminal",
        pickup = vector3(1025.9, -3184.63, 5.9),
        spawns = {
            vector4(1009.65, -3185.64, 5.9, 359.8),
            vector4(1017.74, -3184.99, 5.9, 1.66),
            vector4(1025.9, -3184.63, 5.9, 2.43),
            vector4(1033.97, -3185.05, 5.9, 355.9),
            vector4(1046.33, -3186.27, 5.9, 359.48),
            vector4(1058.22, -3185.82, 5.9, 359.92),
        }
    },

    harmony = {
        label = 'Harmony Freight Depot',
        pickup = vector3(195.43, 2747.35, 43.43),
        spawns = {
            vector4(205.28, 2749.38, 43.45, 113.86),
            vector4(159.97, 2762.62, 43.28, 260.48),
            vector4(161.07, 2752.78, 43.39, 275.82),
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
            vector4(-500.16, -2844.19, 6.0, 42.84),
        }
    },
    -- add more depots
    -- pickupDepot = {
    --     label = 'DepotLabel',
    --     pickup = vector3(0.0, 0.0, 0.0), -- map blip location
    --     spawns = {
    --         vector4(00.00, 00.00, 00.00, 00.00),
    --         vector4(00.00, 00.00, 00.00, 00.00),
    --         vector4(00.00, 00.00, 00.00, 00.00),
    --         vector4(00.00, 00.00, 00.00, 00.00),
    --     }
    -- },
}

-- Ranks, payouts, and interaction timing
Config.Ranks = {
    { rank = 1, label = 'Probationary Driver', xp = 0 },
    { rank = 2, label = 'City Courier', xp = 5000 },
    { rank = 3, label = 'Route Driver', xp = 15000 },
    { rank = 4, label = 'Trailer Certified Driver', xp = 35000 },
    { rank = 5, label = 'Freight Operator', xp = 65000 },
    { rank = 6, label = 'Long Haul Driver', xp = 110000 },
    { rank = 7, label = 'Heavy Freight Specialist', xp = 175000 },
    { rank = 8, label = 'Fleet Lead', xp = 260000 },
    { rank = 9, label = 'Logistics Supervisor', xp = 375000 },
    { rank = 10, label = 'LSFC Master Hauler', xp = 500000 },
    --{ rank = 0, label = 'RANK LABEL', xp = 1000000 },

}

Config.Payouts = {
    van = { min = 1200, max = 1500, xp = 120, rep = 2 },
    boxtruck = { min = 2200, max = 2500, xp = 250, rep = 4 },
    trailer = { min = 4200, max = 4500, xp = 500, rep = 7 }
}

-- Added to the randomized base payout using each route's configured routeLength.
Config.MileagePayout = {
    Enabled = true,
    RatePerMile = 100
}

Config.PrivateContractor = {
    Enabled = true,
    UnlockRank = 5,
    LicenseCost = 50000,
    MaxOwnedVehicles = 6,
    MinFuel = 20,
    MinCondition = 55,
    PayoutMultiplier = 1.35,
    XpMultiplier = 1.10,
    RepBonus = 1,
    PenaltyMultiplier = 1.25,
    CancelFee = 2500,
    CancelRepLoss = 5,
    DailyResetHour = 6,
    DailyRouteChangeCooldownDays = 7,
    DailyRouteCompletionBonus = 3500,
    DailyRouteRepBonus = 2,
    DailyRouteOptionsPerType = 8,
    ContractBoardRoutesPerType = 5,
    ContractBoardRefreshMinutes = 60,
    ResaleBasePercent = 0.80,
    DepreciationPerMile = 10,
    VehicleTypes = { 'van', 'boxtruck', 'trailer' }, -- trailer type uses purchased tractors only; trailers remain route-assigned
    -- Fallback only. Per-vehicle contractor pricing is assigned in config/vehicles.lua.
    VehiclePricing = {
        van = { base = 85000, step = 5000 },
        boxtruck = { base = 165000, step = 10000 },
        trailer = { base = 260000, step = 15000 }
    },
    DailyRoutes = {
        { type = 'van', label = 'Package Route', minRank = 5 },
        { type = 'boxtruck', label = 'Crate Route', minRank = 5 },
        { type = 'trailer', label = 'Trailer Route', minRank = 5 }
    }
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
    disconnectTrailer = 3000,
    secureTrailerLoad = 3000,
    completeLoadChecklist = 2500,
    returnVehicle = 3500,
    spawnGarageVehicle = 2500
}

-- Delivery timing, damage, random events, cancellation, and trailer speed risk
Config.DeliveryTiming = {
    Enabled = true,
    GraceSeconds = 60,
    EarlyBonusWindowSeconds = 90,
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
    WarningMessage = 'Dispatch: Cargo stability warning! Reduce speed.'
}

Config.CargoCondition = {
    Enabled = true,
    CheckInterval = 2000,
    IncidentCooldown = 6000,
    HealthDropThreshold = 12.0,
    DamageScoreMultiplier = 0.08,
    HardBrakeMinSpeed = 35.0,
    HardBrakeDropMph = 28.0,
    HardBrakePenalty = 4,
    SpeedWarningAfter = 9000,
    SpeedPenalty = 2,
    SafeSpeed = {
        van = 85.0,
        boxtruck = 75.0,
        trailer = 70.0
    }
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
    SoundVolume = 0.18,
    SoundsPath = 'sounds/',
    MiniLogo = 'images/badger-logo.png',
    ClickSound = 'click.wav',
    ConfirmSound = 'confirm.wav',
    ErrorSound = 'error.wav',
    AlertSound = 'alert.wav',
    DestinationSound = 'destination.wav',
    SecureSound = 'secure.wav',
    TrailerConnectSound = 'trailer_connect.wav',
    TrailerDisconnectSound = 'trailer_disconnect.wav',
    ImpactWrenchSound = 'impact_wrench.wav'
}

Config.Notifications = {
    Enabled = true,
    Title = 'Los Santos Freight Co.',
    Duration = 8500,
    Sounds = false,
    SoundMap = {
        error = 'alert',
        warning = 'confirm',
        success = 'confirm'
    }
}

Config.Blips = {
    Pickup = { sprite = 478, color = 2, scale = 0.60 },
    PackageDelivery = { sprite = 478, color = 5, scale = 0.60 },
    CrateDelivery = { sprite = 478, color = 3, scale = 0.60 },
    TrailerDelivery = { sprite = 479, color = 47, scale = 0.60 },
    Receiver = { sprite = 280, color = 5, scale = 0.60 },
    ReturnVehicle = { sprite = 477, color = 5, scale = 0.60 },
    Default = { sprite = 1, color = 5, scale = 0.60 }
}

Config.AreaBlips = {
    Enabled = true,
    TrailerPickup = { radius = 55.0, color = 47, alpha = 100 },
    TrailerDrop = { fallbackRadius = 22.0, color = 47, alpha = 100 }
}

Config.VersionCheck = {
    Enabled = true,
    GitHubRawVersionUrl = 'https://raw.githubusercontent.com/DrSnyder86/ls_trucking/main/version.json', -- resource version.json or plain-text version
    ConfigRawVersionUrl = 'https://raw.githubusercontent.com/DrSnyder86/ls_trucking/main/version.json', -- optional raw config/config.lua or config_version JSON
    ContractsRawVersionUrl = 'https://raw.githubusercontent.com/DrSnyder86/ls_trucking/main/version.json', -- optional raw config/contracts.lua or contracts_version JSON
    PrintUpToDate = true,
    CheckDelay = 5000
}
