const frame = document.getElementById('nuiFrame');
const logBox = document.getElementById('previewLog');
const previewViewport = document.getElementById('previewViewport');
let previewLoopTimer = null;
let previewLoopStep = 0;

function log(message) {
    logBox.textContent = `${new Date().toLocaleTimeString()}  ${message}`;
}

function clone(value) {
    return JSON.parse(JSON.stringify(value));
}

function childWindow() {
    return frame && frame.contentWindow;
}

function childDocument() {
    return frame && frame.contentDocument;
}

function send(payload) {
    const target = childWindow();
    if (!target) return;
    target.postMessage(payload, '*');
}

function setViewport(size = 'full') {
    const nextSize = ['full', 'desktop', 'tall', 'compact'].includes(size) ? size : 'full';
    previewViewport.className = `preview-viewport viewport-${nextSize}`;
    document.querySelectorAll('[data-preview-viewport]').forEach(button => {
        button.classList.toggle('active', button.dataset.previewViewport === nextSize);
    });
    log(`Viewport set to ${nextSize}.`);
}

function clickInFrame(selector) {
    const doc = childDocument();
    const target = doc && doc.querySelector(selector);
    if (target) target.click();
    return Boolean(target);
}

function runAfterFrame(callback, delay = 80) {
    window.setTimeout(callback, delay);
}

function route(label, x, y, length, extra = {}) {
    return {
        label,
        routeLength: length,
        estimatedTime: extra.estimatedTime || '12 min est.',
        dropoffs: extra.dropoffs || [{ label, coords: { x, y, z: 35 } }],
        trailerDrop: extra.trailerDrop,
        receiverPed: extra.receiverPed,
        trailerKey: extra.trailerKey
    };
}

const priorities = {
    standard: {
        key: 'standard',
        label: 'Standard Commercial Route',
        shortLabel: 'Standard',
        badge: 'STANDARD',
        description: 'Regular freight timing',
        order: 1,
        minRank: 1,
        payoutMultiplier: 1,
        xpMultiplier: 1
    },
    priority: {
        key: 'priority',
        label: 'Priority Freight',
        shortLabel: 'Priority',
        badge: 'PRIORITY',
        description: 'Higher payout, tighter timing',
        order: 2,
        minRank: 2,
        payoutMultiplier: 1.18,
        xpMultiplier: 1.1
    }
};

