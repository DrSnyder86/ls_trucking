# Los Santos Freight Trucking

**Resource:** `ls_trucking`  
**Version:** `1.0.0`  
**Author:** Drsnyder  
**Frameworks:** QB-Core / Qbox compatible  
**Inventory:** ox_inventory  
**Target:** ox_target or qb-target

Los Santos Freight Trucking is a full delivery and trucking job resource for FiveM. It includes van package routes, box truck crate routes, trailer hauling, rank progression, company garage vehicles, saved vehicle modifications, manifest paperwork, route summaries, trailer checklists, timed deliveries, damage penalties, random dispatch events, and a polished Freight Dispatch tablet UI.

---

## Screenshots

<p align="center">
  <img src="https://r2.fivemanage.com/image/V7AInPUQnHJm.jpg" width="32%" alt="Freight Dispatch UI" />
  <img src="https://r2.fivemanage.com/image/koGBHenopjcv.jpg" width="32%" alt="Company Progress" />
  <img src="https://r2.fivemanage.com/image/H1FOGuz7QLEq.png" width="32%" alt="Mini UI" />  
</p>

<p align="center">
  <img src="https://r2.fivemanage.com/image/85kY7wkXrkA6.png" width="32%" alt="Trailer Checklist" />
  <img src="https://r2.fivemanage.com/image/S7NGeRdCUPO6.png" width="32%" alt="Complete Checklist" />
</p>

<p align="center">
  <img src="https://r2.fivemanage.com/image/O4QPR3R8rJdm.jpg" width="32%" alt="Company Garage" />
  <img src="https://r2.fivemanage.com/image/eKPJOxQE8hJe.png" width="32%" alt="Manifest UI" />
  <img src="https://r2.fivemanage.com/image/HDWrtpGdzsfQ.png" width="32%" alt="Route Summary" />  
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
- Draggable mini route UI.
- Custom Freight Dispatch dialog UI for:
  - Delivery manifests.
  - Trailer manifests.
  - Trailer load checklist.
  - Route completion summary.
  - Cancel route confirmation.

---

## Compatibility

### Required

- `ox_lib`
- `oxmysql`
- `ox_inventory`
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

## Notes

- The resource uses manual destination blips instead of forced mission GPS routes.
- Van and box truck cargo must be loaded, verified, retrieved, and delivered.
- Trailer hauling starts after the trailer is attached and the load checklist is completed.
- Package carrying uses looped carry animations and props.
- The dispatch ped can open the UI and return company vehicles.
- Main UI uses a tablet animation and tablet prop while open.

---

## Support / Editing Tips

- If a cargo prop does not appear, confirm the prop exists in your GTA build or change the `prop` in `Config.CargoTypes`.
- If local vehicle images do not show, check `fxmanifest.lua`, filename casing, file extension, and resource restart/cache.
- If target options do not appear, confirm `Config.TargetSystem` and that either `ox_target` or `qb-target` is running before `ls_trucking`.

### License
For an updated license, check the ``License`` file. That file will always overrule anything mentioned in the ``readme.md``

ls_trucking - DrSnyder

Copyright © 2026 DrSnyder. All rights reserved.

You can use and edit this code to your liking as long as you don't ever claim it to be your own code and always provide proper credit. You're not allowed to sell ls_trucking or any code you take from it. If you want to release your own version of ls_trucking, you have to link the original GitHub repo, or release it via a Forked repo.
