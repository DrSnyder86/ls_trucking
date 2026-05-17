Config.ContractsVersion = '1.0.0'

Config.Contracts = {
    van = {
        label = 'Van Deliveries',
        description = 'Deliver packages in a cargo van on a planned local route.',
        cargo = 'Packages',
        difficulty = 'Easy',
        cardColor = '#e6ab00',
        tags = { 'Postal Service', 'Local Stops', 'Multi Drop' },
        businesses = { 'PostOP Express', 'Go Postal', 'QuickShip Couriers' },
        requiredCargo = 4,
        pickupPed = { label = 'Go Postal Warehouse Clerk', model = `s_m_m_postal_01`, coords = vector4(125.12, 98.36, 81.84, 157.28), scenario = 'WORLD_HUMAN_CLIPBOARD' },
        pickup = { label = 'Go Postal Sorting Center', coords = vector3(125.12, 98.36, 81.84) },
        routes = {
            { label = 'East Los Santos Parcel Route', routeLength = '3.0 mi', dropoffs = {
                { label = 'Digital Den - La Mesa', coords = vector3(392.476837, -831.473450, 29.343481), unload = 1 },
                { label = 'Ammu-Nation - Legion', coords = vector3(15.732404, -1114.611694, 29.917459), unload = 1 },
                { label = 'LTD Gasoline - Davis', coords = vector3(-40.582649, -1750.794312, 28.974571), unload = 1 },
                { label = 'Binco - Strawberry Ave', coords = vector3(70.733727, -1390.371216, 29.333855), unload = 1 }
            } },
            { label = 'West Side Business Route', routeLength = '3.0 mi', dropoffs = {
                { label = 'Suburban - Del Perro', coords = vector3(-1198.147583, -775.407654, 17.291162), unload = 1 },
                { label = 'Binco - South Rockford', coords = vector3(-822.338501, -1072.938477, 11.275532), unload = 1 },
                { label = 'Robs Liquor - Vespucci', coords = vector3(-1222.418701, -913.285583, 12.190260), unload = 1 },
                { label = 'Bean Machine - Eclipse', coords = vector3(-634.836365, 209.479980, 74.128387), unload = 1 }
            } },
            { label = 'Vinewood Express Route', routeLength = '3.0 mi', dropoffs = {
                { label = 'Vinewood Tattoo', coords = vector3(319.730133, 183.169907, 103.435867), unload = 1 },
                { label = 'Up-n-Atom - Vinewood', coords = vector3(81.606529, 275.403595, 110.225998), unload = 1 },
                { label = 'Luxury Autos - Rockford', coords = vector3(-777.058655, -243.877350, 37.230682), unload = 1 },
                { label = 'Bean Machine - Eclipse', coords = vector3(-627.196533, 239.042496, 81.962952), unload = 1 }
            } },
            { label = 'Southside Local Stops', routeLength = '3.0 mi', dropoffs = {
                { label = 'LTD Gasoline - Grove', coords = vector3(-40.538353, -1750.916016, 29.373398), unload = 1 },
                { label = '24/7 Market - Innocence', coords = vector3(27.731812, -1349.405029, 29.342958), unload = 1 },
                { label = 'Ammu-Nation - Vespucci Blvd', coords = vector3(845.259888, -1029.429443, 28.194813), unload = 1 },
                { label = 'Robs Liquor - El Rancho', coords = vector3(1129.896240, -979.913452, 46.386639), unload = 1 }
            } },
            { label = 'Sandy Shores Rural Mail Route', routeLength = '5.2 mi', dropoffs = {
                { label = 'Sandy 24/7 Market', coords = vector3(1963.950317, 3739.766846, 32.369686), unload = 1 },
                { label = 'Yellow Jack Inn', coords = vector3(1989.510620, 3054.332520, 47.426117), unload = 1 },
                { label = 'Sandy Medical Clinic', coords = vector3(1816.228760, 3678.325684, 34.442177), unload = 1 },
                { label = "Sandy Airfield Office", coords = vector3(1759.603027, 3299.130371, 41.179695), unload = 1 }
            } },
            { label = 'Grapeseed Farm Deliveries', routeLength = '6.4 mi', dropoffs = {
                { label = "Millar's Fishery Grapeseed", coords = vector3(1696.619263, 3595.322021, 35.631393), unload = 1 },
                { label = 'Grapeseed Binco', coords = vector3(1699.010864, 4820.926270, 42.040264), unload = 1 },
                { label = 'Grapeseed LTD', coords = vector3(1703.011353, 4917.499023, 42.135468), unload = 1 },
                { label = "O'Neil Farm Supply", coords = vector3(2485.357910, 4954.426758, 45.203793), unload = 1 },              
            } },
            { label = 'Chumash Coastal Parcel Route', routeLength = '4.8 mi', dropoffs = {
                { label = 'Chumash 24/7', coords = vector3(-3240.021484, 1003.000000, 12.533175), unload = 1 },
                { label = 'Ammu-Nation - Chumash', coords = vector3(-3169.297363, 1083.295044, 20.838696), unload = 1 },
                { label = 'Pacific Bluffs Country Club', coords = vector3(-3024.722900, 79.809143, 11.736604), unload = 1 },
                { label = 'Banham Canyon Mail Drop', coords = vector3(-2720.989746, 1502.013184, 106.600357), unload = 1 }
            } },
            { label = 'Paleto Postal Run', routeLength = '10.5 mi', dropoffs = {
                { label = 'Blaine Co. Savings & Loans', coords = vector3(-109.315414, 6468.653809, 31.683596), unload = 1 },
                { label = 'Paleto Bay Fire Station', coords = vector3(-381.099640, 6116.862305, 31.610924), unload = 1 },
                { label = 'Paleto Auto Services', coords = vector3(119.166046, 6626.976562, 32.150269), unload = 1 },
                { label = 'Clucking Bell Farms Office', coords = vector3(-69.835938, 6253.328613, 31.175774), unload = 1 }
            } },
            { label = 'Route 68 Express Parcel Run', routeLength = '5.2 mi', dropoffs = {
                { label = 'Harmony Motel Office', coords = vector3(1142.615723, 2663.962646, 38.374855), unload = 1 },
                { label = 'Larrys RV Sales Office', coords = vector3(1224.730835, 2728.893066, 38.079941), unload = 1 },
                { label = 'Yellow Jack Hotel #1', coords = vector3(1980.862427, 3049.828857, 50.577446), unload = 1 },
                { label = 'Sandy Shores Airfield Maintenance', coords = vector3(1716.094116, 3295.402100, 41.104122), unload = 1 }
            } }
        }
    },
    boxtruck = {
        label = 'Box Truck Deliveries',
        description = 'Load crates from a warehouse and restock stores along a planned route.',
        cargo = 'Crates',
        difficulty = 'Medium',
        cardColor = '#3f8cff',
        tags = { 'Warehouse Supply', 'Store Restock', 'Crates' },
        businesses = { 'Depot Distribution', 'Redwood Retail', 'Binco Central' },
        requiredCargo = 6,
        pickupPed = { label = 'PostOps Freight Coordinator', model = `s_m_m_dockwork_01`, coords = vector4(-433.43, -2788.9, 6.0, 19.06), scenario = 'WORLD_HUMAN_CLIPBOARD' },
        pickup = { label = 'PostOps Freight Warehouse', coords = vector3(-433.43, -2788.9, 6.0) },
        routes = {
            { label = 'East City Store Restock', dropoffs = {
                { label = 'Binco - Textile Drop', coords = vector3(430.506104, -809.204529, 28.965164), unload = 2 },
                { label = 'LTD Gasoline - Mirror Park', coords = vector3(1163.514404, -313.286804, 68.942574), unload = 2 },
                { label = '24/7 Supermarket - Clinton Ave', coords = vector3(373.270325, 341.260101, 103.126053), unload = 2 }
            } },
            { label = 'Restaurant Supply Route', dropoffs = {
                { label = 'Burger Shot - Vespucci', coords = vector3(-1200.367188, -886.022217, 13.441433), unload = 2 },
                { label = 'Snr. Buns - Little Seoul', coords = vector3(-519.964478, -678.224915, 33.738033), unload = 2 },
                { label = 'Up-n-Atom - Vinewood', coords = vector3(90.507431, 297.611938, 110.194550), unload = 2 }
            } },
            { label = 'Downtown Retail Restock', dropoffs = {
                { label = 'Ammu-Nation - Legion', coords = vector3(-6.116421, -1106.383179, 29.203417), unload = 2 },
                { label = 'Digital Den - Mission Row', coords = vector3(372.771362, -827.044495, 29.230076), unload = 2 },
                { label = 'Suburban - Hawick Ave', coords = vector3(118.746887, -237.937347, 53.364349), unload = 2 }
            } },
            { label = 'West Coast Retail Run', dropoffs = {
                { label = 'Binco - Vespucci', coords = vector3(-833.222717, -1071.921997, 11.444455), unload = 2 },
                { label = 'Robs Liquor - Vespucci', coords = vector3(-1217.732910, -916.098694, 11.390692), unload = 2 },
                { label = 'LTD Gasoline - Richman', coords = vector3(-1828.923340, 800.790527, 138.573669), unload = 2 }
            } },
            { label = 'Route 68 County Restock', routeLength = '5.7 mi', dropoffs = {
                { label = 'Harmony 24/7 Loading Door', coords = vector3(543.718994, 2658.850342, 42.102001), unload = 2 },
                { label = 'Route 68 Store', coords = vector3(1201.793335, 2654.055176, 37.884415), unload = 2 },
                { label = "Rex's Diner Supply", coords = vector3(2549.273193, 2581.908203, 37.971207), unload = 2 }
            } },
            { label = 'Paleto Bay Store Supply', routeLength = '10.6 mi', dropoffs = {
                { label = 'Paleto Auto Parts', coords = vector3(119.113647, 6626.925293, 32.064049), unload = 2 },
                { label = 'Bay Hardware Storage', coords = vector3(-5.577757, 6490.679199, 31.448158), unload = 2 },
                { label = 'Paleto Liguor Supply Door', coords = vector3(-394.661102, 6074.418457, 31.378326), unload = 2 }
            } },
            { label = 'Chumash Retail Supply', routeLength = '4.9 mi', dropoffs = {
                { label = 'Chumash 24/7 Loading Area', coords = vector3(-3253.682617, 999.057007, 12.385384), unload = 2 },
                { label = 'Chumash Hardware Supply', coords = vector3(-3159.655518, 1045.136108, 20.864847), unload = 2 },
                { label = 'Pacific Bluffs Country Club', coords = vector3(-2953.308105, 48.857761, 11.574520), unload = 2 }
            } },
            { label = 'Grapeseed Wholesale Restock', routeLength = '6.4 mi', dropoffs = {
                { label = 'Wonderama Arcade', coords = vector3(1710.514282, 4760.571289, 42.143238), unload = 2 },
                { label = 'Shady Tree Farm Supply', coords = vector3(2565.827148, 4673.510742, 33.923622), unload = 2 },
                { label = "Millar's Boat Shop Supply", coords = vector3(1334.238892, 4306.925293, 38.219261), unload = 2 }
            } },
            { label = 'Mount Chiliad Lodge Freight', routeLength = '10.8 mi', dropoffs = {
                { label = 'Bayview Lodge', coords = vector3(-679.586487,5800.853027,17.381531), unload = 2 },
                { label = 'Pala Springs Bike Rentals', coords = vector3(-768.633606, 5597.558105, 33.540520), unload = 2 },               
                { label = 'Paleto Lumber Storage', coords = vector3(-589.302185, 5348.634277, 70.231682), unload = 2 }
            } }
        }
    },
    trailer = {
        label = 'Trailer Hauling',
        description = 'Hook a trailer at the docks, drop it in the receiving yard, then finalize with the receiver.',
        cargo = 'Trailer',
        difficulty = 'Hard',
        cardColor = '#a263ff',
        tags = { 'Large Freight', 'Long Haul', 'Receiver Signoff' },
        businesses = { 'Jetsam Freight', 'Global Freight Co.', 'Bluewater Logistics' },
        requiredCargo = 1,
        pickup = { label = 'Docks Transfer Depot', coords = vector3(1244.30, -3184.92, 5.90) },
        routes = {
            { label = 'Cypress Flats Freight Yard', pickupDepot = 'harmony', trailerKey = 'dryvan', trailerContents = 'General freight pallets', routeLength = '5.6 mi', trailerDrop = { label = 'Cypress Flats Receiving Yard', coords = vector3(1015.51, -2508.01, 28.3), radius = 22.0 }, receiverPed = { label = 'Warehouse Receiver', model = `s_m_m_gaffer_01`, coords = vector4(1018.49, -2510.06, 28.48, 87.09), scenario = 'WORLD_HUMAN_CLIPBOARD' } },
            { label = 'Sandy Shores Trailer Parking', pickupDepot = 'lsport', trailerKey = 'freight', trailerContents = 'Blaine County store supplies', routeLength = '5.6 mi', trailerDrop = { label = 'Sandy Shores Supply Yard', coords = vector3(1795.56, 3405.71, 40.62), radius = 22.0 }, receiverPed = { label = 'Blaine County Receiver', model = `s_m_m_gaffer_01`, coords = vector4(1798.6, 3412.85, 40.34, 105.0), scenario = 'WORLD_HUMAN_CLIPBOARD' } },
            { label = 'Paleto Freight Storage', pickupDepot = 'harmony', trailerKey = 'long', trailerContents = 'Industrial equipment pallets', routeLength = '7.6 mi', trailerDrop = { label = 'Paleto Freight Warehouse', coords = vector3(3.46, 6442.08, 31.43), radius = 18.0 }, receiverPed = { label = 'Paleto Warehouse Supervisor', model = `s_m_m_gaffer_01`, coords = vector4(5.25, 6444.4, 31.43, 141.15), scenario = 'WORLD_HUMAN_CLIPBOARD' } },
            { label = 'Palmer-Taylor Supply Delivery', pickupDepot = 'lsport', trailerKey = 'freight', trailerContents = 'Facility Maintenance Equipment', routeLength = '7.6 mi', trailerDrop = { label = 'Station Equipment Storage', coords = vector3(2672.57, 1428.12, 24.50), radius = 18.0 }, receiverPed = { label = 'Maintenance Supervisor', model = `s_m_m_gaffer_01`, coords = vector4(2668.74, 1436.49, 24.5, 279.31), scenario = 'WORLD_HUMAN_CLIPBOARD' } },
            { label = 'RON Fuel Depot Transfer', pickupDepot = 'docks', trailerKey = 'tanker', trailerContents = 'Offroad-Diesel fuel', routeLength = '7.6 mi', trailerDrop = { label = 'Alamo Sea Depot', coords = vector3(335.37, 3407.26, 36.71), radius = 18.0 }, receiverPed = { label = 'Alamo Sea Depot Receiver', model = `s_m_m_gaffer_01`, coords = vector4(345.07, 3405.47, 36.48, 18.17), scenario = 'WORLD_HUMAN_CLIPBOARD' } },
            { label = 'Port Container Yard Transfer', pickupDepot = 'docks', trailerKey = 'container', trailerContents = 'Sealed shipping container', routeLength = '1.8 mi', trailerDrop = { label = 'Elysian Island Container Yard', coords = vector3(849.73, -3219.17, 5.90), radius = 18.0 }, receiverPed = { label = 'Container Yard Clerk', model = `s_m_m_dockwork_01`, coords = vector4(857.73, -3204.24, 5.99, 177.18), scenario = 'WORLD_HUMAN_CLIPBOARD' } },
            { label = 'Harmony Flatbed Equipment Haul', pickupDepot = 'lsport', trailerKey = 'flatbed', trailerContents = 'Secured construction equipment', routeLength = '5.9 mi', trailerDrop = { label = 'Harmony Equipment Yard', coords = vector3(568.37, 2805.77, 42.05), radius = 18.0 }, receiverPed = { label = 'Equipment Yard Receiver', model = `s_m_m_gaffer_01`, coords = vector4(570.52, 2795.26, 42.03, 299.54), scenario = 'WORLD_HUMAN_CLIPBOARD' } },
            { label = 'Paleto Logging Delivery', pickupDepot = 'harmony', trailerKey = 'logs', trailerContents = 'Timber logs', routeLength = '7.6 mi', trailerDrop = { label = 'Paleto Lumber Mill', coords = vector3(-562.61, 5350.38, 70.21), radius = 22.0 }, receiverPed = { label = 'Lumber Mill Receiver', model = `s_m_m_lathandy_01`, coords = vector4(-562.61, 5350.38, 70.21, 66.83), scenario = 'WORLD_HUMAN_CLIPBOARD' } },
            { label = 'Vinewood Event Equipment Delivery', pickupDepot = 'lsport', trailerKey = 'tv', trailerContents = 'Event lighting and broadcast equipment', routeLength = '4.7 mi', trailerDrop = { label = 'Vinewood Bowl Event Center', coords = vector3(644.21, 598.84, 128.91), radius = 18.0 }, receiverPed = { label = 'Event Logistics Manager', model = `s_m_m_highsec_01`, coords = vector4(658.29, 591.47, 129.05, 65.23), scenario = 'WORLD_HUMAN_CLIPBOARD' } },
        }
    }
}


