Config = {}

--[[

 _____                                                                                                     _____ 
( ___ )                                                                                                   ( ___ )
 |   |~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|   | 
 |   |  ██╗     ███████╗    ███████╗██████╗ ███████╗██╗ ██████╗ ██╗  ██╗████████╗     ██████╗ ██████╗      |   | 
 |   |  ██║     ██╔════╝    ██╔════╝██╔══██╗██╔════╝██║██╔════╝ ██║  ██║╚══██╔══╝    ██╔════╝██╔═══██╗     |   | 
 |   |  ██║     ███████╗    █████╗  ██████╔╝█████╗  ██║██║  ███╗███████║   ██║       ██║     ██║   ██║     |   | 
 |   |  ██║     ╚════██║    ██╔══╝  ██╔══██╗██╔══╝  ██║██║   ██║██╔══██║   ██║       ██║     ██║   ██║     |   | 
 |   |  ███████╗███████║    ██║     ██║  ██║███████╗██║╚██████╔╝██║  ██║   ██║       ╚██████╗╚██████╔╝██╗  |   | 
 |   |  ╚══════╝╚══════╝    ╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝ ╚═════╝ ╚═╝  ╚═╝   ╚═╝        ╚═════╝ ╚═════╝ ╚═╝  |   | 
 |___|~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|___| 
(_____)                                                                                                   (_____)

    LS TRUCKING MAIN CONFIG

    01. Metadata and quick setup
    02. Framework integrations
    03. Primary locations
    04. Commands and receiver access
    05. Contract workflow and interactions
    06. Vehicle and trailer lifecycle
    07. Economy and progression
    08. Action and delivery timing
    09. Risk, condition, and penalties
    10. Navigation and world markers
    11. UI, radio, and notifications
    12. Security and validation
    13. Version checking

    Conventions used in this file:
    - vector3 values are x, y, z. vector4 adds heading as the fourth value.
    - Distances and radii are meters unless the field says otherwise.
    - Durations are milliseconds unless the field name ends in Seconds or Minutes.
    - Decimal percentages use 0.08 for 8 percent. Whole percentages are called out explicitly.
]]

-- ============================================================================
-- 01. METADATA AND QUICK SETUP
-- ============================================================================

Config.Locale = 'en' -- Loads matching Lua and NUI locale files; missing entries fall back to English.
Config.ConfigVersion = '1.4.0' -- Config schema version; this is separate from the resource release version.
Config.Debug = false -- Enables debug visuals/logging. Admin commands remain available to authorized admins.

Config.Framework = 'auto' -- auto, qb, qbox, esx, nd/nd_framework, nd_core, standalone
Config.RequireJob = true -- Set false to allow players without the configured framework job to use LS Trucking.
Config.JobName = 'trucker' -- Exact internal job name used by the selected framework.
Config.RequireDuty = true -- Only applies when RequireJob is true. Uses framework duty when available, otherwise the LSFC session duty.

-- ============================================================================
-- 02. FRAMEWORK INTEGRATIONS
-- ============================================================================

-- Set a provider explicitly when multiple compatible resources are running. Auto uses the first supported started resource.
-- Target system: auto, ox, qb, or textui. Auto prefers an installed target resource and falls back to ox_lib TextUI.
Config.TargetSystem = 'auto'

Config.Inventory = {
    System = 'auto', -- auto, nd_inventory, ox_inventory, qb-inventory, lj-inventory, ps-inventory, qs-inventory, or custom
    Debug = false, -- Prints inventory adapter decisions and failed item operations to the server console.
    -- Keeps route cargo in a server-memory trunk when the provider cannot manipulate vehicle inventories.
    -- This fallback is only for LS Trucking cargo, is not a general inventory, and resets with the resource.
    UseInternalTrunkFallback = true,
    TrunkPrefix = 'trunk' -- Combined with the normalized plate, for example trunkLSFC1234.
}

Config.Fuel = {
    -- none skips external fuel exports but still sets/reads GTA's native fuel level.
    System = 'auto', -- auto, nd_fuel, lc_fuel/lc-fuel, ox_fuel, LegacyFuel, ps-fuel, cdn-fuel, lj-fuel, qb-fuel, BigDaddy-Fuel, or none
    DefaultFuel = 100.0 -- Initial company/contractor vehicle fuel on a 0-100 scale.
}

