const app = document.getElementById('app');
const mini = document.getElementById('mini');
const contractList = document.getElementById('contractList');
const startBtn = document.getElementById('startBtn');
const vehicleSelect = document.getElementById('vehicleSelect');
const prioritySelect = document.getElementById('prioritySelect');
const priorityInfo = document.getElementById('priorityInfo');
const reuseBox = document.getElementById('reuseBox');
const reuseVehicleCheck = document.getElementById('reuseVehicleCheck');
const reuseVehicleText = document.getElementById('reuseVehicleText');
const vehicleSelectWrap = document.getElementById('vehicleSelectWrap');
const currentJobBox = document.getElementById('currentJobBox');
const noCurrentJob = document.getElementById('noCurrentJob');
const cancelJobBtn = document.getElementById('cancelJobBtn');
const returnGarageBtn = document.getElementById('returnGarageBtn');
const lastRouteSummaryBox = document.getElementById('lastRouteSummaryBox');
const lastSummaryTitle = document.getElementById('lastSummaryTitle');
const lastSummaryPayout = document.getElementById('lastSummaryPayout');
const lastSummaryGrid = document.getElementById('lastSummaryGrid');
const freightDialog = document.getElementById('freightDialog');
const freightDialogTitle = document.getElementById('freightDialogTitle');
const freightDialogContent = document.getElementById('freightDialogContent');
const freightDialogClose = document.getElementById('freightDialogClose');

let selectedContract = 'van';
let selectedVehicleIndex = 1;
let selectedPriority = { van: 'standard', boxtruck: 'standard', trailer: 'standard' };
let previewRouteCache = {};
let dispatchData = null;

let uiSoundSettings = {
    enabled: false,
    volume: 0.22,
    path: 'sounds/',
    click: 'click.wav',
    confirm: 'confirm.wav',
    error: 'error.wav',
    alert: 'alert.wav',
    destination: 'destination.wav',
    secure: 'secure.wav'
};

function configureUISounds(config) {
    const soundConfig = config?.uiSounds || {};
    uiSoundSettings.enabled = soundConfig.Sounds === true || soundConfig.Enabled === true;
    uiSoundSettings.volume = Number(soundConfig.SoundVolume ?? soundConfig.Volume ?? 0.22);
    uiSoundSettings.path = soundConfig.SoundsPath || 'sounds/';
    uiSoundSettings.click = soundConfig.ClickSound || 'click.wav';
    uiSoundSettings.confirm = soundConfig.ConfirmSound || 'confirm.wav';
    uiSoundSettings.error = soundConfig.ErrorSound || 'error.wav';
    uiSoundSettings.alert = soundConfig.AlertSound || 'alert.wav';
    uiSoundSettings.destination = soundConfig.DestinationSound || 'destination.wav';
    uiSoundSettings.secure = soundConfig.SecureSound || 'secure.wav';
}

function playUISound(type = 'click') {
    if (!uiSoundSettings.enabled) return;

    const filename = type === 'confirm'
        ? uiSoundSettings.confirm
        : type === 'error'
            ? uiSoundSettings.error
            : type === 'alert'
                ? uiSoundSettings.alert
                : type === 'destination'
                    ? uiSoundSettings.destination
                    : type === 'secure'
                        ? uiSoundSettings.secure
                        : uiSoundSettings.click;

    try {
        const audio = new Audio(`${uiSoundSettings.path}${filename}`);
        audio.volume = Math.max(0, Math.min(1, uiSoundSettings.volume));
        audio.play().catch(() => {});
    } catch (_) {}
}


const contractMeta = {
    van: { number: '01', accent: '#e6ab00', payout: '$1,200 - $2,200', badge: 'LOCAL' },
    boxtruck: { number: '02', accent: '#3f8cff', payout: '$2,400 - $4,200', badge: 'FREIGHT' },
    trailer: { number: '03', accent: '#a263ff', payout: '$5,000 - $9,500', badge: 'TRAILER' }
};


function clearFreightDialogActions() {
    const actions = document.getElementById('freightDialogActions');
    if (!actions) return;
    actions.innerHTML = '';
}

function createFreightButton(label, className, onClick) {
    const button = document.createElement('button');
    button.innerText = label || 'Close';
    button.className = className || '';
    button.addEventListener('click', onClick);
    return button;
}

function escapeHTML(value) {
    return String(value ?? '')
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#039;');
}