const previewDispatch = {
    radioFrequency: '68.9',
    config: {
        radioFrequency: '68.9',
        allowVehicleReuseAfterRoute: true,
        requireSameTypeForVehicleReuse: true,
        uiSounds: { Enabled: false }
    },
    player: {
        name: 'Alex Driver',
        citizenid: 'LSF-0421',
        rank: 3,
        rankLabel: 'Route Driver',
        xp: 1850,
        nextRankXp: 3000,
        reputation: 28,
        jobsCompleted: 17,
        completedRouteStreak: 4,
        wallet: 84250,
        totalCancelled: 1,
        jobText: 'Trucker - Driver'
    },
    ranks: [
        { rank: 1, label: 'New Hire', xp: 0 },
        { rank: 2, label: 'Dock Runner', xp: 750 },
        { rank: 3, label: 'Route Driver', xp: 1500 },
        { rank: 4, label: 'Freight Specialist', xp: 3000 }
    ],
    contracts: {
        van: {
            label: 'Van Delivery',
            description: 'Small package runs around Los Santos.',
            cardColor: '#e6ab00',
            tags: ['City', 'Fast', 'Packages'],
            businesses: ['24/7', 'Liquor Ace', 'Ammu-Nation'],
            pickup: { label: 'LSFC Terminal', coords: { x: -41.54, y: -2513.28, z: 6.16 } },
            cargo: 'Packages',
            requiredCargo: 4,
            routes: [route('Mirror Park 24/7', 1158, -326, '4.8 mi'), route('Vespucci Liquor Ace', -1222, -908, '5.3 mi')]
        },
        boxtruck: {
            label: 'Box Truck Freight',
            description: 'Medium freight and pallet deliveries.',
            cardColor: '#3f8cff',
            tags: ['Pallets', 'Freight', 'Citywide'],
            businesses: ['Hardware', 'Market', 'Warehouse'],
            pickup: { label: 'LSFC Loading Bay', coords: { x: -52.2, y: -2520.5, z: 6.1 } },
            cargo: 'Crates',
            requiredCargo: 6,
            routes: [route('Paleto Hardware', -260, 6066, '13.4 mi'), route('Sandy Shores Market', 1960, 3742, '10.6 mi')]
        },
        trailer: {
            label: 'Trailer Hauling',
            description: 'Tractor-trailer depot assignments.',
            cardColor: '#a263ff',
            tags: ['Long Haul', 'Trailer', 'Depot'],
            businesses: ['Railyard', 'Port', 'Paleto'],
            pickup: { label: 'LSFC Tractor Yard', coords: { x: -71.3, y: -2528.9, z: 6.1 } },
            cargo: 'Dry Van',
            requiredCargo: 1,
            routes: [
                route('Paleto Receiving Yard', -246, 6172, '15.2 mi', {
                    trailerKey: 'dryvan',
                    trailerDrop: { label: 'Paleto Receiving Yard', coords: { x: -246, y: 6172, z: 31 } },
                    receiverPed: { label: 'Paleto Yard Receiver', coords: { x: -252, y: 6162, z: 31 } }
                })
            ]
        }
    },
    vehicles: {
        van: [
            { type: 'van', index: 1, label: 'Speedo Express', model: 'speedo', plate: 'LSF 214', minRank: 1, stored: true, photo: '../images/photos/vehicles/speedo.webp' },
            { type: 'van', index: 2, label: 'Rumpo Custom', model: 'rumpo', plate: 'LSF 618', minRank: 2, stored: true, photo: '../images/photos/vehicles/rumpo.webp' }
        ],
        boxtruck: [
            { type: 'boxtruck', index: 1, label: 'Mule Freight', model: 'mule', plate: 'LSF 502', minRank: 1, stored: true, photo: '../images/photos/vehicles/mule2.webp' },
            { type: 'boxtruck', index: 2, label: 'Pounder Custom', model: 'pounder', plate: 'LSF 733', minRank: 3, stored: false, photo: '../images/photos/vehicles/pounder.webp' }
        ],
        trailer: [
            { type: 'trailer', index: 1, label: 'Phantom + Dry Van', model: 'phantom', plate: 'LSF 900', minRank: 2, stored: true, photo: '../images/photos/vehicles/phantom.webp' }
        ]
    },
    garage: [
        { type: 'van', index: 1, label: 'Speedo Express', plate: 'LSF 214', minRank: 1, stored: true, photo: '../images/photos/vehicles/speedo.webp' },
        { type: 'boxtruck', index: 1, label: 'Mule Freight', plate: 'LSF 502', minRank: 1, stored: true, photo: '../images/photos/vehicles/mule2.webp' },
        { type: 'trailer', index: 1, label: 'Phantom + Dry Van', plate: 'LSF 900', minRank: 2, stored: true, photo: '../images/photos/vehicles/phantom.webp' }
    ],
    priorityLoads: {
        van: { ...priorities },
        boxtruck: { ...priorities },
        trailer: { ...priorities }
    },
    payouts: {
        van: { min: 1200, max: 1800 },
        boxtruck: { min: 2400, max: 3400 },
        trailer: { min: 4600, max: 6200 }
    },
    mileagePayout: { Enabled: true, RatePerMile: 125 },
    routeTrailers: {
        dryvan: { label: 'Dry Van Trailer', model: 'trailers2', photo: '../images/photos/trailers/dryvan.webp' }
    },
    reuse: {
        available: true,
        type: 'boxtruck',
        vehicleLabel: 'Pounder Custom',
        plate: 'LSF 733'
    },
    dispatchHome: {
        zoom: { min: 1, max: 2.2, default: 1, step: 0.25 },
        points: [
            { id: 'terminal', category: 'terminal', label: 'LSFC Dispatch', description: 'Dispatch desk and duty check-in.', coords: { x: -41.54, y: -2513.28, z: 6.16 } },
            { id: 'garage', category: 'garage', label: 'Company Garage', description: 'Company fleet pickup.', coords: { x: -69, y: -2527, z: 6.1 } },
            { id: 'van-route', category: 'van', label: 'Van Route Area', description: 'Sample city delivery area.', coords: { x: 1158, y: -326, z: 69 } },
            { id: 'trailer-yard', category: 'trailer', label: 'Paleto Yard', description: 'Sample trailer receiving yard.', coords: { x: -246, y: 6172, z: 31 } }
        ]
    },
    contractor: {
        enabled: true,
        unlocked: true,
        licensed: true,
        rep: 14,
        unlockRank: 2,
        licenseCost: 15000,
        dailyBonus: 1000,
        dailyRepBonus: 2,
        dailyRouteKey: 'paleto-box',
        dailyRouteLabel: 'Paleto Hardware Supply',
        dailyRouteCompleted: false,
        dailyRouteCanChange: true,
        minFuel: 20,
        minCondition: 55,
        cancelFee: 750,
        maxOwnedVehicles: 6,
        vehicles: [
            { id: 101, type: 'boxtruck', typeLabel: 'Box Truck', index: 2, label: 'Pounder Custom', plate: 'PC 101', stored: false, out: true, fuel: 87, condition: 94, mileage: 153.7, originalPrice: 42500, resalePrice: 38250, photo: '../images/photos/vehicles/pounder.webp' }
        ],
        dailyRoutes: [
            { key: 'paleto-box', type: 'boxtruck', typeLabel: 'Box Truck', label: 'Paleto Hardware Supply', destination: 'Paleto Hardware', routeLength: '13.4 mi', minRank: 2, unlocked: true }
        ],
        board: [
            { key: 'board-1', type: 'boxtruck', typeLabel: 'Box Truck', label: 'Hardware Freight', destination: 'Paleto Hardware', priorityKey: 'standard', routeIndex: 1, vehicleId: 101, vehicleLabel: 'Pounder Custom', payout: 5200, rep: 3, canStart: true }
        ],
        market: [
            { type: 'van', index: 1, typeLabel: 'Van', label: 'Speedo Express', price: 18000, minRank: 1, owned: false, photo: '../images/photos/vehicles/speedo.webp' },
            { type: 'boxtruck', index: 2, typeLabel: 'Box Truck', label: 'Pounder Custom', price: 42500, minRank: 3, owned: true, photo: '../images/photos/vehicles/pounder.webp' }
        ]
    },
    companyStats: {
        topDrivers: [{ label: 'Alex Driver', xp: 1850, driverRank: 3, driverRankLabel: 'Route Driver' }],
        mostDeliveries: [{ label: 'Alex Driver', jobsCompleted: 17, reputation: 28 }],
        contractorRep: [{ label: 'Alex Driver', contractorRep: 14, licensed: true }]
    },
    routeHistory: [
        {
            contractId: 'LSF-1048',
            routeLabel: 'Mirror Park 24/7',
            vehicleLabel: 'Speedo Express',
            payout: 1850,
            xp: 42,
            reputation: 2,
            completedAt: 'Preview Session',
            duration: '11 min',
            cargo: '4 / 4',
            conditionLabel: 'Stable'
        }
    ]
};