Config.Keys = {
    System = 'auto', -- auto, qb-vehiclekeys, qbx_vehiclekeys, Renewed-Vehiclekeys, MrNewbVehicleKeys, wasabi_carlock, cd_garage, or none
    GiveOnSpawn = true, -- Gives the requesting player keys after a job vehicle is created.
    RemoveOnReturn = false, -- Attempts to revoke keys when a company or contractor vehicle is stored.
    OwnerOnly = true -- Removes synchronized job-vehicle keys from players other than the current checkout owner.
}

-- ============================================================================
-- 03. PRIMARY LOCATIONS
-- ============================================================================

-- DispatchPed.coords controls both the ped position and facing direction.
Config.DispatchPed = {
    model = `s_m_m_dockwork_01`,
    coords = vector4(-41.54, -2513.28, 6.16, 311.58),
    scenario = 'WORLD_HUMAN_CLIPBOARD'
}

Config.DutyTarget = {
    enabled = true, -- Effective only when RequireJob and RequireDuty are enabled.
    useDispatchPed = true, -- False creates a separate sphere interaction instead of attaching to the dispatch ped.
    coords = nil, -- Nil falls back to DispatchPed.coords, then Depot.terminal.
    radius = 2.0, -- Radius of the separate sphere interaction; unused while useDispatchPed is true.
    label = 'Clock In / Out',
    icon = 'fa-solid fa-clock'
}

Config.Depot = {
    terminal = vector3(-41.54, -2513.28, 6.16), -- Dispatch terminal interaction and general depot fallback.
    request = vector3(-41.54, -2513.28, 6.16), -- Center used to authorize vehicle and contract requests.
    requestRadius = 120.0, -- Overrides Security.DistanceChecks.Depot for depot request callbacks.
    vehicleSpawn = vector4(-46.58, -2503.58, 6.01, 237.01), -- Company contract vehicle spawn.
    garageSpawn = vector4(-46.58, -2503.58, 6.01, 237.01), -- Stored company and contractor fleet spawn.
    vehicleReturn = vector3(-41.54, -2513.28, 6.16) -- Company and contractor vehicle storage point.
}

-- Trailer contracts reference these table names with pickupDepot, for example pickupDepot = 'docks'.
-- Spawn positions are checked in list order and the first unoccupied position is used.
Config.TrailerDepots = {
    docks = {
        label = 'Jetsam Terminal',
        area = 'Elysian Island / Port of Los Santos',
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
        area = 'Route 68 / Harmony',
        pickup = vector3(195.43, 2747.35, 43.43),
        spawns = {
            vector4(205.28, 2749.38, 43.45, 113.86),
            vector4(159.97, 2762.62, 43.28, 260.48),
            vector4(161.07, 2752.78, 43.39, 275.82),
        }
    },

    lsport = {
        label = 'Post OP Depository',
        area = 'Elysian Island / Port of Los Santos',
        pickup = vector3(-481.64, -2828.94, 6.0),
        spawns = {
            vector4(-482.52, -2825.57, 6.0, 47.29),
            vector4(-477.69, -2821.69, 6.0, 45.63),
            vector4(-486.43, -2830.37, 6.0, 46.17),
            vector4(-495.9, -2839.4, 6.0, 49.71),
            vector4(-500.16, -2844.19, 6.0, 42.84),
        }
    }
}

-- ============================================================================
-- 04. COMMANDS AND RECEIVER ACCESS
-- ============================================================================

Config.Command = 'trucking' -- Opens the dispatch tablet when the player has access.
Config.DispatchKey = 'F3' -- Default key mapping for the dispatch tablet command.
Config.MiniUIToggleCommand = 'truckui' -- Toggles the compact dock receiver during an active route.
Config.FullReceiverCommand = 'truckreceiver' -- Opens the handheld full receiver.
Config.FullReceiverKey = 'F2' -- Default key mapping for the full receiver command.
Config.CancelCommand = 'canceltrucking' -- Opens the active-route cancellation flow.

-- ============================================================================
-- 05. CONTRACT WORKFLOW AND INTERACTIONS
-- ============================================================================