function formatFreightPrintout(content = '') {
    const rawLines = String(content || '').replace(/\r/g, '').split('\n');
    const html = [];
    let activeSection = '';

    const slugSection = (value = '') => String(value)
        .toLowerCase()
        .replace(/[^a-z0-9]+/g, '-')
        .replace(/^-+|-+$/g, '');

    // All key/value printout rows use left labels with right-aligned data values.
    // This gives route summaries, manifests, and checklists a cleaner official printout layout.
    const rightAlignedSections = 'all';

    const pushSection = (title) => {
        activeSection = slugSection(title);
        html.push(`<div class="print-section print-section-${activeSection}">${escapeHTML(title)}</div>`);
    };

    for (let i = 0; i < rawLines.length; i += 1) {
        const raw = rawLines[i] || '';
        const line = raw.trim();
        const nextLine = (rawLines[i + 1] || '').trim();

        if (!line) {
            html.push('<div class="print-spacer"></div>');
            continue;
        }

        if (/^-{3,}$/.test(line)) {
            continue;
        }

        if (nextLine && /^-{3,}$/.test(nextLine)) {
            pushSection(line);
            i += 1;
            continue;
        }

        if (/^\*\*(.+)\*\*$/.test(line)) {
            pushSection(line.replace(/^\*\*|\*\*$/g, ''));
            continue;
        }

        const stopMatch = line.match(/^Stop\s+(\d+)\s*[-–]\s*(.+)$/i);
        if (stopMatch) {
            const stopNumber = String(stopMatch[1]).padStart(2, '0');
            const stopName = stopMatch[2].trim() || 'Delivery Stop';
            html.push(`<div class="print-row print-row-right print-stop-row"><span>STOP ${escapeHTML(stopNumber)}</span><strong>${escapeHTML(stopName)}</strong></div>`);
            continue;
        }

        const colonIndex = line.indexOf(':');
        if (colonIndex > 0) {
            const label = line.slice(0, colonIndex).replace(/^[-•]\s*/, '').trim();
            const value = line.slice(colonIndex + 1).trim() || '—';
            const rowClass = rightAlignedSections === 'all' || rightAlignedSections.has?.(activeSection) ? 'print-row print-row-right' : 'print-row';
            html.push(`<div class="${rowClass}"><span>${escapeHTML(label)}</span><strong>${escapeHTML(value)}</strong></div>`);
            continue;
        }

        if (/^[-•]\s+/.test(line) || /^\d+\.\s+/.test(line)) {
            const noteClass = rightAlignedSections === 'all' || rightAlignedSections.has?.(activeSection) ? 'print-note print-note-right' : 'print-note';
            html.push(`<div class="${noteClass}">${escapeHTML(line)}</div>`);
            continue;
        }

        html.push(`<div class="print-line">${escapeHTML(line)}</div>`);
    }

    return `<div class="printout-paper">${html.join('')}</div>`;
}

function showFreightDialog(data = {}) {
    if (!freightDialog) return;

    freightDialogTitle.innerText = data.header || 'Freight Dispatch';
    freightDialogContent.classList.remove('with-form');
    freightDialogContent.classList.add('printout');
    freightDialogContent.innerHTML = formatFreightPrintout(data.content || '');
    clearFreightDialogActions();

    const actions = document.getElementById('freightDialogActions');
    const mode = data.mode || 'info';

    if (mode === 'confirm') {
        actions.appendChild(createFreightButton(data.cancelLabel || 'Cancel', 'secondary', () => {
            playUISound('click');
            post('freightDialogResult', { confirmed: false });
        }));

        actions.appendChild(createFreightButton(data.confirmLabel || 'Confirm', '', () => {
            playUISound('confirm');
            post('freightDialogResult', { confirmed: true });
        }));
    } else {
        actions.appendChild(createFreightButton(data.closeLabel || 'Close', '', closeFreightDialog));
    }

    freightDialog.classList.remove('hidden');
    playUISound('confirm');
}

function showFreightCancelDialog(data = {}) {
    if (!freightDialog) return;

    freightDialogTitle.innerText = data.header || 'Cancel Freight Route';
    clearFreightDialogActions();

    const repLoss = Number(data.repLoss || 0);
    const reasons = Array.isArray(data.reasons) ? data.reasons : [];

    freightDialogContent.classList.remove('printout');
    freightDialogContent.classList.add('with-form');

    const options = reasons.map((reason) => {
        const value = String(reason.value || reason.label || 'other');
        const label = String(reason.label || reason.value || 'Other');
        return `<option value="${value}">${label}</option>`;
    }).join('');

    freightDialogContent.innerHTML = `
        <div class="freight-form">
            <div class="freight-form-warning">
                Cancelling this route will remove <strong>${repLoss}</strong> reputation.
            </div>

            <label class="freight-form-label" for="freightCancelReason">Reason for cancel</label>
            <select id="freightCancelReason" class="freight-form-select">
                ${options}
            </select>

            <label class="freight-form-check">
                <input id="freightCancelConfirm" type="checkbox">
                <span>I understand this route will be cancelled and reputation will be lost.</span>
            </label>

            <div id="freightCancelError" class="freight-form-error hidden">
                Select a reason and check the confirmation box before cancelling.
            </div>
        </div>
    `;

    const actions = document.getElementById('freightDialogActions');

    actions.appendChild(createFreightButton('Go Back', 'secondary', () => {
        playUISound('click');
        post('freightDialogResult', { confirmed: false });
    }));

    actions.appendChild(createFreightButton('Cancel Route', 'danger', () => {
        const reason = document.getElementById('freightCancelReason')?.value;
        const confirmed = document.getElementById('freightCancelConfirm')?.checked;
        const error = document.getElementById('freightCancelError');

        if (!reason || !confirmed) {
            if (error) error.classList.remove('hidden');
            playUISound('error');
            return;
        }

        playUISound('alert');
        post('freightDialogResult', {
            confirmed: true,
            reason
        });
    }));

    freightDialog.classList.remove('hidden');
    playUISound('alert');
}

function hideFreightDialog() {
    if (!freightDialog) return;
    freightDialog.classList.add('hidden');
    freightDialogContent.classList.remove('with-form');
    freightDialogContent.classList.remove('printout');
    freightDialogContent.innerHTML = '';
    clearFreightDialogActions();
}

function closeFreightDialog() {
    playUISound('click');
    post('freightDialogClose');
}

if (freightDialog) {
    freightDialog.addEventListener('click', (event) => {
        if (event.target === freightDialog) closeFreightDialog();
    });
}