const activeDispatch = {
    ...previewDispatch,
    currentJob: {
        id: 'LSF-2042',
        contractId: 'LSF-2042',
        label: 'Priority Freight - Paleto Hardware',
        stage: 'Deliver cargo',
        notice: 'Next stop is ready for delivery confirmation.',
        type: 'boxtruck',
        payout: 5525,
        loadedCargo: 4,
        requiredCargo: 6,
        currentStop: 1,
        totalStops: 2,
        destination: 'Paleto Hardware',
        expectedCompletion: '14 min',
        estimatedTime: '18 min est.',
        vehicleLabel: 'Pounder Custom',
        plate: 'LSF 733',
        routeLength: '13.4 mi',
        cargoConditionLabel: 'Stable',
        cargoConditionNote: 'No damage reported.',
        gpsLocked: true,
        radioChatter: 'Dispatch: receiver has your dock lane ready.',
        player: previewDispatch.player,
        routeHistory: previewDispatch.routeHistory
    }
};

const warningDispatch = clone(activeDispatch);
warningDispatch.currentJob = {
    ...warningDispatch.currentJob,
    stage: 'Caution: load stability',
    notice: 'Dispatch flagged rough-road handling. Keep speed steady and avoid hard braking.',
    cargoConditionLabel: 'Caution',
    cargoConditionLevel: 'caution',
    cargoConditionNote: 'Minor load shift detected during the last segment.',
    radioChatter: 'Dispatch: cargo sensors show a load shift. Hold a smooth line to the receiver.',
    contractAlert: {
        label: 'Load Stability Advisory',
        description: 'Cargo condition is vulnerable. Smooth driving preserves payout.'
    }
};

