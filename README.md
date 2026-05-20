# Los Santos Freight Co. Trucker Job
 
**Author:** Drsnyder  
**Frameworks:** QB-Core / Qbox compatible / Standalone
**Inventory:** ox_inventory, qb-inventory, lj-inventory, ps-inventory, qs-inventory
**Fuel:** ox_fuel, LegacyFuel, ps-fuel, cdn-fuel, lj-fuel, qb-fuel, BigDaddy-Fuel  
**Keys:** qb-vehiclekeys, qbx_vehiclekeys, Renewed-Vehiclekeys, MrNewbVehicleKeys, wasabi_carlock, cd_garage

Los Santos Freight Trucking is a full delivery and trucking job resource for FiveM. It includes van package routes, box truck crate routes, trailer hauling, rank progression, company garage vehicles, saved vehicle modifications, manifest paperwork, route summaries, trailer checklists, timed deliveries, damage penalties, random dispatch events, and a polished Freight Dispatch tablet UI. Most delivery routes are local and logistically efficient. No more driving all over the map to complete a route. Config is highly and easily configurable for server owners to add more depot locations, delivery routes and custom vehicles and trailers. All delivery locations provided support the unmodded vanilla gta map. Replacement for qb_truckerjob and qbx_truckerjob.

---

## Screenshots

<p align="center">
  <img src="https://r2.fivemanage.com/image/V7AInPUQnHJm.jpg" width="32%" alt="Freight Dispatch UI" />
  <img src="https://r2.fivemanage.com/image/koGBHenopjcv.jpg" width="32%" alt="Company Progress" />
  <img src="https://r2.fivemanage.com/image/O4QPR3R8rJdm.jpg" width="32%" alt="Company Garage" />   
</p>

<p align="center">
  <img src="https://r2.fivemanage.com/image/85kY7wkXrkA6.png" width="32%" alt="Trailer Checklist" />
  <img src="https://r2.fivemanage.com/image/S7NGeRdCUPO6.png" width="32%" alt="Complete Checklist" />
  <img src="https://r2.fivemanage.com/image/eKPJOxQE8hJe.png" width="32%" alt="Manifest UI" />
</p>

<p align="center">
  <img src="https://r2.fivemanage.com/image/H1FOGuz7QLEq.png" width="32%" alt="Mini UI" />
  <img src="https://r2.fivemanage.com/image/HDWrtpGdzsfQ.png" width="32%" alt="Route Summary" />
</p>
<p align="center">
  <img src="https://r2.fivemanage.com/image/EILDeJYrhYuV.png" width="32%" alt="Cancel UI" />
  <img src="https://r2.fivemanage.com/image/cVjvlsJnxtcL.png" width="32%" alt="Icons" />
</p>

---

## Core Features

### Delivery Types

- **Van Deliveries**
  - Package routes with multi-stop delivery logic.
  - Supports standard packages, alternate package props, and gift packages.
  - Package metadata and manifest details.

- **Box Truck Deliveries**
  - Crate and freight restock routes.
  - Supports freight crates, ammo crates, secure crates, and military crates.
  - Multi-stop planned routes.

- **Trailer Hauling**
  - Separated tractors and route-assigned trailers.
  - Route-specific trailer depots.
  - Trailer load checklist before route start.
  - Receiver signoff at delivery location.

### Rank and Progression

- XP-based rank structure.
- Rank-gated vehicles.
- Rank-gated priority, government, and military contracts.
- Higher-rank contracts can pay more and use different cargo/trailer types.

### Company Garage

- Company vehicle garage through the Freight Dispatch UI.
- Vehicle mods are saved and reapplied when respawned.
- Supports vans, box trucks, and tractor trailers.

### Trailer Systems

- Route-assigned trailer types.
- Multiple trailer depots.
- Trailer checklist stage:
  - Secure truck connection.
  - Confirm trailer load secure.
  - Complete load checklist.
- Trailer damage penalties and clean delivery bonuses.
- Optional speeding risk events for trailer hauling.

### Timing and Payouts

- Estimated delivery time per route.
- Early delivery bonuses.
- Late delivery penalties.
- Random dispatch events that can alter payout, rep, or route timing.
- Return vehicle bonus.
- Cancellation confirmation with reputation penalty and reason selection.

### UI Features

- Freight Dispatch tablet UI.
  - Dispatch Tab - List of Delivery Types and Contract Selection
  - Current Job Tab - Current Job Status, Cancel Job, Last Completed Contract Info
  - Garage Tab - Full List of Available Company Owned Vehicles, Spawn Vehicle
  - Company Tab - Player Company Data, Rank Structure
- Draggable mini route UI.
  - Current Job
  - Job Status
  - Current Stage
  - Expected Completion Time
  - Destination with Address
  - Load & Stop Info
  - Cargo Label
  - Contract Alerts
- Custom Freight Dispatch dialog UI for:
  - Delivery manifests.
  - Trailer manifests.
  - Trailer load checklist.
  - Route completion summary.
  - Cancel route confirmation.