Config.UsePed = true -- Spawns the primary dispatch ped and attaches dispatch interactions to it.
Config.UseTerminalTargetZone = false -- Adds a separate dispatch interaction at Depot.terminal.
Config.TargetDistance = 2.5 -- Maximum interaction distance used by target and TextUI providers.
Config.LoadVerificationMode = 'receiver' -- receiver: verify in the UI; target: verify through a vehicle interaction.

Config.CargoLoading = {
    Mode = 'assisted' -- assisted: one timed vehicle load; manual: carry and load each cargo item individually.
}

Config.FreightHandoff = {
    Enabled = true, -- Enables the pickup-ped handoff dialog and related radio exchange.
    RequirePickupSignature = true, -- Requires van/box-truck cargo release authorization before loading.
    RequireTrailerSignature = true, -- Requires trailer handoff authorization before departure.
    ResponseDelay = 900, -- Delay before the dispatch response is shown.
    PedGreeting = true, -- Plays ambient speech when approaching an active contract ped.
    GreetingCooldown = 15000, -- Minimum delay before that ped may greet the player again.
    GreetingSpeech = { 'GENERIC_HI', 'GENERIC_HOWS_IT_GOING' }, -- GTA speech names selected at random.
    SpeechParams = 'SPEECH_PARAMS_FORCE_NORMAL_CLEAR' -- GTA ambient speech parameter set.
}

Config.DispatchExchange = {
    Enabled = true, -- Sequences request, response, and checklist messages through the dock radio UI.
    RequestDelay = 1250, -- Pause after the player's request message.
    ResponseDelay = 900, -- Pause before dispatch acknowledges the request.
    ChecklistStepDelay = 700 -- Delay between automatic trailer checklist status messages.
}

-- Spawn/despawn distances form a buffer so peds do not repeatedly stream at the boundary.
-- Keep DespawnDistance greater than SpawnDistance.
Config.ActiveContractPeds = {
    SpawnDistance = 100.0, -- meters
    DespawnDistance = 130.0, -- meters
    CheckInterval = 750 -- milliseconds
}

-- ============================================================================
-- 06. VEHICLE AND TRAILER LIFECYCLE
-- ============================================================================

Config.AllowVehicleReuseAfterRoute = true -- Leaves an eligible completed-route vehicle available for the next contract.
Config.RequireSameTypeForVehicleReuse = true -- Reuse only when the next contract uses the same van/boxtruck/trailer class.
Config.DeleteOldVehicleOnNewContract = true -- Cleans up an incompatible or stale job vehicle before a new one is spawned.

Config.SpawnOccupancy = {
    Enabled = true, -- Prevents spawning on top of an existing vehicle.
    VehicleRadius = 4.0, -- Clearance checked around company and garage vehicle spawns.
    TrailerRadius = 6.0 -- Clearance checked around each configured trailer spawn.
}

Config.TrailerAutoDetectInterval = 750 -- Poll rate while waiting for the assigned trailer to be coupled.
Config.TrailerCoupleNoticeDelay = 500 -- Delay before showing the post-coupling checklist instruction.
Config.TrailerDespawnAfterDelivery = 10000 -- Cleanup delay after receiver signoff.

-- ============================================================================
-- 07. ECONOMY AND PROGRESSION
-- ============================================================================

-- When false, route completion skips the built-in payout, stats, XP/rep, and history write.
Config.PayWhenRouteComplete = true
Config.PayToBank = false -- False uses cash; true uses bank for route payouts and service bay charges.
Config.ReturnVehicleBonusEnabled = true
Config.ReturnVehicleBonus = 250 -- Paid once for returning the correct company vehicle after a completed route.

-- min/max define the randomized base payout before mileage, contractor, timing, and damage adjustments.
-- xp and rep are awarded after a successful paid route.
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

-- xp is the cumulative minimum required for a rank. Keep entries in ascending threshold order.
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
    { rank = 10, label = 'LSFC Master Hauler', xp = 500000 }
}

