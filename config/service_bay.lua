Config = Config or {}

Config.ServiceBay = {
    Enabled = true,
    coords = vector3(-169.13, -2462.35, 6.4),
    radius = 4.5,
    drawDistance = 65.0,
    Command = 'lsservice',
    Text = '[E] Open LSFC Service Bay',
    RequireJob = true,
    Marker = {
        type = 1,
        zOffset = -0.95,
        size = vector3(6.0, 6.0, 0.24),
        color = { r = 245, g = 190, b = 40, a = 110 }
    },
    Blip = {
        enabled = true,
        sprite = 446,
        color = 5,
        scale = 0.55,
        label = 'LSFC Service Bay'
    },
    RepDiscount = {
        Enabled = true,
        IncludeContractorRep = true,
        PointsPerPercent = 12,
        MaxPercent = 35
    },
    InstallProgress = {
        service = 1300,
        upgrade = 1200,
        appearance = 900,
        sound = 'impact'
    },
    Prices = {
        Service = {
            drivetrain = 200,
            body = 200,
            full = 400
        },
        Upgrades = {
            engine = { base = 5000, step = 4500 },
            transmission = { base = 4000, step = 3800 },
            brakes = { base = 3000, step = 2600 },
            suspension = { base = 2000, step = 2200 },
            armor = { base = 10000, step = 5200 },
            turbo = 16000,
            tires = 6500
        },
        Appearance = {
            livery = 100,
            extra = 100
        }
    },
    TurboStages = {
        {
            level = 1,
            label = 'Stage 1 Turbo',
            price = 16000,
            power = 0.50,
            torque = 0.70,
            description = 'Turbo kit with ECU/TCU tuning.'
        },
        {
            level = 2,
            label = 'Stage 2 Turbo',
            price = 24000,
            power = 0.70,
            torque = 0.90,
            description = 'Large billet compressor wheels and upgraded bearings.'
        },
        {
            level = 3,
            label = 'Stage 3 Turbo',
            price = 34000,
            power = 1.00,
            torque = 1.20,
            description = 'High performance air-water intercooler kit.'
        }
    },
    Descriptions = {
        service = {
            drivetrain = 'Full drivetrain repair.',
            body = 'Full body repair.',
            full = 'Drivetrain and body repair with service log update.'
        },
        engine = {
            'Performance ignition timing.',
            'High pressure fuel system.',
            'Full throttle mapping.',
            'Forged pistons & rods.'
        },
        transmission = {
            'Performance tune calibration.',
            'Optimized shift points.',
            'High performance torque converter.',
            'High-pressure calibration.'
        },
        brakes = {
            'High pressure brake system.',
            'Six piston calipers.',
            'Ceramic brake pads.',
            'Carbon ceramic slotted & drilled rotors.'
        },
        suspension = {
            'Street suspension kit.',
            'Pro suspension kit.',
            'Race suspension kit.',
            'Lowered suspension kit.'
        },
        armor = {
            'Underbody skid plates and panel bracing.',
            'Door and bumper reinforcement.',
            'Chassis bracing and impact zones.',
            'Full armor plating and structural support.'
        },
        turbo = {
            'Turbo kit with ECU/TCU tuning.',
            'Large billet compressor wheels and upgraded bearings.',
            'High performance air-water intercooler kit.'
        },
        tires = '10-ply commercial run-flats.'
    }
}
Config.Security = Config.Security or {}
Config.Security.Cooldowns = Config.Security.Cooldowns or {}
Config.Security.DistanceChecks = Config.Security.DistanceChecks or {}
Config.Security.Cooldowns.ServiceBay = tonumber(Config.ServiceBay.SecurityCooldown) or 1500
Config.Security.DistanceChecks.ServiceBay = tonumber(Config.ServiceBay.SecurityDistance) or 16.0