function post(name, data = {}) {
    fetch(`https://${GetParentResourceName()}/${name}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data)
    });
}

function formatMoney(value) {
    const number = Number(value || 0);
    return `$${number.toLocaleString()}`;
}


function formatSeconds(seconds) {
    seconds = Math.max(0, Math.floor(Number(seconds || 0)));
    const minutes = Math.floor(seconds / 60);
    const secs = seconds % 60;

    if (minutes >= 60) {
        const hours = Math.floor(minutes / 60);
        const mins = minutes % 60;
        return `${hours}h ${mins}m`;
    }

    return `${minutes}m ${String(secs).padStart(2, '0')}s`;
}

function formatAdjustmentPercent(percent) {
    const value = Number(percent || 0);
    const sign = value > 0 ? '+' : '';
    return `${sign}${Math.round(value * 100)}%`;
}

function titleFromType(type) {
    if (type === 'van') return 'Van Delivery';
    if (type === 'boxtruck') return 'Box Truck Delivery';
    if (type === 'trailer') return 'Trailer Hauling';
    return 'Delivery';
}

function playerRank() {
    return Number(dispatchData?.player?.rank || 1);
}

function garageDisplayLabel(label, type) {
    if (type === 'trailer' && label && label.includes('+')) return label.split('+')[0].trim();
    return label || 'Company Vehicle';
}

function previewImageForVehicle(vehicle, type) {
    if (!vehicle) return '';
    return vehicle.photo || '';
}

function getVehicles(type) {
    if (!dispatchData || !dispatchData.vehicles) return [];
    return dispatchData.vehicles[type] || [];
}

function getSelectedVehicle(type) {
    const vehicles = getVehicles(type);
    return vehicles[selectedVehicleIndex - 1] || vehicles[0] || {};
}

function getPriorities(type) {
    const raw = dispatchData?.priorityLoads?.[type] || {};
    return Object.entries(raw)
        .map(([key, value]) => ({ key, ...value }))
        .sort((a, b) => (a.order || 99) - (b.order || 99));
}

function getSelectedPriority(type) {
    const priorities = getPriorities(type);
    const key = selectedPriority[type] || 'standard';
    return priorities.find(priority => priority.key === key) || priorities[0] || { key: 'standard', label: 'Standard', minRank: 1, payoutMultiplier: 1.0, xpMultiplier: 1.0, repBonus: 0 };
}


function getPreviewRouteCacheKey(type) {
    return `${type}:${selectedPriority[type] || 'standard'}`;
}

function chooseRandomRoute(routes) {
    if (!routes || routes.length === 0) return null;
    return routes[Math.floor(Math.random() * routes.length)];
}

function clearPreviewRoute(type) {
    if (type) {
        delete previewRouteCache[getPreviewRouteCacheKey(type)];
        return;
    }
    previewRouteCache = {};
}

function canUsePriority(priority) {
    return playerRank() >= Number(priority.minRank || 1);
}

function canUseVehicle(vehicle) {
    return playerRank() >= Number(vehicle.minRank || 1);
}

function canReuseCurrentVehicle(type) {
    if (!dispatchData || !dispatchData.reuse || !dispatchData.reuse.available) return false;
    if (!dispatchData.config || !dispatchData.config.allowVehicleReuseAfterRoute) return false;
    if (dispatchData.config.requireSameTypeForVehicleReuse && dispatchData.reuse.type !== type) return false;
    return true;
}

function setTab(tab) {
    document.querySelectorAll('.nav').forEach(el => el.classList.toggle('active', el.dataset.tab === tab));
    document.querySelectorAll('.tab-page').forEach(el => el.classList.add('hidden'));
    document.getElementById(`page-${tab}`).classList.remove('hidden');
}

document.querySelectorAll('.nav').forEach(nav => nav.addEventListener('click', () => { playUISound('click'); setTab(nav.dataset.tab); }));

function renderPlayer(data) {
    const p = data.player || {};
    document.getElementById('rankText').innerText = `RANK ${p.rank || 1}`;
    document.getElementById('rankLabel').innerText = p.rankLabel || 'New Hire';
    document.getElementById('jobsText').innerText = p.jobsCompleted || 0;
    document.getElementById('repText').innerText = p.reputation || '0';
    document.getElementById('walletText').innerText = formatMoney(p.wallet);
    document.getElementById('playerName').innerText = p.name || 'Driver';
    document.getElementById('citizenId').innerText = `CID: ${p.citizenid || 'N/A'}`;
    const jobText = p.jobText || (p.job ? `${p.job.label || p.job.name || 'Unemployed'} - ${p.job.gradeName || p.job.gradeLevel || 'None'}` : 'Unemployed - None');
    document.getElementById('playerJob').innerText = jobText;
    document.getElementById('companyRank').innerText = `Rank ${p.rank || 1}`;
    document.getElementById('companyRankLabel').innerText = p.rankLabel || 'New Hire';
    document.getElementById('companyXp').innerText = p.xp || 0;
    document.getElementById('companyNextXp').innerText = `Next rank: ${p.nextRankXp || 0} XP`;
    document.getElementById('companyRep').innerText = p.reputation || 0;
    document.getElementById('companyJobs').innerText = p.jobsCompleted || 0;
    document.getElementById('companyEarned').innerText = formatMoney(p.wallet);
    document.getElementById('companyCancelled').innerText = p.totalCancelled || 0;
    document.getElementById('radioFrequency').innerText = data.radioFrequency || data.config?.radioFrequency || 'CH. 68.9';
}


function renderLastRouteSummary(summary) {
    if (!lastRouteSummaryBox || !lastSummaryGrid) return;

    if (!summary) {
        lastRouteSummaryBox.classList.add('hidden');
        return;
    }

    const timeData = summary.time || {};
    const adjustments = Array.isArray(summary.adjustments)
        ? summary.adjustments.filter((adj) => adj && Number(adj.percent || 0) !== 0)
        : [];

    const adjustmentsText = adjustments.length > 0
        ? adjustments.map((adj) => `${adj.label || 'Adjustment'} ${formatAdjustmentPercent(adj.percent)}`).join(' • ')
        : 'None';

    lastSummaryTitle.innerText = `${titleFromType(summary.contractType)}${summary.priorityLabel ? ` • ${summary.priorityLabel}` : ''}`;
    lastSummaryPayout.innerText = formatMoney(summary.payout);

    const rows = [
        ['Driver', summary.driverName || 'Driver'],
        ['Job / Grade', summary.jobText || 'Unknown'],
        ['Completed At', summary.completedAt || 'N/A'],
        ['Route', summary.routeLabel || 'Completed Route'],
        ['Route Length', summary.routeLength || 'N/A'],
        ['Vehicle', summary.vehicleLabel || 'Company Vehicle'],
        ['Estimated Time', formatSeconds(timeData.estimatedSeconds || summary.estimatedSeconds || 0)],
        ['Completed In', formatSeconds(timeData.elapsedSeconds || 0)],
        ['Timing Result', timeData.label || 'Complete'],
        ['Dispatch Event', summary.randomEvent?.label || 'None'],
        ['Payout Adjustments', adjustmentsText],
        ['Base Payout', formatMoney(summary.basePayout || summary.payout || 0)],
        ['Final Payout', formatMoney(summary.payout || 0)],
        ['XP / Rep', `${summary.xp || 0} XP • ${summary.rep || 0} Rep`]
    ];

    if (summary.contractType === 'trailer') {
        rows.splice(7, 0, ['Trailer Damage', `${Math.floor(Number(summary.damagePercent || 0))}%`]);
    }

    lastSummaryGrid.innerHTML = rows.map(([label, value]) => `
        <div class="summary-field">
            <small>${label}</small>
            <strong>${value}</strong>
        </div>
    `).join('');

    lastRouteSummaryBox.classList.remove('hidden');
}

function renderCurrentJob(data) {
    const job = data.currentJob;
    if (!job) {
        currentJobBox.classList.add('hidden');
        noCurrentJob.classList.remove('hidden');
        return;
    }

    currentJobBox.classList.remove('hidden');
    noCurrentJob.classList.add('hidden');
    document.getElementById('currentJobTitle').innerText = job.label || 'Active Job';
    document.getElementById('currentJobStage').innerText = job.stage || 'Active route';
    document.getElementById('currentJobPayout').innerText = formatMoney(job.payout);
    document.getElementById('currentJobCargo').innerText = `${job.loadedCargo || 0} / ${job.requiredCargo || 0}`;
    document.getElementById('currentJobStops').innerText = `${job.currentStop || 0} / ${job.totalStops || 0}`;
}

function renderGarage(data) {
    const garageList = document.getElementById('garageList');
    garageList.innerHTML = '';

    (data.garage || []).forEach(vehicle => {
        const card = document.createElement('div');
        card.className = 'garage-card';
        const status = vehicle.stored ? 'Stored' : 'Out';
        const minRank = Number(vehicle.minRank || 1);
        const locked = playerRank() < minRank;
        const image = vehicle.photo || '';

        card.innerHTML = `
            <img src="${image}" alt="${vehicle.label || 'Vehicle'}">
            <strong>${garageDisplayLabel(vehicle.label, vehicle.type)}</strong>
            <small>${titleFromType(vehicle.type)} • ${vehicle.plate || 'NO PLATE'} • ${status}</small>
            <small class="rank-tag ${locked ? 'locked' : ''}">${locked ? `Requires Rank ${minRank}` : `Rank ${minRank}+`}</small>
            <button data-type="${vehicle.type}" data-index="${vehicle.index}" ${locked ? 'disabled' : ''}>${locked ? 'Locked' : 'Spawn Vehicle'}</button>
        `;

        card.querySelector('button').addEventListener('click', () => {
            if (locked) { playUISound('error'); return; }
            playUISound('confirm');
            post('spawnGarageVehicle', { vehicleType: vehicle.type, vehicleIndex: vehicle.index });
        });

        garageList.appendChild(card);
    });
}

function renderRanks(data) {
    const rankList = document.getElementById('rankList');
    rankList.innerHTML = '';

    (data.ranks || []).forEach(rank => {
        const row = document.createElement('div');
        row.className = 'rank-row';
        row.innerHTML = `<strong>Rank ${rank.rank} - ${rank.label}</strong><span>${rank.xp} XP</span>`;
        rankList.appendChild(row);
    });
}

function renderPrioritySelector(type) {
    const priorities = getPriorities(type);
    prioritySelect.innerHTML = '';

    if (!selectedPriority[type] || !priorities.some(priority => priority.key === selectedPriority[type])) {
        selectedPriority[type] = 'standard';
    }

    priorities.forEach(priority => {
        const option = document.createElement('option');
        option.value = priority.key;
        option.disabled = !canUsePriority(priority);
        option.innerText = `${priority.shortLabel || priority.label} ${option.disabled ? `(Rank ${priority.minRank})` : ''}`;
        prioritySelect.appendChild(option);
    });

    const current = priorities.find(priority => priority.key === selectedPriority[type]);
    if (!current || !canUsePriority(current)) {
        const firstUnlocked = priorities.find(canUsePriority) || priorities[0];
        selectedPriority[type] = firstUnlocked?.key || 'standard';
    }

    prioritySelect.value = selectedPriority[type];
    updatePriorityInfo();
}

function updatePriorityInfo() {
    const priority = getSelectedPriority(selectedContract);
    const mult = Number(priority.payoutMultiplier || 1.0);
    const xpMult = Number(priority.xpMultiplier || 1.0);
    const req = Number(priority.minRank || 1);
    priorityInfo.innerText = `${priority.description || 'Standard route'} • Rank ${req}+ • ${Math.round(mult * 100)}% payout • ${Math.round(xpMult * 100)}% XP`;
}

function renderVehicleSelector(type) {
    const vehicles = getVehicles(type);
    vehicleSelect.innerHTML = '';

    vehicles.forEach((vehicle, index) => {
        const option = document.createElement('option');
        option.value = index + 1;
        const locked = !canUseVehicle(vehicle);
        option.disabled = locked;
        option.innerText = `${vehicle.label || `Vehicle ${index + 1}`} ${locked ? `(Rank ${vehicle.minRank})` : ''}`;
        vehicleSelect.appendChild(option);
    });

    selectedVehicleIndex = 1;
    const firstUnlocked = vehicles.findIndex(canUseVehicle);
    if (firstUnlocked >= 0) selectedVehicleIndex = firstUnlocked + 1;
    vehicleSelect.value = String(selectedVehicleIndex);

    updateReuseBox();
    updateVehiclePreview();
}

function updateReuseBox() {
    const canReuse = canReuseCurrentVehicle(selectedContract);
    reuseVehicleCheck.checked = false;

    if (!canReuse) {
        reuseBox.classList.add('hidden');
        vehicleSelectWrap.classList.remove('hidden');
        return;
    }

    reuseBox.classList.remove('hidden');
    const reuse = dispatchData.reuse || {};
    reuseVehicleText.innerText = `Available: ${reuse.vehicleLabel || 'Current Company Vehicle'}`;
    vehicleSelectWrap.classList.remove('hidden');
}

function updateVehiclePreview() {
    const usingReuse = reuseVehicleCheck.checked && canReuseCurrentVehicle(selectedContract);

    if (usingReuse) {
        document.getElementById('selectedVehicleName').innerText = dispatchData.reuse.vehicleLabel || 'Current Company Vehicle';
        const img = document.getElementById('vehiclePhoto');
        img.src = '';
        img.style.display = 'none';
        vehicleSelectWrap.classList.add('hidden');
        return;
    }

    vehicleSelectWrap.classList.remove('hidden');
    const vehicle = getSelectedVehicle(selectedContract);
    document.getElementById('selectedVehicleName').innerText = vehicle.label || 'Company Vehicle';

    const img = document.getElementById('vehiclePhoto');
    const previewPhoto = previewImageForVehicle(vehicle, selectedContract);
    img.src = previewPhoto;
    img.style.display = previewPhoto ? 'block' : 'none';
}

function renderContracts(data) {
    contractList.innerHTML = '';
    const contracts = data.contracts || {};

    ['van', 'boxtruck', 'trailer'].forEach(type => {
        const contract = contracts[type];
        if (!contract) return;

        const meta = contractMeta[type];
        const vehicle = getVehicles(type)[0] || {};
        const cardImage = previewImageForVehicle(vehicle, type);
        const priority = getSelectedPriority(type);
        const card = document.createElement('div');
        card.className = `contract-card ${selectedContract === type ? 'selected' : ''}`;
        card.style.setProperty('--accent', contract.cardColor || meta.accent);
        card.dataset.type = type;

        card.innerHTML = `
            <img class="vehicle-photo-card" src="${cardImage}" alt="${vehicle.label || 'Vehicle'}">
            <div>
                <div class="card-title">${contract.label}</div>
                <div class="card-desc">${contract.description}</div>
                <div class="tags">
                    ${(contract.tags || []).map(tag => `<span>${tag}</span>`).join('')}
                    <span>${priority.shortLabel || priority.label}</span>
                </div>
                <div class="businesses">${(contract.businesses || []).join(' • ')}</div>
            </div>
            <div class="card-stats">
                <small>PAYOUT</small>
                <div class="payout">${meta.payout}</div>
                <small>BEST LOAD</small>
                <div class="difficulty">${priority.shortLabel || priority.label}</div>
            </div>
        `;

        card.addEventListener('click', () => {
            playUISound('click');
            selectedContract = type;
            selectedVehicleIndex = 1;
            renderContracts(dispatchData);
            renderSelected(contract, type);
            renderPrioritySelector(type);
            renderVehicleSelector(type);
        });

        contractList.appendChild(card);
    });
}

function distanceBetween(a, b) {
    if (!a || !b) return 0;
    const dx = (a.x || 0) - (b.x || 0);
    const dy = (a.y || 0) - (b.y || 0);
    const dz = (a.z || 0) - (b.z || 0);
    return Math.sqrt(dx * dx + dy * dy + dz * dz);
}

function estimateRouteLength(contract, route) {
    if (!route) return 'N/A';
    if (route.routeLength) return route.routeLength;

    const points = [];
    if (contract.pickup?.coords) points.push(contract.pickup.coords);
    if (route.dropoffs) route.dropoffs.forEach(stop => stop.coords && points.push(stop.coords));
    if (route.trailerDrop?.coords) points.push(route.trailerDrop.coords);
    if (route.receiverPed?.coords) points.push(route.receiverPed.coords);

    let total = 0;
    for (let i = 1; i < points.length; i++) total += distanceBetween(points[i - 1], points[i]);
    if (total <= 0) return 'N/A';

    return `${(total / 1609.34).toFixed(1)} mi est.`;
}



function parseMilesFromLength(lengthText) {
    if (!lengthText) return null;
    const match = String(lengthText).match(/([\d.]+)/);
    return match ? Number(match[1]) : null;
}

function estimateRouteTime(contract, type, route, priority) {
    if (!route) return 'N/A';
    if (route.estimatedTime) return route.estimatedTime;
    if (route.estimatedSeconds) {
        const min = Math.floor(route.estimatedSeconds / 60);
        return `${min} min`;
    }

    const length = estimateRouteLength(contract, route);
    const miles = parseMilesFromLength(length);

    if (!miles) {
        const fallback = type === 'trailer' ? 15 : type === 'boxtruck' ? 12 : 9;
        return `${fallback} min est.`;
    }

    const base = type === 'trailer' ? 8 : type === 'boxtruck' ? 6 : 4;
    const perMile = type === 'trailer' ? 2.15 : type === 'boxtruck' ? 1.85 : 1.65;
    let minutes = Math.ceil(base + miles * perMile);

    if (priority?.key === 'priority') minutes = Math.max(5, minutes - 1);
    if (priority?.key === 'government') minutes += 2;
    if (priority?.key === 'military') minutes += 3;

    return `${minutes} min est.`;
}


function getRouteTrailer(route, priority) {
    if (!route && !priority) return null;

    const key = route?.trailerKey || priority?.defaultTrailerKey || 'dryvan';
    const trailer = dispatchData?.routeTrailers?.[key];

    if (!trailer) return null;

    return {
        key,
        label: trailer.label || trailer.model || key,
        model: trailer.model,
        photo: trailer.photo
    };
}

function getPreviewRoute(contract, type) {
    const key = getPreviewRouteCacheKey(type);

    if (previewRouteCache[key]) {
        return previewRouteCache[key];
    }

    const priority = getSelectedPriority(type);
    const pool = priority.routes && priority.routes.length > 0
        ? priority.routes
        : (contract.routes || []);

    previewRouteCache[key] = chooseRandomRoute(pool);
    return previewRouteCache[key];
}

function renderRoutePreview(contract, type) {
    const list = document.getElementById('routePreviewList');
    const badge = document.getElementById('routeTypeBadge');
    const priority = getSelectedPriority(type);
    const route = getPreviewRoute(contract, type);

    list.innerHTML = '';
    badge.innerText = priority.badge || contractMeta[type]?.badge || 'ROUTE';

    const steps = [];
    steps.push(contract.pickup?.label || 'Pickup');

    if (type === 'trailer') {
        const assignedTrailer = getRouteTrailer(route, priority);
        if (assignedTrailer) steps.push(`Assigned Trailer: ${assignedTrailer.label}`);
    }

    if (route) {
        if (route.dropoffs) route.dropoffs.forEach(stop => steps.push(stop.label));
        if (route.trailerDrop) {
            steps.push(route.trailerDrop.label);
            if (route.receiverPed) steps.push(route.receiverPed.label);
        }
    }

    steps.slice(0, 8).forEach((step, index) => {
        const row = document.createElement('div');
        row.className = 'route-step';
        row.innerHTML = `<span>${index + 1}</span><strong>${step}</strong>`;
        list.appendChild(row);
    });

    document.getElementById('routeLengthText').innerText = estimateRouteLength(contract, route);
    const timeText = document.getElementById('routeTimeText');
    if (timeText) timeText.innerText = estimateRouteTime(contract, type, route, priority);
}


function updateSelectedRouteTrailerPreview(contract, type, route, priority) {
    let wrap = document.getElementById('routeTrailerPreview');
    const vehiclePreview = document.getElementById('vehiclePreview');

    if (!wrap && vehiclePreview) {
        wrap = document.createElement('div');
        wrap.id = 'routeTrailerPreview';
        wrap.className = 'vehicle-preview route-trailer-preview hidden';
        wrap.innerHTML = `
            <img id="routeTrailerPhoto" src="" alt="Route Trailer">
            <div>
                <small>ASSIGNED TRAILER</small>
                <strong id="routeTrailerName">Route Trailer</strong>
            </div>
        `;
        vehiclePreview.insertAdjacentElement('afterend', wrap);
    }

    if (!wrap) return;

    if (type !== 'trailer') {
        wrap.classList.add('hidden');
        return;
    }

    const assignedTrailer = getRouteTrailer(route, priority);

    if (!assignedTrailer) {
        wrap.classList.add('hidden');
        return;
    }

    const img = document.getElementById('routeTrailerPhoto');
    const name = document.getElementById('routeTrailerName');

    if (img) {
        img.src = assignedTrailer.photo || '';
        img.style.display = assignedTrailer.photo ? 'block' : 'none';
    }

    if (name) name.innerText = assignedTrailer.label || 'Route Trailer';
    wrap.classList.remove('hidden');
}

function renderSelected(contract, type) {
    const route = getPreviewRoute(contract, type);
    let firstDropoff = 'Selected Route';

    if (route && route.dropoffs && route.dropoffs[0]) firstDropoff = route.dropoffs[0].label;
    else if (route && route.trailerDrop) firstDropoff = route.trailerDrop.label;

    const priority = getSelectedPriority(type);
    document.getElementById('selectedType').innerText = `${titleFromType(type)} • ${priority.shortLabel || priority.label}`;
    document.getElementById('pickupText').innerText = contract.pickup?.label || 'Pickup Location';
    document.getElementById('dropoffText').innerText = firstDropoff;
    
    if (type === 'trailer') {
        const assignedTrailer = getRouteTrailer(route, priority);
        document.getElementById('cargoText').innerText = assignedTrailer ? assignedTrailer.label : `${contract.cargo || 'Trailer'} x1`;
    } else {
        document.getElementById('cargoText').innerText = `${contract.cargo || 'Cargo'} x${contract.requiredCargo || 1}`;
    }

    updateSelectedRouteTrailerPreview(contract, type, route, priority);
    renderRoutePreview(contract, type);
    updatePriorityInfo();
}

function openUI(data) {
    dispatchData = data;
    configureUISounds(data.config || {});
    selectedContract = 'van';
    selectedVehicleIndex = 1;
    selectedPriority = { van: 'standard', boxtruck: 'standard', trailer: 'standard' };
    clearPreviewRoute();

    renderPlayer(data);
    renderCurrentJob(data);
    renderLastRouteSummary(data.lastRouteSummary);
    renderGarage(data);
    renderRanks(data);
    renderContracts(data);
    renderPrioritySelector('van');
    renderSelected(data.contracts.van, 'van');
    renderVehicleSelector('van');
    setTab('dispatch');
    app.classList.remove('hidden');
}

function closeUI() {
    app.classList.add('hidden');
}

vehicleSelect.addEventListener('change', () => {
    playUISound('click');
    selectedVehicleIndex = Number(vehicleSelect.value || 1);
    updateVehiclePreview();
});

prioritySelect.addEventListener('change', () => {
    playUISound('click');
    selectedPriority[selectedContract] = prioritySelect.value || 'standard';
    clearPreviewRoute(selectedContract);
    renderContracts(dispatchData);
    renderSelected(dispatchData.contracts[selectedContract], selectedContract);
});

reuseVehicleCheck.addEventListener('change', () => { playUISound('click'); updateVehiclePreview(); });

startBtn.addEventListener('click', () => {
    playUISound('confirm');
    const reuseVehicle = reuseVehicleCheck.checked && canReuseCurrentVehicle(selectedContract);
    post('startContract', {
        contractType: selectedContract,
        vehicleIndex: selectedVehicleIndex,
        priorityKey: selectedPriority[selectedContract] || 'standard',
        reuseVehicle
    });
});

cancelJobBtn.addEventListener('click', () => { playUISound('error'); post('cancelCurrentJob'); });
returnGarageBtn.addEventListener('click', () => { playUISound('confirm'); post('returnGarageVehicle'); });

document.addEventListener('keydown', event => {
    if (event.key === 'Escape') post('close');
});

window.addEventListener('message', event => {
    const data = event.data;

    if (data.action === 'open') openUI(data.data);
    if (data.action === 'close') closeUI();
    if (data.action === 'showFreightDialog') showFreightDialog(data);
    if (data.action === 'showFreightCancelDialog') showFreightCancelDialog(data);
    if (data.action === 'hideFreightDialog') hideFreightDialog();

    if (data.action === 'playSound') {
        playUISound(data.sound || data.type || 'click');
    }

    if (data.action === 'showMini') {
        const contract = data.contract || {};
        document.getElementById('miniTitle').innerText = contract.label || titleFromType(contract.type) || 'Active Contract';
        document.getElementById('miniPayout').innerText = formatMoney(contract.payout);
        document.getElementById('miniNotice').innerText = contract.notice || 'Follow your route instructions.';
        document.getElementById('miniStage').innerText = contract.stage || 'Active';
        const miniExpected = document.getElementById('miniExpected');
        const miniExpectedText = document.getElementById('miniExpectedText');
        if (miniExpected && miniExpectedText) {
            if (contract.expectedCompletion) {
                miniExpectedText.innerText = contract.expectedCompletion;
                miniExpected.classList.remove('hidden');
            } else {
                miniExpected.classList.add('hidden');
            }
        }
        document.getElementById('miniDestination').innerText = contract.destination || 'N/A';
        const miniDestinationAddress = document.getElementById('miniDestinationAddress');
        if (miniDestinationAddress) {
            if (contract.destinationAddress) {
                miniDestinationAddress.innerText = contract.destinationAddress;
                miniDestinationAddress.classList.remove('hidden');
            } else {
                miniDestinationAddress.classList.add('hidden');
            }
        }
        document.getElementById('miniCargoLoaded').innerText = `${contract.loadedCargo || 0} / ${contract.requiredCargo || 0}`;
        document.getElementById('miniProgress').innerText = `${contract.currentStop || 0} / ${contract.totalStops || 0}`;
        document.getElementById('miniCargo').innerText = contract.cargo || 'Cargo';

        const miniAlert = document.getElementById('miniAlert');
        const miniAlertText = document.getElementById('miniAlertText');
        const alert = contract.contractAlert;

        if (miniAlert && miniAlertText && alert && (alert.label || alert.description)) {
            miniAlertText.innerText = `${alert.label || 'Dispatch Alert'}${alert.description ? ' - ' + alert.description : ''}`;
            miniAlert.classList.remove('hidden');
        } else if (miniAlert) {
            miniAlert.classList.add('hidden');
        }

        mini.classList.remove('hidden');
    }

    if (data.action === 'hideMini') mini.classList.add('hidden');

    if (data.action === 'updateLastRouteSummary') {
        renderLastRouteSummary(data.summary);
    }
});

// Movable mini CB UI. Drag is now transform-based instead of top/left based.
// This avoids FiveM CEF cases where CSS top/height causes the box to only move sideways.
(function setupMiniUIDrag() {
    const box = document.getElementById('mini');
    if (!box) return;

    const storageKey = 'ls_trucking_mini_pos_v3';
    const oldStorageKey = 'ls_trucking_mini_pos';

    function viewport() {
        return {
            width: Math.max(window.innerWidth || 0, document.documentElement.clientWidth || 0, 1280),
            height: Math.max(window.innerHeight || 0, document.documentElement.clientHeight || 0, 720)
        };
    }

    function clamp(value, min, max) {
        return Math.min(Math.max(value, min), max);
    }

    function readPoint(event) {
        const touch = event.touches?.[0] || event.changedTouches?.[0];
        const source = touch || event;

        return {
            clientX: Number(source.clientX ?? 0),
            clientY: Number(source.clientY ?? 0),
            pageX: Number(source.pageX ?? source.clientX ?? 0),
            pageY: Number(source.pageY ?? source.clientY ?? 0),
            screenX: Number(source.screenX ?? source.clientX ?? 0),
            screenY: Number(source.screenY ?? source.clientY ?? 0)
        };
    }

    let pos = { x: 0, y: 0 };
    let dragging = false;
    let last = null;
    let activeTouchId = null;

    function defaultPosition() {
        const vp = viewport();
        const rect = box.getBoundingClientRect();
        return {
            x: Math.max(20, vp.width - rect.width - Math.round(vp.width * 0.02)),
            y: Math.max(20, Math.round(vp.height * 0.18))
        };
    }

    function applyPosition(save = false) {
        const vp = viewport();
        const rect = box.getBoundingClientRect();
        const maxX = Math.max(0, vp.width - rect.width);
        const maxY = Math.max(0, vp.height - rect.height);

        pos.x = clamp(pos.x, 0, maxX);
        pos.y = clamp(pos.y, 0, maxY);

        box.style.setProperty('--mini-x', `${Math.round(pos.x)}px`);
        box.style.setProperty('--mini-y', `${Math.round(pos.y)}px`);

        if (save) {
            localStorage.setItem(storageKey, JSON.stringify({
                x: Math.round(pos.x),
                y: Math.round(pos.y)
            }));
        }
    }

    function loadPosition() {
        let raw = localStorage.getItem(storageKey);

        // Import the older left/top save one time if present.
        if (!raw) {
            const oldRaw = localStorage.getItem(oldStorageKey);
            if (oldRaw) {
                try {
                    const old = JSON.parse(oldRaw);
                    if (Number.isFinite(old.left) && Number.isFinite(old.top)) {
                        raw = JSON.stringify({ x: old.left, y: old.top });
                    }
                } catch (e) {}
            }
        }

        if (raw) {
            try {
                const saved = JSON.parse(raw);
                if (Number.isFinite(saved.x) && Number.isFinite(saved.y)) {
                    pos = { x: saved.x, y: saved.y };
                    applyPosition(false);
                    return;
                }
            } catch (e) {}
        }

        requestAnimationFrame(() => {
            pos = defaultPosition();
            applyPosition(false);
        });
    }

    function startDrag(event) {
        if (event.type === 'mousedown' && event.button !== 0) return;

        // Only left click/touch drag. Keep it simple and avoid pointer capture.
        const point = readPoint(event);
        dragging = true;
        last = point;
        activeTouchId = event.touches?.[0]?.identifier ?? null;
        box.classList.add('dragging');

        event.preventDefault();
        event.stopPropagation();
    }

    function moveDrag(event) {
        if (!dragging || !last) return;

        // When touching, keep the same finger if possible.
        let point;
        if (event.touches && activeTouchId !== null) {
            const touch = Array.from(event.touches).find((t) => t.identifier === activeTouchId) || event.touches[0];
            point = readPoint({ touches: [touch] });
        } else {
            point = readPoint(event);
        }

        let dx = 0;
        let dy = 0;

        // Prefer browser movement values when available.
        if (typeof event.movementX === 'number' && event.movementX !== 0) dx = event.movementX;
        if (typeof event.movementY === 'number' && event.movementY !== 0) dy = event.movementY;

        // Fallback to several coordinate systems. Some FiveM CEF builds freeze clientY,
        // but screenY/pageY usually still update.
        if (dx === 0) {
            dx = (point.clientX - last.clientX) || (point.pageX - last.pageX) || (point.screenX - last.screenX);
        }

        if (dy === 0) {
            dy = (point.clientY - last.clientY) || (point.pageY - last.pageY) || (point.screenY - last.screenY);
        }

        pos.x += dx;
        pos.y += dy;

        last = point;
        applyPosition(false);

        event.preventDefault();
        event.stopPropagation();
    }

    function stopDrag(event) {
        if (!dragging) return;

        dragging = false;
        last = null;
        activeTouchId = null;
        box.classList.remove('dragging');
        applyPosition(true);

        if (event) {
            event.preventDefault();
            event.stopPropagation();
        }
    }

    loadPosition();

    box.addEventListener('mousedown', startDrag);
    box.addEventListener('touchstart', startDrag, { passive: false });

    document.addEventListener('mousemove', moveDrag, true);
    document.addEventListener('mouseup', stopDrag, true);
    document.addEventListener('mouseleave', stopDrag, true);
    document.addEventListener('touchmove', moveDrag, { passive: false, capture: true });
    document.addEventListener('touchend', stopDrag, true);
    document.addEventListener('touchcancel', stopDrag, true);

    window.addEventListener('resize', () => applyPosition(true));
})();