Config.PrivateContractor = {
    -- Access and fleet requirements
    Enabled = true,
    UnlockRank = 5, -- Minimum Config.Ranks rank required to purchase a contractor license.
    LicenseCost = 50000, -- One-time contractor license purchase price.
    MaxOwnedVehicles = 6, -- Maximum total privately owned LSFC fleet units per player.
    MinFuel = 50, -- Whole fuel percentage required before starting a contractor route.
    MinCondition = 80, -- Whole vehicle condition percentage required before starting a route.
    VehicleTypes = { 'van', 'boxtruck', 'trailer' }, -- Trailer type purchases tractors; route trailers remain assigned.

    -- Rewards and cancellation costs
    PayoutMultiplier = 1.35, -- Multiplies the route and priority payout.
    XpMultiplier = 1.10, -- Multiplies route XP before it is rounded.
    RepBonus = 1, -- Flat contractor reputation added to each completed route.
    PenaltyMultiplier = 1.25, -- Multiplies percentage-based route penalties for contractors.
    CancelFee = 2500, -- Additional contractor cash/bank charge on cancellation.
    CancelRepLoss = 5, -- Contractor reputation removed on cancellation.

    -- Contract board generation
    ContractBoardRoutesPerType = 8, -- Maximum offers for the currently checked-out contractor vehicle type.
    ContractBoardRefreshMinutes = 60, -- Board seed and displayed refresh timer interval.
    -- Trailer boards only show routes whose pickupDepot matches the selected terminal.
    -- Van and box truck routes can originate from either cargo terminal; their displayed
    -- mileage, ETA, and mileage pay are adjusted for the selected route origin.
    PickupDepots = {
        van = { 'go_postal', 'post_op' },
        boxtruck = { 'go_postal', 'post_op' },
        trailer = { 'docks', 'harmony', 'lsport' }
    },
    DefaultPickupDepots = {
        van = 'go_postal',
        boxtruck = 'post_op',
        trailer = 'docks'
    },

    -- Dedicated route program
    DailyResetHour = 6, -- Daily completion boundary in the game server's local timezone (0-23).
    DailyRouteChangeCooldownDays = 7, -- Real days before a player may select another dedicated route.
    DailyRouteCompletionBonus = 3500, -- Extra payout for the first dedicated-route completion in a daily period.
    DailyRouteRepBonus = 2, -- Extra contractor reputation for that daily completion.
    DailyRouteOptionsPerType = 8, -- Maximum configured route choices shown per dedicated vehicle type.
    -- Without a routeIndex, each entry exposes routes from that type's configured priority pool.
    DailyRoutes = {
        { type = 'van', label = 'Package Route', minRank = 5 },
        { type = 'boxtruck', label = 'Crate Route', minRank = 5 },
        { type = 'trailer', label = 'Trailer Route', minRank = 5 }
    },

    -- Vehicle resale
    ResaleBasePercent = 0.80, -- 0.80 = 80 percent of original price before mileage depreciation.
    DepreciationPerMile = 10, -- Currency removed from resale value for each recorded mile.

    -- Fallback only. Per-vehicle contractor pricing is assigned in config/vehicles.lua.
    -- Formula: base + ((vehicle index - 1) * step).
    VehiclePricing = {
        van = { base = 85000, step = 5000 },
        boxtruck = { base = 165000, step = 10000 },
        trailer = { base = 260000, step = 15000 }
    }
}

-- ============================================================================
-- 08. ACTION AND DELIVERY TIMING
-- ============================================================================

-- All progress durations are milliseconds.
Config.Progress = {
    -- Package/crate handling
    collectCargo = 2500,
    loadCargo = 3000,
    verifyLoadedCargo = 2500,
    grabCargo = 2500,
    deliverCargo = 3500,

    -- Trailer handoff and load checklist
    finalizeTrailer = 5000,
    confirmTrailerDrop = 2500,
    confirmTrailerLoad = 3500,
    secureTruckLoad = 3000,
    disconnectTrailer = 3000,
    secureTrailerLoad = 3000,
    completeLoadChecklist = 2500,

    -- Depot vehicle actions
    returnVehicle = 3500,
    spawnGarageVehicle = 2500
}