### Additional

- GTA Style Active Mission Blips With No Auto GPS Route - Players Determine Their Own Routes
- Delivery Package Animations with Full Prop Support
- Tablet Animations with Prop when the UI is Open
  
## Gameplay Instructions
### Package/Crate Delivery
- Visit the Dispatch Ped at the Depot Terminal or open the ui.
- Choose a contract type or spawn a vehicle from the garage.
- Once a contract is selected, choose to either use your available garage vehicle or a contract specific job vehicle.
- After a contract is started you will be provided with a Delivery Manifest and pickup location.
- Drive to the pickup location and speak to the clerk. PostOps or GoPostal
- Load packages or crates into your vehicle - Cargo doors or trunk must be open.
- After load is complete, target the vehicle to verify.
- Once verified, player will receive dispatch and delivery location data.
- Visit each location, pickup package when targeting the vehicle if the specified doors are open, deliver to drop location.
- When a contract is completed, players will receive payment and a detailed summary of the contract.
- Return your vehicle to the Depot or open the ui and start another contract.

### Trailer Delivery
- Visit the Dispatch Ped at the Depot Terminal or open the ui.
- Choose a contract type or spawn a vehicle from the garage.
- Once a contract is selected, choose to either use your available garage vehicle or a contract specific job vehicle.
- After a contract is started you will be provided with a Trailer Manifest and pickup location.
- Drive to the pickup location and locate your trailer.
- Attach the specified trailer to your tractor.
- Hop out and target the rear of the tractor. You can view Checklist, Complete Checklist and Secure Trailer Attached here.
- Step 1 - Secure Trailer Attached - when targeting the rear of the tractor.
- Step 2 - Verify Trailer Load Secure - when targeting the rear of the trailer.
- Step 3 - Complete Checklist - when targeting rear of the tractor again.
- When the player verifies checklist complete, you will be provided with a delivery location.
- Head on over to the drop location and detach your trailer.
- Jump out and target the trailer to verify detached.
- Once verified, Speak to the receiver ped to complete the contract.
- When a contract is completed, players will receive payment and a detailed summary of the contract.
- Return your vehicle to the Depot or open the ui and start another contract.
---
### Download
https://github.com/DrSnyder86/ls_trucking/archive/refs/heads/main.zip

### Github (Always up-to-date)
https://github.com/DrSnyder86/ls_trucking/tree/main

## Compatibility

### Required

- `ox_lib`
- `oxmysql`
- `Compatible Inventory`
- target resource:
  - `ox_target`, or
  - `qb-target`

### Frameworks

- QB-Core
- Qbox
- Standalone mode is partially supported for basic logic, but QB/Qbox is recommended for player identity, jobs, and citizen IDs.

### Optional / Supported

- qbx radial menu snippets included.
- qb radial menu snippets included.

### Supported Inventories

```text
ox_inventory       Full item metadata + trunk inventory support
qb-inventory       Player item support + internal route cargo trunk fallback
lj-inventory       Player item support + internal route cargo trunk fallback
ps-inventory       Player item support + internal route cargo trunk fallback
qs-inventory       Player item support + internal route cargo trunk fallback
```

`ox_inventory` is still the recommended inventory because it has the cleanest item metadata and trunk inventory behavior. Other inventories are supported through compatibility wrappers. Because trunk APIs vary heavily between inventory scripts, non-ox inventories use an internal job-trunk fallback for route cargo so the job loop still works.

### Supported Fuel Scripts

```text
ox_fuel
LegacyFuel
ps-fuel
cdn-fuel
lj-fuel
qb-fuel
```

### Supported Key Scripts

```text
qb-vehiclekeys
qbx_vehiclekeys
Renewed-Vehiclekeys
MrNewbVehicleKeys
wasabi_carlock
cd_garage
```

---

## Install Guide

1. Place the resource folder in your server resources folder:

```text
resources/[jobs]/ls_trucking
```

2. Import the SQL file once:

```text
ls_trucking/sql/ls_trucking.sql
```

3. Add the resource to `server.cfg` after dependencies:

```cfg
ensure oxmysql
ensure ox_lib
ensure ox_inventory
ensure ox_target
ensure ls_trucking
```

For qb-target instead of ox_target:

```cfg
ensure oxmysql
ensure ox_lib
ensure ox_inventory
ensure qb-target
ensure ls_trucking
```

4. Restart the server.

---

## Inventory Items

Add these items to `ox_inventory/data/items.lua`.