const standbyReceiver = {
    hasActiveRoute: false,
    label: 'Receiver Standby',
    stage: 'No route assigned',
    notice: 'Dispatch is standing by.',
    radioFrequency: '68.9',
    radioChatter: '',
    reuseVehicle: {
        available: true,
        vehicleLabel: 'Pounder Custom',
        plate: 'LSF 733'
    },
    player: previewDispatch.player,
    routeHistory: previewDispatch.routeHistory
};

const serviceBayData = {
    vehicle: { label: 'Pounder Custom', plate: 'LSF 733', type: 'boxtruck', index: 2 },
    state: { engineHealth: 875, bodyHealth: 940, fuel: 76, mileage: 214.6 },
    invoice: { discountPercent: 5 },
    installed: [
        { label: 'Engine', value: 'Stage 1' },
        { label: 'Brakes', value: 'Stock' },
        { label: 'Turbo', value: 'Stage 1 Turbo' },
        { label: 'Livery', value: 'LSFC Yellow' }
    ],
    serviceOptions: [
        { key: 'engine_repair', label: 'Engine Service', description: 'Inspect belts, fluids, and powertrain wear.', price: 850, icon: 'fa-wrench' },
        { key: 'body_repair', label: 'Body Repair', description: 'Straighten panels and repair dock rash.', price: 650, icon: 'fa-spray-can' },
        { key: 'refuel', label: 'Fleet Refuel', description: 'Top off the tank before the next run.', price: 420, icon: 'fa-gas-pump' }
    ],
    upgradeOptions: [
        {
            key: 'engine',
            label: 'Engine Tune',
            icon: 'fa-gauge-high',
            current: 1,
            currentLabel: 'Stage 1',
            removable: false,
            levels: [
                { level: 1, label: 'Stage 1', price: 0, description: 'Currently installed.' },
                { level: 2, label: 'Stage 2', price: 4500, description: 'Improved hill pull and acceleration.' },
                { level: 3, label: 'Stage 3', price: 7200, description: 'Maximum fleet-approved tune.' }
            ]
        },
        {
            key: 'turbo',
            label: 'Turbo',
            icon: 'fa-fan',
            current: 1,
            currentLabel: 'Stage 1 Turbo',
            removable: true,
            levels: [
                { level: 2, label: 'Stage 2 Turbo', price: 5200, description: 'High-flow compressor and revised wastegate duty cycle.' },
                { level: 3, label: 'Stage 3 Turbo', price: 7800, description: 'Hybrid turbocharger with reinforced freight-grade boost control.' }
            ]
        }
    ],
    appearanceOptions: [
        {
            key: 'livery',
            label: 'Fleet Livery',
            icon: 'fa-palette',
            current: 0,
            currentLabel: 'Standard',
            levels: [
                { level: 0, label: 'Standard', price: 0, description: 'Current LSFC livery.' },
                { level: 1, label: 'High Visibility', price: 1200, description: 'Bright yard-safety package.' }
            ]
        }
    ],
    extraOptions: [
        { extraId: 1, label: 'Roof Beacon', description: 'Toggle amber roof beacon.', price: 350, target: true, icon: 'fa-lightbulb' }
    ]
};