-- ETA priority: route.estimatedSeconds, then routeLength calculation, then Defaults.
Config.DeliveryTiming = {
    Enabled = true,
    GraceSeconds = 60, -- A route becomes late only after ETA plus this allowance.
    EarlyBonusWindowSeconds = 90, -- Finish at least this many seconds before ETA for the early bonus.
    EarlyBonusPercent = 0.08, -- 0.08 = 8 percent
    LatePenaltyPercent = 0.12, -- 0.12 = 12 percent
    MinimumFinalPayoutPercent = 0.45, -- Final adjusted payout cannot fall below 45 percent of base payout.

    -- Seconds used only when a route has neither estimatedSeconds nor a readable routeLength.
    Defaults = {
        van = { standard = 600, priority = 540, government = 720, military = 780 },
        boxtruck = { standard = 900, priority = 780, government = 1020, military = 1200 },
        trailer = { standard = 900, priority = 1260, government = 1320, military = 1500 }
    },

    -- Used with BaseMinutes to calculate an estimate from routeLength values such as "15.7 mi".
    MinutesPerMile = {
        van = 1.65,
        boxtruck = 1.85,
        trailer = 2.15
    },

    BaseMinutes = { -- Fixed handling time added before the per-mile estimate.
        van = 4,
        boxtruck = 6,
        trailer = 8
    }
}

-- ============================================================================
-- 09. RISK, CONDITION, AND PENALTIES
-- ============================================================================

-- Applies after cargo verification to vans/box trucks, or while an assigned trailer is coupled.
-- Condition starts at 100 and can be reduced by impacts, hard braking, and sustained speeding.
Config.CargoCondition = {
    Enabled = true,
    CheckInterval = 2000, -- Sampling interval used for body health, speed, and braking changes.
    IncidentCooldown = 6000, -- Minimum time between recorded condition incidents.
    HealthDropThreshold = 12.0, -- Minimum body-health loss between samples before an impact is recorded.
    DamageScoreMultiplier = 0.08, -- Cargo-condition points lost per body-health point, with a 2-point minimum.
    HardBrakeMinSpeed = 35.0, -- Previous sampled speed must be at least this many mph.
    HardBrakeDropMph = 28.0, -- Speed loss between samples required to record hard braking.
    HardBrakePenalty = 4, -- Cargo-condition points removed per hard-braking incident.
    SpeedWarningAfter = 9000, -- Continuous overspeed time before condition begins receiving penalties.
    SpeedPenalty = 2, -- Cargo-condition points removed per eligible overspeed incident.
    SafeSpeed = { -- Fallback mph limits; a trailer route's safeSpeed overrides the trailer value.
        van = 75.0,
        boxtruck = 75.0,
        trailer = 70.0
    }
}

-- Trailer-route-only physical failure risk while the assigned tractor remains above safe speed.
Config.SpeedRisk = {
    Enabled = true,
    CheckInterval = 5000, -- Failure roll interval after RiskAfter has elapsed.
    WarningAfter = 10000, -- Continuous overspeed time before the warning is shown.
    RiskAfter = 20000, -- Continuous overspeed time before failure rolls begin.
    DefaultSafeSpeed = 75.0, -- Fallback mph when the active trailer route has no safeSpeed.
    TireBlowoutChance = 3, -- whole percent chance per check after RiskAfter
    EngineFailureChance = 1, -- whole percent chance per check after RiskAfter
    EngineDamageAmount = 120.0, -- Engine health removed after a successful failure roll.
    MinimumEngineHealth = 350.0, -- Speed-risk damage alone will not reduce engine health below this value.
    WarningMessage = 'Dispatch: Cargo stability warning! Reduce speed.'
}

Config.TrailerDamagePenalties = {
    Enabled = true,
    CleanBonusPercent = 0.04, -- 0.04 = 4 percent bonus below CleanThresholdPercent damage
    CleanThresholdPercent = 2.5, -- whole damage percentage
    -- Evaluated from top to bottom; keep the highest damage threshold first.
    Levels = {
        { minDamagePercent = 35.0, penaltyPercent = 0.30, label = 'Heavy trailer damage' },
        { minDamagePercent = 20.0, penaltyPercent = 0.18, label = 'Moderate trailer damage' },
        { minDamagePercent = 8.0, penaltyPercent = 0.08, label = 'Light trailer damage' }
    }
}

Config.CancelPenalty = {
    Enabled = true,
    ReputationLoss = 3, -- Standard job reputation removed; contractor losses are configured separately above.
    -- value is the stable internal reason sent to the server; label is the player-facing menu text.
    Reasons = {
        { value = 'vehicle_damaged', label = 'Vehicle / trailer damaged' },
        { value = 'wrong_vehicle', label = 'Wrong vehicle selected' },
        { value = 'route_issue', label = 'Route issue / blocked destination' },
        { value = 'out_of_time', label = 'Out of time' },
        { value = 'player_choice', label = 'Changed my mind' },
        { value = 'other', label = 'Other' }
    }
}

