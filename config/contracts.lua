Config.ContractsVersion = '1.1.0'

Config.Contracts = {
    van = {
        label = 'Package Delivery',
        description = 'Deliver packages in a cargo van on a planned local route.',
        cargo = 'Packages',
        difficulty = 'Easy',
        cardColor = '#e6ab00',
        tags = { 'Postal Service', 'Local Stops', 'Multi Drop' },
        businesses = { 'Los Santos Delivery', 'GO Postal Express', 'Alpha Mail Couriers' },
        requiredCargo = 4,
        pickupPed = { label = 'Go Postal Warehouse Clerk', model = `s_m_m_postal_01`, coords = vector4(125.12, 98.36, 81.84, 157.28), scenario = 'WORLD_HUMAN_CLIPBOARD' },
        pickup = { label = 'Go Postal Sorting Center', coords = vector3(125.12, 98.36, 81.84) },
        routes = {
            { label = 'East Los Santos Parcel Route', routeLength = '3.0 mi', dropoffs = {
                { label = 'Digital Den - Mission Row', coords = vector3(392.476837, -831.473450, 29.343481), unload = 1 },
                { label = 'Ammu-Nation - Legion', coords = vector3(15.732404, -1114.611694, 29.917459), unload = 1 },
                { label = 'LTD Gasoline - Davis', coords = vector3(-40.582649, -1750.794312, 28.974571), unload = 1 },
                { label = 'Binco - Strawberry Ave', coords = vector3(70.733727, -1390.371216, 29.333855), unload = 1 }
            } },
            { label = 'West Side Business Route', routeLength = '3.0 mi', dropoffs = {
                { label = 'Suburban - Del Perro', coords = vector3(-1198.147583, -775.407654, 17.291162), unload = 1 },
                { label = 'Robs Liquor - Vespucci', coords = vector3(-1222.418701, -913.285583, 12.190260), unload = 1 },
                { label = 'Binco - South Rockford', coords = vector3(-822.338501, -1072.938477, 11.275532), unload = 1 },
                { label = 'Bean Machine', coords = vector3(-848.805176, -589.413696, 29.310863), unload = 1 }
            } },
            { label = 'Vinewood Express Route 3', routeLength = '3.0 mi', dropoffs = {
                { label = 'Tattoo - Vinewood', coords = vector3(319.730133, 183.169907, 103.435867), unload = 1 },
                { label = 'Up-n-Atom - Vinewood', coords = vector3(81.606529, 275.403595, 110.225998), unload = 1 },
                { label = 'Luxury Autos - Rockford', coords = vector3(-777.058655, -243.877350, 37.230682), unload = 1 },
                { label = 'Bean Machine - Eclipse Blvd', coords = vector3(-627.196533, 239.042496, 81.962952), unload = 1 }
            } },
            { label = 'Southside Local Stops', routeLength = '3.0 mi', dropoffs = {
                { label = 'LTD Gasoline - Grove St', coords = vector3(-40.538353, -1750.916016, 29.373398), unload = 1 },
                { label = '24/7 Market - Innocence Blvd', coords = vector3(27.731812, -1349.405029, 29.342958), unload = 1 },
                { label = 'Ammu-Nation - Vespucci Blvd', coords = vector3(845.259888, -1029.429443, 28.194813), unload = 1 },
                { label = 'Robs Liquor - El Rancho Blvd', coords = vector3(1129.896240, -979.913452, 46.386639), unload = 1 }
            } },
            { label = 'Sandy Shores Rural Mail Route', routeLength = '5.2 mi', dropoffs = {
                { label = '24/7 Market - Sandy', coords = vector3(1963.950317, 3739.766846, 32.369686), unload = 1 },
                { label = 'Yellow Jack Inn', coords = vector3(1989.510620, 3054.332520, 47.426117), unload = 1 },
                { label = 'Sandy Medical Center', coords = vector3(1816.228760, 3678.325684, 34.442177), unload = 1 },
                { label = "Sandy Airfield Office", coords = vector3(1759.603027, 3299.130371, 41.179695), unload = 1 }
            } },
            { label = 'Grapeseed Farm Deliveries', routeLength = '4.4 mi', dropoffs = {
                { label = "Millar's Fishery - Grapeseed", coords = vector3(1332.591431, 4324.773438, 38.176300), unload = 1 },
                { label = 'Binco - Grapeseed', coords = vector3(1699.010864, 4820.926270, 42.040264), unload = 1 },
                { label = 'LTD Gas- Grapeseed', coords = vector3(1705.598633, 4917.042969, 41.729256), unload = 1 },
                { label = "O'Neil Farm Supply", coords = vector3(2485.357910, 4954.426758, 45.203793), unload = 1 },              
            } },
            { label = 'Chumash Coastal Parcel Route', routeLength = '4.8 mi', dropoffs = {
                { label = '24/7 Market - Chumash', coords = vector3(-3240.021484, 1003.000000, 12.533175), unload = 1 },
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
            } },

            --Drop locations below double as freight deliveries
            { label = 'Paleto Parcel Run 1', routeLength = '11.2 mi', dropoffs = {
                { label = 'Chiliad Lumber Depot', coords = vector3(-841.857544, 5400.711426, 34.587448), unload = 1 },
                { label = 'Lumber Mill Office', coords = vector3(-567.073547, 5252.993164, 70.487740), unload = 1 },
                { label = 'Paleto Market', coords = vector3(-358.403625, 6061.510254, 31.587317), unload = 1 },
                { label = 'Jetsam Freight Office', coords = vector3(-254.537033, 6149.252930, 31.443413), unload = 1 }
            } },
            { label = 'Clucking Bell Farms Parcel Run', routeLength = '11.2 mi', dropoffs = {
                { label = 'Clucking Bell Farms', coords = vector3(-841.857544, 5400.711426, 34.587448), unload = 1 },
                { label = 'Clucking Bell Farms', coords = vector3(-69.835938, 6253.328613, 31.175774), unload = 2 },
                { label = 'Clucking Bell Farms', coords = vector3(-156.187424, 6292.883789, 31.927034), unload = 1 },
            } },
            { label = 'Paleto Parcel Run 2', routeLength = '11.2 mi', dropoffs = {
                { label = 'Paleto Market', coords = vector3(-340.276062, 6239.358887, 31.605780), unload = 1 },
                { label = 'Paleto Pets', coords = vector3(-270.261841, 6283.909668, 31.612719), unload = 1 },
                { label = 'Dream View Motel', coords = vector3(-127.690742, 6340.618652, 31.549658), unload = 1 },
                { label = 'Donkey Punch Farms', coords = vector3(415.857239, 6520.785645, 27.754330), unload = 1 }
            } },
            { label = 'Grapeseed Area Parcel Run', routeLength = '6.2 mi', dropoffs = {
                { label = 'Union Grain Service', coords = vector3(2873.461914, 4421.856934, 48.661907), unload = 1 },
                { label = 'Senora Service Station', coords = vector3(2932.933594, 4618.909668, 48.847176), unload = 1 },
                { label = 'Catfish View Dockhouse', coords = vector3(3807.872559, 4478.960449, 6.308082), unload = 1 },
                { label = 'Shady Tree Farms', coords = vector3(2555.832520, 4651.750488, 34.190342), unload = 1 }
            } },
            { label = 'Joshua Rd Express Route 1', routeLength = '5.2 mi', dropoffs = {
                { label = 'Park View Diner', coords = vector3(2697.807861, 4324.140137, 45.916328), unload = 1 },
                { label = 'Globe Oil Service Station', coords = vector3(2507.957275, 4209.833496, 39.806049), unload = 1 },
                { label = 'Joshua Rd Liquor', coords = vector3(2468.221191, 4100.718750, 38.029720), unload = 1 },
                { label = "Red's Auto Parts", coords = vector3(2521.675293, 4110.962891, 38.634415), unload = 1 }
            } },
            { label = 'Joshua Rd Express Route 2', routeLength = '5.2 mi', dropoffs = {
                { label = 'Liquor Market', coords = vector3(2440.936768, 4067.922119, 37.958191), unload = 1 },
                { label = 'Alamo Sea Liquor', coords = vector3(917.551270, 3654.669434, 32.627457), unload = 1 },
                { label = 'Alamo Sea Auto Shop', coords = vector3(433.669556, 3572.812012, 33.269352), unload = 1 },
                { label = 'Stoner Cement Works', coords = vector3(287.995178, 2844.023438, 44.722176), unload = 1 }
            } },
            { label = 'Route 68 Express Route', routeLength = '5.2 mi', dropoffs = {
                { label = 'Bolingbroke Fleet Depot', coords = vector3(1861.587158, 2720.349365, 45.770119), unload = 1 },
                { label = 'Binco Receiving', coords = vector3(1190.292358, 2721.373047, 38.038509), unload = 1 },
                { label = 'Animal Ark', coords = vector3(568.654236, 2796.905029, 42.015179), unload = 1 },
                { label = 'Harmony Auto Service', coords = vector3(256.642487, 2585.715088, 44.903656), unload = 1 }
            } },
            { label = 'Vinewood Express Route 1', routeLength = '3.2 mi', dropoffs = {
                { label = 'Gems Jewelry', coords = vector3(230.623215, 381.732513, 106.463928), unload = 1 },
                { label = 'Pitchers', coords = vector3(197.587814, 306.583832, 105.387054), unload = 1 },
                { label = 'Gentry Manor Service', coords = vector3(-103.200790, 397.256653, 112.528976), unload = 1 },
                { label = 'Full Moon Film Theater', coords = vector3(-570.471191, 310.515991, 84.459511), unload = 1 }
            } },
            { label = 'Vinewood Express Route 2', routeLength = '3.2 mi', dropoffs = {
                { label = 'Diamond Casino Receiving', coords = vector3(976.577759, 17.106155, 80.863548), unload = 1 },
                { label = 'Doppler Theater', coords = vector3(349.059906, 173.547729, 103.062988), unload = 1 },
                { label = "Blarney's - Vinewood", coords = vector3(116.591873, 168.301239, 104.767517), unload = 1 },
                { label = 'Spitroasters', coords = vector3(-242.026535, 280.126312, 92.077690), unload = 1 }
            } },
            { label = 'Baytree Canyon Express', routeLength = '5.2 mi', dropoffs = {
                { label = 'Sisyphus Theater', coords = vector3(226.358856, 1150.013916, 225.443848), unload = 1 },
                { label = 'Fatal Incursion Loading', coords = vector3(172.319946, 1243.218872, 223.098434), unload = 1 },
                { label = 'Farm Supply', coords = vector3(-42.625698, 1884.889648, 195.464157), unload = 1 },
                { label = 'Baytree Depot', coords = vector3(861.926758, 2175.535156, 52.391312), unload = 1 }
            } },
            { label = 'Senora Rd Route', routeLength = '5.2 mi', dropoffs = {
                { label = 'Vinewood Cafe', coords = vector3(815.349182, 541.972290, 125.798347), unload = 1 },
                { label = 'Stoner Cement Works', coords = vector3(1215.721680, 1846.846313, 78.906372), unload = 1 },
                { label = 'Redwood Lights Track Office', coords = vector3(1128.622803, 2125.241455, 55.595875), unload = 1 },
                { label = 'Rebel Radio', coords = vector3(729.925659, 2531.944824, 73.246857), unload = 1 }
            } },
            { label = 'Senora Way Route', routeLength = '5.2 mi', dropoffs = {
                { label = 'Palmer-Taylor Municipal', coords = vector3(2855.047363, 1480.141602, 24.577040), unload = 1 },
                { label = "Rex's Diner", coords = vector3(2549.346191, 2581.707031, 38.219421), unload = 1 },
                { label = 'Davis Quartz Receiving', coords = vector3(2707.641357, 2776.520508, 37.850311), unload = 2 },
            } },
            { label = 'Mirror Park Express 1', routeLength = '3.2 mi', dropoffs = {
                { label = "Gabriela's Market", coords = vector3(1145.069702, -299.404755, 68.892982), unload = 1 },
                { label = "Horny's Burgers", coords = vector3(1246.974976, -350.390411, 69.200500), unload = 1 },
                { label = 'Mirror Park Auto Service', coords = vector3(1124.302856, -784.701172, 57.694912), unload = 1 },
                { label = 'Robs Liquor - El Rancho Blvd', coords = vector3(1124.302856, -784.701172, 57.694912), unload = 1 },
            } },
            { label = 'Mirror Park Express 2', routeLength = '3.2 mi', dropoffs = {
                { label = "24/7 Market - Mirror Park", coords = vector3(1160.835693, -312.466187, 69.314995), unload = 1 },
                { label = "Hearty Tac", coords = vector3(1106.717407, -354.868622, 67.226349), unload = 1 },
                { label = 'Digital Den - Mirror Park', coords = vector3(1137.242432, -470.582275, 66.733788), unload = 1 },
                { label = "Chico's Market", coords = vector3(1093.098999, -787.103027, 58.413136), unload = 1 },
            } },
            { label = 'City Express Route 1', routeLength = '3.2 mi', dropoffs = {
                { label = "The Richman Hotel Service", coords = vector3(-1215.745361, 343.756866, 71.302376), unload = 1 },
                { label = "ULSA Office", coords = vector3(-1649.934082, 151.358231, 62.121620), unload = 1 },
                { label = 'Vinewood Beauty Salon Supply', coords = vector3(-1450.118530, -385.674133, 38.349293), unload = 1 },
                { label = "Lifeinvader Service Entrance", coords = vector3(-1052.905029, -246.541962, 38.280460), unload = 1 },
            } },
            { label = 'City Express Route 2', routeLength = '3.2 mi', dropoffs = {
                { label = "The Viceroy Hotel Service", coords = vector3(-862.777344, -1227.723389, 6.340658), unload = 1 },
                { label = "Steamboat Beers", coords = vector3(-1186.423828, -1385.739380, 4.612758), unload = 1 },
                { label = "Giovanni's Italian Restaurant", coords = vector3(-1353.562256, -886.355164, 13.779840), unload = 1 },
                { label = "MissT - Vespucci", coords = vector3(-1329.920288, -581.136963, 29.584597), unload = 1 },
            } },
            { label = 'City Express Route 3', routeLength = '3.2 mi', dropoffs = {
                { label = "Richard's Majestic - Stage 13", coords = vector3(-1197.975098, -540.614685, 28.961802), unload = 1 },
                { label = "Von Crastenburg - Richman", coords = vector3(-1161.188477, -218.293747, 38.046009), unload = 1 },
                { label = "Pipeline Inn Service", coords = vector3(-2206.036377, -373.986572, 13.450862), unload = 1 },
                { label = "Out Of Towners - Del Perro", coords = vector3(-1656.674927, -983.051147, 8.107500), unload = 1 },
            } },
        }
    },
    boxtruck = {
        label = 'Crate Delivery',
        description = 'Load crates from a warehouse and restock businesses along a planned route.',
        cargo = 'Crates',
        difficulty = 'Medium',
        cardColor = '#3f8cff',
        tags = { 'Warehouse Supply', 'Store Restock', 'Crates' },
        businesses = { 'LAST DROP Warehouse', 'Liberty State Delivery', 'Post OP' },
        requiredCargo = 6,
        pickupPed = { label = 'Post OP Freight Coordinator', model = `s_m_m_dockwork_01`, coords = vector4(-433.43, -2788.9, 6.0, 19.06), scenario = 'WORLD_HUMAN_CLIPBOARD' },
        pickup = { label = 'Post OP Freight Warehouse', coords = vector3(-433.43, -2788.9, 6.0) },
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
                } },
                { label = 'East City Store Restock', dropoffs = {
                    { label = 'Binco - Textile Drop', coords = vector3(430.506104, -809.204529, 28.965164), unload = 2 },
                    { label = 'LTD Gasoline - Mirror Park', coords = vector3(1163.514404, -313.286804, 68.942574), unload = 2 },
                    { label = '24/7 Market - Clinton Ave', coords = vector3(373.270325, 341.260101, 103.126053), unload = 2 }
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
                    { label = 'LTD Gas - Richman', coords = vector3(-1828.923340, 800.790527, 138.573669), unload = 2 }
                } },
                { label = 'Route 68 County Restock', routeLength = '5.7 mi', dropoffs = {
                    { label = '24/7 Loading Door - Harmony', coords = vector3(543.718994, 2658.850342, 42.102001), unload = 2 },
                    { label = 'Route 68 Store - Harmony', coords = vector3(1201.793335, 2654.055176, 37.884415), unload = 2 },
                    { label = "Rex's Diner Supply", coords = vector3(2549.273193, 2581.908203, 37.971207), unload = 2 }
                } },
                { label = 'Paleto Bay Store Supply', routeLength = '8.6 mi', dropoffs = {
                    { label = 'Paleto Auto Parts', coords = vector3(119.113647, 6626.925293, 32.064049), unload = 2 },
                    { label = 'Bay Hardware Storage', coords = vector3(-5.577757, 6490.679199, 31.448158), unload = 2 },
                    { label = 'Paleto Liguor Supply Door', coords = vector3(-394.661102, 6074.418457, 31.378326), unload = 2 }
                } },
                { label = 'Chumash Retail Supply', routeLength = '4.9 mi', dropoffs = {
                    { label = '24/7 Loading Area - Chumash', coords = vector3(-3253.682617, 999.057007, 12.385384), unload = 2 },
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
                } },
        }
    },
    trailer = {
        label = 'Trailer Hauling',
        description = 'Hook a trailer at the depot, drop it in the receiving yard, then finalize with the receiver.',
        cargo = 'Trailer',
        difficulty = 'Hard',
        cardColor = '#da1d1d',
        tags = { 'Large Freight', 'Long Haul', 'Receiver Signoff' },
        businesses = { 'Jetsam', 'RS Haul', 'Lando-Corp', 'Bilgeco' },
        requiredCargo = 1,
        pickup = { label = 'Jetsam Terminal Depot', coords = vector3(1025.9, -3184.63, 5.9) },
        routes = {
            {
                    label = 'Cypress Flats Freight',
                    pickupDepot = 'harmony',
                    trailerKey = 'dryvan',
                    trailerContents = 'General freight pallets',
                    routeLength = '5.6 mi',
                    trailerDrop = {
                        label = 'Cypress Flats Receiving Yard',
                        coords = vector3(1015.51, -2508.01, 28.3),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Warehouse Receiver',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(1018.49, -2510.06, 28.48, 87.09),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
            {
                    label = 'Cluckin Bell Farms Haul',
                    pickupDepot = 'lsport',
                    trailerKey = 'reefer3',
                    trailerContents = 'General freight pallets',
                    routeLength = '8.2 mi',
                    trailerDrop = {
                        label = 'Cluckin Bell Loading Dock',
                        coords = vector3(184.29, 6394.69, 31.38),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Warehouse Receiver',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(185.68, 6380.86, 32.34, 303.88),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
            {
                    label = 'Pißwasser Brewing Co.',
                    pickupDepot = 'harmony',
                    trailerKey = 'reefer',
                    trailerContents = 'New Recycled Bottles',
                    routeLength = '5.6 mi',
                    trailerDrop = {
                        label = 'Pißwasser Brewery Loading Dock',
                        coords = vector3(838.47, -1932.98, 28.98),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Warehouse Receiver',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(832.43, -1926.34, 30.31, 219.26),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
            {
                    label = 'YOU TOOL Retail Freight',
                    pickupDepot = 'harmony',
                    trailerKey = 'reefer2',
                    trailerContents = 'Wiwang Electronics Components',
                    routeLength = '5.6 mi',
                    trailerDrop = {
                        label = 'You Tool Receiving Area',
                        coords = vector3(2673.64, 3518.09, 52.72),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Warehouse Manager',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(2681.74, 3514.88, 53.31, 76.44),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
            {
                    label = 'Sandy Shores Trailer Transfer',
                    pickupDepot = 'lsport',
                    trailerKey = 'freight',
                    trailerContents = 'Blaine County store supplies',
                    routeLength = '5.6 mi',
                    trailerDrop = {
                        label = 'Sandy Shores Transfer Yard',
                        coords = vector3(1795.56, 3405.71, 40.62),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Blaine County Receiver',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(1798.6, 3412.85, 40.34, 105.0),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
            {
                    label = 'Paleto Freight Storage',
                    pickupDepot = 'harmony',
                    trailerKey = 'reefer2',
                    trailerContents = 'Industrial equipment',
                    routeLength = '7.6 mi',
                    trailerDrop = {
                        label = 'Paleto Freight Warehouse',
                        coords = vector3(3.46, 6442.08, 31.43),
                        radius = 18.0
                    },
                    receiverPed = {
                        label = 'Paleto Warehouse Supervisor',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(5.25, 6444.4, 31.43, 141.15),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
            {
                    label = 'Fridgit Cold Storage',
                    pickupDepot = 'harmony',
                    trailerKey = 'reefer3',
                    trailerContents = 'General Freight',
                    routeLength = '4.6 mi',
                    trailerDrop = {
                        label = 'Fridgit Cold Storage Warehouse',
                        coords = vector3(872.82, -1670.3, 30.5),
                        radius = 18.0
                    },
                    receiverPed = {
                        label = 'Fridgit Warehouse Supervisor',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(880.57, -1668.28, 31.78, 84.61),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
            {
                    label = 'Fridgit Cold Storage',
                    pickupDepot = 'harmony',
                    trailerKey = 'reefer4',
                    trailerContents = 'General Freight',
                    routeLength = '4.6 mi',
                    trailerDrop = {
                        label = 'Fridgit Cold Storage Warehouse',
                        coords = vector3(995.9, -1533.1, 30.37),
                        radius = 18.0
                    },
                    receiverPed = {
                        label = 'Fridgit Warehouse Supervisor',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(991.82, -1528.81, 30.88, 181.44),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
            {
                    label = 'Palmer-Taylor Supply Delivery',
                    pickupDepot = 'lsport',
                    trailerKey = 'freight',
                    trailerContents = 'Facility Maintenance Equipment',
                    routeLength = '7.6 mi',
                    trailerDrop = {
                        label = 'Station Equipment Storage',
                        coords = vector3(2672.57, 1428.12, 24.50),
                        radius = 18.0
                    },
                    receiverPed = {
                        label = 'Maintenance Supervisor',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(2668.74, 1436.49, 24.5, 279.31),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
            {
                    label = 'RON Fuel Depot Transfer',
                    pickupDepot = 'docks',
                    trailerKey = 'tanker',
                    trailerContents = 'Offroad-Diesel Fuel',
                    routeLength = '7.6 mi',
                    trailerDrop = {
                        label = 'Alamo Sea Depot',
                        coords = vector3(332.95, 3408.22, 36.71),
                        radius = 18.0
                    },
                    receiverPed = {
                        label = 'Alamo Sea Depot Receiver',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(345.07, 3405.47, 36.48, 18.17),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
            {
                    label = 'Port Container Yard Transfer',
                    pickupDepot = 'lsport',
                    trailerKey = 'container',
                    trailerContents = 'Sealed shipping container',
                    routeLength = '1.8 mi',
                    trailerDrop = {
                        label = 'Elysian Island Container Yard',
                        coords = vector3(849.73, -3219.17, 5.90),
                        radius = 18.0
                    },
                    receiverPed = {
                        label = 'Container Yard Clerk',
                        model = `s_m_m_dockwork_01`,
                        coords = vector4(857.73, -3204.24, 5.99, 177.18),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
            {
                    label = 'Harmony Flatbed Equipment Haul',
                    pickupDepot = 'lsport',
                    trailerKey = 'flatbed_lift_equipment',
                    trailerContents = 'Construction Lift Components',
                    routeLength = '5.9 mi',
                    trailerDrop = {
                        label = 'Harmony Equipment Yard',
                        coords = vector3(568.37, 2805.77, 42.05),
                        radius = 18.0
                    },
                    receiverPed = {
                        label = 'Equipment Yard Receiver',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(570.52, 2795.26, 42.03, 299.54),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
            {
                    label = 'Paleto Logging Delivery',
                    pickupDepot = 'harmony',
                    trailerKey = 'logs',
                    trailerContents = 'Timber logs',
                    routeLength = '7.6 mi',
                    trailerDrop = {
                        label = 'Paleto Lumber Mill',
                        coords = vector3(-562.61, 5350.38, 70.21),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Lumber Mill Receiver',
                        model = `s_m_m_lathandy_01`,
                        coords = vector4(-562.61, 5350.38, 70.21, 66.83),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
            {
                    label = 'Vinewood Event Equipment Delivery',
                    pickupDepot = 'lsport',
                    trailerKey = 'tv2',
                    trailerContents = 'Event lighting and broadcast equipment',
                    routeLength = '4.7 mi',
                    trailerDrop = {
                        label = 'Vinewood Bowl Event Center',
                        coords = vector3(644.21, 598.84, 128.91),
                        radius = 18.0
                    },
                    receiverPed = {
                        label = 'Event Logistics Manager',
                        model = `s_m_m_highsec_01`,
                        coords = vector4(658.29, 591.47, 129.05, 65.23),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
            {
                    label = 'The Secure Unit Delivery',
                    pickupDepot = 'harmony',
                    trailerKey = 'tv2',
                    trailerContents = 'General Freight',
                    routeLength = '4.7 mi',
                    trailerDrop = {
                        label = 'Secure Unit - Bay 7',
                        coords = vector3(917.22, -1265.58, 25.53),
                        radius = 18.0
                    },
                    receiverPed = {
                        label = 'Logistics Manager',
                        model = `s_m_m_lathandy_01`,
                        coords = vector4(909.91, -1267.73, 25.59, 354.41),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
            {
                    label = 'Utopia Gardens Developement',
                    pickupDepot = 'harmony',
                    trailerKey = 'tv2',
                    trailerContents = 'General Contracting Materials',
                    routeLength = '4.7 mi',
                    trailerDrop = {
                        label = 'Utopia Gardens',
                        coords = vector3(1384.03, -742.49, 67.19),
                        radius = 18.0
                    },
                    receiverPed = {
                        label = 'Construction Foreman',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(1403.44, -732.48, 67.53, 101.63),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Utopia Gardens Developement',
                    pickupDepot = 'harmony',
                    trailerKey = 'flatbed_woodpile3',
                    trailerContents = 'Construction Materials - Wood Beams',
                    routeLength = '4.6 mi',
                    trailerDrop = {
                        label = 'Utopia Gardens',
                        coords = vector3(1384.03, -742.49, 67.19),
                        radius = 18.0
                    },
                    receiverPed = {
                        label = 'Construction Foreman',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(1403.44, -732.48, 67.53, 101.63),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Utopia Gardens Developement',
                    pickupDepot = 'harmony',
                    trailerKey = 'flatbed_woodpile2',
                    trailerContents = 'Construction Materials - Boxes',
                    routeLength = '4.6 mi',
                    trailerDrop = {
                        label = 'Utopia Gardens',
                        coords = vector3(1384.03, -742.49, 67.19),
                        radius = 18.0
                    },
                    receiverPed = {
                        label = 'Construction Foreman',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(1403.44, -732.48, 67.53, 101.63),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Utopia Gardens Developement',
                    pickupDepot = 'harmony',
                    trailerKey = 'flatbed_woodpile',
                    trailerContents = 'Construction Materials - Lumber',
                    routeLength = '4.6 mi',
                    trailerDrop = {
                        label = 'Utopia Gardens',
                        coords = vector3(1384.03, -742.49, 67.19),
                        radius = 18.0
                    },
                    receiverPed = {
                        label = 'Construction Foreman',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(1403.44, -732.48, 67.53, 101.63),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Utopia Gardens Developement',
                    pickupDepot = 'harmony',
                    trailerKey = 'flatbed_plywood',
                    trailerContents = 'Construction Materials - Plywood',
                    routeLength = '4.6 mi',
                    trailerDrop = {
                        label = 'Utopia Gardens',
                        coords = vector3(1384.03, -742.49, 67.19),
                        radius = 18.0
                    },
                    receiverPed = {
                        label = 'Construction Foreman',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(1403.44, -732.48, 67.53, 101.63),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Utopia Gardens Developement',
                    pickupDepot = 'harmony',
                    trailerKey = 'flatbed_plywood2',
                    trailerContents = 'Construction Materials - Plywood',
                    routeLength = '4.6 mi',
                    trailerDrop = {
                        label = 'Utopia Gardens',
                        coords = vector3(1384.03, -742.49, 67.19),
                        radius = 18.0
                    },
                    receiverPed = {
                        label = 'Construction Foreman',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(1403.44, -732.48, 67.53, 101.63),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },

                {
                    label = 'YOU TOOL Retail Freight',
                    pickupDepot = 'harmony',
                    trailerKey = 'flatbed_woodpile3',
                    trailerContents = 'Construction Materials - Wood Beams',
                    routeLength = '2.6 mi',
                    trailerDrop = {
                        label = 'You Tool Receiving Area',
                        coords = vector3(2673.64, 3518.09, 52.72),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Warehouse Manager',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(2681.74, 3514.88, 53.31, 76.44),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'YOU TOOL Freight',
                    pickupDepot = 'harmony',
                    trailerKey = 'flatbed_woodpile2',
                    trailerContents = 'Construction Materials - Boxes',
                    routeLength = '2.6 mi',
                    trailerDrop = {
                        label = 'You Tool Receiving Area',
                        coords = vector3(2673.64, 3518.09, 52.72),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Warehouse Manager',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(2681.74, 3514.88, 53.31, 76.44),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'YOU TOOL Freight',
                    pickupDepot = 'harmony',
                    trailerKey = 'flatbed_woodpile',
                    trailerContents = 'Construction Materials - Lumber',
                    routeLength = '2.6 mi',
                    trailerDrop = {
                        label = 'You Tool Receiving Area',
                        coords = vector3(2673.64, 3518.09, 52.72),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Warehouse Manager',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(2681.74, 3514.88, 53.31, 76.44),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'YOU TOOL Freight',
                    pickupDepot = 'harmony',
                    trailerKey = 'flatbed_plywood',
                    trailerContents = 'Construction Materials - Plywood',
                    routeLength = '2.6 mi',
                    trailerDrop = {
                        label = 'You Tool Receiving Area',
                        coords = vector3(2673.64, 3518.09, 52.72),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Warehouse Manager',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(2681.74, 3514.88, 53.31, 76.44),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'YOU TOOL Freight',
                    pickupDepot = 'harmony',
                    trailerKey = 'flatbed_plywood2',
                    trailerContents = 'Construction Materials - Plywood',
                    routeLength = '2.6 mi',
                    trailerDrop = {
                        label = 'You Tool Receiving Area',
                        coords = vector3(2673.64, 3518.09, 52.72),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Warehouse Manager',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(2681.74, 3514.88, 53.31, 76.44),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'MEGA MALL Freight',
                    pickupDepot = 'harmony',
                    trailerKey = 'flatbed_plywood',
                    trailerContents = 'Construction Materials - Plywood',
                    routeLength = '3.8 mi',
                    trailerDrop = {
                        label = 'Mega Mall Receiving Area',
                        coords = vector3(104.38, -1818.24, 26.53),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Warehouse Manager',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(98.87, -1810.53, 27.07, 215.41),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'MEGA MALL Freight',
                    pickupDepot = 'harmony',
                    trailerKey = 'flatbed_plywood2',
                    trailerContents = 'Construction Materials - Plywood',
                    routeLength = '3.8 mi',
                    trailerDrop = {
                        label = 'Mega Mall Receiving Area',
                        coords = vector3(104.38, -1818.24, 26.53),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Warehouse Manager',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(98.87, -1810.53, 27.07, 215.41),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'STD Contractors - La Puerta Site',
                    pickupDepot = 'harmony',
                    trailerKey = 'flatbed_plywood2',
                    trailerContents = 'Construction Materials - Plywood',
                    routeLength = '3.85 mi',
                    trailerDrop = {
                        label = 'La Puerta Construction Area',
                        coords = vector3(-475.75, -875.32, 23.77),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Site Foreman',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(-471.07, -865.85, 23.96, 167.02),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'STD Contractors - La Puerta Site',
                    pickupDepot = 'harmony',
                    trailerKey = 'flatbed_plywood',
                    trailerContents = 'Construction Materials - Plywood',
                    routeLength = '3.85 mi',
                    trailerDrop = {
                        label = 'La Puerta Construction Area',
                        coords = vector3(-475.75, -875.32, 23.77),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Site Foreman',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(-471.07, -865.85, 23.96, 167.02),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'STD Contractors - La Puerta Site',
                    pickupDepot = 'harmony',
                    trailerKey = 'flatbed_woodpile',
                    trailerContents = 'Construction Materials - Lumber',
                    routeLength = '3.85 mi',
                    trailerDrop = {
                        label = 'La Puerta Construction Area',
                        coords = vector3(-475.75, -875.32, 23.77),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Site Foreman',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(-471.07, -865.85, 23.96, 167.02),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'STD Contractors - La Puerta Site',
                    pickupDepot = 'harmony',
                    trailerKey = 'flatbed_woodpile2',
                    trailerContents = 'Construction Materials - Boxes',
                    routeLength = '3.85 mi',
                    trailerDrop = {
                        label = 'La Puerta Construction Area',
                        coords = vector3(-475.75, -875.32, 23.77),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Site Foreman',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(-471.07, -865.85, 23.96, 167.02),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'STD Contractors - La Puerta Site',
                    pickupDepot = 'harmony',
                    trailerKey = 'flatbed_woodpile3',
                    trailerContents = 'Construction Materials - Wood Beams',
                    routeLength = '3.85 mi',
                    trailerDrop = {
                        label = 'La Puerta Construction Area',
                        coords = vector3(-475.75, -875.32, 23.77),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Site Foreman',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(-471.07, -865.85, 23.96, 167.02),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'STD Contractors - La Puerta Site',
                    pickupDepot = 'harmony',
                    trailerKey = 'flatbed_aircon',
                    trailerContents = 'Commercial Air Conditioners',
                    routeLength = '3.85 mi',
                    trailerDrop = {
                        label = 'La Puerta Construction Area',
                        coords = vector3(-475.75, -875.32, 23.77),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Site Foreman',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(-471.07, -865.85, 23.96, 167.02),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'STD Contractors - La Puerta Site',
                    pickupDepot = 'harmony',
                    trailerKey = 'flatbed_generators',
                    trailerContents = 'Commercial Generators',
                    routeLength = '3.85 mi',
                    trailerDrop = {
                        label = 'La Puerta Construction Area',
                        coords = vector3(-475.75, -875.32, 23.77),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Site Foreman',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(-471.07, -865.85, 23.96, 167.02),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'STD Contractors - La Puerta Site',
                    pickupDepot = 'harmony',
                    trailerKey = 'flatbed_lift_equipment',
                    trailerContents = 'Construction Lift Components',
                    routeLength = '3.85 mi',
                    trailerDrop = {
                        label = 'La Puerta Construction Area',
                        coords = vector3(-475.75, -875.32, 23.77),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Site Foreman',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(-471.07, -865.85, 23.96, 167.02),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                --std lsport
                {
                    label = 'STD Contractors - La Puerta Site',
                    pickupDepot = 'lsport',
                    trailerKey = 'flatbed_plywood2',
                    trailerContents = 'Construction Materials - Plywood',
                    routeLength = '2.20 mi',
                    trailerDrop = {
                        label = 'La Puerta Construction Area',
                        coords = vector3(-475.75, -875.32, 23.77),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Site Foreman',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(-471.07, -865.85, 23.96, 167.02),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'STD Contractors - La Puerta Site',
                    pickupDepot = 'lsport',
                    trailerKey = 'flatbed_plywood',
                    trailerContents = 'Construction Materials - Plywood',
                    routeLength = '2.20 mi',
                    trailerDrop = {
                        label = 'La Puerta Construction Area',
                        coords = vector3(-475.75, -875.32, 23.77),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Site Foreman',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(-471.07, -865.85, 23.96, 167.02),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'STD Contractors - La Puerta Site',
                    pickupDepot = 'lsport',
                    trailerKey = 'flatbed_woodpile',
                    trailerContents = 'Construction Materials - Lumber',
                    routeLength = '2.20 mi',
                    trailerDrop = {
                        label = 'La Puerta Construction Area',
                        coords = vector3(-475.75, -875.32, 23.77),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Site Foreman',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(-471.07, -865.85, 23.96, 167.02),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'STD Contractors - La Puerta Site',
                    pickupDepot = 'lsport',
                    trailerKey = 'flatbed_woodpile2',
                    trailerContents = 'Construction Materials - Boxes',
                    routeLength = '2.20 mi',
                    trailerDrop = {
                        label = 'La Puerta Construction Area',
                        coords = vector3(-475.75, -875.32, 23.77),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Site Foreman',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(-471.07, -865.85, 23.96, 167.02),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'STD Contractors - La Puerta Site',
                    pickupDepot = 'lsport',
                    trailerKey = 'flatbed_woodpile3',
                    trailerContents = 'Construction Materials - Wood Beams',
                    routeLength = '2.20 mi',
                    trailerDrop = {
                        label = 'La Puerta Construction Area',
                        coords = vector3(-475.75, -875.32, 23.77),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Site Foreman',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(-471.07, -865.85, 23.96, 167.02),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'STD Contractors - La Puerta Site',
                    pickupDepot = 'lsport',
                    trailerKey = 'flatbed_aircon',
                    trailerContents = 'Commercial Air Conditioners',
                    routeLength = '2.20 mi',
                    trailerDrop = {
                        label = 'La Puerta Construction Area',
                        coords = vector3(-475.75, -875.32, 23.77),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Site Foreman',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(-471.07, -865.85, 23.96, 167.02),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'STD Contractors - La Puerta Site',
                    pickupDepot = 'lsport',
                    trailerKey = 'flatbed_generators',
                    trailerContents = 'Commercial Generators',
                    routeLength = '2.20 mi',
                    trailerDrop = {
                        label = 'La Puerta Construction Area',
                        coords = vector3(-475.75, -875.32, 23.77),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Site Foreman',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(-471.07, -865.85, 23.96, 167.02),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'STD Contractors - La Puerta Site',
                    pickupDepot = 'lsport',
                    trailerKey = 'flatbed_lift_equipment',
                    trailerContents = 'Construction Lift Components',
                    routeLength = '2.20 mi',
                    trailerDrop = {
                        label = 'La Puerta Construction Area',
                        coords = vector3(-475.75, -875.32, 23.77),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Site Foreman',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(-471.07, -865.85, 23.96, 167.02),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                --std docks
                {
                    label = 'STD Contractors - La Puerta Site',
                    pickupDepot = 'docks',
                    trailerKey = 'flatbed_plywood2',
                    trailerContents = 'Construction Materials - Plywood',
                    routeLength = '2.40 mi',
                    trailerDrop = {
                        label = 'La Puerta Construction Area',
                        coords = vector3(-475.75, -875.32, 23.77),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Site Foreman',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(-471.07, -865.85, 23.96, 167.02),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'STD Contractors - La Puerta Site',
                    pickupDepot = 'docks',
                    trailerKey = 'flatbed_plywood',
                    trailerContents = 'Construction Materials - Plywood',
                    routeLength = '2.40 mi',
                    trailerDrop = {
                        label = 'La Puerta Construction Area',
                        coords = vector3(-475.75, -875.32, 23.77),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Site Foreman',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(-471.07, -865.85, 23.96, 167.02),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'STD Contractors - La Puerta Site',
                    pickupDepot = 'docks',
                    trailerKey = 'flatbed_woodpile',
                    trailerContents = 'Construction Materials - Lumber',
                    routeLength = '2.40 mi',
                    trailerDrop = {
                        label = 'La Puerta Construction Area',
                        coords = vector3(-475.75, -875.32, 23.77),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Site Foreman',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(-471.07, -865.85, 23.96, 167.02),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'STD Contractors - La Puerta Site',
                    pickupDepot = 'docks',
                    trailerKey = 'flatbed_woodpile2',
                    trailerContents = 'Construction Materials - Boxes',
                    routeLength = '2.40 mi',
                    trailerDrop = {
                        label = 'La Puerta Construction Area',
                        coords = vector3(-475.75, -875.32, 23.77),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Site Foreman',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(-471.07, -865.85, 23.96, 167.02),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'STD Contractors - La Puerta Site',
                    pickupDepot = 'docks',
                    trailerKey = 'flatbed_woodpile3',
                    trailerContents = 'Construction Materials - Wood Beams',
                    routeLength = '2.40 mi',
                    trailerDrop = {
                        label = 'La Puerta Construction Area',
                        coords = vector3(-475.75, -875.32, 23.77),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Site Foreman',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(-471.07, -865.85, 23.96, 167.02),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'STD Contractors - La Puerta Site',
                    pickupDepot = 'docks',
                    trailerKey = 'flatbed_aircon',
                    trailerContents = 'Commercial Air Conditioners',
                    routeLength = '2.40 mi',
                    trailerDrop = {
                        label = 'La Puerta Construction Area',
                        coords = vector3(-475.75, -875.32, 23.77),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Site Foreman',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(-471.07, -865.85, 23.96, 167.02),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'STD Contractors - La Puerta Site',
                    pickupDepot = 'docks',
                    trailerKey = 'flatbed_generators',
                    trailerContents = 'Commercial Generators',
                    routeLength = '2.40 mi',
                    trailerDrop = {
                        label = 'La Puerta Construction Area',
                        coords = vector3(-475.75, -875.32, 23.77),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Site Foreman',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(-471.07, -865.85, 23.96, 167.02),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'STD Contractors - La Puerta Site',
                    pickupDepot = 'docks',
                    trailerKey = 'flatbed_lift_equipment',
                    trailerContents = 'Construction Lift Components',
                    routeLength = '2.40 mi',
                    trailerDrop = {
                        label = 'La Puerta Construction Area',
                        coords = vector3(-475.75, -875.32, 23.77),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Site Foreman',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(-471.07, -865.85, 23.96, 167.02),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'YOU TOOL Freight',
                    pickupDepot = 'docks',
                    trailerKey = 'flatbed_plywood',
                    trailerContents = 'Construction Materials - Plywood',
                    routeLength = '5.0 mi',
                    trailerDrop = {
                        label = 'You Tool Receiving Area',
                        coords = vector3(2673.64, 3518.09, 52.72),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Warehouse Manager',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(2681.74, 3514.88, 53.31, 76.44),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'YOU TOOL Freight',
                    pickupDepot = 'docks',
                    trailerKey = 'flatbed_plywood2',
                    trailerContents = 'Construction Materials - Plywood',
                    routeLength = '5.0 mi',
                    trailerDrop = {
                        label = 'You Tool Receiving Area',
                        coords = vector3(2673.64, 3518.09, 52.72),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Warehouse Manager',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(2681.74, 3514.88, 53.31, 76.44),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'YOU TOOL Freight',
                    pickupDepot = 'docks',
                    trailerKey = 'flatbed_woodpile',
                    trailerContents = 'Construction Materials - Lumber',
                    routeLength = '5.0 mi',
                    trailerDrop = {
                        label = 'You Tool Receiving Area',
                        coords = vector3(2673.64, 3518.09, 52.72),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Warehouse Manager',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(2681.74, 3514.88, 53.31, 76.44),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'YOU TOOL Freight',
                    pickupDepot = 'docks',
                    trailerKey = 'flatbed_woodpile2',
                    trailerContents = 'Construction Materials - Boxes',
                    routeLength = '5.0 mi',
                    trailerDrop = {
                        label = 'You Tool Receiving Area',
                        coords = vector3(2673.64, 3518.09, 52.72),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Warehouse Manager',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(2681.74, 3514.88, 53.31, 76.44),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'YOU TOOL Freight',
                    pickupDepot = 'docks',
                    trailerKey = 'flatbed_woodpile3',
                    trailerContents = 'Construction Materials - Wood Beams',
                    routeLength = '5.0 mi',
                    trailerDrop = {
                        label = 'You Tool Receiving Area',
                        coords = vector3(2673.64, 3518.09, 52.72),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Warehouse Manager',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(2681.74, 3514.88, 53.31, 76.44),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'YOU TOOL Freight',
                    pickupDepot = 'docks',
                    trailerKey = 'cement_bags',
                    trailerContents = 'Construction Materials - Cement Mix',
                    routeLength = '5.0 mi',
                    trailerDrop = {
                        label = 'You Tool Receiving Area',
                        coords = vector3(2673.64, 3518.09, 52.72),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Warehouse Manager',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(2681.74, 3514.88, 53.31, 76.44),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'YOU TOOL Freight',
                    pickupDepot = 'docks',
                    trailerKey = 'tarp_cargo1',
                    trailerContents = 'Misc. Freight',
                    routeLength = '5.0 mi',
                    trailerDrop = {
                        label = 'You Tool Receiving Area',
                        coords = vector3(2673.64, 3518.09, 52.72),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Warehouse Manager',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(2681.74, 3514.88, 53.31, 76.44),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'YOU TOOL Freight',
                    pickupDepot = 'docks',
                    trailerKey = 'tarp_cargo2',
                    trailerContents = 'Misc. Freight',
                    routeLength = '5.0 mi',
                    trailerDrop = {
                        label = 'You Tool Receiving Area',
                        coords = vector3(2673.64, 3518.09, 52.72),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Warehouse Manager',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(2681.74, 3514.88, 53.31, 76.44),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'YOU TOOL Freight',
                    pickupDepot = 'lsport',
                    trailerKey = 'flatbed_plywood2',
                    trailerContents = 'Construction Materials - Plywood',
                    routeLength = '5.2 mi',
                    trailerDrop = {
                        label = 'You Tool Receiving Area',
                        coords = vector3(2673.64, 3518.09, 52.72),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Warehouse Manager',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(2681.74, 3514.88, 53.31, 76.44),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'YOU TOOL Freight',
                    pickupDepot = 'lsport',
                    trailerKey = 'flatbed_plywood2',
                    trailerContents = 'Construction Materials - Plywood',
                    routeLength = '5.2 mi',
                    trailerDrop = {
                        label = 'You Tool Receiving Area',
                        coords = vector3(2673.64, 3518.09, 52.72),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Warehouse Manager',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(2681.74, 3514.88, 53.31, 76.44),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'YOU TOOL Freight',
                    pickupDepot = 'lsport',
                    trailerKey = 'flatbed_woodpile',
                    trailerContents = 'Construction Materials - Lumber',
                    routeLength = '5.2 mi',
                    trailerDrop = {
                        label = 'You Tool Receiving Area',
                        coords = vector3(2673.64, 3518.09, 52.72),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Warehouse Manager',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(2681.74, 3514.88, 53.31, 76.44),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'YOU TOOL Freight',
                    pickupDepot = 'lsport',
                    trailerKey = 'flatbed_woodpile2',
                    trailerContents = 'Construction Materials - Boxes',
                    routeLength = '5.2 mi',
                    trailerDrop = {
                        label = 'You Tool Receiving Area',
                        coords = vector3(2673.64, 3518.09, 52.72),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Warehouse Manager',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(2681.74, 3514.88, 53.31, 76.44),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'YOU TOOL Freight',
                    pickupDepot = 'lsport',
                    trailerKey = 'flatbed_woodpile3',
                    trailerContents = 'Construction Materials - Wood Beams',
                    routeLength = '5.2 mi',
                    trailerDrop = {
                        label = 'You Tool Receiving Area',
                        coords = vector3(2673.64, 3518.09, 52.72),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Warehouse Manager',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(2681.74, 3514.88, 53.31, 76.44),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'YOU TOOL Freight',
                    pickupDepot = 'lsport',
                    trailerKey = 'cement_bags',
                    trailerContents = 'Construction Materials - Cement Mix',
                    routeLength = '5.2 mi',
                    trailerDrop = {
                        label = 'You Tool Receiving Area',
                        coords = vector3(2673.64, 3518.09, 52.72),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Warehouse Manager',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(2681.74, 3514.88, 53.31, 76.44),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'YOU TOOL Freight',
                    pickupDepot = 'lsport',
                    trailerKey = 'tarp_cargo1',
                    trailerContents = 'Misc. Freight',
                    routeLength = '5.2 mi',
                    trailerDrop = {
                        label = 'You Tool Receiving Area',
                        coords = vector3(2673.64, 3518.09, 52.72),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Warehouse Manager',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(2681.74, 3514.88, 53.31, 76.44),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'YOU TOOL Freight',
                    pickupDepot = 'lsport',
                    trailerKey = 'tarp_cargo2',
                    trailerContents = 'Misc. Freight',
                    routeLength = '5.2 mi',
                    trailerDrop = {
                        label = 'You Tool Receiving Area',
                        coords = vector3(2673.64, 3518.09, 52.72),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Warehouse Manager',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(2681.74, 3514.88, 53.31, 76.44),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                -- reds auto paleto
                {
                    label = 'Reds Auto Freight',
                    pickupDepot = 'lsport',
                    trailerKey = 'flatbed_plywood2',
                    trailerContents = 'Construction Materials - Plywood',
                    routeLength = '8.5 mi',
                    trailerDrop = {
                        label = 'Reds Auto Receiving Area',
                        coords = vector3(-194.74, 6276.57, 31.49),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Warehouse Manager',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(-195.72, 6265.81, 31.49, 3.08),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Reds Auto Freight',
                    pickupDepot = 'lsport',
                    trailerKey = 'flatbed_plywood2',
                    trailerContents = 'Construction Materials - Plywood',
                    routeLength = '8.5 mi',
                    trailerDrop = {
                        label = 'Reds Auto Receiving Area',
                        coords = vector3(-194.74, 6276.57, 31.49),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Warehouse Manager',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(-195.72, 6265.81, 31.49, 3.08),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Reds Auto Freight',
                    pickupDepot = 'lsport',
                    trailerKey = 'flatbed_woodpile',
                    trailerContents = 'Construction Materials - Lumber',
                    routeLength = '8.5 mi',
                    trailerDrop = {
                        label = 'Reds Auto Receiving Area',
                        coords = vector3(-194.74, 6276.57, 31.49),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Warehouse Manager',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(-195.72, 6265.81, 31.49, 3.08),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Reds Auto Freight',
                    pickupDepot = 'lsport',
                    trailerKey = 'flatbed_woodpile2',
                    trailerContents = 'Construction Materials - Boxes',
                    routeLength = '8.5 mi',
                    trailerDrop = {
                        label = 'Reds Auto Receiving Area',
                        coords = vector3(-194.74, 6276.57, 31.49),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Warehouse Manager',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(-195.72, 6265.81, 31.49, 3.08),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Reds Auto Freight',
                    pickupDepot = 'lsport',
                    trailerKey = 'flatbed_woodpile3',
                    trailerContents = 'Construction Materials - Wood Beams',
                    routeLength = '8.5 mi',
                    trailerDrop = {
                        label = 'Reds Auto Receiving Area',
                        coords = vector3(-194.74, 6276.57, 31.49),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Warehouse Manager',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(-195.72, 6265.81, 31.49, 3.08),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Reds Auto Freight',
                    pickupDepot = 'lsport',
                    trailerKey = 'cement_bags',
                    trailerContents = 'Construction Materials - Cement Mix',
                    routeLength = '8.5 mi',
                    trailerDrop = {
                        label = 'Reds Auto Receiving Area',
                        coords = vector3(-194.74, 6276.57, 31.49),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Warehouse Manager',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(-195.72, 6265.81, 31.49, 3.08),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Reds Auto Freight',
                    pickupDepot = 'lsport',
                    trailerKey = 'tarp_cargo1',
                    trailerContents = 'Misc. Freight',
                    routeLength = '8.5 mi',
                    trailerDrop = {
                        label = 'Reds Auto Receiving Area',
                        coords = vector3(-194.74, 6276.57, 31.49),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Warehouse Manager',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(-195.72, 6265.81, 31.49, 3.08),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Reds Auto Freight',
                    pickupDepot = 'lsport',
                    trailerKey = 'tarp_cargo2',
                    trailerContents = 'Misc. Freight',
                    routeLength = '8.5 mi',
                    trailerDrop = {
                        label = 'Reds Auto Receiving Area',
                        coords = vector3(-194.74, 6276.57, 31.49),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Warehouse Manager',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(-195.72, 6265.81, 31.49, 3.08),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                -- morris and sons feed supply
                {
                    label = 'Morris & Sons Supply Freight',
                    pickupDepot = 'lsport',
                    trailerKey = 'flatbed_plywood2',
                    trailerContents = 'Construction Materials - Plywood',
                    routeLength = '8.2 mi',
                    trailerDrop = {
                        label = 'Morris & Sons Receiving Area',
                        coords = vector3(-35.78, 6363.18, 31.3),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Warehouse Manager',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(-51.69, 6359.46, 31.45, 254.72),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Morris & Sons Supply Freight',
                    pickupDepot = 'lsport',
                    trailerKey = 'flatbed_plywood2',
                    trailerContents = 'Construction Materials - Plywood',
                    routeLength = '8.2 mi',
                    trailerDrop = {
                        label = 'Morris & Sons Receiving Area',
                        coords = vector3(-35.78, 6363.18, 31.3),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Warehouse Manager',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(-51.69, 6359.46, 31.45, 254.72),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Morris & Sons Supply Freight',
                    pickupDepot = 'lsport',
                    trailerKey = 'flatbed_woodpile',
                    trailerContents = 'Construction Materials - Lumber',
                    routeLength = '8.2 mi',
                    trailerDrop = {
                        label = 'Morris & Sons Receiving Area',
                        coords = vector3(-35.78, 6363.18, 31.3),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Warehouse Manager',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(-51.69, 6359.46, 31.45, 254.72),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Morris & Sons Supply Freight',
                    pickupDepot = 'lsport',
                    trailerKey = 'flatbed_woodpile2',
                    trailerContents = 'Construction Materials - Boxes',
                    routeLength = '8.2 mi',
                    trailerDrop = {
                        label = 'Morris & Sons Receiving Area',
                        coords = vector3(-35.78, 6363.18, 31.3),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Warehouse Manager',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(-51.69, 6359.46, 31.45, 254.72),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Morris & Sons Supply Freight',
                    pickupDepot = 'lsport',
                    trailerKey = 'flatbed_woodpile3',
                    trailerContents = 'Construction Materials - Wood Beams',
                    routeLength = '8.2 mi',
                    trailerDrop = {
                        label = 'Morris & Sons Receiving Area',
                        coords = vector3(-35.78, 6363.18, 31.3),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Warehouse Manager',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(-51.69, 6359.46, 31.45, 254.72),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Morris & Sons Supply Freight',
                    pickupDepot = 'lsport',
                    trailerKey = 'cement_bags',
                    trailerContents = 'Construction Materials - Cement Mix',
                    routeLength = '8.2 mi',
                    trailerDrop = {
                        label = 'Morris & Sons Receiving Area',
                        coords = vector3(-35.78, 6363.18, 31.3),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Warehouse Manager',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(-51.69, 6359.46, 31.45, 254.72),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Morris & Sons Supply Freight',
                    pickupDepot = 'lsport',
                    trailerKey = 'tarp_cargo1',
                    trailerContents = 'Misc. Freight',
                    routeLength = '8.2 mi',
                    trailerDrop = {
                        label = 'Morris & Sons Receiving Area',
                        coords = vector3(-35.78, 6363.18, 31.3),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Warehouse Manager',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(-51.69, 6359.46, 31.45, 254.72),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Morris & Sons Supply Freight',
                    pickupDepot = 'lsport',
                    trailerKey = 'tarp_cargo2',
                    trailerContents = 'Misc. Freight',
                    routeLength = '8.2 mi',
                    trailerDrop = {
                        label = 'Morris & Sons Receiving Area',
                        coords = vector3(-35.78, 6363.18, 31.3),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Warehouse Manager',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(-51.69, 6359.46, 31.45, 254.72),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                -- clucking bell farms construction
                {
                    label = 'Clucking Bell Construction',
                    pickupDepot = 'lsport',
                    trailerKey = 'flatbed_plywood2',
                    trailerContents = 'Construction Materials - Plywood',
                    routeLength = '8.2 mi',
                    trailerDrop = {
                        label = 'Clucking Bell Construction Area',
                        coords = vector3(122.81, 6416.71, 31.35),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Site Supervisor',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(122.48, 6406.74, 31.37, 319.57),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Clucking Bell Construction',
                    pickupDepot = 'lsport',
                    trailerKey = 'flatbed_plywood2',
                    trailerContents = 'Construction Materials - Plywood',
                    routeLength = '8.2 mi',
                    trailerDrop = {
                        label = 'Clucking Bell Construction Area',
                        coords = vector3(122.81, 6416.71, 31.35),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Site Supervisor',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(122.48, 6406.74, 31.37, 319.57),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Clucking Bell Construction',
                    pickupDepot = 'lsport',
                    trailerKey = 'flatbed_woodpile',
                    trailerContents = 'Construction Materials - Lumber',
                    routeLength = '8.2 mi',
                    trailerDrop = {
                        label = 'Clucking Bell Construction Area',
                        coords = vector3(122.81, 6416.71, 31.35),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Site Supervisor',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(122.48, 6406.74, 31.37, 319.57),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Clucking Bell Construction',
                    pickupDepot = 'lsport',
                    trailerKey = 'flatbed_woodpile2',
                    trailerContents = 'Construction Materials - Boxes',
                    routeLength = '8.2 mi',
                    trailerDrop = {
                        label = 'Clucking Bell Construction Area',
                        coords = vector3(122.81, 6416.71, 31.35),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Site Supervisor',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(122.48, 6406.74, 31.37, 319.57),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Clucking Bell Construction',
                    pickupDepot = 'lsport',
                    trailerKey = 'flatbed_woodpile3',
                    trailerContents = 'Construction Materials - Wood Beams',
                    routeLength = '8.2 mi',
                    trailerDrop = {
                        label = 'Clucking Bell Construction Area',
                        coords = vector3(122.81, 6416.71, 31.35),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Site Supervisor',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(122.48, 6406.74, 31.37, 319.57),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Clucking Bell Construction',
                    pickupDepot = 'lsport',
                    trailerKey = 'cement_bags',
                    trailerContents = 'Construction Materials - Cement Mix',
                    routeLength = '8.2 mi',
                    trailerDrop = {
                        label = 'Clucking Bell Construction Area',
                        coords = vector3(122.81, 6416.71, 31.35),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Site Supervisor',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(122.48, 6406.74, 31.37, 319.57),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Clucking Bell Construction',
                    pickupDepot = 'lsport',
                    trailerKey = 'tarp_cargo1',
                    trailerContents = 'Misc. Freight',
                    routeLength = '8.2 mi',
                    trailerDrop = {
                        label = 'Clucking Bell Construction Area',
                        coords = vector3(122.81, 6416.71, 31.35),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Site Supervisor',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(122.48, 6406.74, 31.37, 319.57),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Clucking Bell Construction',
                    pickupDepot = 'lsport',
                    trailerKey = 'tarp_cargo2',
                    trailerContents = 'Misc. Freight',
                    routeLength = '8.2 mi',
                    trailerDrop = {
                        label = 'Clucking Bell Construction Area',
                        coords = vector3(122.81, 6416.71, 31.35),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Site Supervisor',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(122.48, 6406.74, 31.37, 319.57),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Clucking Bell Construction',
                    pickupDepot = 'docks',
                    trailerKey = 'flatbed_plywood2',
                    trailerContents = 'Construction Materials - Plywood',
                    routeLength = '8.4 mi',
                    trailerDrop = {
                        label = 'Clucking Bell Construction Area',
                        coords = vector3(122.81, 6416.71, 31.35),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Site Supervisor',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(122.48, 6406.74, 31.37, 319.57),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Clucking Bell Construction',
                    pickupDepot = 'docks',
                    trailerKey = 'flatbed_plywood2',
                    trailerContents = 'Construction Materials - Plywood',
                    routeLength = '8.4 mi',
                    trailerDrop = {
                        label = 'Clucking Bell Construction Area',
                        coords = vector3(122.81, 6416.71, 31.35),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Site Supervisor',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(122.48, 6406.74, 31.37, 319.57),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Clucking Bell Construction',
                    pickupDepot = 'docks',
                    trailerKey = 'flatbed_woodpile',
                    trailerContents = 'Construction Materials - Lumber',
                    routeLength = '8.4 mi',
                    trailerDrop = {
                        label = 'Clucking Bell Construction Area',
                        coords = vector3(122.81, 6416.71, 31.35),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Site Supervisor',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(122.48, 6406.74, 31.37, 319.57),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Clucking Bell Construction',
                    pickupDepot = 'docks',
                    trailerKey = 'flatbed_woodpile2',
                    trailerContents = 'Construction Materials - Boxes',
                    routeLength = '8.4 mi',
                    trailerDrop = {
                        label = 'Clucking Bell Construction Area',
                        coords = vector3(122.81, 6416.71, 31.35),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Site Supervisor',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(122.48, 6406.74, 31.37, 319.57),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Clucking Bell Construction',
                    pickupDepot = 'docks',
                    trailerKey = 'flatbed_woodpile3',
                    trailerContents = 'Construction Materials - Wood Beams',
                    routeLength = '8.4 mi',
                    trailerDrop = {
                        label = 'Clucking Bell Construction Area',
                        coords = vector3(122.81, 6416.71, 31.35),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Site Supervisor',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(122.48, 6406.74, 31.37, 319.57),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Clucking Bell Construction',
                    pickupDepot = 'docks',
                    trailerKey = 'cement_bags',
                    trailerContents = 'Construction Materials - Cement Mix',
                    routeLength = '8.4 mi',
                    trailerDrop = {
                        label = 'Clucking Bell Construction Area',
                        coords = vector3(122.81, 6416.71, 31.35),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Site Supervisor',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(122.48, 6406.74, 31.37, 319.57),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Clucking Bell Construction',
                    pickupDepot = 'docks',
                    trailerKey = 'tarp_cargo1',
                    trailerContents = 'Misc. Freight',
                    routeLength = '8.4 mi',
                    trailerDrop = {
                        label = 'Clucking Bell Construction Area',
                        coords = vector3(122.81, 6416.71, 31.35),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Site Supervisor',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(122.48, 6406.74, 31.37, 319.57),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Clucking Bell Construction',
                    pickupDepot = 'docks',
                    trailerKey = 'tarp_cargo2',
                    trailerContents = 'Misc. Freight',
                    routeLength = '8.4 mi',
                    trailerDrop = {
                        label = 'Clucking Bell Construction Area',
                        coords = vector3(122.81, 6416.71, 31.35),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Site Supervisor',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(122.48, 6406.74, 31.37, 319.57),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },

                -- Bilgeco Shipping
                {
                    label = 'Bilgeco Shipping Services',
                    pickupDepot = 'harmony',
                    trailerKey = 'cartrailer',
                    trailerContents = 'Empty Car Hauler',
                    routeLength = '4.5 mi',
                    trailerDrop = {
                        label = 'Bilgeco Storage Facility',
                        coords = vector3(-1157.21, -2180.61, 13.2),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Warehouse Supervisor',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(-1147.58, -2178.13, 13.38, 106.01),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },

                -- Redwood Lights Track
                {
                    label = 'Redwood Lights Track Haul',
                    pickupDepot = 'docks',
                    trailerKey = 'flatbed_woodpile',
                    trailerContents = 'Construction Materials - Lumber',
                    routeLength = '4.5 mi',
                    trailerDrop = {
                        label = 'Contractor Office Area',
                        coords = vector3(1218.28, 2387.59, 65.46),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Material Handler',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(1218.91, 2396.93, 66.07, 178.18),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Redwood Lights Track Haul',
                    pickupDepot = 'docks',
                    trailerKey = 'flatbed_woodpile2',
                    trailerContents = 'Construction Materials - Boxes',
                    routeLength = '4.5 mi',
                    trailerDrop = {
                        label = 'Contractor Office Area',
                        coords = vector3(1218.28, 2387.59, 65.46),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Material Handler',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(1218.91, 2396.93, 66.07, 178.18),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Redwood Lights Track Haul',
                    pickupDepot = 'docks',
                    trailerKey = 'flatbed_woodpile3',
                    trailerContents = 'Construction Materials - Wood Beams',
                    routeLength = '4.5 mi',
                    trailerDrop = {
                        label = 'Contractor Office Area',
                        coords = vector3(1218.28, 2387.59, 65.46),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Material Handler',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(1218.91, 2396.93, 66.07, 178.18),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Redwood Lights Track Haul',
                    pickupDepot = 'docks',
                    trailerKey = 'heavy_mixer',
                    trailerContents = 'HVY Mixer',
                    routeLength = '4.5 mi',
                    trailerDrop = {
                        label = 'Contractor Office Area',
                        coords = vector3(1218.28, 2387.59, 65.46),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Material Handler',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(1218.91, 2396.93, 66.07, 178.18),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Redwood Lights Track Haul',
                    pickupDepot = 'docks',
                    trailerKey = 'flatbed_plywood',
                    trailerContents = 'Construction Materials - Plywood',
                    routeLength = '4.5 mi',
                    trailerDrop = {
                        label = 'Contractor Office Area',
                        coords = vector3(1218.28, 2387.59, 65.46),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Material Handler',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(1218.91, 2396.93, 66.07, 178.18),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Redwood Lights Track Haul',
                    pickupDepot = 'docks',
                    trailerKey = 'flatbed_plywood2',
                    trailerContents = 'Construction Materials - Plywood',
                    routeLength = '4.5 mi',
                    trailerDrop = {
                        label = 'Contractor Office Area',
                        coords = vector3(1218.28, 2387.59, 65.46),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Material Handler',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(1218.91, 2396.93, 66.07, 178.18),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Redwood Lights Track Haul',
                    pickupDepot = 'lsport',
                    trailerKey = 'flatbed_woodpile',
                    trailerContents = 'Construction Materials - Lumber',
                    routeLength = '4.4 mi',
                    trailerDrop = {
                        label = 'Contractor Office Area',
                        coords = vector3(1218.28, 2387.59, 65.46),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Material Handler',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(1218.91, 2396.93, 66.07, 178.18),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Redwood Lights Track Haul',
                    pickupDepot = 'lsport',
                    trailerKey = 'flatbed_woodpile2',
                    trailerContents = 'Construction Materials - Boxes',
                    routeLength = '4.4 mi',
                    trailerDrop = {
                        label = 'Contractor Office Area',
                        coords = vector3(1218.28, 2387.59, 65.46),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Material Handler',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(1218.91, 2396.93, 66.07, 178.18),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Redwood Lights Track Haul',
                    pickupDepot = 'lsport',
                    trailerKey = 'flatbed_woodpile3',
                    trailerContents = 'Construction Materials - Wood Beams',
                    routeLength = '4.4 mi',
                    trailerDrop = {
                        label = 'Contractor Office Area',
                        coords = vector3(1218.28, 2387.59, 65.46),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Material Handler',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(1218.91, 2396.93, 66.07, 178.18),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Redwood Lights Track Haul',
                    pickupDepot = 'lsport',
                    trailerKey = 'heavy_mixer',
                    trailerContents = 'HVY Mixer',
                    routeLength = '4.4 mi',
                    trailerDrop = {
                        label = 'Contractor Office Area',
                        coords = vector3(1218.28, 2387.59, 65.46),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Material Handler',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(1218.91, 2396.93, 66.07, 178.18),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Redwood Lights Track Haul',
                    pickupDepot = 'lsport',
                    trailerKey = 'flatbed_plywood',
                    trailerContents = 'Construction Materials - Plywood',
                    routeLength = '4.4 mi',
                    trailerDrop = {
                        label = 'Contractor Office Area',
                        coords = vector3(1218.28, 2387.59, 65.46),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Material Handler',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(1218.91, 2396.93, 66.07, 178.18),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Redwood Lights Track Haul',
                    pickupDepot = 'lsport',
                    trailerKey = 'flatbed_plywood2',
                    trailerContents = 'Construction Materials - Plywood',
                    routeLength = '4.4 mi',
                    trailerDrop = {
                        label = 'Contractor Office Area',
                        coords = vector3(1218.28, 2387.59, 65.46),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Material Handler',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(1218.91, 2396.93, 66.07, 178.18),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },

                -- Road Construction - Heavy Equipment
                {
                    label = 'Great Ocean Road Construction',
                    pickupDepot = 'lsport',
                    trailerKey = 'heavy_dozer',
                    trailerContents = 'HVY Bulldozer',
                    routeLength = '6.5 mi',
                    trailerDrop = {
                        label = 'North Chumash GOH Road Project',
                        coords = vector3(-2354.93, 4094.6, 33.4),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Site Foreman',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(-2348.37, 4110.37, 34.95, 177.9),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Great Ocean Road Construction',
                    pickupDepot = 'lsport',
                    trailerKey = 'heavy_mixer',
                    trailerContents = 'HVY Mixer',
                    routeLength = '6.5 mi',
                    trailerDrop = {
                        label = 'North Chumash GOH Road Project',
                        coords = vector3(-2354.93, 4094.6, 33.4),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Site Foreman',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(-2348.37, 4110.37, 34.95, 177.9),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Great Ocean Road Construction',
                    pickupDepot = 'lsport',
                    trailerKey = 'conc_barriers2',
                    trailerContents = 'Concrete Construction Barriers',
                    routeLength = '6.5 mi',
                    trailerDrop = {
                        label = 'North Chumash GOH Road Project',
                        coords = vector3(-2354.93, 4094.6, 33.4),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Site Foreman',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(-2348.37, 4110.37, 34.95, 177.9),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Great Ocean Road Construction',
                    pickupDepot = 'lsport',
                    trailerKey = 'conc_barriers',
                    trailerContents = 'Concrete Construction Barriers',
                    routeLength = '6.5 mi',
                    trailerDrop = {
                        label = 'North Chumash GOH Road Project',
                        coords = vector3(-2354.93, 4094.6, 33.4),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Site Foreman',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(-2348.37, 4110.37, 34.95, 177.9),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Great Ocean Road Construction',
                    pickupDepot = 'lsport',
                    trailerKey = 'heavy_roadheader',
                    trailerContents = 'Road Resurface Header',
                    routeLength = '6.5 mi',
                    trailerDrop = {
                        label = 'North Chumash GOH Road Project',
                        coords = vector3(-2354.93, 4094.6, 33.4),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Site Foreman',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(-2348.37, 4110.37, 34.95, 177.9),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Great Ocean Road Construction',
                    pickupDepot = 'docks',
                    trailerKey = 'heavy_dozer',
                    trailerContents = 'HVY Bulldozer',
                    routeLength = '6.9 mi',
                    trailerDrop = {
                        label = 'North Chumash GOH Road Project',
                        coords = vector3(-2354.93, 4094.6, 33.4),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Site Foreman',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(-2348.37, 4110.37, 34.95, 177.9),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Great Ocean Road Construction',
                    pickupDepot = 'docks',
                    trailerKey = 'heavy_roadheader',
                    trailerContents = 'Road Resurface Header',
                    routeLength = '6.9 mi',
                    trailerDrop = {
                        label = 'North Chumash GOH Road Project',
                        coords = vector3(-2354.93, 4094.6, 33.4),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Site Foreman',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(-2348.37, 4110.37, 34.95, 177.9),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'North Calafia Construction',
                    pickupDepot = 'docks',
                    trailerKey = 'heavy_dozer',
                    trailerContents = 'HVY Bulldozer',
                    routeLength = '6.4 mi',
                    trailerDrop = {
                        label = 'North Calafia Project',
                        coords = vector3(356.05, 4442.13, 62.96),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Site Foreman',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(349.14, 4431.04, 63.62, 290.85),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'North Calafia Construction',
                    pickupDepot = 'lsport',
                    trailerKey = 'heavy_dozer',
                    trailerContents = 'HVY Bulldozer',
                    routeLength = '6.4 mi',
                    trailerDrop = {
                        label = 'North Calafia Project',
                        coords = vector3(356.05, 4442.13, 62.96),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Site Foreman',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(349.14, 4431.04, 63.62, 290.85),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Los Santos Heavy Equipment Haul',
                    pickupDepot = 'lsport',
                    trailerKey = 'heavy_dozer',
                    trailerContents = 'HVY Bulldozer',
                    routeLength = '1.8 mi',
                    trailerDrop = {
                        label = 'Los Santos Equipment Co',
                        coords = vector3(949.25, -1576.14, 30.4),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Site Foreman',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(947.82, -1570.78, 30.52, 182.98),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Los Santos Heavy Equipment Haul',
                    pickupDepot = 'lsport',
                    trailerKey = 'heavy_mixer',
                    trailerContents = 'HVY Mixer',
                    routeLength = '1.8 mi',
                    trailerDrop = {
                        label = 'Los Santos Equipment Co',
                        coords = vector3(949.25, -1576.14, 30.4),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Site Foreman',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(947.82, -1570.78, 30.52, 182.98),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Los Santos Heavy Equipment Haul',
                    pickupDepot = 'lsport',
                    trailerKey = 'heavy_roadheader',
                    trailerContents = 'Road Resurface Header',
                    routeLength = '1.8 mi',
                    trailerDrop = {
                        label = 'Los Santos Equipment Co',
                        coords = vector3(949.25, -1576.14, 30.4),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Site Foreman',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(947.82, -1570.78, 30.52, 182.98),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Los Santos Heavy Equipment Haul',
                    pickupDepot = 'docks',
                    trailerKey = 'heavy_dozer',
                    trailerContents = 'HVY Bulldozer',
                    routeLength = '1.9 mi',
                    trailerDrop = {
                        label = 'Los Santos Equipment Co',
                        coords = vector3(949.25, -1576.14, 30.4),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Site Foreman',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(947.82, -1570.78, 30.52, 182.98),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Los Santos Heavy Equipment Haul',
                    pickupDepot = 'docks',
                    trailerKey = 'heavy_mixer',
                    trailerContents = 'HVY Mixer',
                    routeLength = '1.9 mi',
                    trailerDrop = {
                        label = 'Los Santos Equipment Co',
                        coords = vector3(949.25, -1576.14, 30.4),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Site Foreman',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(947.82, -1570.78, 30.52, 182.98),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Los Santos Heavy Equipment Haul',
                    trailerKey = 'heavy_roadheader',
                    trailerContents = 'Road Resurface Header',
                    trailerContents = 'HVY Mixer',
                    routeLength = '1.9 mi',
                    trailerDrop = {
                        label = 'Los Santos Equipment Co',
                        coords = vector3(949.25, -1576.14, 30.4),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Site Foreman',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(947.82, -1570.78, 30.52, 182.98),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Los Santos Heavy Equipment Haul',
                    pickupDepot = 'harmony',
                    trailerKey = 'heavy_dozer',
                    trailerContents = 'HVY Bulldozer',
                    routeLength = '3.5 mi',
                    trailerDrop = {
                        label = 'Los Santos Equipment Co',
                        coords = vector3(949.25, -1576.14, 30.4),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Site Foreman',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(947.82, -1570.78, 30.52, 182.98),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Los Santos Heavy Equipment Haul',
                    pickupDepot = 'harmony',
                    trailerKey = 'heavy_mixer',
                    trailerContents = 'HVY Mixer',
                    routeLength = '3.5 mi',
                    trailerDrop = {
                        label = 'Los Santos Equipment Co',
                        coords = vector3(949.25, -1576.14, 30.4),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Site Foreman',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(947.82, -1570.78, 30.52, 182.98),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Los Santos Heavy Equipment Haul',
                    pickupDepot = 'harmony',
                    trailerKey = 'heavy_roadheader',
                    trailerContents = 'Road Resurface Header',
                    routeLength = '3.5 mi',
                    trailerDrop = {
                        label = 'Los Santos Equipment Co',
                        coords = vector3(949.25, -1576.14, 30.4),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Site Foreman',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(947.82, -1570.78, 30.52, 182.98),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                -- Secure Unit
                {
                    label = 'The Secure Unit Transfer',
                    pickupDepot = 'harmony',
                    trailerKey = 'cartrailer',
                    trailerContents = 'Empty Car Hauler',
                    routeLength = '3.3 mi',
                    trailerDrop = {
                        label = 'The Secure Unit - Storage Facility',
                        coords = vector3(886.11, -1250.97, 26.07),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Warehouse Supervisor',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(894.42, -1258.19, 25.88, 355.29),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'The Secure Unit Transfer',
                    pickupDepot = 'docks',
                    trailerKey = 'cartrailer',
                    trailerContents = 'Empty Car Hauler',
                    routeLength = '2.0 mi',
                    trailerDrop = {
                        label = 'The Secure Unit - Storage Facility',
                        coords = vector3(886.11, -1250.97, 26.07),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Warehouse Supervisor',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(894.42, -1258.19, 25.88, 355.29),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'The Secure Unit Transfer',
                    pickupDepot = 'lsport',
                    trailerKey = 'cartrailer',
                    trailerContents = 'Empty Car Hauler',
                    routeLength = '1.9 mi',
                    trailerDrop = {
                        label = 'The Secure Unit - Storage Facility',
                        coords = vector3(886.11, -1250.97, 26.07),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Warehouse Supervisor',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(894.42, -1258.19, 25.88, 355.29),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                -- Pier 400 
                {
                    label = 'Pier 400 Logistics',
                    pickupDepot = 'harmony',
                    trailerKey = 'heavy_dock_crane',
                    trailerContents = 'HVY Dock Crane (Main Frame)',
                    routeLength = '4.5 mi',
                    trailerDrop = {
                        label = 'Pier 400 - Receiving',
                        coords = vector3(-70.22, -2447.32, 6.01),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Yard Technician',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(-61.64, -2446.44, 6.0, 156.68),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Pier 400 Logistics',
                    pickupDepot = 'harmony',
                    trailerKey = 'heavy_dock_truck',
                    trailerContents = 'Dock Crane Trucks',
                    routeLength = '4.5 mi',
                    trailerDrop = {
                        label = 'Pier 400 - Receiving',
                        coords = vector3(-70.22, -2447.32, 6.01),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Yard Technician',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(-61.64, -2446.44, 6.0, 156.68),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Pier 400 Logistics',
                    pickupDepot = 'harmony',
                    trailerKey = 'heavy_dock_lift',
                    trailerContents = 'Dock Crane Lift Cages',
                    routeLength = '4.5 mi',
                    trailerDrop = {
                        label = 'Pier 400 - Receiving',
                        coords = vector3(-70.22, -2447.32, 6.01),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Yard Technician',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(-61.64, -2446.44, 6.0, 156.68),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Pier 400 Logistics',
                    pickupDepot = 'harmony',
                    trailerKey = 'flatbed_lift_equipment',
                    trailerContents = 'Construction Lift Components',
                    routeLength = '4.5 mi',
                    trailerDrop = {
                        label = 'Pier 400 - Receiving',
                        coords = vector3(-70.22, -2447.32, 6.01),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Yard Technician',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(-61.64, -2446.44, 6.0, 156.68),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Pier 400 Logistics',
                    pickupDepot = 'harmony',
                    trailerKey = 'flatbed_tanks2',
                    trailerContents = 'Tank',
                    routeLength = '4.5 mi',
                    trailerDrop = {
                        label = 'Pier 400 - Receiving',
                        coords = vector3(-70.22, -2447.32, 6.01),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Yard Technician',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(-61.64, -2446.44, 6.0, 156.68),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Pier 400 Logistics',
                    pickupDepot = 'harmony',
                    trailerKey = 'flatbed_tanks',
                    trailerContents = 'Tank',
                    routeLength = '4.5 mi',
                    trailerDrop = {
                        label = 'Pier 400 - Receiving',
                        coords = vector3(-70.22, -2447.32, 6.01),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Yard Technician',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(-61.64, -2446.44, 6.0, 156.68),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Pier 400 Logistics',
                    pickupDepot = 'harmony',
                    trailerKey = 'flatbed_generators',
                    trailerContents = 'Commercial Generators',
                    routeLength = '4.5 mi',
                    trailerDrop = {
                        label = 'Pier 400 - Receiving',
                        coords = vector3(-70.22, -2447.32, 6.01),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Yard Technician',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(-61.64, -2446.44, 6.0, 156.68),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Pier 400 Logistics',
                    pickupDepot = 'harmony',
                    trailerKey = 'flatbed_generators2',
                    trailerContents = 'Industrial Generators',
                    routeLength = '4.5 mi',
                    trailerDrop = {
                        label = 'Pier 400 - Receiving',
                        coords = vector3(-70.22, -2447.32, 6.01),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Yard Technician',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(-61.64, -2446.44, 6.0, 156.68),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Pier 400 Logistics',
                    pickupDepot = 'harmony',
                    trailerKey = 'flatbed_aircon',
                    trailerContents = 'Commercial Air Conditioners',
                    routeLength = '4.5 mi',
                    trailerDrop = {
                        label = 'Pier 400 - Receiving',
                        coords = vector3(-70.22, -2447.32, 6.01),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Yard Technician',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(-61.64, -2446.44, 6.0, 156.68),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Pier 400 Logistics',
                    pickupDepot = 'harmony',
                    trailerKey = 'flatbed_carriercargo_2',
                    trailerContents = 'Construction Materials - Cargo',
                    routeLength = '4.5 mi',
                    trailerDrop = {
                        label = 'Pier 400 - Receiving',
                        coords = vector3(-70.22, -2447.32, 6.01),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Yard Technician',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(-61.64, -2446.44, 6.0, 156.68),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                -- LSIA Hanger 
                {
                    label = 'LSIA Freight Operations',
                    pickupDepot = 'harmony',
                    trailerKey = 'heavy_airport',
                    trailerContents = 'Fly US Ripley (Aircraft Tug)',
                    routeLength = '5.0 mi',
                    trailerDrop = {
                        label = 'LSIA Freight Hanger',
                        coords = vector3(-1247.44, -3386.78, 13.94),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Logistics Officer',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(-1242.45, -3391.88, 13.94, 51.9),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'LSIA Freight Operations',
                    pickupDepot = 'harmony',
                    trailerKey = 'flatbed_air_freight',
                    trailerContents = 'Air Freight Containers',
                    routeLength = '5.0 mi',
                    trailerDrop = {
                        label = 'LSIA Freight Hanger',
                        coords = vector3(-1247.44, -3386.78, 13.94),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Logistics Officer',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(-1242.45, -3391.88, 13.94, 51.9),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'LSIA Freight Operations',
                    pickupDepot = 'docks',
                    trailerKey = 'heavy_airport',
                    trailerContents = 'Fly US Ripley (Aircraft Tug)',
                    routeLength = '3.0 mi',
                    trailerDrop = {
                        label = 'LSIA Freight Hanger',
                        coords = vector3(-1247.44, -3386.78, 13.94),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Logistics Officer',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(-1242.45, -3391.88, 13.94, 51.9),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'LSIA Freight Operations',
                    pickupDepot = 'docks',
                    trailerKey = 'flatbed_air_freight',
                    trailerContents = 'Air Freight Containers',
                    routeLength = '3.0 mi',
                    trailerDrop = {
                        label = 'LSIA Freight Hanger',
                        coords = vector3(-1247.44, -3386.78, 13.94),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Logistics Officer',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(-1242.45, -3391.88, 13.94, 51.9),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'LSIA Freight Operations',
                    pickupDepot = 'lsport',
                    trailerKey = 'heavy_airport',
                    trailerContents = 'Fly US Ripley (Aircraft Tug)',
                    routeLength = '2.5 mi',
                    trailerDrop = {
                        label = 'LSIA Freight Hanger',
                        coords = vector3(-1247.44, -3386.78, 13.94),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Logistics Officer',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(-1242.45, -3391.88, 13.94, 51.9),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'LSIA Freight Operations',
                    pickupDepot = 'lsport',
                    trailerKey = 'flatbed_air_freight',
                    trailerContents = 'Air Freight Containers',
                    routeLength = '2.5 mi',
                    trailerDrop = {
                        label = 'LSIA Freight Hanger',
                        coords = vector3(-1247.44, -3386.78, 13.94),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Logistics Officer',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(-1242.45, -3391.88, 13.94, 51.9),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                -- LSDWP Canal Project
                {
                    label = 'LSDWP Logistics',
                    pickupDepot = 'lsport',
                    trailerKey = 'flatbed_woodpile',
                    trailerContents = 'Construction Materials - Lumber',
                    routeLength = '2.5 mi',
                    trailerDrop = {
                        label = 'LSDWP Canal Project',
                        coords = vector3(695.85, -1542.59, 9.71),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Logistics Officer',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(703.22, -1540.01, 9.71, 113.47),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'LSDWP Logistics',
                    pickupDepot = 'docks',
                    trailerKey = 'flatbed_woodpile',
                    trailerContents = 'Construction Materials - Lumber',
                    routeLength = '2.5 mi',
                    trailerDrop = {
                        label = 'LSDWP Canal Project',
                        coords = vector3(695.85, -1542.59, 9.71),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Logistics Officer',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(703.22, -1540.01, 9.71, 113.47),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'LSDWP Logistics',
                    pickupDepot = 'harmony',
                    trailerKey = 'flatbed_woodpile',
                    trailerContents = 'Construction Materials - Lumber',
                    routeLength = '4.5 mi',
                    trailerDrop = {
                        label = 'LSDWP Canal Project',
                        coords = vector3(695.85, -1542.59, 9.71),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Logistics Officer',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(703.22, -1540.01, 9.71, 113.47),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
        }
    }
}


-- Rank-gated service tiers shown in the dispatch UI.
-- Standard and Priority share Config.Contracts[type].routes; Priority only changes
-- rank, payout, XP, reputation, cargo, and timing behavior. Government and Military
-- tiers may define their own specialized route pools below.
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
            repBonus = 3,
            description = 'Fast same-day handling on standard parcel routes.',
            badge = 'PRIORITY',
            cargoTypes = { 'standard_package', 'standard_package2', 'standard_package3', 'standard_package4', 'gift_package' }
        },
        government = {
            order = 3,
            label = 'Government Courier Contract',
            shortLabel = 'Government',
            minRank = 5,
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
            minRank = 3,
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
            minRank = 4,
            payoutMultiplier = 1.35,
            xpMultiplier = 1.25,
            repBonus = 2,
            description = 'Time-sensitive handling on standard freight routes.',
            badge = 'PRIORITY',
            cargoTypes = { 'freight_crate', 'ammo_crate' }
        },
        government = {
            order = 3,
            label = 'Government Supply Contract',
            shortLabel = 'Government',
            minRank = 6,
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
            minRank = 7,
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
            minRank = 4,
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
            minRank = 6,
            payoutMultiplier = 1.4,
            xpMultiplier = 1.3,
            repBonus = 2,
            description = 'Priority handling and deadlines on standard trailer routes.',
            badge = 'LONG HAUL',
            defaultTrailerKey = 'reefer2'
        },
        government = {
            order = 3,
            label = 'Government Logistics Haul',
            shortLabel = 'Government',
            minRank = 7,
            payoutMultiplier = 1.95,
            xpMultiplier = 1.6,
            repBonus = 5,
            description = 'Secure trailer deliveries for state facilities and utilities.',
            badge = 'GOV',
            defaultTrailerKey = 'tanker',
            routes = {
                {
                    label = 'Palmer-Taylor Fuel Transfer',
                    pickupDepot = 'docks',
                    trailerKey = 'tanker',
                    trailerContents = 'Diesel fuel',
                    routeLength = '5.3 mi',
                    trailerDrop = {
                        label = 'Palmer-Taylor Fuel Depot',
                        coords = vector3(2672.57, 1428.12, 24.50),
                        radius = 18.0
                    },
                    receiverPed = {
                        label = 'Palmer-Taylor Receiver',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(2665.24, 1435.44, 24.50, 88.0),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'State Utility Equipment Drop',
                    pickupDepot = 'lsport',
                    trailerKey = 'freight',
                    trailerContents = 'State utility equipment',
                    routeLength = '5.8 mi',
                    trailerDrop = {
                        label = 'Palmer-Taylor Power Yard',
                        coords = vector3(2787.3, 1709.59, 24.62),
                        radius = 18.0
                    },
                    receiverPed = {
                        label = 'Utility Yard Receiver',
                        model = `s_m_m_gaffer_01`,
                        coords = vector4(2788.04, 1714.63, 24.58, 177.51),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Humane Labs Tanker Transfer',
                    pickupDepot = 'docks',
                    trailerKey = 'chemical_tanker',
                    trailerContents = 'Industrial treatment chemicals',
                    routeLength = '11.6 mi',
                    trailerDrop = {
                        label = 'Humane Labs Service Gate',
                        coords = vector3(3485.95, 3672.75, 33.89),
                        radius = 20.0
                    },
                    receiverPed = {
                        label = 'Lab Logistics Receiver',
                        model = `s_m_m_chemsec_01`,
                        coords = vector4(3493.98, 3686.11, 33.89, 134.74),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'State Event Equipment Transfer',
                    pickupDepot = 'lsport',
                    trailerKey = 'tv',
                    trailerContents = 'Emergency broadcast equipment',
                    routeLength = '5.5 mi',
                    trailerDrop = {
                        label = 'Kortz Center Service Entrance',
                        coords = vector3(-2354.91, 271.93, 166.16),
                        radius = 20.0
                    },
                    receiverPed = {
                        label = 'State Event Coordinator',
                        model = `s_m_m_highsec_01`,
                        coords = vector4(-2347.01, 263.86, 164.58, 65.86),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                }
            }
        },
        military = {
            order = 4,
            label = 'Military Haul Contract',
            shortLabel = 'Military',
            minRank = 8,
            payoutMultiplier = 2.65,
            xpMultiplier = 2.0,
            repBonus = 8,
            description = 'Restricted Fort Zancudo and military logistics contracts.',
            badge = 'MIL',
            defaultTrailerKey = 'military',
            routes = {
                {
                    label = 'Fort Zancudo Restricted Haul',
                    pickupDepot = 'lsport',
                    trailerKey = 'military',
                    trailerContents = 'Restricted military equipment',
                    routeLength = '7.4 mi',
                    trailerDrop = {
                        label = 'Fort Zancudo Maintenance Facility',
                        coords = vector3(-2451.39, 2985.36, 32.81),
                        radius = 20.0
                    },
                    receiverPed = {
                        label = 'Military Logistics Officer',
                        model = `s_m_y_marine_03`,
                        coords = vector4(-2456.15, 2974.54, 32.96, 289.37),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Fort Zancudo Restricted Haul',
                    pickupDepot = 'lsport',
                    trailerKey = 'flatbed_crates_carrier',
                    trailerContents = 'Restricted military equipment',
                    routeLength = '7.4 mi',
                    trailerDrop = {
                        label = 'Zancudo Secure Container Yard',
                        coords = vector3(-2439.79, 3346.07, 32.83),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Zancudo Security Officer',
                        model = `s_m_y_marine_02`,
                        coords = vector4(-2427.69, 3345.38, 32.98, 66.75),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Fort Zancudo Restricted Haul',
                    pickupDepot = 'lsport',
                    trailerKey = 'military_explosive_cargo',
                    trailerContents = 'Restricted military explosives',
                    routeLength = '7.4 mi',
                    trailerDrop = {
                        label = 'Zancudo Secure Container Yard',
                        coords = vector3(-2439.79, 3346.07, 32.83),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Zancudo Security Officer',
                        model = `s_m_y_marine_02`,
                        coords = vector4(-2427.69, 3345.38, 32.98, 66.75),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Fort Zancudo Restricted Haul',
                    pickupDepot = 'lsport',
                    trailerKey = 'military_flatbed_cargo',
                    trailerContents = 'Secure Military Equipment Containers',
                    routeLength = '7.4 mi',
                    trailerDrop = {
                        label = 'Zancudo Secure Container Yard',
                        coords = vector3(-2439.79, 3346.07, 32.83),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Zancudo Security Officer',
                        model = `s_m_y_marine_02`,
                        coords = vector4(-2427.69, 3345.38, 32.98, 66.75),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Zancudo Airfield Equipment Transfer',
                    pickupDepot = 'docks',
                    trailerKey = 'heavy_military',
                    trailerContents = 'Heavy airfield equipment',
                    routeLength = '7.1 mi',
                    trailerDrop = {
                        label = 'Zancudo Main Hangar',
                        coords = vector3(-1829.41, 2998.96, 32.81),
                        radius = 20.0
                    },
                    receiverPed = {
                        label = 'Zancudo Logistics Officer',
                        model = `s_m_y_marine_01`,
                        coords = vector4(-1827.23, 3007.55, 32.81, 140.32),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Port to Zancudo Container Transport',
                    pickupDepot = 'docks',
                    trailerKey = 'container',
                    trailerContents = 'Restricted sealed military container',
                    routeLength = '7.9 mi',
                    trailerDrop = {
                        label = 'Zancudo Secure Container Yard',
                        coords = vector3(-2439.79, 3346.07, 32.83),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Zancudo Security Officer',
                        model = `s_m_y_marine_02`,
                        coords = vector4(-2427.69, 3345.38, 32.98, 66.75),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Zancudo Military Timber Support',
                    pickupDepot = 'harmony',
                    trailerKey = 'logs',
                    trailerContents = 'Fortification timber',
                    routeLength = '3.6 mi',
                    trailerDrop = {
                        label = 'Zancudo Training Yard',
                        coords = vector3(-1945.5, 3355.84, 32.96),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Training Yard Quartermaster',
                        model = `s_m_y_marine_03`,
                        coords = vector4(-1953.41, 3358.06, 32.96, 188.74),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                },
                {
                    label = 'Merryweather Fuel Transfer',
                    pickupDepot = 'harmony',
                    trailerKey = 'tanker',
                    trailerContents = 'Jet Fuel',
                    routeLength = '7.6 mi',
                    trailerDrop = {
                        label = 'Zancudo Training Yard',
                        coords = vector3(485.65, -3382.36, 6.07),
                        radius = 22.0
                    },
                    receiverPed = {
                        label = 'Merryweather Security Officer',
                        model = `s_m_y_marine_03`,
                        coords = vector4(485.65, -3382.36, 6.07, 359.42),
                        scenario = 'WORLD_HUMAN_CLIPBOARD'
                    }
                }
            }
        }
    }
}