const serviceBayStockData = clone(serviceBayData);
serviceBayStockData.vehicle = { label: 'Mule Freight', plate: 'LSF 502', type: 'boxtruck', index: 1 };
serviceBayStockData.state = { engineHealth: 642, bodyHealth: 711, fuel: 42, mileage: 83.4 };
serviceBayStockData.installed = [
    { label: 'Engine', value: 'Stock' },
    { label: 'Brakes', value: 'Stock' },
    { label: 'Turbo', value: 'Stock' },
    { label: 'Tires', value: 'Standard' }
];
serviceBayStockData.upgradeOptions = serviceBayStockData.upgradeOptions.map(option => ({
    ...option,
    current: 0,
    currentLabel: 'Stock',
    removable: false,
    levels: option.key === 'turbo'
        ? [
            { level: 1, label: 'Stage 1 Turbo', price: 3200, description: 'OEM-style forced induction kit with safe boost control.' },
            { level: 2, label: 'Stage 2 Turbo', price: 5200, description: 'High-flow compressor and revised wastegate duty cycle.' },
            { level: 3, label: 'Stage 3 Turbo', price: 7800, description: 'Hybrid turbocharger with reinforced freight-grade boost control.' }
        ]
        : option.levels.map(level => ({ ...level, price: level.level === 1 ? 2800 : level.price }))
}));
serviceBayStockData.appearanceOptions = serviceBayStockData.appearanceOptions.map(option => ({
    ...option,
    current: 0,
    currentLabel: 'Standard'
}));

function installPreviewHooks() {
    const target = childWindow();
    if (!target) return;

    target.GetParentResourceName = () => 'ls_trucking_preview';
    const browserFetch = target.fetch.bind(target);
    target.fetch = (url, options) => {
        const textUrl = String(url || '');
        if (textUrl.startsWith('https://ls_trucking_preview/')) {
            const name = textUrl.split('/').pop();
            log(`NUI callback: ${name}`);
            return Promise.resolve(new Response(JSON.stringify({ success: true, preview: true }), {
                headers: { 'Content-Type': 'application/json' }
            }));
        }
        return browserFetch(url, options);
    };
}

function openDispatch(withActiveJob = false, quiet = false) {
    send({ action: 'open', data: withActiveJob ? activeDispatch : previewDispatch });
    if (!quiet) log(withActiveJob ? 'Opened dispatch with active job sample.' : 'Opened dispatch tablet sample.');
}

function openDispatchData(data, label, quiet = false) {
    send({ action: 'open', data });
    if (!quiet) log(label);
}

function openDispatchTab(tab, data = previewDispatch, label = 'Opened dispatch tab sample.') {
    openDispatchData(data, label, true);
    runAfterFrame(() => {
        clickInFrame(`[data-tab="${tab}"]`);
        log(label);
    });
}

function openMini(contract = activeDispatch.currentJob, label = 'Opened receiver mini sample.', quiet = false) {
    send({ action: 'showMini', contract });
    if (!quiet) log(label);
}

function openDock(contract = activeDispatch.currentJob, label = 'Opened receiver dock sample.', quiet = false) {
    send({ action: 'showMiniDock', contract });
    if (!quiet) log(label);
}

function openServiceBay(data = serviceBayData, label = 'Opened service bay sample.', quiet = false) {
    send({ action: 'serviceBayOpen', data: clone(data) });
    if (!quiet) log(label);
}

