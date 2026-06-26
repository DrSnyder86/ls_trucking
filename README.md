# Los Santos Freight Co. Trucking

**Resource:** `ls_trucking`  
**Version:** `1.0.0`  
**Author:** DrSnyder  
**Game:** FiveM / GTA V  
**Main command:** `/trucking`  
**Receiver command:** `/truckreceiver`  
**Dock command:** `/truckui`  
**Default receiver key:** `F2`
**Default dispatch key:** `F3`

Los Santos Freight Co. Trucking is a full freight career resource for FiveM. It includes company freight contracts, private contractor progression, garage vehicles, cargo handling, trailer hauling, dispatch radio chatter, receiver and dock UIs, route history, job summaries, random delivery events, and admin trailer cargo prop tools.

The script is built around a dispatch tablet for selecting work and a handheld receiver for active route operations. Players can run company freight, unlock private contractor work, buy their own approved vehicles, save vehicle fuel and condition, choose an optional dedicated daily route, and build a trucking career through rank, XP, reputation, payouts, and route history.

---

## Screenshots
### Dispatch UI

<p align="center">
  <img src="https://r2.fivemanage.com/image/MjSADCAoSkti.png" width="32%" alt="Freight Dispatch UI" />
  <img src="https://r2.fivemanage.com/image/T4DTiQnvJkHq.png" width="32%" alt="Company stats" />
  <img src="https://r2.fivemanage.com/image/GPA5TCuUt2K9.png" width="32%" alt="Company Garage" />   
</p>
<p align="center">
  <img src="https://r2.fivemanage.com/image/PjImpifso7HQ.png" width="32%" alt="Contractor Tab" />
  <img src="https://r2.fivemanage.com/image/8C7Ncxxk2AMm.png" width="32%" alt="Contracts" />
  <img src="https://r2.fivemanage.com/image/Pki1Ts3kP8Gy.png" width="32%" alt="History" />   
</p>

### Receiver UI 
<p align="center">
  <img src="https://r2.fivemanage.com/image/AQXF7S1qTZPv.png" width="50%" alt="Mini UI" />
  <img src="https://r2.fivemanage.com/image/5H9p7Jk7ENbt.png" width="50%" alt="Mini UI" />
  <img src="https://r2.fivemanage.com/image/JMaNGVPUBG16.png" width="50%" alt="Mini UI" />
  <img src="https://r2.fivemanage.com/image/pcp69CvC6UsK.png" width="50%" alt="Mini UI" />
  <img src="https://r2.fivemanage.com/image/5Gd7YCwrZ9sV.png" width="50%" alt="Mini UI" />
</p>
<p align="center">
  <img src="https://r2.fivemanage.com/image/EILDeJYrhYuV.png" width="32%" alt="Cancel UI" />
  <img src="https://r2.fivemanage.com/image/it9spcvBTLBj.png" width="32%" alt="Drop Authorization" />
  <img src="https://r2.fivemanage.com/image/cVjvlsJnxtcL.png" width="32%" alt="Icons" />
</p>

### Pier 400 YMAP's
<p align="center">
  <img src="https://r2.fivemanage.com/image/ccZDudCK2O33.jpg" width="50%" alt="Terminal" />
  <img src="https://r2.fivemanage.com/image/lBDvnLXxJHHZ.jpg" width="50%" alt="Weigh Station" />
</p>

### Trailer YTD's
<p align="center">
  <img src="https://r2.fivemanage.com/image/hxf2uJfRhxXg.jpg" width="50%" alt="Trailer" />
  <img src="https://r2.fivemanage.com/image/0HBrvRAeAfEv.png" width="50%" alt="Trailer" />
  <img src="https://r2.fivemanage.com/image/MRUy6TR5jy1V.png" width="50%" alt="Trailer" />
</p>
<p align="center">
  <img src="https://r2.fivemanage.com/image/GDujeRCNPjRA.png" width="50%" alt="Trailer" />
  <img src="https://r2.fivemanage.com/image/B3Dlc6gTgeXB.png" width="50%" alt="Trailer" />
  <img src="https://r2.fivemanage.com/image/fhLE76oWpkYI.png" width="50%" alt="Trailer" />
</p>
<p align="center">
  <img src="https://r2.fivemanage.com/image/c4rmfmqhmNt8.png" width="50%" alt="Trailer" />
  <img src="https://r2.fivemanage.com/image/Wl9PMqOg7mgV.jpg" width="50%" alt="Trailer" />
  <img src="https://r2.fivemanage.com/image/3CzeTQg2EUew.png" width="50%" alt="Trailer" />
</p>

## Highlights

