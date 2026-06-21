-- Cargo, inventory items, and manifest settings
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