-- Rank-gated priority load options. Players can choose these in the dispatch UI.
-- payoutMultiplier/xpMultiplier modify the base Config.Payouts for the delivery type.
Config.PriorityLoads = {
    van = {
        standard = {
            order = 1,
            label = 'Standard Commercial Route',
            shortLabel = 'Standard',
            minRank = 1,
            payoutMultiplier = 1.0,
            xpMultiplier = 1.0,
            repBonus = 0,
            description = 'Regular business parcel route.',
            badge = 'LOCAL',
            cargoTypes = { 'standard_package', 'standard_package2', 'standard_package3', 'standard_package4', 'gift_package' }
        },
        priority = {
            order = 2,
            label = 'Priority Same-Day Parcels',
            shortLabel = 'Priority',
            minRank = 2,
            payoutMultiplier = 1.25,
            xpMultiplier = 1.15,
            repBonus = 1,
            description = 'Fast same-day parcels with a tighter route.',
            badge = 'PRIORITY',
            cargoTypes = { 'standard_package', 'standard_package2', 'standard_package3', 'standard_package4', 'gift_package' },
            routes = {
                { label = 'Downtown Priority Parcel Route', routeLength = '3.0 mi', dropoffs = {
                    { label = 'Lifeinvader Offices', coords = vector3(-1082.382568, -247.148697, 37.812641), unload = 1 },
                    { label = 'Arcadius Business Center', coords = vector3(-117.141243, -603.058411, 36.527893), unload = 1 },
                    { label = 'Maze Bank Tower', coords = vector3(-66.820435, -802.914795, 44.362087), unload = 1 },
                    { label = 'Union Depository Lobby', coords = vector3(3.204726, -706.294312, 46.131504), unload = 1 }
                } },
                { label = 'Vinewood Priority Courier', routeLength = '3.0 mi', dropoffs = {
                    { label = 'Richards Majestic Studio', coords = vector3(-1010.730103, -479.614563, 40.157387), unload = 1 },
                    { label = 'Weazel News Studio', coords = vector3(-597.951050, -931.943665, 23.911154), unload = 1 },
                    { label = 'Doppler Cinema', coords = vector3(340.426056, 179.672760, 103.237465), unload = 1 },
                    { label = 'Tequi-la-la', coords = vector3(-564.312683, 278.726105, 83.148193), unload = 1 }
                } },
                { label = 'Airport Same-Day Courier', routeLength = '2.5 mi', dropoffs = {
                    { label = 'LSIA Cargo Office', coords = vector3(-1018.326782, -2864.335938, 14.254752), unload = 1 },
                    { label = 'Jetsam Security Desk', coords = vector3(-744.552124, -2553.236328, 13.836541), unload = 1 },
                    { label = 'LSIA FD', coords = vector3(-1035.773315, -2383.272461, 14.015807), unload = 1 },
                    { label = 'Flight School Office', coords = vector3(-1154.705078, -2713.552002, 20.034019), unload = 1 }
                } },
                { label = 'County Priority Parcel Route', routeLength = '6.9 mi', dropoffs = {
                    { label = 'Harmony Motel Office', coords = vector3(1142.615723, 2663.737061, 38.216003), unload = 1 },
                    { label = 'Sandy Sheriff Admin', coords = vector3(1855.996460, 3683.904053, 34.351368), unload = 1 },
                    { label = 'Sandy Medical Front Desk', coords = vector3(1816.155151, 3678.282959, 34.365837), unload = 1 },
                    { label = 'Grapeseed Binco', coords = vector3(1698.882446, 4820.912598, 42.169758), unload = 1 }
                } }
            }
        },
        government = {
            order = 3,
            label = 'Government Courier Contract',
            shortLabel = 'Government',
            minRank = 4,
            payoutMultiplier = 1.75,
            xpMultiplier = 1.45,
            repBonus = 3,
            description = 'Secure paperwork and office supply deliveries for city departments.',
            badge = 'GOV',
            cargoTypes = { 'secure_crate', 'ammo_crate' },
            routes = {
                { label = 'Los Santos Government Courier', routeLength = '3.0 mi', dropoffs = {
                    { label = 'City Hall Mailroom', coords = vector3(-534.144531, -166.800995, 38.4543002), unload = 1 },
                    { label = 'Mission Row Records', coords = vector3(488.121948, -1002.276489, 27.838045), unload = 1 },
                    { label = 'Pillbox Medical Admin', coords = vector3(357.506439, -589.356323, 28.947571), unload = 1 },
                    { label = 'Court Records Annex', coords = vector3(243.351288, -1074.570801, 29.339186), unload = 1 }
                } },
                { label = 'State Agency Document Run', routeLength = '5.1 mi', dropoffs = {
                    { label = 'Davis Sheriff Office', coords = vector3(361.404785, -1585.010620, 29.308186), unload = 1 },
                    { label = 'Los Santos City Hall', coords = vector3(-516.324097, -210.748230, 38.412117), unload = 1 },
                    { label = 'Vinewood PD', coords = vector3(637.892700,1.859410,83.005905), unload = 1 },
                    { label = 'NOOSE Records Desk', coords = vector3(2475.255371, -384.120544, 94.636337), unload = 1 },
                } },
                { label = 'Blaine County Agency Courier', routeLength = '12.6 mi', dropoffs = {
                    { label = 'Senora Road Notary Office', coords = vector3(803.418884, 2176.086426, 52.604275), unload = 1 },
                    { label = 'Sandy Shores Sheriff', coords = vector3(1855.996460, 3683.904053, 34.351368), unload = 1 },
                    { label = 'Mount Chiliad Ranger Station', coords = vector3(-1490.077759, 4981.378906, 63.515480), unload = 1 },
                    { label = 'SAFD Station 1', coords = vector3(-379.123016, 6117.844238, 31.911854), unload = 1 },
                } }
            }
        }
    },

    boxtruck = {
        standard = {
            order = 1,
            label = 'Standard Freight Restock',
            shortLabel = 'Standard',
            minRank = 1,
            payoutMultiplier = 1.0,
            xpMultiplier = 1.0,
            repBonus = 0,
            description = 'Regular store restock freight.',
            badge = 'FREIGHT',
            cargoTypes = { 'freight_crate', 'ammo_crate' }
        },
        priority = {
            order = 2,
            label = 'Priority Warehouse Freight',
            shortLabel = 'Priority',
            minRank = 3,
            payoutMultiplier = 1.35,
            xpMultiplier = 1.25,
            repBonus = 2,
            description = 'Time-sensitive crates for major businesses.',
            badge = 'PRIORITY',
            cargoTypes = { 'freight_crate', 'ammo_crate' },
            routes = {
                { label = 'Business District Restock', routeLength = '3.0 mi', dropoffs = {
                    { label = 'Arcadius Receiver', coords = vector3(-195.910034, -571.435486, 34.683182), unload = 2 },
                    { label = 'Maze Bank Receiving', coords = vector3(-132.772385, -814.108826, 31.920395), unload = 2 },
                    { label = 'Union Depository Service Door', coords = vector3(37.690437, -692.746704, 31.938002), unload = 2 }
                } },
                { label = 'Airport Freight Express', routeLength = '2.5 mi', dropoffs = {
                    { label = 'LSIA Cargo Gate A', coords = vector3(-1013.866821, -2856.611084, 14.165094), unload = 2 },
                    { label = 'LSIA Hangar Office', coords = vector3(-1277.512817, -3428.684814, 13.949889), unload = 2 },
                    { label = 'Pegasus Maintenance Hangar', coords = vector3(-1636.761353, -3181.685547, 13.843104), unload = 2 }
                } },
                { label = 'Port Priority Freight Run', routeLength = '2.5 mi', dropoffs = {
                    { label = 'Jetsam Terminal Dock Office', coords = vector3(798.338257, -2988.722656, 6.075550), unload = 2 },
                    { label = 'Bilgeco Receiving Bay', coords = vector3(1209.085205, -3113.625488, 5.582935), unload = 2 },
                    { label = 'Bilgeco Maintenance Shed', coords = vector3(865.694458, -3203.170166, 5.967897), unload = 2 }
                } },
                { label = 'Blaine County Priority Freight', routeLength = '6.8 mi', dropoffs = {
                    { label = 'Harmony Utility Yard', coords = vector3(620.832764, 2800.335938, 42.053699), unload = 2 },
                    { label = 'Sandy Airfield Storage', coords = vector3(1744.324097,3307.367676,40.873077), unload = 2 },
                    { label = 'Grapeseed Farm Co-op', coords = vector3(1711.750854, 4742.249512, 41.963402), unload = 2 }
                } }
            }
        },
        government = {
            order = 3,
            label = 'Government Supply Contract',
            shortLabel = 'Government',
            minRank = 4,
            payoutMultiplier = 1.85,
            xpMultiplier = 1.55,
            repBonus = 4,
            description = 'Bulk supply crates for public agencies.',
            badge = 'GOV',
            cargoTypes = { 'secure_crate', 'ammo_crate' },
            routes = {
                { label = 'Emergency Services Supply Run', routeLength = '3.0 mi', dropoffs = {
                    { label = 'Mission Row Supply Drop', coords = vector3(459.568420, -1008.031555, 28.227655), unload = 2 },
                    { label = 'Pillbox Medical Loading Area', coords = vector3(320.198120, -560.238525, 28.760803), unload = 2 },
                    { label = 'Davis Fire Station', coords = vector3(209.304260, -1669.928955, 29.636614), unload = 2 }
                } },
                { label = 'NOOSE Equipment Transfer', routeLength = '5.6 mi', dropoffs = {
                    { label = 'NOOSE Receiving Bay', coords = vector3(2521.779541, -453.282776, 92.849403), unload = 2 },
                    { label = 'Palmer-Taylor Utility Yard', coords = vector3(2669.925293, 1600.757568, 24.437483), unload = 2 },
                    { label = 'Sandy Shores Sheriff', coords = vector3(1854.643677, 3683.134033, 34.463627), unload = 2 }
                } },
                { label = 'County Public Works Freight', routeLength = '14.4 mi', dropoffs = {
                    { label = 'Los Santos Public Works Depot', coords = vector3(835.290100, -3203.170410, 5.951118), unload = 2 },
                    { label = 'Senora Road Municipal', coords = vector3(862.084351, 2175.836182, 52.271679), unload = 2 },
                    { label = 'Paleto Medical Supplies', coords = vector3(-261.819244, 6309.516113, 32.267597), unload = 2 }
                } }
            }
        },
        military = {
            order = 4,
            label = 'Military Supply Contract',
            shortLabel = 'Military',
            minRank = 5,
            payoutMultiplier = 2.35,
            xpMultiplier = 1.85,
            repBonus = 6,
            description = 'Restricted supply crates routed to military facilities.',
            badge = 'MIL',
            cargoTypes = { 'military_crate', 'military_crate2', 'ammo_crate' },
            routes = {
                { label = 'Fort Zancudo Supply Route', routeLength = '7.2 mi', dropoffs = {
                    { label = 'LS Naval Port Supply', coords = vector3(454.222656, -3079.377441, 5.984760), unload = 2 },
                    { label = 'Zancudo Security Supply', coords = vector3(-2304.446289, 3426.871338, 30.986799), unload = 2 },
                    { label = 'Zancudo Motor Pool Service Area', coords = vector3(-1797.071167, 3102.808350, 32.783108), unload = 2 }
                } },
                { label = 'Military Coastline Supply Run', routeLength = '7.8 mi', dropoffs = {
                    { label = 'Jetsam Terminal Security Office', coords = vector3(805.617310, -2950.686523, 6.012570), unload = 2 },
                    { label = 'Zancudo Tower 2', coords = vector3(-2408.977539, 3266.585205, 32.936138), unload = 2 },
                    { label = 'Zancudo Airbase Main Hanger', coords = vector3(-1778.399536, 2994.600830, 32.400108), unload = 2 }
                } }
            }
        }
    },

    trailer = {
        standard = {
            order = 1,
            label = 'Standard Trailer Haul',
            shortLabel = 'Standard',
            minRank = 1,
            payoutMultiplier = 1.0,
            xpMultiplier = 1.0,
            repBonus = 0,
            description = 'Regular freight trailer delivery.',
            badge = 'TRAILER',
            defaultTrailerKey = 'dryvan'
        },
        priority = {
            order = 2,
            label = 'Priority Long Haul',
            shortLabel = 'Priority',
            minRank = 3,
            payoutMultiplier = 1.4,
            xpMultiplier = 1.3,
            repBonus = 2,
            description = 'Longer-haul trailer deliveries with better payout.',
            badge = 'LONG HAUL',
            defaultTrailerKey = 'long',
            routes = {
                { label = 'Los Santos to Sandy Shores Airfield', pickupDepot = 'docks', trailerKey = 'freight', trailerContents = 'Retail freight pallets', routeLength = '5.7 mi', trailerDrop = { label = 'Sandy Shores Airfield', coords = vector3(1736.04, 3320.45, 41.22), radius = 18.0 }, receiverPed = { label = 'Sandy Airfield Receiver', model = `s_m_m_gaffer_01`, coords = vector4(1747.79, 3296.52, 41.15, 154.86), scenario = 'WORLD_HUMAN_CLIPBOARD' } },
                { label = 'Los Santos to Paleto Industrial', pickupDepot = 'lsport', trailerKey = 'long', trailerContents = 'Long-haul industrial freight', routeLength = '12.9 mi', trailerDrop = { label = 'Paleto Freight Yard', coords = vector3(60.72, 6468.4, 31.42), radius = 18.0 }, receiverPed = { label = 'Paleto Yard Manager', model = `s_m_m_gaffer_01`, coords = vector4(59.98, 6477.41, 31.43, 253.3), scenario = 'WORLD_HUMAN_CLIPBOARD' } },
                { label = 'Docks to Grapeseed Co-op Transfer', pickupDepot = 'docks', trailerKey = 'container', trailerContents = 'Sealed agriculture import container', routeLength = '7.2 mi', trailerDrop = { label = 'Grapeseed Farm Co-op', coords = vector3(1740.3, 4693.65, 43.56), radius = 20.0 }, receiverPed = { label = 'Grapeseed Co-op Volunteer', model = `s_m_m_gaffer_01`, coords = vector4(1725.29, 4714.45, 42.13, 200.1), scenario = 'WORLD_HUMAN_CLIPBOARD' } },
                { label = 'Harmony to Paleto Lumber Flatbed Haul', pickupDepot = 'harmony', trailerKey = 'flatbed', trailerContents = 'Empty Trailer Return', routeLength = '3.9 mi', trailerDrop = { label = 'Lumber Yard', coords = vector3(-800.41, 5406.8, 33.93), radius = 20.0 }, receiverPed = { label = 'Lumber Receiving Foreman', model = `s_m_m_lathandy_01`, coords = vector4(-807.51, 5397.17, 34.42, 324.27), scenario = 'WORLD_HUMAN_CLIPBOARD' } }
            }
        },
        government = {
            order = 3,
            label = 'Government Logistics Haul',
            shortLabel = 'Government',
            minRank = 4,
            payoutMultiplier = 1.95,
            xpMultiplier = 1.6,
            repBonus = 5,
            description = 'Secure trailer deliveries for state facilities and utilities.',
            badge = 'GOV',
            defaultTrailerKey = 'tanker',
            routes = {
                { label = 'Palmer-Taylor Fuel Transfer', pickupDepot = 'docks', trailerKey = 'tanker', trailerContents = 'Diesel fuel', routeLength = '5.3 mi', trailerDrop = { label = 'Palmer-Taylor Fuel Depot', coords = vector3(2672.57, 1428.12, 24.50), radius = 18.0 }, receiverPed = { label = 'Palmer-Taylor Receiver', model = `s_m_m_gaffer_01`, coords = vector4(2665.24, 1435.44, 24.50, 88.0), scenario = 'WORLD_HUMAN_CLIPBOARD' } },
                { label = 'State Utility Equipment Drop', pickupDepot = 'lsport', trailerKey = 'freight', trailerContents = 'State utility equipment', routeLength = '5.8 mi', trailerDrop = { label = 'Palmer-Taylor Power Yard', coords = vector3(2787.3, 1709.59, 24.62), radius = 18.0 }, receiverPed = { label = 'Utility Yard Receiver', model = `s_m_m_gaffer_01`, coords = vector4(2788.04, 1714.63, 24.58, 177.51), scenario = 'WORLD_HUMAN_CLIPBOARD' } },
                { label = 'Chemical Plant Tanker Transfer', pickupDepot = 'docks', trailerKey = 'chemical_tanker', trailerContents = 'Industrial treatment chemicals', routeLength = '11.6 mi', trailerDrop = { label = 'Humane Labs Service Gate', coords = vector3(3485.95, 3672.75, 33.89), radius = 20.0 }, receiverPed = { label = 'Lab Logistics Receiver', model = `s_m_m_chemsec_01`, coords = vector4(3493.98, 3686.11, 33.89, 134.74), scenario = 'WORLD_HUMAN_CLIPBOARD' } },
                { label = 'State Event Equipment Transfer', pickupDepot = 'lsport', trailerKey = 'tv', trailerContents = 'Emergency broadcast equipment', routeLength = '5.5 mi', trailerDrop = { label = 'Kortz Center Service Entrance', coords = vector3(-2354.91, 271.93, 166.16), radius = 20.0 }, receiverPed = { label = 'State Event Coordinator', model = `s_m_m_highsec_01`, coords = vector4(-2347.01, 263.86, 164.58, 65.86), scenario = 'WORLD_HUMAN_CLIPBOARD' } }
            }
        },
        military = {
            order = 4,
            label = 'Military Haul Contract',
            shortLabel = 'Military',
            minRank = 5,
            payoutMultiplier = 2.65,
            xpMultiplier = 2.0,
            repBonus = 8,
            description = 'Restricted Fort Zancudo and military logistics contracts.',
            badge = 'MIL',
            defaultTrailerKey = 'military',
            routes = {
                { label = 'Fort Zancudo Restricted Haul', pickupDepot = 'lsport', trailerKey = 'military', trailerContents = 'Restricted military equipment', routeLength = '7.4 mi', trailerDrop = { label = 'Fort Zancudo Maintenance Facility', coords = vector3(-2451.39, 2985.36, 32.81), radius = 20.0 }, receiverPed = { label = 'Military Logistics Officer', model = `s_m_y_marine_03`, coords = vector4(-2456.15, 2974.54, 32.96, 289.37), scenario = 'WORLD_HUMAN_CLIPBOARD' } },
                { label = 'Zancudo Airfield Equipment Transfer', pickupDepot = 'docks', trailerKey = 'heavy_military', trailerContents = 'Heavy airfield equipment', routeLength = '7.1 mi', trailerDrop = { label = 'Zancudo Main Hangar', coords = vector3(-1829.41, 2998.96, 32.81), radius = 20.0 }, receiverPed = { label = 'Zancudo Logistics Officer', model = `s_m_y_marine_01`, coords = vector4(-1827.23, 3007.55, 32.81, 140.32), scenario = 'WORLD_HUMAN_CLIPBOARD' } },
                { label = 'Port to Zancudo Container Transport', pickupDepot = 'docks', trailerKey = 'container', trailerContents = 'Restricted sealed military container', routeLength = '7.9 mi', trailerDrop = { label = 'Zancudo Secure Container Yard', coords = vector3(-2439.79, 3346.07, 32.83), radius = 22.0 }, receiverPed = { label = 'Zancudo Security Officer', model = `s_m_y_marine_02`, coords = vector4(-2427.69, 3345.38, 32.98, 66.75), scenario = 'WORLD_HUMAN_CLIPBOARD' } },
                { label = 'Zancudo Military Timber Support', pickupDepot = 'harmony', trailerKey = 'logs', trailerContents = 'Fortification timber', routeLength = '3.6 mi', trailerDrop = { label = 'Zancudo Training Yard', coords = vector3(-1945.5, 3355.84, 32.96), radius = 22.0 }, receiverPed = { label = 'Training Yard Quartermaster', model = `s_m_y_marine_03`, coords = vector4(-1953.41, 3358.06, 32.96, 188.74), scenario = 'WORLD_HUMAN_CLIPBOARD' } },
                { label = 'Merryweather Fuel Transfer', pickupDepot = 'harmony', trailerKey = 'tanker', trailerContents = 'Jet Fuel', routeLength = '7.6 mi', trailerDrop = { label = 'Zancudo Training Yard', coords = vector3(485.65, -3382.36, 6.07), radius = 22.0 }, receiverPed = { label = 'Merryweather Security Officer', model = `s_m_y_marine_03`, coords = vector4(485.65, -3382.36, 6.07, 359.42), scenario = 'WORLD_HUMAN_CLIPBOARD' } }
            }
        }
    }
}