- Dispatch tablet with contract, current job, garage, contractor, company, and route history views.
- Handheld receiver UI with app-style pages for current route, manifest, load, vehicle, dispatch log, and settings.
- Compact route dock UI for quick route status during active work.
- Company contracts for van, box truck, and trailer hauling jobs.
- Private contractor system with license purchase, vehicle ownership, optional dedicated daily route assignments, contractor reputation, and higher-risk payouts.
- Company garage and private fleet support with saved vehicle props, fuel, engine health, and body health.
- Cargo collection, trunk loading, delivery handoff, cargo condition, and route completion tracking.
- Trailer hookup, trailer load checklist, secure/load verification, receiver signoff, and trailer drop validation.
- Configurable flatbed trailer cargo props with an in-game admin editor and test spawner.
- Dispatch radio chatter, TX/RX light behavior, GPS lock status, signal bars, route progress, and status sounds.
- Random delivery events such as rush orders, audits, reroutes, dock delays, customer call-aheads, and other route modifiers.
- Rank progression with 10 ranks, ending at 500,000 XP.arge intrusive popup.
- Framework adapters for QB-Core, Qbox, ESX, ND_Core, and standalone fallback.
- Inventory, fuel, key, and target compatibility bridges.
- Vehicles.config includes popular add-on vehicle tables. Uncomment desired vehicle tables. Vanilla vehicle tables
included by default.
- Pier 400 Port area cleanup ymaps included. Removes Trailers from pump and weigh station area.
- Also includes ytd's with custom LSF Liveries and vehicle.metas for trailer compatibility for gta vanilla vehicles.

---

## Requirements

Required:

- `ox_lib`
- `oxmysql`
- `ox_target` or `qb-target`
- A supported framework or standalone mode
- A supported inventory system

Recommended:

- A supported fuel script
- A supported vehicle key script
- SQL database access
- Admin permissions configured through your framework or ACE permissions

---

## Supported Frameworks

Set this in `config/config.lua`:

```lua
Config.Framework = 'auto' -- auto, qb, qbox, esx, nd, standalone
```

Supported modes:

- `auto` - detects the running framework.
- `qb` - QB-Core.
- `qbox` - Qbox / qbx_core.
- `esx` - ESX / es_extended.
- `nd` - ND_Core.
- `standalone` - no framework economy integration. Useful for testing or custom integrations.

Notes:

- QB-Core and Qbox are the most complete drop-in targets.
- ESX and ND_Core support is handled through the framework adapter.
- ESX and ND_Core installs are best paired with `ox_inventory`.
- Standalone mode can run the job flow, but money, jobs, and permissions may need custom integration if used on a live economy server.

---

## Supported Scripts

### Target

```lua
Config.TargetSystem = 'auto' -- auto, ox, qb
```

Supported:

- `ox_target`
- `qb-target`

### Inventory

```lua
Config.Inventory = {
    System = 'auto',
    Debug = false,
    UseInternalTrunkFallback = true,
    TrunkPrefix = 'trunk'
}
```

Supported:

- `ox_inventory`
- `qb-inventory`
- `lj-inventory`
- `ps-inventory`
- `qs-inventory`
- `custom`

Notes:

- `ox_inventory` has the best metadata and trunk support.
- Other inventories use player item handling plus the internal route trunk fallback when needed.
- Item templates are included in the `install` folder.

### Fuel

```lua
Config.Fuel = {
    System = 'auto',
    DefaultFuel = 100.0
}
```

Supported:

- `ox_fuel`
- `LegacyFuel`
- `ps-fuel`
- `cdn-fuel`
- `lj-fuel`
- `qb-fuel`
- `BigDaddy-Fuel`
- `none`

### Vehicle Keys

```lua
Config.Keys = {
    System = 'auto',
    GiveOnSpawn = true,
    RemoveOnReturn = false,
    OwnerOnly = true
}
```

`OwnerOnly` tells LSFC to keep vehicle keys assigned to the driver who checked out the vehicle. When a company or contractor vehicle is assigned, other online clients are asked to remove keys for that plate through the configured key script.

Supported:

- `qb-vehiclekeys`
- `qbx_vehiclekeys`
- `Renewed-Vehiclekeys`
- `MrNewbVehicleKeys`
- `wasabi_carlock`
- `cd_garage`
- `none`

---

## Installation

1. Place the resource folder in your server resources.
2. Import `sql/ls_trucking.sql` into your database.
3. Add inventory items from the matching file in the `install` folder.
4. Configure `config/config.lua`.
5. Configure routes, vehicles, items, contracts, and random events if desired.
6. Ensure dependencies before `ls_trucking`.
7. Start the server and check the startup summary in console.