function fillServiceBayCart() {
    runAfterFrame(() => clickInFrame('[data-service-add]'), 80);
    runAfterFrame(() => clickInFrame('[data-page="upgrades"]'), 150);
    runAfterFrame(() => clickInFrame('[data-cycle-add="engine"]'), 230);
    runAfterFrame(() => clickInFrame('[data-cycle-add="turbo"]'), 300);
    runAfterFrame(() => clickInFrame('[data-page="appearance"]'), 380);
    runAfterFrame(() => clickInFrame('[data-cycle-add="livery"]'), 460);
    runAfterFrame(() => clickInFrame('[data-extra-add="1"]'), 540);
}

function openServiceBayCart() {
    openServiceBay(serviceBayData, 'Opened service bay with populated work order.', true);
    fillServiceBayCart();
    runAfterFrame(() => log('Opened service bay with populated work order.'), 640);
}

function openServiceBayProcessing() {
    openServiceBay(serviceBayData, 'Opened service bay install progress sample.', true);
    fillServiceBayCart();
    runAfterFrame(() => {
        send({
            action: 'serviceBayInstallProgress',
            phase: 'start',
            label: 'Installing Stage 2 Turbo',
            detail: 'Calibrating boost control and torque delivery',
            index: 2,
            total: 4,
            percent: 0,
            duration: 6500
        });
        log('Opened service bay install progress sample.');
    }, 700);
}

function closeAll(quiet = false) {
    ['close', 'hideMini', 'hideMiniDock', 'serviceBayClose', 'hideFreightDialog', 'hideTrailerCargoEditor'].forEach(action => send({ action }));
    if (!quiet) log('Closed preview UI.');
}

function stopPreviewLoop(showLog = true) {
    if (previewLoopTimer) clearInterval(previewLoopTimer);
    previewLoopTimer = null;
    previewLoopStep = 0;
    if (showLog) log('Stopped preview loop.');
}

function startOpenCloseLoop(label, openFn) {
    stopPreviewLoop(false);
    const maxSteps = 16;
    previewLoopStep = 0;

    const runStep = () => {
        if (previewLoopStep >= maxSteps) {
            stopPreviewLoop(false);
            closeAll(true);
            log(`${label} loop complete.`);
            return;
        }

        if (previewLoopStep % 2 === 0) {
            openFn(true);
        } else {
            closeAll(true);
        }
        previewLoopStep += 1;
    };

    runStep();
    previewLoopTimer = window.setInterval(runStep, 520);
    log(`${label} open/close loop started.`);
}

frame.addEventListener('load', () => {
    installPreviewHooks();
    openDispatch(false);
});

document.addEventListener('click', event => {
    const viewportButton = event.target.closest('[data-preview-viewport]');
    if (viewportButton) {
        setViewport(viewportButton.dataset.previewViewport);
        return;
    }

    const button = event.target.closest('[data-preview-action]');
    if (!button) return;

    const action = button.dataset.previewAction;
    if (action === 'dispatch') openDispatch(false);
    if (action === 'dispatch-active') openDispatch(true);
    if (action === 'dispatch-contractor') openDispatchTab('contractor', previewDispatch, 'Opened dispatch contractor tab sample.');
    if (action === 'dispatch-warning') openDispatchData(warningDispatch, 'Opened dispatch warning state sample.');
    if (action === 'mini') openMini();
    if (action === 'mini-standby') openMini(standbyReceiver, 'Opened receiver standby sample.');
    if (action === 'dock') openDock();
    if (action === 'mini-warning') openMini(warningDispatch.currentJob, 'Opened receiver warning sample.');
    if (action === 'service-stock') openServiceBay(serviceBayStockData, 'Opened stock service bay sample.');
    if (action === 'service') openServiceBay(serviceBayData, 'Opened partial-upgrade service bay sample.');
    if (action === 'service-cart') openServiceBayCart();
    if (action === 'service-processing') openServiceBayProcessing();
    if (action === 'loop-dispatch') startOpenCloseLoop('Dispatch', quiet => openDispatch(true, quiet));
    if (action === 'loop-service') startOpenCloseLoop('Service bay', quiet => openServiceBay(serviceBayData, 'Opened service bay sample.', quiet));
    if (action === 'stop-loop') stopPreviewLoop();
    if (action === 'close') closeAll();
});