```lua
['ls_package'] = {
    label = 'Delivery Package',
    image = 'ls_package.png',
    weight = 2500,
    stack = true,
    close = true,
    description = 'A package assigned to a Los Santos Freight Co. delivery route.'
},

['ls_package2'] = {
    label = 'Delivery Package',
    image = 'ls_package2.png',
    weight = 2500,
    stack = true,
    close = true,
    description = 'A boxed package assigned to a Los Santos Freight Co. delivery route.'
},

['ls_package3'] = {
    label = 'Delivery Package',
    image = 'ls_package3.png',
    weight = 2500,
    stack = true,
    close = true,
    description = 'A sealed package assigned to a Los Santos Freight Co. delivery route.'
},

['ls_package4'] = {
    label = 'Delivery Package',
    image = 'ls_package4.png',
    weight = 2500,
    stack = true,
    close = true,
    description = 'A heavy package assigned to a Los Santos Freight Co. delivery route.'
},

['ls_gift_package'] = {
    label = 'Gift Package',
    image = 'ls_gift_package.png',
    weight = 2500,
    stack = true,
    close = true,
    description = 'A special gift package for a Los Santos Freight Co. delivery route.'
},

['ls_crate'] = {
    label = 'Freight Crate',
    image = 'ls_crate.png',
    weight = 6000,
    stack = true,
    close = true,
    description = 'A heavy freight crate assigned to a box truck delivery route.'
},

['ls_ammo_crate'] = {
    label = 'Ammo Crate',
    image = 'ls_ammo_crate.png',
    weight = 7000,
    stack = true,
    close = true,
    description = 'A secured ammunition crate assigned to a restricted delivery route.'
},

['ls_secure_crate'] = {
    label = 'Secure Government Crate',
    image = 'ls_secure_crate.png',
    weight = 7000,
    stack = true,
    close = true,
    description = 'A secured government crate assigned to a Los Santos Freight Co. route.'
},

['ls_military_crate'] = {
    label = 'Merryweather Crate',
    image = 'ls_military_crate.png',
    weight = 8000,
    stack = true,
    close = true,
    description = 'A restricted military freight crate.'
},

['ls_military_crate2'] = {
    label = 'Military Crate',
    image = 'ls_military_crate2.png',
    weight = 8000,
    stack = true,
    close = true,
    description = 'A military freight crate assigned to a restricted route.'
},

['ls_delivery_manifest'] = {
    label = 'Delivery Manifest',
    image = 'ls_delivery_manifest.png',
    weight = 100,
    stack = false,
    close = true,
    description = 'A Los Santos Freight Co. package delivery manifest.'
},

['ls_trailer_manifest'] = {
    label = 'Trailer Manifest',
    image = 'ls_trailer_manifest.png',
    weight = 100,
    stack = false,
    close = true,
    description = 'A Los Santos Freight Co. trailer delivery manifest.'
}
```

Copy the included images from:

```text
ls_trucking/inventory_images/
```

to your ox_inventory image folder.

---

## Commands

```text
/trucking        Open the Freight Dispatch tablet UI
/truckui         Toggle the mini route UI
/canceltrucking  Open cancel route confirmation
```

---

## Configuration Files

The config is split into two files:

```text
config/config.lua      Main settings, vehicles, route trailers, cargo types, depots, payouts, UI, blips, sounds, and version checking
config/contracts.lua   Contract definitions, standard routes, priority routes, government routes, and military routes
```

### Config Version Checks

The resource includes optional version fields for the main config and contracts config:

```lua
Config.ConfigVersion = '1.0.0'
Config.ContractsVersion = '1.0.0'
```

You can later point the version checker to your GitHub raw files if you want to compare server configs against your published defaults.

---

## Custom Vehicle Images

Vehicle and trailer images are controlled by the `photo` field in `config/config.lua`.

Examples:

```lua
photo = 'https://docs.fivem.net/vehicles/speedo.webp'
```

or, for local resource images:

```lua
photo = 'images/speedo.png'
```

If using local images, make sure the files are in:

```text
ls_trucking/images/
```

and that the filename and extension exactly match the config path.

---

## Radial Menu Examples

Two example files are included:

```text
qb_radial_items.lua
qbx_radial_items.lua
```

Use the matching snippets in your radial menu config to open the trucking UI or toggle the mini UI.

---

## Notes and Tips

- `ox_inventory` is recommended for the most complete item metadata and trunk support.
- Non-ox inventories use an internal route cargo fallback for vehicle cargo storage because every inventory handles trunks differently.
- If item metadata does not display in your inventory, the job will still work, but item descriptions may be less detailed.
- If a fuel/key script does not work with your specific fork, edit `client/compat.lua` for fuel/key support.
- If target options do not appear, confirm `Config.TargetSystem` and that your target resource starts before `ls_trucking`.
- If local images do not show, check `fxmanifest.lua`, filename casing, file extension, and restart/cache.

### License
For an updated license, check the ``License`` file. That file will always overrule anything mentioned in the ``readme.md``

ls_trucking - DrSnyder

Copyright © 2026 DrSnyder. All rights reserved.

You can use and edit this code to your liking as long as you don't ever claim it to be your own code and always provide proper credit. You're not allowed to sell ls_trucking or any code you take from it. If you want to release your own version of ls_trucking, you have to link the original GitHub repo, or release it via a Forked repo.