Example ensure order:

```cfg
ensure ox_lib
ensure oxmysql
ensure ox_target
ensure qb-core
ensure ox_inventory
ensure ls_trucking
```

Use your actual framework, inventory, target, fuel, and key resources.

---

## Database Tables

The included SQL creates:

- `player_trucking` - rank, XP, reputation, jobs completed, earnings, cancellations.
- `trucking_history` - completed route history.
- `trucking_garage` - company garage vehicle state and saved props.
- `trucking_contractor_profiles` - contractor license, rep, dedicated route assignment, daily completion, weekly route-change timestamp.
- `trucking_contractor_vehicles` - owned contractor vehicles, stored state, fuel, engine health, body health.

If a vehicle is out during a resource or server restart, the script is designed to restore the vehicle state as stored.

---

## Main Config Files

- `config/config.lua` - main framework, commands, UI, ranks, economy, security, depots, timing, penalties, contractor settings.
- `config/contracts.lua` - route pools, contract data, stops, businesses, route layouts.
- `config/vehicles.lua` - company vehicles and contractor vehicles.
- `config/route_trailers.lua` - route trailer definitions, trailer cargo prop layouts, liveries, extras, and trailer instructions.
- `config/items.lua` - cargo item definitions.
- `config/random_events.lua` - random delivery events.

Trailer pickup/drop area circles are controlled from `Config.AreaBlips` in `config/config.lua`. Set `Enabled = false` to disable the extra minimap circles, or adjust radius/color/alpha per trailer pickup and drop stage.

Install helper files:

- `install/ox_inventory_items.lua`
- `install/qb_inventory_items.lua`
- `install/qs_inventory_items.lua`
- `install/qb_radial_items.lua`
- `install/qbx_radial_items.lua`
- `install/ADD-ON-Trailers.meta`

---

## Player Commands

- `/trucking` - opens the Los Santos Freight Co. dispatch tablet.
- `/truckreceiver` - toggles the full handheld receiver.
- `/truckui` - toggles the compact route dock.
- `/canceltrucking` - cancels the active route with confirmation.

Default keybind:

- `F9` - toggles the full receiver. This can be changed with `Config.FullReceiverKey`.

If `Config.RequireJob` is enabled, receiver access respects the configured job requirement.

---

## Admin Commands

Admin commands are available to admins even when debug mode is disabled. Debug mode still controls extra debug visuals and logs.

Permission checks use framework admin/god permissions first, then common admin ACE checks, then the optional ACE entries in:

```lua
Config.Security.AdminAces = { 'ls_trucking.admin', 'ls_trucking.debug' }
```

Commands:

- `/lstruck_resetjob` - force reset your active trucking job.
- `/lstruck_clearpeds` - clear active contract worker peds.
- `/lstruck_giveitems` - give cargo items for the current active route.
- `/lstruck_summary` - open an admin route state summary.
- `/lstruck_rank <playerId> <rank>` - set a player's trucking rank XP.
- `/lstruck_rep <playerId> <amount>` - adjust a player's trucking reputation.
- `/lstruck_resetstats <playerId>` - reset trucking stats.
- `/lstraileredit <trailerKey>` - open the trailer cargo prop editor.
- `/lstrailertest <trailerKey>` - spawn a configured trailer and cargo props without starting a contract.
- `/lstrailerclear` - remove the current trailer test unit.

---

## Dispatch Tablet

The dispatch tablet is the main job hub.

### Contracts

- Select van, box truck, or trailer contract types.
- Select company vehicle and load priority.
- View route preview, stops, payout, cargo, distance, and estimated time.
- Start company contracts from the right-side context panel.

### Current Job

- Shows the current route state, route details, cargo progress, stops, vehicle, trailer status, manifest, and current objectives.

### Garage

- View company fleet vehicles.
- Select a vehicle card to preview vehicle data in the right panel.
- Spawn vehicles from the selected vehicle panel.
- Return the current company vehicle to save modifications.
- Spawn checks prevent vehicles from spawning into occupied spots.

### Contractor

- Purchase a contractor license once the required rank is reached.
- Buy approved vans, box trucks, and tractors.
- Store and spawn owned contractor vehicles.
- Save fuel, engine health, body health, and vehicle props when garaged.
- Only one contractor vehicle can be out at a time.
- Choose an optional dedicated daily route assignment by delivery type from a compact route list.
- Dedicated daily routes stay assigned after selection and can be changed after the configured weekly cooldown.
- Complete the dedicated daily route once per server day for bonus payout and contractor rep.
- Available private contracts are separate from the dedicated daily route and only show route choices for the private vehicle type currently spawned.
- Contractor routes require minimum fuel and condition.
- Contractor jobs pay more but have higher penalties and cancellation costs.