-- ============================================================================
-- 10. NAVIGATION AND WORLD MARKERS
-- ============================================================================

Config.UseBlip = true -- Shows the permanent dispatch terminal blip; active route blips use Config.Blips.
Config.UseMissionGPSWaypoints = true -- Draws a mission-style GPS route to contract pickup and drop-off blips.

-- GTA blip sprite/color IDs are used throughout this section.
Config.DispatchBlip = {
    coords = vector3(-41.54, -2513.28, 6.16),
    sprite = 477,
    color = 5,
    scale = 0.55,
    label = 'Los Santos Freight Co.'
}

-- On-duty LSFC unit tracking blips.
Config.JobBlips = {
    enabled = true,
    updateInterval = 7500, -- Maximum time between shared unit position updates.
    minMoveDistance = 25.0, -- Movement required to send an earlier position update.
    showSelf = true, -- Includes the local player's LSFC unit blip.
    requireDuty = true, -- Hides players who are not on duty.
    shortRange = true, -- Uses GTA short-range behavior for shared unit blips.
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

Config.Blips = {
    -- Each entry is used for the active destination matching that route stage.
    Pickup = { sprite = 478, color = 2, scale = 0.60 },
    PackageDelivery = { sprite = 478, color = 5, scale = 0.60 },
    CrateDelivery = { sprite = 478, color = 3, scale = 0.60 },
    TrailerDelivery = { sprite = 479, color = 47, scale = 0.60 },
    Receiver = { sprite = 280, color = 5, scale = 0.60 },
    ReturnVehicle = { sprite = 477, color = 5, scale = 0.60 },
    Default = { sprite = 1, color = 5, scale = 0.60 }
}

Config.AreaBlips = {
    Enabled = true, -- Adds minimap radius circles around active trailer pickup/drop areas.
    TrailerPickup = { radius = 55.0, color = 47, alpha = 100 },
    TrailerDrop = { fallbackRadius = 22.0, color = 47, alpha = 100 } -- Route acceptanceRadius overrides fallbackRadius.
}

-- Package/crate delivery ground marker and TextUI interaction.
Config.DropoffTarget = {
    Radius = 3.5, -- Backward-compatible fallback when Distance is omitted.
    Distance = 3.5, -- Player distance at which the delivery prompt becomes actionable.
    MarkerDrawDistance = 55.0,
    MarkerType = 1, -- GTA DrawMarker type ID.
    MarkerSize = 1.35, -- Marker width and depth.
    MarkerHeight = 1.50, -- Marker vertical scale.
    MarkerZOffset = -2.00, -- Vertical adjustment from the configured stop coordinate.
    MarkerAlpha = 145 -- 0 is transparent; 255 is opaque.
}

-- Trailer placement marker. Client tolerance drives marker color; the server independently validates placement.
Config.TrailerDropMarker = {
    Enabled = true,
    DrawDistance = 120.0,
    MarkerType = 1, -- GTA DrawMarker type ID.
    Size = 6.0, -- Overall placement target diameter.
    Height = 0.50, -- Marker vertical scale.
    ZOffset = -0.65, -- Vertical adjustment from the configured trailer drop coordinate.
    PositionTolerance = 1.40, -- Client centered threshold in meters.
    ServerTolerance = 0.75, -- Extra validation allowance added server-side for network position drift.
    MaxSettleSpeed = 0.15, -- Maximum trailer speed in meters/second while settling.
    SettleTime = 2000, -- Time the centered, detached trailer must remain settled.
    Alpha = 115, -- 0 is transparent; 255 is opaque.
    Colors = {
        Outside = { r = 220, g = 55, b = 48 },
        Inside = { r = 242, g = 180, b = 45 },
        Centered = { r = 76, g = 220, b = 105 },
        Detached = { r = 235, g = 240, b = 238 }
    }
}

-- ============================================================================
-- 11. UI, RADIO, AND NOTIFICATIONS
-- ============================================================================

Config.RadioFrequency = '68.9' -- Displayed channel label; this does not join an external voice-radio channel.
Config.ReceiverRefreshInterval = 15000 -- milliseconds between passive receiver/signal refreshes

Config.DispatchHome = {
    -- Add a north-up San Andreas map to /images and set MapImage to its local NUI path.
    -- Markers project GTA world coordinates against MapBounds.
    MapImage = '../images/photos/locations/MapImage.webp',
    -- These GTA world-coordinate edges must match the visible edges of MapImage.
    MapBounds = {
        minX = -6000,
        maxX = 7000,
        minY = -4200,
        maxY = 8800
    },
    MapZoom = 1.0, -- Initial zoom when the dispatch map is opened.
    MapZoomMin = 1.0,
    MapZoomMax = 2.8,
    MapZoomStep = 0.25, -- Amount used by buttons and each mouse-wheel zoom step.
    -- Local NUI paths used by the dispatch home location cards.
    Photos = {
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

Config.RadioMessageAudio = {
    Enabled = true,
    NativeInJobVehicle = true, -- Uses GTA CB-radio sounds while driving the assigned job vehicle.
    DriverOnly = true, -- Suppresses normal radio audio for passengers.
    StartSound = 'Start_Squelch', -- GTA frontend sound name, not a file in html/sounds.
    EndSound = 'End_Squelch', -- GTA frontend sound name, not a file in html/sounds.
    SoundSet = 'CB_RADIO_SFX', -- GTA audio reference used by StartSound and EndSound.
    EndDelay = 575, -- Delay between the start and end static sounds.
    Cooldown = 225 -- Minimum spacing between separate radio audio sequences.
}

Config.UI = {
    Sounds = true,
    SoundVolume = 0.18, -- NUI sound volume on a 0.0-1.0 scale.
    SoundsPath = 'sounds/', -- Path relative to html/index.html; keep the trailing slash.
    MiniLogo = 'images/badger-logo.webp', -- Local NUI path relative to the html folder.
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
    Enabled = true, -- Controls visual ox_lib notifications; receiver/dock radio messages are unaffected.
    Title = 'Los Santos Freight Co.',
    Duration = 8500, -- milliseconds
    Sounds = false, -- Notification-specific sounds; independent from Config.UI.Sounds.
    -- Maps notification types to logical Config.UI sound names such as alert or confirm.
    SoundMap = {
        error = 'alert',
        warning = 'confirm',
        success = 'confirm'
    }
}

-- ============================================================================
-- 12. SECURITY AND VALIDATION
-- ============================================================================

Config.Security = {
    ServerDistanceChecks = true, -- Keep enabled in production; validates sensitive actions against player position.
    ValidateConfig = true, -- Checks required coordinates, route references, and common setup errors on startup.
    PrintStartupSummary = true, -- Prints detected framework/provider and configuration status once on startup.
    AdminAces = { 'ls_trucking.admin', 'ls_trucking.debug' }, -- Framework permissions and common admin ACEs are checked first.
    MaxSavedPropsLength = 24000, -- Maximum serialized vehicle-properties payload accepted from a client.

    -- Milliseconds between accepted server requests from the same player.
    Cooldowns = {
        Dispatch = 500,
        Contract = 2000,
        Cargo = 750,
        Trailer = 1000,
        ReturnVehicle = 2000,
        CompleteRoute = 2000,
        Cancel = 1500
    },

    -- Maximum server-authorized distance in meters. These do not change marker or TextUI draw distances.
    -- Depot.requestRadius takes precedence for depot vehicle/contract request callbacks.
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

-- ============================================================================
-- 13. VERSION CHECKING
-- ============================================================================

Config.VersionCheck = {
    Enabled = true,
    -- GitHubRawVersionUrl reads the resource version plus optional download/changelog fields.
    GitHubRawVersionUrl = 'https://raw.githubusercontent.com/DrSnyder86/ls_trucking/main/version.json', -- version.json or plain-text version
    -- The same version.json may serve these URLs when it contains config, contract, and vehicle config versions.
    ConfigRawVersionUrl = 'https://raw.githubusercontent.com/DrSnyder86/ls_trucking/main/version.json',
    ContractsRawVersionUrl = 'https://raw.githubusercontent.com/DrSnyder86/ls_trucking/main/version.json',
    VehicleConfigRawVersionUrl = 'https://raw.githubusercontent.com/DrSnyder86/ls_trucking/main/version.json',
    PrintUpToDate = true, -- False suppresses successful current-version messages, but not warnings or errors.
    CheckDelay = 5000 -- Delay after resource start before HTTP version checks begin.
}