### Company

- View player career stats, rank progress, reputation, earnings, completed jobs, and rank information.

### Route History

- View completed route summaries.
- Expand recent job tiles to review route, payout, XP, reputation, vehicle, contract type, and completion data.

---

## Receiver UI

The receiver is a handheld device-style UI. It can be opened during or outside an active route.

Receiver pages:

- **Current Route** - active objective, notice, destination, ETA, alerts, cargo, payout, route progress, cancel route.
- **Manifest** - contract data and stop/package data.
- **Load** - cargo state and load priority/request tools.
- **Vehicle** - assigned vehicle data, fuel, condition, GPS, locks, engine, lights, doors, hood, trunk, hazards, locate.
- **Dispatch Log** - radio traffic and route completion summary history.
- **Settings** - player info, rank, XP, reputation, receiver assignment, model/firmware, dock model, movement toggle, dock toggle.

Receiver details:

- Model label: `BDG-LSFC-R-1.1`.
- Dock model label: `BDG-LSFC-D-1.1`.
- TX/RX indicators react to updates and route messages.
- GPS lock and signal bars update based on route/dispatch state.
- Receiver movement can be toggled from settings.
- The player uses a phone-style prop and animation while the receiver is open.
- The receiver allows walking and driving while open.

---

## Compact Dock UI

The compact dock is designed as a smaller route receiver fixed near the screen edge.

It shows:

- Channel.
- Freight logo.
- RX/TX/GPS/signal block.
- Current radio chatter.
- Destination name and street area.
- Route name.
- Cargo and stop icon progress.
- Last update time.
- Thin route progress bar.
- Dock model watermark.

The dock can be toggled with `/truckui` and can be moved when movement mode is enabled.

---

## Route Flow

### Van Routes

- Talk to pickup worker.
- Collect package.
- Open trunk/cargo area.
- Load package into vehicle.
- Verify load attached.
- Drive to delivery stop.
- Grab package from vehicle.
- Deliver package.
- Continue through all stops.

The script accounts for missing trunk/cargo doors so players are not blocked if a door is damaged or detached.

### Box Truck Routes

- Collect crates.
- Load crates into the assigned box truck.
- Verify cargo.
- Deliver crates to stores or warehouses.
- Complete all assigned stops.

### Trailer Routes

- Spawn or use assigned tractor.
- Travel to trailer depot.
- Hook assigned trailer.
- Secure trailer/load.
- Complete checklist.
- Drive to receiving yard.
- Detach trailer in drop zone.
- Confirm trailer dropped.
- Complete receiver signoff.

Trailer depots can have multiple spawn spots, and the script tries available spots when one is occupied.

---

## Random Delivery Events

Random delivery events live in:

```text
config/random_events.lua
```

Events can affect:

- Route time.
- Payout.
- XP.
- Reputation.
- Alert text.
- Radio chatter.
- Route urgency.

Examples include:

- Rush order bonus.
- Dock delay.
- Traffic reroute.
- Receiver audit.
- Customer call-ahead.
- Dispatch schedule changes.

---

## Progression

Ranks are configured in `config/config.lua`.

Current default rank list:

- Rank 1 - Probationary Driver
- Rank 2 - City Courier
- Rank 3 - Route Driver
- Rank 4 - Trailer Certified Driver
- Rank 5 - Freight Operator
- Rank 6 - Long Haul Driver
- Rank 7 - Heavy Freight Specialist
- Rank 8 - Fleet Lead
- Rank 9 - Logistics Supervisor
- Rank 10 - LSFC Master Hauler

Rank 10 requires 500,000 XP.

---

## Vehicle Plates

Trucking vehicle plates use the configured prefix plus a random five-character number/letter combo.

Example format:

```text
LSV1A2B3
```

Adjust the prefix and vehicle data in the vehicle config files.

---

## Trailer Cargo Prop System

Flatbed-style route trailers can spawn with configured cargo props already attached. This is useful for flatbeds, military trailers, freight trailers, and custom cargo variations.

Configured trailers live in:

```text
config/route_trailers.lua
```

Look for:

```lua
Config.RouteTrailers = {
    flatbed = {
        label = 'Flatbed Trailer',
        model = 'trflat',
        cargoProps = {
            -- props here
        }
    }
}
```

Each trailer variation can use the same trailer model with different cargo props. For example, one `trflat` entry can be empty, another can carry crates, and another can carry containers.

### Trailer Prop Editor

Use:

```text
/lstraileredit <trailerKey>
```

The editor lets admins:

- Select a configured trailer by `Config.RouteTrailers` key.
- Add, duplicate, delete, and edit cargo props.
- Adjust model names.
- Nudge offset and rotation by axis.
- Print ready-to-paste `cargoProps` data to console.

Camera keys while editing:

- `A` / `D` or arrow left/right - rotate camera.
- `W` / `S` or arrow up/down - adjust camera height.
- `Q` / `E` - zoom.
- `R` - reset camera.

### Trailer Test Spawner

Use:

```text
/lstrailertest <trailerKey>
/lstrailerclear
```

This lets admins spawn and inspect a configured trailer without starting a contract.

Recommended workflow:

1. Copy or create a trailer entry in `Config.RouteTrailers`.
2. Run `/lstraileredit trailer_key`.
3. Tune the props in-game.
4. Print the config.
5. Paste the printed `cargoProps` into `config/route_trailers.lua`.
6. Run `/lstrailertest trailer_key`.
7. Assign the trailer key to routes once it looks right.

---

## Sounds

Receiver and job sounds are stored in:

```text
html/sounds
```

The current sound direction is older radio clicks, short beeps, squelch, dispatch updates, trailer air connection, and electrical connection clicks.

---

## Security And Performance

The script includes:

- Server distance checks for route actions.
- Action cooldowns.
- Spawn occupancy checks.
- Config validation.
- Startup summary.
- Admin permission checks.
- Passive receiver/signal refresh interval.
- Cleanup paths for receiver, dispatch tablet, peds, vehicles, props, and NUI state.

Key settings:

```lua
Config.ReceiverRefreshInterval = 15000
Config.SpawnOccupancy = {
    Enabled = true,
    VehicleRadius = 4.0,
    TrailerRadius = 6.0
}
```

---

## Customization Notes

Good places to start:

- Add routes in `config/contracts.lua`.
- Add company or contractor vehicles in `config/vehicles.lua`.
- Add route trailers and trailer prop layouts in `config/route_trailers.lua`.
- Add new cargo items in `config/items.lua`.
- Add route events in `config/random_events.lua`.
- Replace receiver/dock logos in the `images` folder.
- Replace sounds in `html/sounds`.
- Adjust ranks, payouts, penalties, route timing, and contractor rules in `config/config.lua`.

---

## Troubleshooting

### Dispatch tablet opens but jobs do not start

- Check server console for startup validation messages.
- Confirm `oxmysql` is running and the SQL was imported.
- Confirm your framework adapter is detecting the expected framework.
- Confirm target and inventory resources are started before `ls_trucking`.

### Vehicle will not spawn

- Make sure the spawn area is not occupied.
- Confirm you are within the configured depot request range.
- Check `Config.SpawnOccupancy`.
- Check company/contractor vehicle stored state in the database if needed.

### Cargo cannot be loaded or delivered

- Confirm the cargo item exists in your inventory resource.
- Confirm the matching install item file was added.
- If not using `ox_inventory`, keep `UseInternalTrunkFallback = true`.

### Contractor route says active after restart

- Confirm the latest SQL columns exist.
- Confirm the resource has write access to update contractor route state.
- Check `trucking_contractor_profiles` and `trucking_contractor_vehicles`.

### Receiver or dock access with job requirement

- If `Config.RequireJob = true`, confirm the player's framework job matches `Config.JobName`.
- Admin commands are separate from player receiver access.

### Trailer props do not appear

- Confirm the prop model name exists and can be loaded.
- Test with `/lstrailertest <trailerKey>`.
- Make sure the trailer entry has `cargoProps`.
- Check console for model loading errors.

---

## Development Notes

The script has been split into focused client and server modules where possible:

- Framework and compatibility bridges.
- Route state and route helpers.
- Cargo handling.
- Depot vehicle handling.
- Dispatch data.
- Route summaries/history.
- Trailer cargo props, editor, and tester.

`client/main.lua` and `server/main.lua` still coordinate the larger flow, but most heavy feature areas now live in separate modules.

---

## Credits

Created by DrSnyder.

Resource label:

```text
ls_trucking by DrSnyder
```

### License
For an updated license, check the ``License`` file. That file will always overrule anything mentioned in the ``readme.md``

ls_trucking - DrSnyder

Copyright © 2026 DrSnyder. All rights reserved.

You can use and edit this code to your liking as long as you don't ever claim it to be your own code and always provide proper credit. You're not allowed to sell ls_trucking or any code you take from it. If you want to release your own version of ls_trucking, you have to link the original GitHub repo, or release it via a Forked repo.
