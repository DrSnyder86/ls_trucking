const app = document.getElementById('app');
const mini = document.getElementById('mini');
const miniDock = document.getElementById('miniDock');
const dispatchHomeMap = document.getElementById('dispatchHomeMap');
const contractList = document.getElementById('contractList');
const garageList = document.getElementById('garageList');
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
const manifestJobBtn = document.getElementById('manifestJobBtn');
const returnGarageBtn = document.getElementById('returnGarageBtn');
const dispatchCloseBtn = document.getElementById('dispatchCloseBtn');
const contractorContent = document.getElementById('contractorContent');
const companyDashboard = document.getElementById('companyDashboard');
const routeHistoryList = document.getElementById('routeHistoryList');
const previewContracts = document.getElementById('previewContracts');
const previewContext = document.getElementById('previewContext');
const freightDialog = document.getElementById('freightDialog');
const freightDialogTitle = document.getElementById('freightDialogTitle');
const freightDialogContent = document.getElementById('freightDialogContent');
const trailerCargoEditor = document.getElementById('trailerCargoEditor');
const trailerCargoEditorTitle = document.getElementById('trailerCargoEditorTitle');
const trailerCargoEditorModel = document.getElementById('trailerCargoEditorModel');
const trailerCargoEditorPropSelect = document.getElementById('trailerCargoEditorPropSelect');
const trailerCargoEditorPropModel = document.getElementById('trailerCargoEditorPropModel');
const trailerCargoEditorStep = document.getElementById('trailerCargoEditorStep');
const trailerCargoEditorOffset = document.getElementById('trailerCargoEditorOffset');
const trailerCargoEditorRotation = document.getElementById('trailerCargoEditorRotation');

let selectedContract = 'van';
let selectedVehicleIndex = 1;
let selectedPriority = { van: 'standard', boxtruck: 'standard', trailer: 'standard' };
let previewRouteCache = {};
let dispatchData = null;
let activeDispatchTab = 'home';
let selectedDispatchHomePointId = null;
let dispatchMapZoom = null;
let dispatchMapPan = { x: 0, y: 0 };
let dispatchMapDrag = null;
let selectedGarageKey = null;
let contractorMarketVisible = false;
let selectedContractorPanel = 'vehicle';
let selectedContractorDailyRouteKey = null;
let selectedContractorDailyType = null;
let selectedContractorVehicleId = null;
let selectedContractorContractKey = null;
let selectedContractorMarketKey = null;
let miniPulseTimer = null;
let miniLastSignature = '';
let miniDockLastSignature = '';
let miniCurrentPage = 'home';
let miniLastContract = {};
let miniHideTimer = null;
let trailerCargoEditorState = null;
let miniDockHideTimer = null;
let miniPageTransitionTimer = null;
let dispatchHideTimer = null;
let dispatchParkTimer = null;
let dispatchCleanupTimers = [];
let dispatchRenderSignatures = {};
const RECEIVER_ANIMATION_MS = 240;
const MINI_PAGE_ANIMATION_MS = 230;
const DISPATCH_ANIMATION_MS = 160;
const DISPATCH_CLEANUP_PARK_MS = 2500;
const MINI_MOVEMENT_STORAGE_KEY = 'ls_trucking_receiver_movement_unlocked';
const MINI_PAGE_ORDER = ['home', 'route', 'manifest', 'load', 'vehicle', 'dispatch', 'settings'];

let miniMovementUnlocked = false;

try {
    miniMovementUnlocked = localStorage.getItem(MINI_MOVEMENT_STORAGE_KEY) === 'true';
} catch {
    miniMovementUnlocked = false;
}

function applyMiniMovementState() {
    if (mini) mini.classList.toggle('movement-unlocked', miniMovementUnlocked);
    if (miniDock) miniDock.classList.toggle('movement-unlocked', miniMovementUnlocked);
}

function setMiniMovementUnlocked(enabled, rerender = false) {
    miniMovementUnlocked = enabled === true;
    try {
        localStorage.setItem(MINI_MOVEMENT_STORAGE_KEY, miniMovementUnlocked ? 'true' : 'false');
    } catch {}
    applyMiniMovementState();

    if (rerender && miniCurrentPage === 'settings') {
        renderMiniSettingsPage(miniLastContract || {});
    }
}

function isMiniMovementUnlocked() {
    return miniMovementUnlocked === true;
}

applyMiniMovementState();

function flashMiniRadio(direction = 'tx') {
    const targets = [mini, miniDock].filter(Boolean);
    if (!targets.length) return;
    const flashClass = direction === 'rx' ? 'radio-rx-flash' : 'dispatch-flash';

    targets.forEach(target => {
        target.classList.remove('dispatch-flash', 'radio-rx-flash');
        void target.offsetWidth;
        target.classList.add(flashClass);
    });
    clearTimeout(miniPulseTimer);
    miniPulseTimer = setTimeout(() => {
        targets.forEach(target => target.classList.remove('dispatch-flash', 'radio-rx-flash'));
    }, 1700);
}

let uiSoundSettings = {
    enabled: false,
    volume: 0.22,
    path: 'sounds/',
    click: 'click.wav',
    confirm: 'confirm.wav',
    error: 'error.wav',
    alert: 'alert.wav',
    destination: 'destination.wav',
    secure: 'secure.wav',
    trailerConnect: 'trailer_connect.wav',
    trailerDisconnect: 'trailer_disconnect.wav',
    impact: 'impact_wrench.wav'
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
    uiSoundSettings.trailerConnect = soundConfig.TrailerConnectSound || 'trailer_connect.wav';
    uiSoundSettings.trailerDisconnect = soundConfig.TrailerDisconnectSound || 'trailer_disconnect.wav';
    uiSoundSettings.impact = soundConfig.ImpactWrenchSound || soundConfig.ImpactSound || 'impact_wrench.wav';
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
                        : (type === 'trailerConnect' || type === 'trailer_connect')
                            ? uiSoundSettings.trailerConnect
                            : (type === 'trailerDisconnect' || type === 'trailer_disconnect')
                                ? uiSoundSettings.trailerDisconnect
                                : (type === 'impact' || type === 'impactWrench' || type === 'impact_wrench')
                                    ? uiSoundSettings.impact
                                    : uiSoundSettings.click;

    try {
        const audio = new Audio(`${uiSoundSettings.path}${filename}`);
        audio.volume = Math.max(0, Math.min(1, uiSoundSettings.volume));
        audio.play().catch(() => {});
    } catch {}
}


const contractMeta = {
    van: { number: '01', accent: '#e6ab00', badge: 'LOCAL' },
    boxtruck: { number: '02', accent: '#3f8cff', badge: 'FREIGHT' },
    trailer: { number: '03', accent: '#a263ff', badge: 'TRAILER' }
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

        const stopMatch = line.match(/^Stop\s+(\d+)\s*-\s*(.+)$/i);
        if (stopMatch) {
            const stopNumber = String(stopMatch[1]).padStart(2, '0');
            const stopName = stopMatch[2].trim() || 'Delivery Stop';
            html.push(`<div class="print-row print-row-right print-stop-row"><span>STOP ${escapeHTML(stopNumber)}</span><strong>${escapeHTML(stopName)}</strong></div>`);
            continue;
        }

        const colonIndex = line.indexOf(':');
        if (colonIndex > 0) {
            const label = line.slice(0, colonIndex).replace(/^[-*]\s*/, '').trim();
            const value = line.slice(colonIndex + 1).trim() || '-';
            const rowClass = rightAlignedSections === 'all' || rightAlignedSections.has?.(activeSection) ? 'print-row print-row-right' : 'print-row';
            html.push(`<div class="${rowClass}"><span>${escapeHTML(label)}</span><strong>${escapeHTML(value)}</strong></div>`);
            continue;
        }

        if (/^[-*]\s+/.test(line) || /^\d+\.\s+/.test(line)) {
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

    freightDialog.classList.remove('dialog-summary', 'dialog-manifest', 'dialog-checklist', 'dialog-handoff');
    const dialogHeaderText = String(data.header || '').toLowerCase();
    if (dialogHeaderText.includes('summary')) {
        freightDialog.classList.add('dialog-summary');
    } else if (dialogHeaderText.includes('manifest')) {
        freightDialog.classList.add('dialog-manifest');
    } else if (dialogHeaderText.includes('checklist')) {
        freightDialog.classList.add('dialog-checklist');
    }

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

    freightDialog.classList.remove('dialog-summary', 'dialog-manifest', 'dialog-checklist', 'dialog-handoff');
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

function showFreightHandoff(data = {}) {
    if (!freightDialog) return;

    const records = Array.isArray(data.contracts) ? data.contracts.filter(Boolean) : [];
    const mode = data.mode === 'trailer' ? 'trailer' : 'pickup';
    const signerName = String(data.signerName || 'Assigned Driver');
    const actionLabel = mode === 'trailer' ? 'Complete Trailer Drop-Off' : 'Confirm Cargo Pickup';
    const handoffType = mode === 'trailer' ? 'Proof of Delivery' : 'Cargo Release';

    freightDialog.classList.remove('dialog-summary', 'dialog-manifest', 'dialog-checklist');
    freightDialog.classList.add('dialog-handoff');
    freightDialogTitle.innerText = data.header || `${handoffType} Handoff`;
    freightDialogContent.classList.remove('printout');
    freightDialogContent.classList.add('with-form');
    clearFreightDialogActions();

    const options = records.map(record => {
        const id = String(record.contractId || 'UNASSIGNED');
        return `<option value="${escapeHTML(id)}">${escapeHTML(id)} - ${escapeHTML(record.routeLabel || 'Freight Route')}</option>`;
    }).join('');

    freightDialogContent.innerHTML = `
        <div class="handoff-form">
            <div class="handoff-status-line">
                <span><i class="fas fa-user-tie"></i>${escapeHTML(data.pedLabel || 'Freight Clerk')}</span>
                <strong>${escapeHTML(handoffType)}</strong>
            </div>

            <label class="freight-form-label" for="handoffContractSelect">Select manifest</label>
            <select id="handoffContractSelect" class="freight-form-select" ${records.length <= 1 ? 'disabled' : ''}>
                ${options || '<option value="">No active manifest</option>'}
            </select>

            <section id="handoffManifestDetails" class="handoff-manifest-details"></section>

            <label class="freight-form-check handoff-sign-check">
                <input id="handoffSignatureConfirm" type="checkbox" ${records.length ? '' : 'disabled'}>
                <span>I authorize this electronic freight handoff and certify the manifest information above.</span>
            </label>

            <div id="handoffSignaturePad" class="handoff-signature-pad">
                <small>AUTHORIZED SIGNATURE</small>
                <strong id="handoffSignatureName">Awaiting driver authorization</strong>
                <span id="handoffSignatureTime">Check the authorization box to sign</span>
            </div>

            <div id="handoffFormError" class="freight-form-error hidden">
                Select a manifest and authorize the electronic signature before continuing.
            </div>
        </div>
    `;

    const select = document.getElementById('handoffContractSelect');
    const details = document.getElementById('handoffManifestDetails');
    const signatureCheck = document.getElementById('handoffSignatureConfirm');
    const signaturePad = document.getElementById('handoffSignaturePad');
    const signatureName = document.getElementById('handoffSignatureName');
    const signatureTime = document.getElementById('handoffSignatureTime');
    const error = document.getElementById('handoffFormError');

    const selectedRecord = () => records.find(record => String(record.contractId || '') === String(select?.value || '')) || records[0];
    const renderDetails = () => {
        const record = selectedRecord();
        if (!details || !record) {
            if (details) details.innerHTML = '<p>No active freight manifest was received.</p>';
            return;
        }

        const detailRows = [
            ['Contract', record.contractId],
            ['Route', record.routeLabel],
            ['Load', record.loadLabel],
            ['Quantity', record.quantityLabel],
            ['Vehicle', record.vehicleLabel],
            ['Plate', record.plate],
            ['Handoff Location', record.locationLabel]
        ].filter(([, value]) => value !== undefined && value !== null && value !== '');

        details.innerHTML = detailRows.map(([label, value]) => `
            <div class="handoff-detail-row">
                <span>${escapeHTML(label)}</span>
                <strong>${escapeHTML(value)}</strong>
            </div>
        `).join('');
    };

    const actions = document.getElementById('freightDialogActions');
    actions.appendChild(createFreightButton('Go Back', 'secondary', () => {
        playUISound('click');
        post('freightDialogResult', { confirmed: false });
    }));

    const confirmButton = createFreightButton(actionLabel, '', () => {
        const record = selectedRecord();
        if (!record || !signatureCheck?.checked) {
            error?.classList.remove('hidden');
            playUISound('error');
            return;
        }

        playUISound('secure');
        post('freightDialogResult', {
            confirmed: true,
            contractId: record.contractId,
            signatureAccepted: true
        });
    });
    confirmButton.disabled = true;
    actions.appendChild(confirmButton);

    select?.addEventListener('change', () => {
        error?.classList.add('hidden');
        renderDetails();
    });

    signatureCheck?.addEventListener('change', () => {
        const signed = signatureCheck.checked;
        signaturePad?.classList.toggle('is-signed', signed);
        confirmButton.disabled = !signed || records.length === 0;
        error?.classList.add('hidden');

        if (signatureName) signatureName.textContent = signed ? signerName : 'Awaiting driver authorization';
        if (signatureTime) {
            signatureTime.textContent = signed
                ? `Electronically authorized ${new Date().toLocaleString([], { dateStyle: 'short', timeStyle: 'short' })}`
                : 'Check the authorization box to sign';
        }

        playUISound(signed ? 'confirm' : 'click');
    });

    renderDetails();
    freightDialog.classList.remove('hidden');
    playUISound('click');
}

function hideFreightDialog() {
    if (!freightDialog) return;
    freightDialog.classList.add('hidden');
    freightDialog.classList.remove('dialog-handoff');
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

function formatTrailerEditorNumber(value) {
    const number = Number(value);
    return Number.isFinite(number) ? number.toFixed(3) : '0.000';
}

function getTrailerEditorSelectedProp() {
    if (!trailerCargoEditorState?.props?.length) return null;
    const selected = Number(trailerCargoEditorState.selectedIndex || 1);
    return trailerCargoEditorState.props.find(prop => Number(prop.index) === selected) || trailerCargoEditorState.props[0];
}

function renderTrailerCargoEditor(state = {}) {
    trailerCargoEditorState = {
        ...(trailerCargoEditorState || {}),
        ...state,
        props: Array.isArray(state.props) ? state.props : (trailerCargoEditorState?.props || [])
    };

    if (!trailerCargoEditor) return;

    const current = trailerCargoEditorState;
    if (trailerCargoEditorTitle) trailerCargoEditorTitle.innerText = `${current.label || 'Trailer'} (${current.key || 'unknown'})`;
    if (trailerCargoEditorModel) trailerCargoEditorModel.innerText = current.model || 'model';

    if (trailerCargoEditorPropSelect) {
        trailerCargoEditorPropSelect.innerHTML = '';
        (current.props || []).forEach(prop => {
            const option = document.createElement('option');
            option.value = String(prop.index);
            option.innerText = `${prop.index}. ${prop.model || 'prop'}`;
            trailerCargoEditorPropSelect.appendChild(option);
        });
        trailerCargoEditorPropSelect.value = String(current.selectedIndex || 1);
    }

    if (trailerCargoEditorStep) trailerCargoEditorStep.value = current.step || 0.05;

    const prop = getTrailerEditorSelectedProp();
    if (trailerCargoEditorPropModel) trailerCargoEditorPropModel.value = prop?.model || '';
    if (trailerCargoEditorOffset) {
        const offset = prop?.offset || {};
        trailerCargoEditorOffset.innerText = `${formatTrailerEditorNumber(offset.x)} / ${formatTrailerEditorNumber(offset.y)} / ${formatTrailerEditorNumber(offset.z)}`;
    }
    if (trailerCargoEditorRotation) {
        const rotation = prop?.rotation || {};
        trailerCargoEditorRotation.innerText = `${formatTrailerEditorNumber(rotation.x)} / ${formatTrailerEditorNumber(rotation.y)} / ${formatTrailerEditorNumber(rotation.z)}`;
    }
}

function showTrailerCargoEditor(state = {}) {
    renderTrailerCargoEditor(state);
    if (trailerCargoEditor) trailerCargoEditor.classList.remove('hidden');
}

function hideTrailerCargoEditor() {
    if (trailerCargoEditor) trailerCargoEditor.classList.add('hidden');
    trailerCargoEditorState = null;
}

function sendTrailerCargoEditorAction(action, data = {}) {
    const step = Number(trailerCargoEditorStep?.value || trailerCargoEditorState?.step || 0.05);
    post('trailerCargoEditorAction', { action, step, ...data });
}

if (trailerCargoEditor) {
    trailerCargoEditor.addEventListener('click', event => {
        const actionButton = event.target.closest('[data-trailer-editor-action]');
        if (actionButton) {
            const action = actionButton.dataset.trailerEditorAction;
            if (action === 'close') {
                post('trailerCargoEditorClose');
            } else {
                sendTrailerCargoEditorAction(action);
            }
            return;
        }

        const nudgeButton = event.target.closest('[data-trailer-editor-field]');
        if (nudgeButton) {
            sendTrailerCargoEditorAction('nudge', {
                field: nudgeButton.dataset.trailerEditorField,
                axis: nudgeButton.dataset.trailerEditorAxis,
                delta: Number(nudgeButton.dataset.trailerEditorDelta || 0)
            });
        }
    });
}

if (trailerCargoEditorPropSelect) {
    trailerCargoEditorPropSelect.addEventListener('change', () => {
        sendTrailerCargoEditorAction('select', { index: Number(trailerCargoEditorPropSelect.value || 1) });
    });
}

if (trailerCargoEditorStep) {
    trailerCargoEditorStep.addEventListener('change', () => {
        sendTrailerCargoEditorAction('step', { step: Number(trailerCargoEditorStep.value || 0.05) });
    });
}

if (trailerCargoEditorPropModel) {
    trailerCargoEditorPropModel.addEventListener('change', () => {
        sendTrailerCargoEditorAction('setModel', { model: trailerCargoEditorPropModel.value.trim() });
    });
}

window.addEventListener('keydown', event => {
    if (!trailerCargoEditor || trailerCargoEditor.classList.contains('hidden')) return;

    if (event.key === 'Escape') {
        post('trailerCargoEditorClose');
        return;
    }

    const targetTag = (event.target?.tagName || '').toLowerCase();
    if (targetTag === 'input' || targetTag === 'select' || targetTag === 'textarea') return;

    const normalizedKey = event.key.length === 1 ? event.key.toLowerCase() : event.key;
    const cameraKeys = {
        a: 'left',
        ArrowLeft: 'left',
        d: 'right',
        ArrowRight: 'right',
        q: 'zoomOut',
        e: 'zoomIn',
        w: 'up',
        ArrowUp: 'up',
        s: 'down',
        ArrowDown: 'down',
        r: 'reset'
    };
    const control = cameraKeys[normalizedKey];
    if (!control) return;

    event.preventDefault();
    sendTrailerCargoEditorAction('camera', { control });
});

function formatMoney(value) {
    const number = Number(value || 0);
    return `$${number.toLocaleString()}`;
}

function formatInteger(value, fallback = '0') {
    const number = Number(value);
    if (!Number.isFinite(number)) return fallback;
    return Math.floor(number).toLocaleString();
}

function formatMiniFrequency(value) {
    const text = String(value || '68.9').trim();
    return text.replace(/^CH\.?\s*/i, '').trim() || '68.9';
}

function formatMiniClock() {
    const date = new Date();
    return `${String(date.getHours()).padStart(2, '0')}:${String(date.getMinutes()).padStart(2, '0')}`;
}

function normalizeLogoPath(value) {
    const logoPath = String(value || 'images/badger-logo.png').trim();
    if (/^(https?:|nui:|data:|\.{0,2}\/)/i.test(logoPath)) return logoPath;
    return `../${logoPath.replace(/^\/+/, '')}`;
}

function updateReceiverLogo(img, logo) {
    if (!img || !logo) return;
    const logoPath = normalizeLogoPath(logo);

    if (img.getAttribute('src') !== logoPath) {
        img.parentElement?.classList.remove('has-logo');
        img.style.display = 'block';
        img.src = logoPath;
    }
}

function updateReceiverSignal(meter, contract = {}) {
    if (!meter) return;
    const signal = Math.max(0, Math.min(4, Number(contract.signalStrength ?? 4)));
    meter.dataset.signal = String(signal);
    meter.title = contract.signalLabel || 'Dispatch signal';
}

function updateReceiverRadioLine(line, text) {
    if (!line) return;
    const radioText = text || '';
    line.classList.toggle('hidden', !radioText);
    const target = line.querySelector('span');
    if (target) target.innerText = radioText;
}

function updateReceiverRouteProgress(bar, contract = {}) {
    if (!bar) return;
    const totalStops = Number(contract.totalStops || 0);
    const currentStop = Number(contract.currentStop || 0);
    const routePercent = totalStops > 0 ? Math.max(0, Math.min(100, (currentStop / totalStops) * 100)) : 0;
    bar.style.width = `${routePercent}%`;
}

function escapeHtml(value) {
    return String(value ?? '').replace(/[&<>"']/g, char => ({
        '&': '&amp;',
        '<': '&lt;',
        '>': '&gt;',
        '"': '&quot;',
        "'": '&#39;'
    }[char]));
}

function setText(id, value) {
    const element = document.getElementById(id);
    if (element) element.innerText = value;
}

function miniActiveLabel(contract = {}) {
    return contract.hasActiveRoute === false ? 'STANDBY' : 'ACTIVE';
}

function miniInfoRow(label, value, icon = 'fa-circle-info') {
    if (value === undefined || value === null || value === '') return '';
    return `
        <div class="mini-info-row">
            <i class="fas ${icon}"></i>
            <div><small>${escapeHtml(label)}</small><strong>${escapeHtml(value)}</strong></div>
        </div>
    `;
}

function miniPanel(title, rows, extraClass = '') {
    const content = Array.isArray(rows) ? rows.filter(Boolean).join('') : rows;
    return `
        <section class="mini-info-panel ${extraClass}">
            <small>${escapeHtml(title)}</small>
            ${content || '<p>No data received.</p>'}
        </section>
    `;
}

function miniTrailerPhotoPanel(contract = {}) {
    if (!contract.trailerPhoto) return '';

    const trailerName = contract.trailerLabel || contract.cargo || 'Assigned Trailer';
    return `
        <section class="mini-info-panel mini-trailer-photo-panel">
            <small>Assigned Trailer</small>
            <img src="${escapeHtml(contract.trailerPhoto)}" alt="${escapeHtml(trailerName)}" onerror="this.closest('.mini-trailer-photo-panel').style.display='none'">
            <strong>${escapeHtml(trailerName)}</strong>
            ${contract.trailerContents ? `<span>${escapeHtml(contract.trailerContents)}</span>` : ''}
        </section>
    `;
}

function miniActionButton(label, icon, action, title = '') {
    return `
        <button class="mini-action-button" data-mini-vehicle-action="${escapeHtml(action)}" title="${escapeHtml(title || label)}">
            <i class="fas ${icon}"></i>
            <span>${escapeHtml(label)}</span>
        </button>
    `;
}

function miniLoadActionButton(label, status, icon, action, options = {}) {
    const classes = [
        'mini-wide-action',
        'mini-load-action',
        options.complete ? 'is-complete' : '',
        options.pending ? 'is-pending' : ''
    ].filter(Boolean).join(' ');

    return `
        <button class="${classes}" data-mini-load-action="${escapeHtml(action)}" ${options.disabled ? 'disabled' : ''}>
            <i class="fas ${icon}"></i>
            <span><strong>${escapeHtml(label)}</strong><small>${escapeHtml(status)}</small></span>
        </button>
    `;
}

function getReceiverVehicleType(contract = {}) {
    return contract.reuseVehicle?.type || contract.vehicleType || (contract.type !== 'standby' ? contract.type : '') || '';
}

function getReceiverPriorityOptions(contract = {}) {
    const type = getReceiverVehicleType(contract);
    const configured = contract.priorityOptions || [];
    const fromDispatch = dispatchData?.priorityLoads?.[type] || {};
    const options = Array.isArray(configured) && configured.length
        ? configured
        : Object.entries(fromDispatch).map(([key, priority]) => ({ key, ...priority }));

    return options
        .filter(option => option && option.key)
        .sort((a, b) => Number(a.order || 99) - Number(b.order || 99));
}

function getSelectedReceiverPriority(contract = {}) {
    const type = getReceiverVehicleType(contract);
    const options = getReceiverPriorityOptions(contract);

    if (!type) return 'standard';
    if (!selectedPriority[type] || !options.some(option => option.key === selectedPriority[type])) {
        selectedPriority[type] = options[0]?.key || 'standard';
    }

    return selectedPriority[type] || 'standard';
}

function renderReceiverPriorityPanel(contract = {}) {
    const reuse = contract.reuseVehicle || {};
    const privateUnit = reuse.contractor || reuse.source === 'contractor';

    if (contract.hasActiveRoute !== false) {
        return '';
    }

    if (contract.canStartCurrentVehicleJob === false) {
        return miniPanel('Route Request', '<p>Current-vehicle route requests are disabled in config.</p>', 'mini-start-panel');
    }

    if (!reuse.available) {
        return miniPanel('Route Request', '<p>No current vehicle detected. Spawn or keep an assigned unit out, then request a load from the receiver.</p>', 'mini-start-panel');
    }

    let options = getReceiverPriorityOptions(contract);
    if (privateUnit) {
        options = options.filter(option => option.key === 'standard');
    }

    const selected = privateUnit ? 'standard' : getSelectedReceiverPriority(contract);
    const priorityButtons = options.length
        ? options.map(option => `
            <button class="mini-priority-choice ${option.key === selected ? 'selected' : ''}" data-mini-priority="${escapeHtml(option.key)}">
                <strong>${escapeHtml(option.shortLabel || option.label || option.key)}</strong>
                <span>${escapeHtml(option.badge || `RANK ${option.minRank || 1}+`)}</span>
            </button>
        `).join('')
        : '<p>No priority data received.</p>';

    return miniPanel(privateUnit ? 'Request Private Load' : 'Request Load', `
        <div class="mini-request-unit">
            <i class="fas fa-truck-fast"></i>
            <div><small>${privateUnit ? 'PRIVATE UNIT' : 'CURRENT UNIT'}</small><strong>${escapeHtml(reuse.vehicleLabel || reuse.label || 'Assigned Vehicle')}</strong></div>
        </div>
        <div class="mini-priority-grid">${priorityButtons}</div>
        <button class="mini-wide-action ${contract.contractRequestPending ? 'is-pending' : ''}" data-mini-start-current-job ${contract.contractRequestPending ? 'disabled' : ''}>
            <i class="fas fa-tower-broadcast"></i>
            <span>${contract.contractRequestPending ? 'Awaiting Dispatch' : privateUnit ? 'Request Private Route' : 'Request Route'}</span>
        </button>
    `, 'mini-start-panel');
}

function getMiniPageName(view) {
    if (!view) return 'home';
    return view.id === 'miniHomePage' ? 'home' : view.dataset.miniView || 'home';
}

function clearMiniPageMotion(view) {
    if (!view) return;
    view.classList.remove('mini-page-enter-right', 'mini-page-enter-left', 'mini-page-exit-left', 'mini-page-exit-right');
}

function setMiniPage(page = 'home', options = {}) {
    const requestedPage = page || 'home';
    const views = Array.from(document.querySelectorAll('#mini .mini-app-page'));
    const nextView = views.find(view => getMiniPageName(view) === requestedPage) || views.find(view => getMiniPageName(view) === 'home');
    const nextPage = nextView ? getMiniPageName(nextView) : 'home';
    const previousPage = miniCurrentPage || 'home';
    const currentView = views.find(view => getMiniPageName(view) === previousPage && !view.classList.contains('hidden'));
    const miniHidden = !mini || mini.classList.contains('hidden');
    const shouldAnimate = !options.instant && !miniHidden && previousPage !== nextPage && nextView;

    miniCurrentPage = nextPage;
    clearTimeout(miniPageTransitionTimer);

    if (!shouldAnimate) {
        views.forEach(view => {
            clearMiniPageMotion(view);
            view.classList.toggle('hidden', view !== nextView);
        });
        return;
    }

    const previousIndex = Math.max(0, MINI_PAGE_ORDER.indexOf(previousPage));
    const nextIndex = Math.max(0, MINI_PAGE_ORDER.indexOf(nextPage));
    const forward = nextIndex >= previousIndex;

    views.forEach(view => {
        if (view !== currentView && view !== nextView) {
            clearMiniPageMotion(view);
            view.classList.add('hidden');
        }
    });

    if (currentView && currentView !== nextView) {
        clearMiniPageMotion(currentView);
        currentView.classList.remove('hidden');
        currentView.classList.add(forward ? 'mini-page-exit-left' : 'mini-page-exit-right');
    }

    clearMiniPageMotion(nextView);
    nextView.classList.remove('hidden');
    nextView.classList.add(forward ? 'mini-page-enter-right' : 'mini-page-enter-left');

    miniPageTransitionTimer = setTimeout(() => {
        views.forEach(view => {
            clearMiniPageMotion(view);
            view.classList.toggle('hidden', view !== nextView);
        });
    }, MINI_PAGE_ANIMATION_MS);
}

function showReceiverWithAnimation(wasHidden = false) {
    if (!mini) return;

    clearTimeout(miniHideTimer);
    mini.classList.remove('receiver-closing');

    if (!wasHidden) {
        mini.classList.remove('hidden', 'receiver-pre-open', 'receiver-opening');
        return;
    }

    mini.classList.add('receiver-pre-open');
    mini.classList.remove('hidden');
    requestAnimationFrame(() => {
        if (mini.classList.contains('hidden') || mini.classList.contains('receiver-closing')) return;
        mini.classList.remove('receiver-pre-open');
        mini.classList.add('receiver-opening');
        clearTimeout(miniHideTimer);
        miniHideTimer = setTimeout(() => {
            mini.classList.remove('receiver-opening');
        }, RECEIVER_ANIMATION_MS);
    });
}

function hideReceiverWithAnimation(onHidden) {
    if (!mini) return;

    clearTimeout(miniHideTimer);
    mini.classList.remove('receiver-pre-open', 'receiver-opening');

    if (mini.classList.contains('hidden')) {
        if (typeof onHidden === 'function') onHidden();
        return;
    }

    mini.classList.add('receiver-closing');
    miniHideTimer = setTimeout(() => {
        mini.classList.add('hidden');
        mini.classList.remove('receiver-closing');
        if (typeof onHidden === 'function') onHidden();
    }, RECEIVER_ANIMATION_MS);
}

function showMiniDockWithAnimation(wasHidden = false) {
    if (!miniDock) return;

    clearTimeout(miniDockHideTimer);
    miniDock.classList.remove('dock-closing');

    if (!wasHidden) {
        miniDock.classList.remove('hidden', 'dock-pre-open');
        return;
    }

    miniDock.classList.add('dock-pre-open');
    miniDock.classList.remove('hidden');
    requestAnimationFrame(() => {
        if (miniDock.classList.contains('hidden') || miniDock.classList.contains('dock-closing')) return;
        miniDock.classList.remove('dock-pre-open');
    });
}

function hideMiniDockWithAnimation(onHidden) {
    if (!miniDock) return;

    clearTimeout(miniDockHideTimer);
    miniDock.classList.remove('dock-pre-open');

    if (miniDock.classList.contains('hidden')) {
        if (typeof onHidden === 'function') onHidden();
        return;
    }

    miniDock.classList.add('dock-closing');
    miniDockHideTimer = setTimeout(() => {
        miniDock.classList.add('hidden');
        miniDock.classList.remove('dock-closing');
        if (typeof onHidden === 'function') onHidden();
    }, RECEIVER_ANIMATION_MS);
}

function groupManifestEntries(entries = []) {
    const groups = [];
    const byKey = new Map();

    entries.forEach((entry, index) => {
        const stop = entry?.stop || index + 1;
        const receiver = entry?.receiver || entry?.dropoff || `Stop ${stop}`;
        const key = `${stop}|${receiver}`;

        if (!byKey.has(key)) {
            const group = { stop, receiver, count: 0, cargo: new Map() };
            byKey.set(key, group);
            groups.push(group);
        }

        const group = byKey.get(key);
        const label = entry?.cargoLabel || entry?.label || 'Delivery Cargo';
        group.count += 1;
        group.cargo.set(label, (group.cargo.get(label) || 0) + 1);
    });

    return groups.sort((a, b) => Number(a.stop || 0) - Number(b.stop || 0));
}

function renderMiniHome(contract = {}) {
    const active = contract.hasActiveRoute !== false;
    const reuse = contract.reuseVehicle || {};
    setText('miniHomeStatus', active ? (contract.label || 'Active route') : 'Receiver standby');
    setText('miniHomeSubstatus', active ? (contract.stage || 'Route active') : 'No active route assigned');
    setText('miniAppRouteBadge', miniActiveLabel(contract));
    setText('miniAppManifestBadge', active ? 'READY' : 'NO LOAD');
    setText('miniAppLoadBadge', contract.cargoConditionLabel || (active ? 'LOADED' : reuse.available ? 'READY' : 'IDLE'));
    setText('miniAppVehicleBadge', active ? (contract.plate || 'ASSIGNED') : reuse.available ? (reuse.plate || 'READY') : 'NONE');
    setText('miniAppDispatchBadge', contract.radioChatter ? 'NEW RX' : 'RX');
}

function renderMiniManifestPage(contract = {}) {
    const content = document.getElementById('miniManifestContent');
    if (!content) return;

    if (contract.hasActiveRoute === false) {
        content.innerHTML = miniPanel('Manifest', '<p>No active manifest is assigned.</p>');
        setText('miniPageManifestState', 'EMPTY');
        return;
    }

    setText('miniPageManifestState', contract.contractId || 'PAPERWORK');

    const summaryRows = [
        miniInfoRow('Contract', contract.contractId, 'fa-hashtag'),
        miniInfoRow('Route', contract.label, 'fa-route'),
        miniInfoRow('Load Type', contract.priorityLabel, 'fa-tag'),
        miniInfoRow('Route Length', contract.routeLength, 'fa-road'),
        miniInfoRow('Payout', formatMoney(contract.payout), 'fa-money-bill-wave')
    ];

    if (contract.type === 'trailer') {
        const instructionList = Array.isArray(contract.trailerInstructions)
            ? contract.trailerInstructions.map(item => `<li>${escapeHtml(item)}</li>`).join('')
            : contract.trailerInstructions
                ? `<li>${escapeHtml(contract.trailerInstructions)}</li>`
                : '<li>Complete load checklist, deliver trailer, detach in the drop zone, then finalize with receiver.</li>';

        content.innerHTML = [
            miniPanel('Contract', summaryRows),
            miniPanel('Trailer Paperwork', [
                miniInfoRow('Pickup Depot', contract.trailerDepotLabel, 'fa-warehouse'),
                miniInfoRow('Trailer', contract.trailerLabel || contract.cargo, 'fa-trailer'),
                miniInfoRow('Contents', contract.trailerContents || contract.cargo, 'fa-boxes-stacked'),
                miniInfoRow('Receiver', contract.trailerDropLabel || contract.destination, 'fa-clipboard-check'),
                miniInfoRow('Safe Speed', contract.safeSpeed ? `${Math.floor(Number(contract.safeSpeed))} MPH` : '', 'fa-gauge-high')
            ]),
            `<section class="mini-info-panel"><small>Instructions</small><ul class="mini-paper-list">${instructionList}</ul></section>`
        ].join('');
        return;
    }

    const manifest = Array.isArray(contract.manifest) ? contract.manifest : [];
    const groups = groupManifestEntries(manifest);
    const pickupSignature = contract.pickupSignature || null;
    const releasePanel = pickupSignature
        ? miniPanel('Pickup Release', [
            miniInfoRow('Signed By', pickupSignature.name, 'fa-signature'),
            miniInfoRow('Signed At', pickupSignature.signedAt, 'fa-clock'),
            miniInfoRow('Location', pickupSignature.location, 'fa-location-dot')
        ])
        : '';
    const stopRows = groups.length
        ? groups.map(group => {
            const cargo = Array.from(group.cargo.entries()).map(([label, count]) => `${label} x${count}`).join(', ') || `${group.count} package`;
            return `
                <div class="mini-stop-card">
                    <small>STOP ${escapeHtml(group.stop)}</small>
                    <strong>${escapeHtml(group.receiver)}</strong>
                    <em>${escapeHtml(cargo)}</em>
                </div>
            `;
        }).join('')
        : '<p>No stop entries received.</p>';

    content.innerHTML = [
        miniPanel('Contract', summaryRows),
        releasePanel,
        `<section class="mini-info-panel"><small>Delivery Stops</small>${stopRows}</section>`
    ].join('');
}

function renderMiniLoadPage(contract = {}) {
    const content = document.getElementById('miniLoadContent');
    if (!content) return;

    setText('miniPageLoadState', contract.cargoConditionLabel || (contract.hasActiveRoute === false ? 'IDLE' : 'STATUS'));

    if (contract.hasActiveRoute === false) {
        content.innerHTML = [
            miniPanel('Load Status', '<p>No cargo is assigned to this receiver.</p>'),
            renderReceiverPriorityPanel(contract)
        ].join('');
        return;
    }

    const checklist = contract.loadChecklist || {};
    const pendingAction = contract.receiverLoadAction || '';
    const actionPending = Boolean(pendingAction);
    const rows = [
        miniInfoRow('Cargo', contract.cargo || 'Cargo', 'fa-box'),
        miniInfoRow('Loaded', `${contract.loadedCargo || 0} / ${contract.requiredCargo || 0}`, 'fa-boxes-stacked'),
        miniInfoRow('Stops', `${contract.currentStop || 0} / ${contract.totalStops || 0}`, 'fa-map-pin'),
        miniInfoRow('Condition', contract.cargoConditionLabel || 'CARGO STABLE', 'fa-shield-halved'),
        miniInfoRow('Condition Notes', contract.cargoConditionNote, 'fa-clipboard-list')
    ];

    if (contract.type === 'trailer') {
        rows.push(
            miniInfoRow('Trailer', contract.trailerLabel || 'Assigned Trailer', 'fa-trailer'),
            miniInfoRow('Truck Connection', checklist.truckSecure ? 'Secured' : 'Pending', 'fa-link'),
            miniInfoRow('Trailer Load', checklist.trailerSecure ? 'Secured' : 'Pending', 'fa-lock'),
            miniInfoRow('Trailer Drop', contract.trailerDropped ? 'Dropped' : 'Not dropped', 'fa-location-dot')
        );
    } else {
        rows.push(
            miniInfoRow('Cargo Ready', contract.cargoReady ? 'Ready for verification' : 'Loading in progress', 'fa-clipboard-check'),
            miniInfoRow('Verified', contract.verifiedCargo ? 'Verified' : 'Pending verification', 'fa-check')
        );
    }

    let verificationPanel = '';
    if ((contract.loadVerificationMode || 'receiver') === 'receiver') {
        if (contract.type === 'trailer') {
            const trailerAttached = contract.trailerAttached === true;
            const truckSecure = checklist.truckSecure === true;
            const trailerSecure = checklist.trailerSecure === true;
            const routeCleared = contract.trailerHooked === true;

            verificationPanel = miniPanel('Dispatch Load Clearance', `
                <div class="mini-load-action-stack">
                    ${miniLoadActionButton(
                        'Submit Checklist',
                        routeCleared ? 'Route cleared by dispatch' : truckSecure && trailerSecure ? 'Ready for dispatch review' : trailerAttached ? 'Complete physical target checks first' : 'Attach assigned trailer first',
                        routeCleared ? 'fa-satellite-dish' : 'fa-paper-plane',
                        'submit_checklist',
                        { complete: routeCleared, pending: pendingAction === 'submit_checklist', disabled: actionPending || routeCleared || !truckSecure || !trailerSecure }
                    )}
                </div>
            `, 'mini-load-clearance-panel');
        } else {
            const verified = contract.verifiedCargo === true;
            const ready = contract.cargoReady === true;
            verificationPanel = miniPanel('Dispatch Manifest Clearance', `
                <div class="mini-load-action-stack">
                    ${miniLoadActionButton(
                        'Verify Cargo Manifest',
                        verified ? 'Manifest verified - route active' : ready ? 'Load count ready for dispatch' : 'Finish loading all assigned cargo',
                        verified ? 'fa-satellite-dish' : 'fa-clipboard-check',
                        'verify_cargo',
                        { complete: verified, pending: pendingAction === 'verify_cargo', disabled: actionPending || verified || !ready }
                    )}
                </div>
            `, 'mini-load-clearance-panel');
        }
    }

    content.innerHTML = [
        verificationPanel,
        contract.type === 'trailer' ? miniTrailerPhotoPanel(contract) : '',
        miniPanel('Load Status', rows),
        renderReceiverPriorityPanel(contract)
    ].filter(Boolean).join('');
}

function renderMiniVehiclePage(contract = {}) {
    const content = document.getElementById('miniVehicleContent');
    if (!content) return;

    setText('miniPageVehicleState', contract.plate || (contract.hasActiveRoute === false ? 'NONE' : 'UNIT'));

    const rows = [
        miniInfoRow('Assigned Vehicle', contract.vehicle || 'Handheld Receiver', 'fa-truck-fast'),
        miniInfoRow('Plate', contract.plate, 'fa-id-card'),
        miniInfoRow('Fuel', contract.vehicleFuelLabel || (contract.vehicleFuel !== undefined ? `${Math.round(Number(contract.vehicleFuel) || 0)}%` : 'N/A'), 'fa-gas-pump'),
        miniInfoRow('Condition', contract.vehicleConditionLabel || 'N/A', 'fa-heart-pulse'),
        miniInfoRow('GPS', contract.gpsLocked === false ? 'Searching' : 'Locked', 'fa-location-crosshairs')
    ];

    if (contract.type === 'trailer') {
        rows.push(
            miniInfoRow('Trailer', contract.trailerLabel || 'Assigned Trailer', 'fa-trailer'),
            miniInfoRow('Safe Speed', contract.safeSpeed ? `${Math.floor(Number(contract.safeSpeed))} MPH` : '', 'fa-gauge-high')
        );
    }

    const hasControlVehicle = contract.hasActiveRoute !== false || contract.reuseVehicle?.available || contract.plate;
    const controlPanel = hasControlVehicle
        ? miniPanel('Vehicle Controls', `
        <div class="mini-action-grid">
            ${miniActionButton('Engine', 'fa-power-off', 'engine', 'Toggle engine')}
            ${miniActionButton('Locks', 'fa-lock', 'locks', 'Toggle door locks')}
            ${miniActionButton('Locate', 'fa-location-crosshairs', 'locate', 'Locate vehicle')}
            ${miniActionButton('Driver', 'fa-door-open', 'door_0', 'Toggle driver door')}
            ${miniActionButton('Hood', 'fa-car-burst', 'door_4', 'Toggle hood')}
            ${miniActionButton('Passenger', 'fa-door-open', 'door_1', 'Toggle passenger door')}
            ${miniActionButton('Rear Left', 'fa-door-open', 'door_2', 'Toggle rear left door')}
            ${miniActionButton('Trunk', 'fa-box-open', 'door_5', 'Toggle trunk')}
            ${miniActionButton('Rear Right', 'fa-door-open', 'door_3', 'Toggle rear right door')}
            ${miniActionButton('All Doors', 'fa-up-right-from-square', 'doors', 'Toggle all doors')}
            ${miniActionButton('Hazards', 'fa-triangle-exclamation', 'hazards', 'Toggle hazard lights')}
            ${miniActionButton('Cab Light', 'fa-lightbulb', 'interior', 'Toggle interior light')}
        </div>
    `, 'mini-control-panel')
        : miniPanel('Vehicle Controls', '<p>No current vehicle detected.</p>', 'mini-control-panel');

    content.innerHTML = [
        miniPanel('Vehicle Data', rows),
        controlPanel
    ].join('');
}

function renderMiniHistoryCards(history = []) {
    const entries = normalizeRouteHistory(history).slice(0, 5);
    if (!entries.length) return '<p>No completed route summaries logged.</p>';

    return entries.map((summary, index) => {
        const fields = routeSummaryFields(summary)
            .filter(([label]) => ['Contract', 'Load', 'Contents', 'Vehicle', 'Completed In', 'Timing Result', 'Cargo Condition', 'Final Payout', 'XP / Rep'].includes(label))
            .map(([label, value]) => miniInfoRow(label, value, 'fa-circle-info'))
            .join('');

        return `
            <details class="mini-history-card" ${index === 0 ? 'open' : ''}>
                <summary>
                    <span>
                        <small>${escapeHtml(summary.completedAt || 'Completed route')}</small>
                        <strong>${escapeHtml(routeSummaryTitle(summary))}</strong>
                    </span>
                    <em>${escapeHtml(formatMoney(summary.payout || 0))}</em>
                </summary>
                ${fields}
            </details>
        `;
    }).join('');
}

function renderMiniDispatchPage(contract = {}) {
    const content = document.getElementById('miniDispatchContent');
    if (!content) return;

    setText('miniPageDispatchState', contract.radioChatter ? 'NEW RX' : 'RX');

    const alert = contract.contractAlert;
    const rows = [
        miniInfoRow('Latest Radio', contract.radioChatter || 'No recent dispatch traffic.', 'fa-tower-broadcast'),
        miniInfoRow('Route Stage', contract.stage, 'fa-location-arrow'),
        miniInfoRow('ETA', contract.expectedCompletion, 'fa-clock'),
        alert ? miniInfoRow(alert.label || 'Dispatch Alert', alert.description || 'Route conditions changed.', 'fa-triangle-exclamation') : '',
        miniInfoRow('Last Update', contract.lastUpdate || formatMiniClock(), 'fa-rotate')
    ];

    content.innerHTML = [
        miniPanel('Dispatch Log', rows),
        miniPanel('Completed Routes', renderMiniHistoryCards(contract.routeHistory || dispatchData?.routeHistory || []), 'mini-history-panel')
    ].join('');
}

function renderMiniSettingsPage(contract = {}) {
    const content = document.getElementById('miniSettingsContent');
    if (!content) return;

    const player = contract.player || dispatchData?.player || {};
    const rankText = player.rank
        ? `Rank ${player.rank}${player.rankLabel ? ` - ${player.rankLabel}` : ''}`
        : player.rankLabel || 'Rank unavailable';
    const xp = Number(player.xp || 0);
    const nextRankXp = Number(player.nextRankXp || 0);
    const xpText = nextRankXp > xp
        ? `${formatInteger(xp)} / ${formatInteger(nextRankXp)} XP`
        : `${formatInteger(xp)} XP`;
    const dockCanToggle = contract.hasActiveRoute !== false && contract.dockEnabled !== false;
    const dockVisible = dockCanToggle && contract.dockVisible !== false;
    const dockButtonText = dockCanToggle ? (dockVisible ? 'Hide Dock' : 'Show Dock') : 'Dock Standby';

    content.innerHTML = [
        miniPanel('Receiver Settings', [
            miniInfoRow('Receiver Model', 'BDG-LSFC-R-1.1', 'fa-microchip'),
            miniInfoRow('Dock Model', 'BDG-LSFC-D-1.1', 'fa-window-restore'),
            miniInfoRow('Firmware', 'BDG-FW 1.1.4', 'fa-code-branch'),
            miniInfoRow('Frequency', formatMiniFrequency(contract.radioFrequency || dispatchData?.radioFrequency || dispatchData?.config?.radioFrequency || '68.9'), 'fa-wave-square'),
            miniInfoRow('Telemetry', contract.signalLabel || 'Dispatch signal locked', 'fa-satellite-dish'),
            `
                <div class="mini-settings-toggle-row">
                    <button class="mini-wide-action mini-settings-toggle mini-movement-toggle ${miniMovementUnlocked ? 'is-enabled' : ''}" data-mini-movement-toggle>
                        <i class="fas ${miniMovementUnlocked ? 'fa-lock' : 'fa-arrows-up-down-left-right'}"></i>
                        <span>${miniMovementUnlocked ? 'Lock Move' : 'Unlock Move'}</span>
                    </button>
                    <button class="mini-wide-action mini-settings-toggle mini-dock-toggle ${dockVisible ? 'is-enabled' : ''}" data-mini-dock-toggle ${dockCanToggle ? '' : 'disabled'}>
                        <i class="fas ${dockVisible ? 'fa-eye-slash' : 'fa-window-restore'}"></i>
                        <span>${dockButtonText}</span>
                    </button>
                </div>
            `
        ]),
        miniPanel('Driver Profile', [
            miniInfoRow('Receiver Assigned To', player.name || 'Driver', 'fa-user'),
            miniInfoRow('Rank', rankText, 'fa-ranking-star'),
            miniInfoRow('XP', xpText, 'fa-gauge-high'),
            miniInfoRow('Reputation', formatInteger(player.reputation || 0), 'fa-star'),
            miniInfoRow('Job / Grade', player.jobText, 'fa-id-badge')
        ])
    ].join('');
}

function renderMiniAppPages(contract = {}) {
    renderMiniHome(contract);
    renderMiniManifestPage(contract);
    renderMiniLoadPage(contract);
    renderMiniVehiclePage(contract);
    renderMiniDispatchPage(contract);
    renderMiniSettingsPage(contract);
}

function miniStructuralSignature(contract = {}) {
    const alert = contract.contractAlert || {};
    const reuse = contract.reuseVehicle || {};
    const checklist = contract.loadChecklist || {};
    const manifest = Array.isArray(contract.manifest) ? contract.manifest : [];
    const manifestSignature = manifest.map(entry => [
        entry?.stop,
        entry?.receiver,
        entry?.dropoff,
        entry?.cargoLabel,
        entry?.label,
        entry?.cargoType
    ].join(':')).join(',');
    const history = normalizeRouteHistory(contract.routeHistory);
    const historySignature = history.map(entry => [
        entry?.historyId,
        entry?.contractId,
        entry?.completedAt,
        entry?.payout,
        entry?.xp,
        entry?.rep
    ].join(':')).join(',');

    return [
        contract.hasActiveRoute,
        contract.type,
        contract.label,
        contract.stage,
        contract.notice,
        contract.destination,
        contract.destinationAddress,
        contract.expectedCompletion,
        alert.label,
        alert.description,
        contract.radioChatter,
        contract.currentStop,
        contract.totalStops,
        contract.loadedCargo,
        contract.requiredCargo,
        contract.cargo,
        contract.payout,
        contract.contractId,
        contract.priorityLabel,
        contract.routeLength,
        contract.plate,
        contract.vehicle,
        contract.vehicleSource,
        contract.contractor,
        contract.contractorVehicleId,
        contract.vehicleType,
        contract.vehicleFuel,
        contract.vehicleFuelLabel,
        contract.vehicleConditionScore,
        contract.vehicleConditionLabel,
        contract.vehicleConditionLevel,
        contract.cargoConditionLabel,
        contract.cargoConditionLevel,
        contract.cargoConditionNote,
        contract.loaded,
        contract.cargoReady,
        contract.verifiedCargo,
        contract.receiverLoadAction,
        contract.loadVerificationMode,
        contract.contractRequestPending,
        contract.trailerAttached,
        contract.trailerHooked,
        contract.trailerDropped,
        contract.trailerLabel,
        contract.trailerContents,
        contract.trailerDepotLabel,
        contract.trailerDropLabel,
        contract.safeSpeed,
        contract.dockEnabled,
        contract.dockVisible,
        contract.dockUserHidden,
        checklist.truckSecure,
        checklist.trailerSecure,
        reuse.available,
        reuse.type,
        reuse.index,
        reuse.plate,
        reuse.vehicleLabel,
        reuse.label,
        reuse.source,
        reuse.contractor,
        reuse.vehicleId,
        manifestSignature,
        historySignature
    ].join('|');
}

function updateGpsIndicator(element, locked) {
    if (!element) return;

    const searching = locked === false;
    element.classList.toggle('gps-search', searching);

    const label = element.querySelector('em');
    if (label) {
        label.innerText = searching ? 'SRCH' : 'LOCK';
    }
}

function renderDockProgressIcons(element, total, iconClass, label, stateForIndex, summary) {
    if (!element) return;

    const count = Math.max(0, Number(total) || 0);
    const visibleCount = Math.min(count, 8);
    const icons = [];

    if (visibleCount <= 0) {
        element.innerHTML = '<i class="fas fa-minus mini-dock-icon-empty"></i>';
        element.setAttribute('aria-label', `${label}: none`);
        return;
    }

    for (let index = 0; index < visibleCount; index += 1) {
        const state = typeof stateForIndex === 'function' ? stateForIndex(index, count) : 'is-pending';
        icons.push(`<i class="${iconClass} ${state}"></i>`);
    }

    if (count > visibleCount) {
        icons.push(`<b>+${count - visibleCount}</b>`);
    }

    element.innerHTML = icons.join('');
    element.setAttribute('aria-label', summary || `${label}: ${count}`);
}

function dockConditionState(level) {
    const normalized = String(level || 'stable').toLowerCase();
    if (normalized === 'stable') return 'is-complete';
    if (normalized === 'critical' || normalized === 'damaged') return 'is-critical';
    return 'is-loaded';
}

function dockLoadIcon(iconClass, state, title) {
    return `<i class="${iconClass} ${state}" title="${escapeHTML(title)}"></i>`;
}

function renderDockLoadStatus(element, contract = {}) {
    if (!element) return;

    const checklist = contract.loadChecklist || {};
    const type = contract.type || 'delivery';
    const conditionState = dockConditionState(contract.cargoConditionLevel);
    const active = contract.hasActiveRoute !== false;
    const icons = [];
    const labels = [];

    if (type === 'trailer') {
        const attached = contract.trailerAttached || contract.trailerHooked;
        const truckSecure = checklist.truckSecure === true;
        const trailerSecure = checklist.trailerSecure === true;
        const secured = contract.trailerHooked || (truckSecure && trailerSecure);
        const partiallySecured = truckSecure || trailerSecure;
        const verified = contract.loaded === true || contract.trailerHooked === true;

        icons.push(dockLoadIcon('fas fa-link', attached ? 'is-complete' : 'is-pending', attached ? 'Trailer attached' : 'Trailer not attached'));
        icons.push(dockLoadIcon('fas fa-lock', secured ? 'is-complete' : partiallySecured ? 'is-loaded' : 'is-pending', secured ? 'Load secured' : partiallySecured ? 'Load secure checks in progress' : 'Load not secured'));
        icons.push(dockLoadIcon('fas fa-shield-halved', conditionState, contract.cargoConditionLabel || 'Trailer condition'));
        icons.push(dockLoadIcon('fas fa-clipboard-check', verified ? 'is-complete' : secured ? 'is-loaded' : 'is-pending', verified ? 'Load verified' : 'Load verification pending'));

        labels.push(attached ? 'attached' : 'attach pending');
        labels.push(secured ? 'secured' : partiallySecured ? 'securing' : 'secure pending');
        labels.push((contract.cargoConditionLabel || 'stable').toLowerCase());
        labels.push(verified ? 'verified' : 'verify pending');
    } else {
        const verified = contract.verifiedCargo === true;
        const verificationReady = contract.cargoReady === true || contract.loaded === true || Number(contract.loadedCargo || 0) > 0;

        icons.push(dockLoadIcon('fas fa-clipboard-check', verified ? 'is-complete' : verificationReady ? 'is-loaded' : 'is-pending', verified ? 'Load verified' : verificationReady ? 'Ready to verify load' : 'Load verification pending'));
        icons.push(dockLoadIcon('fas fa-shield-halved', active ? conditionState : 'is-pending', contract.cargoConditionLabel || 'Cargo condition'));

        labels.push(verified ? 'verified' : verificationReady ? 'verify ready' : 'verify pending');
        labels.push(contract.cargoConditionLabel || 'condition pending');
    }

    element.innerHTML = icons.join('') || '<i class="fas fa-minus mini-dock-icon-empty"></i>';
    element.setAttribute('aria-label', `Load: ${labels.join(', ')}`);
}

function updateMiniLiveFields(contract = {}) {
    const alert = contract.contractAlert;
    mini.dataset.contractType = contract.type || 'delivery';
    setText('miniPageRouteState', miniActiveLabel(contract));

    const miniTitle = document.getElementById('miniTitle');
    if (miniTitle) miniTitle.innerText = contract.label || titleFromType(contract.type) || 'Active Contract';

    const miniChannel = document.getElementById('miniChannel');
    if (miniChannel) miniChannel.innerText = formatMiniFrequency(contract.radioFrequency || dispatchData?.radioFrequency || dispatchData?.config?.radioFrequency || '68.9');

    updateReceiverLogo(document.getElementById('miniMakerLogo'), contract.logo);
    setText('miniPayout', formatMoney(contract.payout));
    setText('miniNotice', contract.notice || 'Follow your route instructions.');
    setText('miniStage', contract.stage || 'Active');

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

    setText('miniDestination', contract.destination || 'N/A');
    const miniDestinationAddress = document.getElementById('miniDestinationAddress');
    if (miniDestinationAddress) {
        if (contract.destinationAddress) {
            miniDestinationAddress.innerText = contract.destinationAddress;
            miniDestinationAddress.classList.remove('hidden');
        } else {
            miniDestinationAddress.classList.add('hidden');
        }
    }

    setText('miniCargoLoaded', `${contract.loadedCargo || 0} / ${contract.requiredCargo || 0}`);
    setText('miniProgress', `${contract.currentStop || 0} / ${contract.totalStops || 0}`);
    setText('miniCargo', contract.cargo || 'Cargo');

    const miniCargoCondition = document.getElementById('miniCargoCondition');
    if (miniCargoCondition) {
        miniCargoCondition.innerText = contract.cargoConditionLabel || 'CARGO STABLE';
        miniCargoCondition.dataset.level = contract.cargoConditionLevel || 'stable';
    }

    const miniCancelRoute = document.getElementById('miniCancelRoute');
    if (miniCancelRoute) {
        miniCancelRoute.classList.toggle('hidden', contract.hasActiveRoute === false);
    }

    const miniLastUpdate = document.getElementById('miniLastUpdate');
    if (miniLastUpdate) miniLastUpdate.innerText = `LAST UPDATE ${contract.lastUpdate || formatMiniClock()}`;

    updateReceiverRadioLine(document.getElementById('miniRadioLine'), contract.radioChatter || '');
    updateReceiverRouteProgress(document.getElementById('miniRouteProgressBar'), contract);
    updateReceiverSignal(document.getElementById('miniSignalMeter'), contract);

    updateGpsIndicator(document.getElementById('miniGpsStatus'), contract.gpsLocked);

    const miniAlert = document.getElementById('miniAlert');
    const miniAlertLabel = document.getElementById('miniAlertLabel');
    const miniAlertText = document.getElementById('miniAlertText');

    if (miniAlert && miniAlertText && alert && (alert.label || alert.description)) {
        if (miniAlertLabel) miniAlertLabel.innerHTML = '<i class="fas fa-triangle-exclamation"></i>ALERT';
        miniAlertText.innerText = `${alert.label || 'Dispatch Alert'}${alert.description ? ' - ' + alert.description : ''}`;
        miniAlert.classList.remove('mini-radio-alert');
        miniAlert.classList.remove('hidden');
    } else if (miniAlert) {
        miniAlert.classList.remove('mini-radio-alert');
        miniAlert.classList.add('hidden');
    }
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

function normalizeRouteHistory(value) {
    if (Array.isArray(value)) return value.filter(Boolean);
    if (value && typeof value === 'object') return [value];
    return [];
}

function routeSummaryTitle(summary = {}) {
    return summary.routeLabel || summary.contractLabel || titleFromType(summary.contractType);
}

function routeSummarySubtitle(summary = {}) {
    return [
        summary.contractId ? `Contract ${summary.contractId}` : '',
        summary.completedAt || '',
        summary.vehicleLabel || ''
    ].filter(Boolean).join(' - ');
}

function isLateRouteSummary(summary = {}) {
    const status = String(summary.time?.status || '').toLowerCase();
    const label = String(summary.time?.label || '').toLowerCase();
    return status === 'late' || label.includes('late');
}

function isDamageFreeRouteSummary(summary = {}) {
    const damage = Number(summary.damagePercent || 0);
    const condition = String(summary.cargoCondition?.label || '').toLowerCase();
    return damage <= 0 && !condition.includes('damage');
}

function countRecentRouteStreak(history, predicate) {
    let count = 0;
    for (const summary of normalizeRouteHistory(history)) {
        if (!predicate(summary || {})) break;
        count += 1;
    }
    return count;
}

function mostFrequentRouteValue(history, getter, fallback = 'None logged') {
    const counts = new Map();
    normalizeRouteHistory(history).forEach(summary => {
        const value = displayText(getter(summary || {}), '');
        if (!value) return;
        counts.set(value, (counts.get(value) || 0) + 1);
    });

    let bestValue = fallback;
    let bestCount = 0;
    counts.forEach((count, value) => {
        if (count > bestCount) {
            bestValue = value;
            bestCount = count;
        }
    });

    return {
        value: bestValue,
        count: bestCount
    };
}

function routeVehicleUsageLabel(summary = {}) {
    const label = displayText(summary.vehicleLabel, '');
    if (!label) return '';
    if (summary.contractType === 'trailer' && label.includes(' + ')) {
        return label.split(' + ')[0].trim();
    }
    return label;
}

function routeDepotUsageLabel(summary = {}) {
    if (summary.contractType === 'trailer') {
        return summary.trailerDepotLabel || summary.pickupDepotLabel || summary.pickupLabel || '';
    }

    return summary.pickupDepotLabel || summary.pickupLabel || summary.depotLabel || '';
}

function getCompanyInsights(data = dispatchData || {}) {
    const history = normalizeRouteHistory(data.routeHistory || data.lastRouteSummary);
    const player = data.player || {};
    const mostUsedVehicle = mostFrequentRouteValue(history, routeVehicleUsageLabel, 'No vehicle history');
    const mostUsedDepot = mostFrequentRouteValue(
        history,
        routeDepotUsageLabel,
        'No depot history'
    );
    const mostCommonRoute = mostFrequentRouteValue(history, summary => summary.routeLabel || summary.contractLabel, 'No route history');

    return {
        damageFreeStreak: countRecentRouteStreak(history, isDamageFreeRouteSummary),
        onTimeStreak: countRecentRouteStreak(history, summary => !isLateRouteSummary(summary)),
        mostUsedVehicle,
        mostUsedDepot,
        mostCommonRoute,
        historyCount: history.length,
        completedRouteStreak: Math.max(0, Number(player.completedRouteStreak || 0))
    };
}

function routeSummaryAdjustments(summary = {}) {
    const adjustments = Array.isArray(summary.adjustments)
        ? summary.adjustments.filter(adj => adj && Number(adj.percent || 0) !== 0)
        : [];

    return adjustments.length
        ? adjustments.map(adj => `${adj.label || 'Adjustment'} ${formatAdjustmentPercent(adj.percent)}`).join(' - ')
        : 'None';
}

function routeSummaryContents(summary = {}) {
    if (summary.contractType === 'trailer') {
        return summary.trailerContents || 'Trailer Freight';
    }

    if (summary.cargo) return summary.cargo;
    if (summary.contractType === 'boxtruck') return 'Crates';
    if (summary.contractType === 'van') return 'Packages';
    return 'Assigned Cargo';
}

function routeSummaryFields(summary = {}) {
    const timeData = summary.time || {};
    const fields = [
        ['Contract', summary.contractId || 'N/A'],
        ['Type', titleFromType(summary.contractType)],
        ['Load', summary.priorityLabel || 'Standard'],
        ['Contents', routeSummaryContents(summary)],
        ['Vehicle', summary.vehicleLabel || 'Company Vehicle'],
        ['Completed', summary.completedAt || 'N/A'],
        ['Route Length', summary.routeLength || 'N/A'],
        ['Completed In', formatSeconds(timeData.elapsedSeconds || 0)],
        ['Timing Result', timeData.label || 'Complete'],
        ['Dispatch Event', summary.randomEvent?.label || 'None'],
        ['Cargo Condition', summary.cargoCondition?.label || 'N/A'],
        ['Payout Adjustments', routeSummaryAdjustments(summary)],
        ['Adjusted Base', formatMoney(summary.basePayout || summary.payout || 0)],
        ['Final Payout', formatMoney(summary.payout || 0)],
        ['XP / Rep', `${summary.xp || 0} XP - ${summary.rep || 0} Rep`]
    ];

    if (summary.contractType === 'trailer') {
        const conditionIndex = fields.findIndex(([label]) => label === 'Cargo Condition');
        fields.splice(conditionIndex, 0, ['Trailer Damage', `${Math.floor(Number(summary.damagePercent || 0))}%`]);
    }

    if (Number(summary.mileageBonus || 0) > 0) {
        const payoutIndex = fields.findIndex(([label]) => label === 'Adjusted Base');
        fields.splice(payoutIndex, 0,
            ['Contract Base', formatMoney(summary.contractBasePayout || 0)],
            ['Mileage Bonus', `${formatMoney(summary.mileageBonus)} (${Number(summary.routeMiles || 0).toFixed(1)} mi @ ${formatMoney(summary.mileageRate || 0)}/mi)`]
        );
    }

    if (summary.contractorDailyBonus && Number(summary.contractorDailyBonus) > 0) {
        const finalPayoutIndex = fields.findIndex(([label]) => label === 'Final Payout');
        fields.splice(finalPayoutIndex, 0, ['Daily Bonus', formatMoney(summary.contractorDailyBonus)]);
    }

    return fields;
}

function routeSummarySections(summary = {}) {
    const timeData = summary.time || {};
    const payoutRows = [];

    if (Number(summary.mileageBonus || 0) > 0) {
        payoutRows.push(
            ['Contract Base', formatMoney(summary.contractBasePayout || 0)],
            ['Mileage Bonus', `${formatMoney(summary.mileageBonus)} (${Number(summary.routeMiles || 0).toFixed(1)} mi @ ${formatMoney(summary.mileageRate || 0)}/mi)`]
        );
    }

    payoutRows.push(
        ['Adjusted Base', formatMoney(summary.basePayout || summary.payout || 0)],
        ['Adjustments', routeSummaryAdjustments(summary)],
        ['Final Payout', formatMoney(summary.payout || 0)],
        ['XP / Rep', `${summary.xp || 0} XP / ${summary.rep || 0} Rep`]
    );

    const sections = [
        {
            title: 'Contract',
            rows: [
                ['Contract', summary.contractId || 'N/A'],
                ['Driver', summary.driverName || 'Driver'],
                ['Type', titleFromType(summary.contractType)],
                ['Completed', summary.completedAt || 'N/A']
            ]
        },
        {
            title: 'Route & Load',
            rows: [
                ['Route', routeSummaryTitle(summary)],
                ['Load Type', summary.priorityLabel || 'Standard'],
                ['Contents', routeSummaryContents(summary)],
                ['Vehicle', summary.vehicleLabel || 'Company Vehicle'],
                ['Route Length', summary.routeLength || 'N/A'],
                ['Stops / Cargo', `${summary.totalStops || 0} stops / ${summary.deliveredCargo || 0} of ${summary.requiredCargo || 0}`]
            ]
        },
        {
            title: 'Timing',
            rows: [
                ['Estimated', formatSeconds(timeData.estimatedSeconds || summary.estimatedSeconds || 0)],
                ['Completed In', formatSeconds(timeData.elapsedSeconds || 0)],
                ['Result', timeData.label || 'Complete']
            ]
        },
        {
            title: 'Condition & Events',
            rows: [
                ['Cargo Condition', summary.cargoCondition?.label || 'N/A'],
                ['Condition Notes', summary.cargoCondition?.note || 'None'],
                ['Dispatch Event', summary.randomEvent?.label || 'None'],
                ['Event Details', summary.randomEvent?.description || 'None']
            ]
        },
        {
            title: 'Payout',
            rows: payoutRows
        }
    ];

    if (summary.contractType === 'trailer') {
        sections[3].rows.splice(2, 0, ['Trailer Damage', `${Math.floor(Number(summary.damagePercent || 0))}%`]);
    }

    if (summary.contractorDailyBonus && Number(summary.contractorDailyBonus) > 0) {
        const finalPayoutIndex = sections[4].rows.findIndex(([label]) => label === 'Final Payout');
        sections[4].rows.splice(finalPayoutIndex, 0, ['Daily Bonus', formatMoney(summary.contractorDailyBonus)]);
    }

    const paperworkRows = [];
    if (summary.pickupSignature) {
        paperworkRows.push(
            ['Pickup Signed By', summary.pickupSignature.name || 'Assigned Driver'],
            ['Pickup Signed At', summary.pickupSignature.signedAt || 'N/A'],
            ['Pickup Location', summary.pickupSignature.location || summary.pickupLabel || 'Cargo Pickup']
        );
    }
    if (summary.deliverySignature) {
        paperworkRows.push(
            ['Delivery Signed By', summary.deliverySignature.name || 'Assigned Driver'],
            ['Delivery Signed At', summary.deliverySignature.signedAt || 'N/A'],
            ['Receiver Location', summary.deliverySignature.location || 'Trailer Receiver']
        );
    }
    if (paperworkRows.length) {
        sections.splice(sections.length - 1, 0, { title: 'Handoff Paperwork', rows: paperworkRows });
    }

    return sections;
}

function renderRouteSummaryPrintout(summary = {}) {
    const sections = routeSummarySections(summary).map(section => {
        const rows = section.rows
            .filter(([, value]) => value !== null && value !== undefined && value !== '')
            .map(([label, value]) => `
                <div class="summary-print-row">
                    <span>${escapeHTML(label)}</span>
                    <strong>${escapeHTML(value)}</strong>
                </div>
            `).join('');

        if (!rows) return '';

        return `
            <section class="summary-print-section">
                <h3>${escapeHTML(section.title)}</h3>
                <div class="summary-print-table">${rows}</div>
            </section>
        `;
    }).join('');

    return `
        <div class="route-summary-printout">
            <div class="summary-print-header">
                <div>
                    <small>LOS SANTOS FREIGHT CO.</small>
                    <strong>Route Completion Report</strong>
                </div>
                <span>${escapeHTML(summary.contractId || 'N/A')}</span>
            </div>
            ${sections}
        </div>
    `;
}

function playerRank() {
    return Number(dispatchData?.player?.rank || 1);
}

function garageDisplayLabel(label, type) {
    if (type === 'trailer' && label && label.includes('+')) return label.split('+')[0].trim();
    return label || 'Company Vehicle';
}

function previewImageForVehicle(vehicle) {
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

function displayText(value, fallback = 'N/A') {
    const text = String(value ?? '').trim();
    return text || fallback;
}

const DISPATCH_MAP_BOUNDS = {
    minX: -4300,
    maxX: 4500,
    minY: -4300,
    maxY: 8300
};

const DISPATCH_MAP_ZOOM = {
    default: 1,
    min: 1,
    max: 2.8,
    step: 0.25
};

const DISPATCH_MAP_CATEGORIES = {
    terminal: { label: 'Terminal', icon: 'fas fa-tower-broadcast' },
    vehicle: { label: 'Vehicle Spawn', icon: 'fas fa-truck-fast' },
    garage: { label: 'Garage Spawn', icon: 'fas fa-warehouse' },
    van: { label: 'Van Pickup', icon: 'fas fa-box' },
    boxtruck: { label: 'Box Truck Pickup', icon: 'fas fa-truck-moving' },
    trailer: { label: 'Trailer Depot', icon: 'fas fa-trailer' }
};

function getDispatchHomePoints(data = dispatchData) {
    return Array.isArray(data?.dispatchHome?.points) ? data.dispatchHome.points.filter(Boolean) : [];
}

function getDispatchMapPointById(id, data = dispatchData) {
    const points = getDispatchHomePoints(data);
    return points.find(point => String(point.id || '') === String(id || '')) || null;
}

function getDispatchMapBounds(data = dispatchData) {
    return {
        ...DISPATCH_MAP_BOUNDS,
        ...(data?.dispatchHome?.mapBounds || {})
    };
}

function getDispatchMapZoomConfig(data = dispatchData) {
    const home = data?.dispatchHome || {};
    const zoomDefault = Number(home.mapZoom ?? DISPATCH_MAP_ZOOM.default);
    const min = Number(home.mapZoomMin ?? DISPATCH_MAP_ZOOM.min);
    const max = Number(home.mapZoomMax ?? DISPATCH_MAP_ZOOM.max);
    const step = Number(home.mapZoomStep ?? DISPATCH_MAP_ZOOM.step);

    return {
        default: Number.isFinite(zoomDefault) ? zoomDefault : DISPATCH_MAP_ZOOM.default,
        min: Number.isFinite(min) ? min : DISPATCH_MAP_ZOOM.min,
        max: Number.isFinite(max) ? max : DISPATCH_MAP_ZOOM.max,
        step: Number.isFinite(step) && step > 0 ? step : DISPATCH_MAP_ZOOM.step
    };
}

function clampDispatchMapZoom(value, config = getDispatchMapZoomConfig()) {
    const zoom = Number(value);
    const min = Math.min(config.min, config.max);
    const max = Math.max(config.min, config.max);
    if (!Number.isFinite(zoom)) return config.default;
    return Math.max(min, Math.min(max, zoom));
}

function getDispatchMapPanLimit(zoom = dispatchMapZoom) {
    if (!dispatchHomeMap || zoom <= 1) return { x: 0, y: 0 };
    const rect = dispatchHomeMap.getBoundingClientRect();
    return {
        x: Math.max(0, (rect.width * (zoom - 1)) / 2),
        y: Math.max(0, (rect.height * (zoom - 1)) / 2)
    };
}

function clampDispatchMapPan(pan = dispatchMapPan, zoom = dispatchMapZoom) {
    const currentZoom = Number(zoom) || 1;
    if (currentZoom <= 1.01) return { x: 0, y: 0 };

    const limit = getDispatchMapPanLimit(currentZoom);
    const x = Number(pan?.x || 0);
    const y = Number(pan?.y || 0);

    return {
        x: Math.max(-limit.x, Math.min(limit.x, x)),
        y: Math.max(-limit.y, Math.min(limit.y, y))
    };
}

function applyDispatchMapTransform() {
    if (!dispatchHomeMap) return;
    const viewport = dispatchHomeMap.querySelector('.dispatch-map-viewport');
    if (!viewport) return;

    const zoomConfig = getDispatchMapZoomConfig(dispatchData || {});
    dispatchMapZoom = clampDispatchMapZoom(dispatchMapZoom, zoomConfig);
    dispatchMapPan = clampDispatchMapPan(dispatchMapPan, dispatchMapZoom);

    viewport.style.setProperty('--map-zoom', dispatchMapZoom.toFixed(2));
    viewport.style.setProperty('--map-pan-x', `${dispatchMapPan.x.toFixed(0)}px`);
    viewport.style.setProperty('--map-pan-y', `${dispatchMapPan.y.toFixed(0)}px`);
    viewport.style.setProperty('--marker-scale', (1 / dispatchMapZoom).toFixed(3));
    dispatchHomeMap.classList.toggle('is-pannable', dispatchMapZoom > zoomConfig.min + 0.01);
    dispatchHomeMap.classList.toggle('is-panning', Boolean(dispatchMapDrag));
}

function renderDispatchMapControls(config) {
    const zoom = clampDispatchMapZoom(dispatchMapZoom, config);
    const canZoomOut = zoom > config.min + 0.01;
    const canZoomIn = zoom < config.max - 0.01;

    return `
        <div class="dispatch-map-controls">
            <button type="button" data-dispatch-map-zoom="out" ${canZoomOut ? '' : 'disabled'} title="Zoom out"><i class="fas fa-minus"></i></button>
            <span>${Math.round(zoom * 100)}%</span>
            <button type="button" data-dispatch-map-zoom="in" ${canZoomIn ? '' : 'disabled'} title="Zoom in"><i class="fas fa-plus"></i></button>
            <button type="button" data-dispatch-map-zoom="reset" title="Reset zoom"><i class="fas fa-compress"></i></button>
        </div>
    `;
}

function getSelectedDispatchMapPoint(data = dispatchData) {
    const points = getDispatchHomePoints(data);
    if (!points.length) {
        selectedDispatchHomePointId = null;
        return null;
    }

    let point = getDispatchMapPointById(selectedDispatchHomePointId, data);
    if (!point) {
        point = points.find(entry => entry.category === 'terminal') || points[0];
        selectedDispatchHomePointId = point.id || null;
    }

    return point;
}

function dispatchMapPosition(coords = {}, overlapIndex = 0, data = dispatchData) {
    const bounds = getDispatchMapBounds(data);
    const rawX = Number(coords.x || 0);
    const rawY = Number(coords.y || 0);
    const xRange = bounds.maxX - bounds.minX;
    const yRange = bounds.maxY - bounds.minY;
    const left = ((rawX - bounds.minX) / xRange) * 100;
    const top = 100 - (((rawY - bounds.minY) / yRange) * 100);
    const offsets = [
        [0, 0],
        [13, -8],
        [-13, 8],
        [13, 9],
        [-13, -9],
        [0, 15]
    ];
    const offset = offsets[overlapIndex % offsets.length];

    return {
        left: Math.max(4, Math.min(96, left)),
        top: Math.max(4, Math.min(96, top)),
        offsetX: offset[0],
        offsetY: offset[1]
    };
}

function displayDispatchAddress(point = {}) {
    return displayText(point.address || point.street || point.zone, 'Address unavailable');
}

function renderDispatchMapArt() {
    return `
        <div class="dispatch-map-art" aria-hidden="true">
            <svg viewBox="0 0 100 140" preserveAspectRatio="none">
                <path class="map-land map-land-main" d="M52 3 C65 8 72 19 76 35 C83 45 85 59 80 75 C84 91 78 104 70 113 C66 125 53 136 39 132 C28 129 22 116 20 103 C13 93 14 78 19 65 C13 53 16 38 24 29 C29 15 39 6 52 3 Z"/>
                <path class="map-land map-land-city" d="M35 95 C45 90 61 92 68 102 C66 114 55 122 43 121 C33 118 28 106 35 95 Z"/>
                <path class="map-road" d="M53 9 C49 26 47 39 51 55 C57 74 50 89 44 103 C39 114 43 124 48 132"/>
                <path class="map-road" d="M25 70 C37 69 47 73 58 81 C66 87 72 95 77 106"/>
                <path class="map-road" d="M28 34 C39 42 48 46 61 45 C69 45 75 49 80 55"/>
                <path class="map-road soft" d="M19 102 C30 99 44 100 57 107 C64 111 69 116 73 122"/>
            </svg>
            <span class="map-region city">LOS SANTOS</span>
            <span class="map-region county">BLAINE COUNTY</span>
            <span class="map-region ocean">PACIFIC</span>
        </div>
    `;
}

function renderDispatchHomeLegend() {
    const legendHtml = Object.entries(DISPATCH_MAP_CATEGORIES).map(([category, meta]) => `
        <span class="dispatch-legend-pill ${category}">
            <i class="${meta.icon}"></i>
            ${escapeHTML(meta.label)}
        </span>
    `).join('');

    return legendHtml;
}

function renderDispatchHome(data = dispatchData) {
    if (!dispatchHomeMap) return;
    const points = getDispatchHomePoints(data);
    const overlapCounts = {};
    const mapImage = data?.dispatchHome?.mapImage;
    const zoomConfig = getDispatchMapZoomConfig(data);

    if (dispatchMapZoom === null) dispatchMapZoom = zoomConfig.default;
    dispatchMapZoom = clampDispatchMapZoom(dispatchMapZoom, zoomConfig);
    dispatchMapPan = clampDispatchMapPan(dispatchMapPan, dispatchMapZoom);

    getSelectedDispatchMapPoint(data);
    const legendHtml = renderDispatchHomeLegend();
    dispatchHomeMap.classList.toggle('has-map-image', Boolean(mapImage));

    if (!points.length) {
        dispatchHomeMap.innerHTML = '<div class="dispatch-map-empty">No dispatch map locations are configured.</div>';
        return;
    }

    const markerHtml = points.map(point => {
        const coords = point.coords || {};
        const coordKey = `${Math.round(Number(coords.x || 0) / 6)}:${Math.round(Number(coords.y || 0) / 6)}`;
        const overlapIndex = overlapCounts[coordKey] || 0;
        overlapCounts[coordKey] = overlapIndex + 1;
        const pos = dispatchMapPosition(coords, overlapIndex, data);
        const category = point.category || 'terminal';
        const meta = DISPATCH_MAP_CATEGORIES[category] || DISPATCH_MAP_CATEGORIES.terminal;
        const selected = String(point.id || '') === String(selectedDispatchHomePointId || '');

        return `
            <button class="dispatch-map-marker ${category} ${selected ? 'selected' : ''}"
                data-dispatch-map-marker="${escapeHTML(point.id || '')}"
                style="--x:${pos.left.toFixed(2)}%;--y:${pos.top.toFixed(2)}%;--ox:${pos.offsetX}px;--oy:${pos.offsetY}px"
                title="${escapeHTML(point.label || meta.label)}">
                <i class="${escapeHTML(point.icon || meta.icon)}"></i>
            </button>
        `;
    }).join('');

    dispatchHomeMap.innerHTML = `
        <div class="dispatch-map-viewport" style="--map-zoom:${dispatchMapZoom.toFixed(2)};--map-pan-x:${dispatchMapPan.x.toFixed(0)}px;--map-pan-y:${dispatchMapPan.y.toFixed(0)}px;--marker-scale:${(1 / dispatchMapZoom).toFixed(3)}">
            ${mapImage ? `<img class="dispatch-map-image" src="${escapeHTML(mapImage)}" alt="" aria-hidden="true">` : ''}
            ${renderDispatchMapArt()}
            <div class="dispatch-map-markers">${markerHtml}</div>
        </div>
        <div class="dispatch-home-legend">${legendHtml}</div>
        ${renderDispatchMapControls(zoomConfig)}
    `;
    applyDispatchMapTransform();
}

function stableDispatchSignature(value) {
    try {
        return JSON.stringify(value ?? null);
    } catch {
        return String(value ?? '');
    }
}

function dispatchRenderChanged(key, value) {
    const signature = stableDispatchSignature(value);
    if (dispatchRenderSignatures[key] === signature) return false;
    dispatchRenderSignatures[key] = signature;
    return true;
}

function dispatchTabSignature(data = {}, tab = activeDispatchTab) {
    if (tab === 'home') {
        return {
            dispatchHome: data.dispatchHome || {},
            currentJob: data.currentJob || null,
            routeHistory: data.routeHistory || data.lastRouteSummary || null,
            garage: data.garage || [],
            contractor: data.contractor || null
        };
    }

    if (tab === 'history') {
        return data.routeHistory || data.lastRouteSummary || null;
    }

    if (tab === 'garage') {
        return { garage: data.garage || [] };
    }

    if (tab === 'contractor') {
        return {
            contractor: data.contractor || {},
            currentJob: data.currentJob || null
        };
    }

    if (tab === 'company') {
        return {
            player: data.player || {},
            contractor: data.contractor || {},
            companyStats: data.companyStats || {},
            routeHistory: data.routeHistory || data.lastRouteSummary || null,
            currentJob: data.currentJob || null,
            ranks: data.ranks || []
        };
    }

    if (tab === 'dispatch') {
        return {
            playerRank: data.player?.rank || 1,
            contracts: data.contracts || {},
            vehicles: data.vehicles || {},
            priorityLoads: data.priorityLoads || {},
            reuse: data.reuse || {}
        };
    }

    return data.currentJob || null;
}

function renderPreviewMetric(label, value, subtext = '') {
    return `
        <div class="preview-metric">
            <small>${escapeHTML(label)}</small>
            <strong>${escapeHTML(displayText(value))}</strong>
            ${subtext ? `<span>${escapeHTML(subtext)}</span>` : ''}
        </div>
    `;
}

function renderPreviewInfo(icon, label, value, subtext = '') {
    return `
        <div class="preview-info-row">
            <i class="fas ${escapeHTML(icon)}"></i>
            <div>
                <small>${escapeHTML(label)}</small>
                <strong>${escapeHTML(displayText(value))}</strong>
                ${subtext ? `<span>${escapeHTML(subtext)}</span>` : ''}
            </div>
        </div>
    `;
}

function buildHomePreviewPanel() {
    const point = getSelectedDispatchMapPoint();

    if (!point) {
        previewContext.innerHTML = `
            <div class="route-box preview-status-card">
                <div class="preview-context-head">
                    <div>
                        <small>DISPATCH MAP</small>
                        <h2>No Location Selected</h2>
                    </div>
                    <span class="preview-pill">STANDBY</span>
                </div>
                <p>No LSFC operating locations are available for the home map.</p>
            </div>
        `;
        return;
    }

    const category = point.category || 'terminal';
    const meta = DISPATCH_MAP_CATEGORIES[category] || DISPATCH_MAP_CATEGORIES.terminal;
    const details = Array.isArray(point.details) ? point.details : [];
    const photoHtml = point.photo
        ? `<img src="${escapeHTML(point.photo)}" alt="${escapeHTML(point.label || 'Dispatch location')}" loading="lazy">`
        : `<div class="dispatch-location-photo-fallback"><i class="${escapeHTML(point.icon || meta.icon)}"></i><span>${escapeHTML(meta.label)}</span></div>`;
    const detailRows = details.length
        ? details.map(row => renderPreviewInfo(row.icon || 'fa-circle-info', row.label || 'Info', row.value ?? 'N/A', row.subtext || '')).join('')
        : [
            renderPreviewInfo('fa-layer-group', 'Type', meta.label),
            renderPreviewInfo('fa-road', 'Street Address', displayDispatchAddress(point)),
            renderPreviewInfo('fa-clipboard-check', 'Use', point.description || 'LSFC operating point.')
        ].join('');
    const insights = getCompanyInsights(dispatchData || {});

    previewContext.innerHTML = `
        <div class="dispatch-location-panel">
            <div class="dispatch-location-photo ${point.photo ? 'has-photo' : ''}">
                ${photoHtml}
            </div>
            <div class="preview-context-head">
                <div>
                    <small>${escapeHTML(meta.label)}</small>
                    <h2>${escapeHTML(point.label || 'Dispatch Location')}</h2>
                </div>
                <span class="preview-pill green">MAP</span>
            </div>
            <p>${escapeHTML(point.description || 'Select Set GPS to route to this operating point.')}</p>
            <div class="preview-metric-grid two">
                ${renderPreviewMetric('Address', displayDispatchAddress(point))}
                ${renderPreviewMetric('Zone', point.zone || 'San Andreas')}
            </div>
            <div class="dispatch-location-details">
                ${detailRows}
            </div>
            <button class="dispatch-gps-button" data-dispatch-set-gps="${escapeHTML(point.id || '')}">
                <i class="fas fa-location-arrow"></i>
                <span>Set GPS</span>
            </button>
        </div>
        <div class="selected preview-brief-card">
            ${renderPreviewInfo('fa-shield-halved', 'Damage-Free Streak', `${insights.damageFreeStreak} routes`, 'Recent clean deliveries')}
            ${renderPreviewInfo('fa-stopwatch', 'On-Time Streak', `${insights.onTimeStreak} routes`, 'Recent on-time performance')}
            ${renderPreviewInfo('fa-truck', 'Most Used Vehicle', insights.mostUsedVehicle.value, insights.mostUsedVehicle.count ? `${insights.mostUsedVehicle.count} logged routes` : '')}
            ${renderPreviewInfo('fa-warehouse', 'Most Used Depot', insights.mostUsedDepot.value, insights.mostUsedDepot.count ? `${insights.mostUsedDepot.count} logged routes` : '')}
        </div>
    `;
}

function getGarageVehicleKey(vehicle) {
    if (!vehicle) return '';
    return `${vehicle.type || 'vehicle'}:${Number(vehicle.index || 0)}`;
}

function getSelectedGarageVehicle() {
    const garage = dispatchData?.garage || [];
    if (!garage.length) {
        selectedGarageKey = null;
        return null;
    }

    let selected = garage.find(vehicle => getGarageVehicleKey(vehicle) === selectedGarageKey);
    if (!selected) {
        selected = garage[0];
        selectedGarageKey = getGarageVehicleKey(selected);
    }

    return selected;
}

function getActiveContractorVehicle(contractor) {
    return (contractor?.vehicles || []).find(vehicle => vehicle.out) || null;
}

function getPrimaryContractorBoard(contractor) {
    const board = contractor?.board || [];
    return board.find(contract => contract.canStart) || board[0] || null;
}

function getContractorVehicleKey(vehicle) {
    return String(vehicle?.id || '');
}

function getContractorDailyRouteKey(route) {
    return String(route?.key || '');
}

function getContractorDailyRouteType(route) {
    return String(route?.type || (route?.types && route.types[0]) || 'van');
}

function getContractorContractKey(contract) {
    if (!contract) return '';
    return contract.key || `${contract.type || 'contract'}:${contract.priorityKey || 'standard'}:${Number(contract.routeIndex || 0)}`;
}

function getContractorMarketKey(vehicle) {
    if (!vehicle) return '';
    return `${vehicle.type || 'vehicle'}:${Number(vehicle.index || 0)}`;
}

function getSelectedContractorVehicle(contractor) {
    const vehicles = contractor?.vehicles || [];
    if (!vehicles.length) {
        selectedContractorVehicleId = null;
        return null;
    }

    let selected = vehicles.find(vehicle => getContractorVehicleKey(vehicle) === String(selectedContractorVehicleId || ''));
    if (!selected) selected = getActiveContractorVehicle(contractor) || vehicles[0];
    selectedContractorVehicleId = getContractorVehicleKey(selected);
    return selected;
}

function getSelectedContractorDailyRoute(contractor) {
    const routes = contractor?.dailyRoutes || [];
    if (!routes.length) {
        selectedContractorDailyRouteKey = null;
        return null;
    }

    let selected = routes.find(route => getContractorDailyRouteKey(route) === String(selectedContractorDailyRouteKey || ''));
    if (!selected && contractor?.dailyRouteKey) selected = routes.find(route => route.key === contractor.dailyRouteKey);
    if (!selected) selected = routes[0];
    selectedContractorDailyRouteKey = getContractorDailyRouteKey(selected);
    return selected;
}

function getSelectedContractorContract(contractor) {
    const board = contractor?.board || [];
    if (!board.length) {
        selectedContractorContractKey = null;
        return null;
    }

    let selected = board.find(contract => getContractorContractKey(contract) === selectedContractorContractKey);
    if (!selected) selected = getPrimaryContractorBoard(contractor);
    selectedContractorContractKey = getContractorContractKey(selected);
    return selected;
}

function getSelectedContractorMarketVehicle(contractor) {
    const market = contractor?.market || [];
    if (!market.length) {
        selectedContractorMarketKey = null;
        return null;
    }

    let selected = market.find(vehicle => getContractorMarketKey(vehicle) === selectedContractorMarketKey);
    if (!selected) selected = market[0];
    selectedContractorMarketKey = getContractorMarketKey(selected);
    return selected;
}

function getContractorTrailerPreview(item = {}) {
    if (!item || item.type !== 'trailer') return null;

    const key = item.trailerKey || '';
    const configured = key && dispatchData?.routeTrailers ? dispatchData.routeTrailers[key] : null;

    return {
        key,
        label: item.trailerLabel || configured?.label || configured?.model || key || 'Assigned Trailer',
        photo: item.trailerPhoto || configured?.photo || '',
        contents: item.trailerContents || configured?.contents || ''
    };
}

function renderContractorTrailerPreview(item = {}) {
    const trailer = getContractorTrailerPreview(item);
    if (!trailer) return '';

    return `
        <div class="contractor-trailer-preview">
            ${trailer.photo ? `<img src="${escapeHTML(trailer.photo)}" alt="${escapeHTML(trailer.label)}">` : '<div class="contractor-trailer-photo-placeholder"><i class="fas fa-trailer"></i></div>'}
            <div>
                <small>ASSIGNED TRAILER</small>
                <strong>${escapeHTML(trailer.label)}</strong>
                ${trailer.contents ? `<span>${escapeHTML(trailer.contents)}</span>` : ''}
            </div>
        </div>
    `;
}

function syncContractorSelection(contractor) {
    const dailyRoute = getSelectedContractorDailyRoute(contractor);
    const vehicle = getSelectedContractorVehicle(contractor);
    const contract = getSelectedContractorContract(contractor);
    const marketVehicle = getSelectedContractorMarketVehicle(contractor);

    if (selectedContractorPanel === 'daily' && dailyRoute) return 'daily';
    if (selectedContractorPanel === 'vehicle' && vehicle) return 'vehicle';
    if (selectedContractorPanel === 'contract' && contract) return 'contract';
    if (selectedContractorPanel === 'market' && marketVehicle) return 'market';

    selectedContractorPanel = vehicle ? 'vehicle' : dailyRoute ? 'daily' : contract ? 'contract' : marketVehicle ? 'market' : 'summary';
    return selectedContractorPanel;
}

function renderContractorDailyRoutePreview(contractor, route) {
    if (!route) return '';

    const selected = route.key === contractor.dailyRouteKey;
    const completed = selected && contractor.dailyRouteCompleted;
    const currentJob = dispatchData?.currentJob;
    const hasJob = Boolean(currentJob);
    const routeActive = selected && currentJob?.contractor && (!currentJob.contractorDailyRouteKey || currentJob.contractorDailyRouteKey === route.key);
    const lockedByCooldown = !selected && contractor.dailyRouteKey && contractor.dailyRouteCanChange === false;
    const canSelect = route.unlocked && !selected && !hasJob && !lockedByCooldown;
    const actionText = routeActive ? 'Route Active' : completed ? 'Completed' : selected ? 'Assigned' : lockedByCooldown ? 'Weekly Lock' : route.unlocked ? 'Assign Dedicated Route' : `Rank ${route.minRank || contractor.unlockRank || 1} Locked`;

    return `
        <div class="route-box preview-status-card">
            <div class="preview-context-head">
                <div>
                    <small>DAILY ROUTE BOARD</small>
                    <h2>${escapeHTML(route.label || 'Dedicated Route Assignment')}</h2>
                </div>
                <span class="preview-pill ${selected ? 'green' : ''}">${escapeHTML(selected ? completed ? 'Done' : 'Assigned' : route.unlocked ? 'Available' : `Rank ${route.minRank || 1}`)}</span>
            </div>
            <p>${escapeHTML(route.description || 'Dedicated private freight assignment.')}</p>
            ${renderContractorTrailerPreview(route)}
            <div class="preview-metric-grid two">
                ${renderPreviewMetric('Type', route.typeLabel || contractorTypeLabel(route.type))}
                ${renderPreviewMetric('Priority', route.priorityShortLabel || route.priorityLabel || 'Standard')}
                ${renderPreviewMetric('Stops', route.stopCount || 0)}
                ${renderPreviewMetric('Length', route.routeLength || 'Pending')}
                ${renderPreviewMetric('Destination', route.destination || 'Assigned route')}
                ${renderPreviewMetric('Required Rank', `Rank ${route.minRank || contractor.unlockRank || 1}`)}
            </div>
            <div class="preview-action-row single">
                <button class="preview-action" data-preview-contractor-daily-route="${escapeHTML(route.key || '')}" ${canSelect ? '' : 'disabled'}>
                    <i class="fas fa-route"></i>${actionText}
                </button>
            </div>
        </div>
        <div class="selected preview-brief-card">
            ${renderPreviewInfo('fa-calendar-day', 'Daily Rule', 'Dedicated route is optional and persists after selection.', contractor.dailyRouteChangeAvailableAt ? `Next change ${contractor.dailyRouteChangeAvailableAt}` : 'Can be changed weekly.')}
            ${renderPreviewInfo('fa-sack-dollar', 'Bonus', `${formatMoney(contractor.dailyBonus || 0)} daily payout bonus`, `${contractor.dailyRepBonus || 0} contractor rep bonus`)}
        </div>
    `;
}

function renderContractorVehiclePreview(contractor, vehicle) {
    if (!vehicle) return '';

    const activeVehicle = getActiveContractorVehicle(contractor);
    const sameOut = activeVehicle && getContractorVehicleKey(activeVehicle) === getContractorVehicleKey(vehicle);
    const anotherOut = activeVehicle && !sameOut;
    const hasJob = Boolean(dispatchData?.currentJob);
    const spawnDisabled = vehicle.out || anotherOut || hasJob;
    const sellDisabled = vehicle.out || hasJob;
    const spawnLabel = hasJob ? 'Route Active' : vehicle.out ? 'Unit Out' : anotherOut ? 'Unit Out' : 'Request';
    const image = vehicle.photo || '';

    return `
        <div class="route-box preview-status-card">
            <div class="preview-context-head">
                <div>
                    <small>SELECTED PRIVATE UNIT</small>
                    <h2>${escapeHTML(vehicle.label || 'Contractor Vehicle')}</h2>
                </div>
                <span class="preview-pill ${vehicle.out ? 'green' : ''}">${escapeHTML(vehicle.out ? 'Out' : 'Stored')}</span>
            </div>
            ${image ? `<img class="preview-vehicle-image" src="${escapeHTML(image)}" alt="${escapeHTML(vehicle.label || 'Contractor Vehicle')}">` : ''}
            <div class="preview-metric-grid two">
                ${renderPreviewMetric('Plate', vehicle.plate || 'NO PLATE')}
                ${renderPreviewMetric('Type', vehicle.typeLabel || contractorTypeLabel(vehicle.type))}
                ${renderPreviewMetric('Fuel', `${vehicle.fuel ?? 0}%`)}
                ${renderPreviewMetric('Condition', `${vehicle.condition ?? 0}%`)}
                ${renderPreviewMetric('Mileage', `${Number(vehicle.mileage || 0).toFixed(1)} mi`)}
                ${renderPreviewMetric('Resale Value', formatMoney(vehicle.resalePrice || 0))}
            </div>
            <div class="preview-action-row three">
                <button class="preview-action" data-preview-contractor-spawn-vehicle="${escapeHTML(getContractorVehicleKey(vehicle))}" ${spawnDisabled ? 'disabled' : ''}>
                    <i class="fas fa-truck"></i>${spawnLabel}
                </button>
                <button class="preview-action secondary" data-preview-contractor-store-vehicle ${sameOut ? '' : 'disabled'}>
                    <i class="fas fa-warehouse"></i>Store Unit
                </button>
                <button class="preview-action danger" data-preview-contractor-sell-vehicle="${escapeHTML(getContractorVehicleKey(vehicle))}" data-resale-price="${Number(vehicle.resalePrice || 0)}" data-original-price="${Number(vehicle.originalPrice || 0)}" data-mileage="${Number(vehicle.mileage || 0)}" ${sellDisabled ? 'disabled' : ''}>
                    <i class="fas fa-dollar-sign"></i>Sell Unit
                </button>
            </div>
        </div>
        <div class="selected preview-brief-card">
            ${renderPreviewInfo('fa-gas-pump', 'Start Requirements', `${contractor.minFuel || 0}% fuel minimum`, `${contractor.minCondition || 0}% condition minimum`)}
            ${renderPreviewInfo('fa-circle-info', 'Storage', sameOut ? 'This private unit is currently out.' : anotherOut ? 'Store the active private unit before spawning another.' : 'Stored units can be spawned for private freight.')}
            ${renderPreviewInfo('fa-chart-line', 'Resale Formula', '80% of original purchase price', `${formatMoney(vehicle.depreciationPerMile || 10)} deducted per completed route mile`)}
        </div>
    `;
}

function renderContractorContractPreview(contractor, contract) {
    if (!contract) return '';

    const hasJob = Boolean(dispatchData?.currentJob);
    const canStart = contract.canStart && !hasJob;
    const startLabel = hasJob ? 'Route Active' : contract.canStart ? contract.daily ? 'Accept Daily Route' : 'Accept Contract' : 'Spawn Matching Unit';

    return `
        <div class="route-box preview-status-card">
            <div class="preview-context-head">
                <div>
                    <small>${contract.daily ? 'DEDICATED DAILY ROUTE' : 'SELECTED PRIVATE CONTRACT'}</small>
                    <h2>${escapeHTML(contract.routeLabel || 'Private Freight Contract')}</h2>
                </div>
                <span class="preview-pill ${contract.canStart ? 'green' : ''}">${escapeHTML(contract.daily ? 'Daily' : contract.priorityShortLabel || contract.priorityLabel || 'Standard')}</span>
            </div>
            <p>${escapeHTML([contract.typeLabel || contractorTypeLabel(contract.type), contract.destination, contract.vehicleLabel || 'Spawn a matching private unit first'].filter(Boolean).join(' - '))}</p>
            ${renderContractorTrailerPreview(contract)}
            <div class="preview-metric-grid two">
                ${renderPreviewMetric('Payout', `${formatMoney(contract.payoutMin || 0)}-${formatMoney(contract.payoutMax || 0)}`)}
                ${renderPreviewMetric('XP / Rep', `${contract.xp || 0} XP / ${contract.rep || 0} REP`)}
                ${renderPreviewMetric('Stops', contract.stopCount || 0)}
                ${renderPreviewMetric('Length', contract.routeLength || 'Pending')}
            </div>
            <div class="preview-action-row single">
                <button class="preview-action" data-preview-contractor-start="${Number(contract.vehicleId || 0)}" data-priority="${escapeHTML(contract.priorityKey || 'standard')}" data-route-index="${Number(contract.routeIndex || 0)}" data-daily-route-key="${escapeHTML(contract.dailyRouteKey || '')}" ${canStart ? '' : 'disabled'}>
                    <i class="fas fa-file-signature"></i>${startLabel}
                </button>
            </div>
        </div>
        <div class="selected preview-brief-card">
            ${renderPreviewInfo('fa-route', 'Dedicated Route', contractor.dailyRouteLabel || 'Optional bonus route not assigned', contractor.dailyRouteCompleted ? 'Daily completion bonus already claimed.' : 'Accept the daily route card to claim bonus credit.')}
            ${renderPreviewInfo('fa-triangle-exclamation', 'Contractor Penalty', `Cancel fee ${formatMoney(contractor.cancelFee || 0)}`, 'Higher private payouts come with tighter accountability.')}
        </div>
    `;
}

function renderContractorMarketPreview(contractor, vehicle) {
    if (!vehicle) return '';

    const locked = !vehicle.unlocked;
    const owned = vehicle.owned;
    const disabled = locked || owned;
    const image = vehicle.photo || '';

    return `
        <div class="route-box preview-status-card">
            <div class="preview-context-head">
                <div>
                    <small>CONTRACTOR FLEET DEALER</small>
                    <h2>${escapeHTML(vehicle.label || 'Vehicle')}</h2>
                </div>
                <span class="preview-pill ${owned ? 'green' : ''}">${escapeHTML(owned ? 'Owned' : locked ? `Rank ${vehicle.minRank || 1}` : formatMoney(vehicle.price || 0))}</span>
            </div>
            ${image ? `<img class="preview-vehicle-image" src="${escapeHTML(image)}" alt="${escapeHTML(vehicle.label || 'Vehicle')}">` : ''}
            <div class="preview-metric-grid two">
                ${renderPreviewMetric('Type', vehicle.typeLabel || contractorTypeLabel(vehicle.type))}
                ${renderPreviewMetric('Required Rank', `Rank ${vehicle.minRank || 1}`)}
                ${renderPreviewMetric('Price', formatMoney(vehicle.price || 0))}
                ${renderPreviewMetric('Fleet Slots', `${(contractor.vehicles || []).length} / ${contractor.maxOwnedVehicles || 0}`)}
            </div>
            <div class="preview-action-row single">
                <button class="preview-action" data-preview-contractor-buy-type="${escapeHTML(vehicle.type || '')}" data-preview-contractor-buy-index="${Number(vehicle.index || 1)}" ${disabled ? 'disabled' : ''}>
                    <i class="fas fa-key"></i>${owned ? 'Owned' : locked ? 'Rank Locked' : 'Purchase Vehicle'}
                </button>
            </div>
        </div>
        <div class="selected preview-brief-card">
            ${renderPreviewInfo('fa-id-card', 'Private Authority', 'Purchased units enter your private fleet.', 'Fuel and condition are saved when stored.')}
            ${renderPreviewInfo('fa-warehouse', 'Storage Rule', 'Only one private vehicle can be out at a time.')}
        </div>
    `;
}

function clampPercent(value) {
    const number = Number(value);
    if (!Number.isFinite(number)) return 0;
    return Math.max(0, Math.min(100, Math.floor(number)));
}

function buildCurrentPreviewPanel() {
    const job = dispatchData?.currentJob;

    if (job) {
        const totalStops = Number(job.totalStops || 0);
        const currentStop = Number(job.currentStop || 0);
        const stopProgress = totalStops > 0 ? clampPercent((currentStop / totalStops) * 100) : 0;
        const requiredCargo = Number(job.requiredCargo || 0);
        const loadedCargo = Number(job.loadedCargo || 0);
        const deliveredCargo = requiredCargo > 0 ? Math.max(0, requiredCargo - loadedCargo) : 0;
        const cargoProgress = requiredCargo > 0 ? clampPercent((deliveredCargo / requiredCargo) * 100) : 0;
        const displayProgress = Math.max(stopProgress, cargoProgress);

        previewContext.innerHTML = `
            <div class="route-box preview-status-card">
                <div class="preview-context-head">
                    <div>
                        <small>ACTIVE ROUTE CONTROL</small>
                        <h2>${escapeHTML(job.label || 'Active Job')}</h2>
                    </div>
                    <span class="preview-pill green">ACTIVE</span>
                </div>
                <p>${escapeHTML(job.stage || 'Route in progress')}</p>
                <div class="company-progress-bar"><span style="width:${displayProgress}%"></span></div>
                <div class="preview-metric-grid">
                    ${renderPreviewMetric('Payout', formatMoney(job.payout))}
                    ${renderPreviewMetric('Cargo', `${job.loadedCargo || 0} / ${job.requiredCargo || 0}`)}
                    ${renderPreviewMetric('Stops', `${job.currentStop || 0} / ${job.totalStops || 0}`)}
                    ${renderPreviewMetric('Condition', job.cargoConditionLabel || 'Stable')}
                    ${renderPreviewMetric('Progress', `${displayProgress}%`, 'Estimated from cargo/stops')}
                    ${renderPreviewMetric('Contract', job.id || 'Active')}
                    ${renderPreviewMetric('Destination', job.destination || 'N/A', job.destinationAddress || '')}
                    ${renderPreviewMetric('Vehicle', job.vehicleLabel || 'N/A', job.plate || '')}
                    ${renderPreviewMetric('ETA', job.expectedCompletion || job.estimatedTime || 'N/A')}
                </div>
            </div>
            <div class="selected preview-brief-card">
                ${renderPreviewInfo('fa-tower-broadcast', 'Dispatch Status', 'Route telemetry active', 'Receiver and dock data are live.')}
                ${renderPreviewInfo('fa-circle-info', 'Next Step', job.stage || 'Follow the route checklist.')}
                ${renderPreviewInfo('fa-boxes-stacked', 'Cargo', job.cargo || 'Assigned freight', job.cargoConditionNote || job.cargoConditionLabel || 'Cargo status live.')}
            </div>
        `;
        return;
    }

    previewContext.innerHTML = `
        <div class="route-box preview-status-card">
            <div class="preview-context-head">
                <div>
                    <small>ACTIVE ROUTE CONTROL</small>
                    <h2>Dispatch Standby</h2>
                </div>
                <span class="preview-pill">IDLE</span>
            </div>
            <p>No active freight route is assigned.</p>
        </div>
        <div class="selected preview-brief-card">
            ${renderPreviewInfo('fa-file-contract', 'Contracts', 'Open Dispatch to select company freight.')}
            ${renderPreviewInfo('fa-clock-rotate-left', 'Route History', 'Completed route summaries are stored in the History tab.')}
        </div>
    `;
}

function buildHistoryPreviewPanel() {
    const history = normalizeRouteHistory(dispatchData?.routeHistory || dispatchData?.lastRouteSummary);
    const latest = history[0];

    if (!latest) {
        previewContext.innerHTML = `
            <div class="route-box preview-status-card">
                <div class="preview-context-head">
                    <div><small>ROUTE HISTORY</small><h2>No Completed Jobs</h2></div>
                    <span class="preview-pill">EMPTY</span>
                </div>
                <p>Completed route summaries will appear here after dispatch closes out a paid route.</p>
            </div>
        `;
        return;
    }

    const timeData = latest.time || {};
    const cargoSummary = routeSummaryContents(latest);
    previewContext.innerHTML = `
        <div class="route-box preview-status-card">
            <div class="preview-context-head">
                <div>
                    <small>LATEST COMPLETED ROUTE</small>
                    <h2>${escapeHTML(routeSummaryTitle(latest))}</h2>
                </div>
                <span class="preview-pill green">LOGGED</span>
            </div>
            <p>${escapeHTML(routeSummarySubtitle(latest))}</p>
            <div class="preview-metric-grid two">
                ${renderPreviewMetric('Final Payout', formatMoney(latest.payout || 0))}
                ${renderPreviewMetric('XP / Rep', `${latest.xp || 0} XP / ${latest.rep || 0} REP`)}
                ${renderPreviewMetric('Timing', timeData.label || 'Complete', formatSeconds(timeData.elapsedSeconds || 0))}
                ${renderPreviewMetric('Load', cargoSummary, latest.cargoCondition?.label || '')}
                ${renderPreviewMetric('Vehicle', latest.vehicleLabel || 'Company Vehicle')}
                ${renderPreviewMetric('History Saved', `${history.length} recent`)}
            </div>
        </div>
        <div class="selected preview-brief-card">
            ${renderPreviewInfo('fa-circle-info', 'Expandable Tiles', 'Open any route card to review payout, XP, timing, cargo, and event data.')}
            ${renderPreviewInfo('fa-tower-broadcast', 'Receiver Copy', 'The same summaries are available from the receiver Dispatch Log.')}
        </div>
    `;
}

function buildGaragePreviewPanel() {
    const vehicle = getSelectedGarageVehicle();

    if (!vehicle) {
        previewContext.innerHTML = `
            <div class="route-box preview-status-card">
                <div class="preview-context-head">
                    <div><small>COMPANY GARAGE</small><h2>No Fleet Data</h2></div>
                    <span class="preview-pill">OFFLINE</span>
                </div>
                <p>No company vehicles are currently configured.</p>
            </div>
        `;
        return;
    }

    const minRank = Number(vehicle.minRank || 1);
    const locked = playerRank() < minRank;
    const status = vehicle.stored ? 'Stored' : 'Out';
    const image = vehicle.photo || '';

    previewContext.innerHTML = `
        <div class="route-box preview-status-card">
            <div class="preview-context-head">
                <div>
                    <small>SELECTED UNIT</small>
                    <h2>${escapeHTML(garageDisplayLabel(vehicle.label, vehicle.type))}</h2>
                </div>
                <span class="preview-pill ${vehicle.stored ? 'green' : ''}">${escapeHTML(status)}</span>
            </div>
            ${image ? `<img class="preview-vehicle-image" src="${escapeHTML(image)}" alt="${escapeHTML(vehicle.label || 'Vehicle')}">` : ''}
            <div class="preview-metric-grid two">
                ${renderPreviewMetric('Plate', vehicle.plate || 'NO PLATE')}
                ${renderPreviewMetric('Required Rank', `Rank ${minRank}`)}
                ${renderPreviewMetric('Type', titleFromType(vehicle.type))}
                ${renderPreviewMetric('Access', locked ? 'Locked' : 'Cleared')}
            </div>
            <div class="preview-action-row">
                <button class="preview-action" data-preview-spawn-garage data-type="${escapeHTML(vehicle.type || '')}" data-index="${Number(vehicle.index || 1)}" ${locked ? 'disabled' : ''}>
                    <i class="fas fa-warehouse"></i>${locked ? 'Rank Locked' : 'Request'}
                </button>
            </div>
        </div>
        <div class="selected preview-brief-card">
            ${renderPreviewInfo('fa-circle-info', 'Garage Note', vehicle.stored ? 'Spawned vehicles can be returned to save upgrades.' : 'Return the vehicle at the garage to store changes.')}
            ${renderPreviewInfo('fa-key', 'Vehicle Source', 'Company fleet', 'Use contracts tab to assign company freight.')}
        </div>
    `;
}

function getCompanyRankProgress(data = dispatchData || {}) {
    const player = data.player || {};
    const xp = Number(player.xp || 0);
    const nextXp = Number(player.nextRankXp || 0);
    const ranks = data.ranks || [];
    const currentRank = ranks.find(rank => Number(rank.rank || 0) === Number(player.rank || 1));
    const currentRankXp = Number(currentRank?.xp || 0);
    const xpRange = Math.max(1, nextXp - currentRankXp);
    const progress = nextXp > currentRankXp ? clampPercent(((xp - currentRankXp) / xpRange) * 100) : 100;

    return {
        xp,
        nextXp,
        xpText: nextXp > xp ? `${formatInteger(xp)} / ${formatInteger(nextXp)}` : formatInteger(xp),
        remaining: Math.max(0, nextXp - xp),
        progress
    };
}

function renderCompanyStatRow(label, value, subtext = '') {
    return `
        <div class="company-stat-row">
            <span>${escapeHTML(label)}</span>
            <div>
                <strong>${escapeHTML(displayText(value))}</strong>
                ${subtext ? `<em>${escapeHTML(subtext)}</em>` : ''}
            </div>
        </div>
    `;
}

function renderCompanyInsight(icon, label, value, subtext = '') {
    return `
        <div class="company-insight">
            <i class="fas ${escapeHTML(icon)}"></i>
            <div>
                <small>${escapeHTML(label)}</small>
                <strong>${escapeHTML(displayText(value))}</strong>
                ${subtext ? `<small>${escapeHTML(subtext)}</small>` : ''}
            </div>
        </div>
    `;
}

function renderCompanyLeaderboard(title, rows, valueGetter, subtextGetter) {
    const list = Array.isArray(rows) && rows.length
        ? rows.map((row, index) => {
            const rank = Number(row.rank || index + 1);
            const label = row.label || row.citizenid || 'Driver';
            const value = valueGetter(row);
            const subtext = subtextGetter ? subtextGetter(row) : '';
            return `
                <div class="company-leader-row">
                    <span class="company-leader-rank">${rank}</span>
                    <div>
                        <strong>${escapeHTML(label)}</strong>
                        ${subtext ? `<small>${escapeHTML(subtext)}</small>` : ''}
                    </div>
                    <span class="company-leader-value">${escapeHTML(value)}</span>
                </div>
            `;
        }).join('')
        : '<div class="empty-card">No leaderboard records yet.</div>';

    return `
        <div class="company-leader-panel">
            <small>Leaderboard</small>
            <h3>${escapeHTML(title)}</h3>
            <div class="company-leader-list">${list}</div>
        </div>
    `;
}

function renderCompanyDashboard(data = dispatchData || {}) {
    if (!companyDashboard) return;

    const player = data.player || {};
    const contractor = data.contractor || {};
    const companyStats = data.companyStats || {};
    const insights = getCompanyInsights(data);
    const rankProgress = getCompanyRankProgress(data);
    const contractorStatus = !contractor.enabled ? 'Disabled' : !contractor.unlocked ? `Unlocks Rank ${contractor.unlockRank || 1}` : contractor.licensed ? 'Licensed' : 'License Available';

    companyDashboard.innerHTML = `
        <div class="company-record-panel">
            <div class="company-record-header">
                <div>
                    <small>Driver Record</small>
                    <h2>${escapeHTML(player.name || 'Driver Profile')}</h2>
                    <small>${escapeHTML(player.rankLabel || 'Company Driver')}</small>
                </div>
                <span class="company-record-badge">RANK ${Number(player.rank || 1)}</span>
            </div>
            <div class="company-progress-head">
                <span>${escapeHTML(rankProgress.remaining > 0 ? `${formatInteger(rankProgress.remaining)} XP to next rank` : 'Current rank complete')}</span>
                <strong>${rankProgress.progress}%</strong>
            </div>
            <div class="company-progress-bar"><span style="width:${rankProgress.progress}%"></span></div>
            <div class="company-stat-table">
                ${renderCompanyStatRow('Rank', `Rank ${player.rank || 1}`, player.rankLabel || 'New Hire')}
                ${renderCompanyStatRow('XP', rankProgress.xpText, rankProgress.nextXp > rankProgress.xp ? 'Toward next rank' : 'Current rank complete')}
                ${renderCompanyStatRow('Company Rep', player.reputation || 0, 'Company standing')}
                ${renderCompanyStatRow('Contractor Rep', contractor.rep || 0, contractorStatus)}
                ${renderCompanyStatRow('Jobs Completed', player.jobsCompleted || 0, 'Total routes')}
                ${renderCompanyStatRow('Career Earnings', formatMoney(player.wallet), 'Completed payouts')}
                ${renderCompanyStatRow('Routes Cancelled', player.totalCancelled || 0, 'Cancellation record')}
                ${renderCompanyStatRow('Assigned Job', player.jobText || 'Unassigned')}
            </div>
        </div>

        <div class="company-section-grid">
            <div class="company-performance-panel">
                <small>Current Streaks</small>
                <h3>Driver Performance</h3>
                <div class="company-insight-grid">
                    ${renderCompanyInsight('fa-shield-halved', 'Damage Free Delivery Streak', `${insights.damageFreeStreak} routes`, 'Recent clean deliveries')}
                    ${renderCompanyInsight('fa-stopwatch', 'On Time Streak', `${insights.onTimeStreak} routes`, 'Recent on-time deliveries')}
                    ${renderCompanyInsight('fa-route', 'Completed Route Streak', `${insights.completedRouteStreak} routes`, 'Consecutive routes')}
                </div>
            </div>
            <div class="company-performance-panel">
                <small>Usage Trends</small>
                <h3>Freight Habits</h3>
                <div class="company-insight-grid">
                    ${renderCompanyInsight('fa-truck-fast', 'Most Used Vehicle', insights.mostUsedVehicle.value, insights.mostUsedVehicle.count ? `${insights.mostUsedVehicle.count} logged routes` : 'No completed routes')}
                    ${renderCompanyInsight('fa-warehouse', 'Most Used Depot', insights.mostUsedDepot.value, insights.mostUsedDepot.count ? `${insights.mostUsedDepot.count} logged routes` : 'No completed routes')}
                    ${renderCompanyInsight('fa-map-location-dot', 'Most Run Route', insights.mostCommonRoute.value, insights.mostCommonRoute.count ? `${insights.mostCommonRoute.count} logged routes` : 'No completed routes')}
                </div>
            </div>
        </div>

        <div class="company-section-grid">
            ${renderCompanyLeaderboard('Top Drivers', companyStats.topDrivers || [], row => `${formatInteger(row.xp || 0)} XP`, row => `Rank ${formatInteger(row.driverRank || 1)}${row.driverRankLabel ? ` - ${row.driverRankLabel}` : ''}`)}
            ${renderCompanyLeaderboard('Most Deliveries', companyStats.mostDeliveries || [], row => `${formatInteger(row.jobsCompleted || 0)} jobs`, row => `${formatInteger(row.reputation || 0)} company rep`)}
            ${renderCompanyLeaderboard('Contractor Rep', companyStats.contractorRep || [], row => `${formatInteger(row.contractorRep || 0)} REP`, row => row.licensed ? 'Licensed contractor' : 'Pending license')}
        </div>
    `;
}

function buildCompanyPreviewPanel() {
    const contractor = dispatchData?.contractor || {};
    const insights = getCompanyInsights(dispatchData || {});
    const companyStats = dispatchData?.companyStats || {};
    const topDriver = Array.isArray(companyStats.topDrivers) ? companyStats.topDrivers[0] : null;
    const deliveryLeader = Array.isArray(companyStats.mostDeliveries) ? companyStats.mostDeliveries[0] : null;
    const contractorLeader = Array.isArray(companyStats.contractorRep) ? companyStats.contractorRep[0] : null;

    previewContext.innerHTML = `
        <div class="selected preview-brief-card">
            <div class="preview-card-title"><i class="fas fa-chart-line"></i><span>Company Snapshot</span></div>
            ${renderPreviewInfo('fa-id-card', 'Contractor Rep', contractor.rep || 0, contractor.licensed ? 'Private authority licensed' : 'Private authority pending')}
            ${renderPreviewInfo('fa-shield-halved', 'Damage-Free Streak', `${insights.damageFreeStreak} routes`, 'Recent clean deliveries')}
            ${renderPreviewInfo('fa-stopwatch', 'On-Time Streak', `${insights.onTimeStreak} routes`, 'Recent on-time deliveries')}
            ${renderPreviewInfo('fa-warehouse', 'Most Used Depot', insights.mostUsedDepot.value, insights.mostUsedDepot.count ? `${insights.mostUsedDepot.count} logged routes` : '')}
            ${renderPreviewInfo('fa-truck-fast', 'Most Used Vehicle', insights.mostUsedVehicle.value, insights.mostUsedVehicle.count ? `${insights.mostUsedVehicle.count} logged routes` : '')}
        </div>
        <div class="selected preview-brief-card">
            <div class="preview-card-title"><i class="fas fa-trophy"></i><span>Leaderboard</span></div>
            ${renderPreviewInfo('fa-trophy', 'Top Driver', topDriver ? `${topDriver.label} - ${formatInteger(topDriver.xp || 0)} XP` : 'No leaderboard records yet.')}
            ${renderPreviewInfo('fa-boxes-stacked', 'Most Deliveries', deliveryLeader ? `${deliveryLeader.label} - ${deliveryLeader.jobsCompleted || 0} jobs` : 'No delivery records yet.')}
            ${renderPreviewInfo('fa-id-badge', 'Contractor Lead', contractorLeader ? `${contractorLeader.label} - ${contractorLeader.contractorRep || 0} rep` : 'No contractor records yet.')}
        </div>
    `;
}

function buildContractorPreviewPanel() {
    const contractor = dispatchData?.contractor || {};

    if (!contractor.enabled) {
        previewContext.innerHTML = `
            <div class="route-box preview-status-card">
                <div class="preview-context-head">
                    <div><small>PRIVATE CONTRACTOR</small><h2>Contractor Work Disabled</h2></div>
                    <span class="preview-pill">OFFLINE</span>
                </div>
                <p>Private contractor authority is disabled in the config.</p>
            </div>
        `;
        return;
    }

    if (!contractor.unlocked) {
        previewContext.innerHTML = `
            <div class="route-box preview-status-card">
                <div class="preview-context-head">
                    <div><small>PRIVATE CONTRACTOR</small><h2>Authority Locked</h2></div>
                    <span class="preview-pill">RANK ${Number(contractor.unlockRank || 1)}</span>
                </div>
                <p>Reach the required trucking rank to apply for private contractor work.</p>
            </div>
        `;
        return;
    }

    if (!contractor.licensed) {
        previewContext.innerHTML = `
            <div class="route-box preview-status-card">
                <div class="preview-context-head">
                    <div><small>PRIVATE CONTRACTOR</small><h2>License Required</h2></div>
                    <span class="preview-pill">${escapeHTML(formatMoney(contractor.licenseCost || 0))}</span>
                </div>
                <p>Purchase contractor authority to buy approved vehicles and accept private freight.</p>
                <div class="preview-metric-grid two">
                    ${renderPreviewMetric('Min Fuel', `${contractor.minFuel || 0}%`)}
                    ${renderPreviewMetric('Min Condition', `${contractor.minCondition || 0}%`)}
                    ${renderPreviewMetric('Cancel Fee', formatMoney(contractor.cancelFee || 0))}
                    ${renderPreviewMetric('Daily Bonus', formatMoney(contractor.dailyBonus || 0))}
                </div>
                <div class="preview-action-row">
                    <button class="preview-action" data-contractor-license><i class="fas fa-id-card"></i>Purchase License</button>
                </div>
            </div>
        `;
        return;
    }

    const panel = syncContractorSelection(contractor);
    const activeVehicle = getActiveContractorVehicle(contractor);
    const selectedDailyRoute = getSelectedContractorDailyRoute(contractor);
    const selectedVehicle = getSelectedContractorVehicle(contractor);
    const selectedContract = getSelectedContractorContract(contractor);
    const selectedMarketVehicle = getSelectedContractorMarketVehicle(contractor);
    const ownedCount = (contractor.vehicles || []).length;
    const marketCount = (contractor.market || []).length;

    if (panel === 'daily' && selectedDailyRoute) {
        previewContext.innerHTML = renderContractorDailyRoutePreview(contractor, selectedDailyRoute);
        return;
    }

    if (panel === 'contract' && selectedContract) {
        previewContext.innerHTML = renderContractorContractPreview(contractor, selectedContract);
        return;
    }

    if (panel === 'market' && selectedMarketVehicle) {
        previewContext.innerHTML = renderContractorMarketPreview(contractor, selectedMarketVehicle);
        return;
    }

    if (panel === 'vehicle' && selectedVehicle) {
        previewContext.innerHTML = renderContractorVehiclePreview(contractor, selectedVehicle);
        return;
    }

    previewContext.innerHTML = `
        <div class="route-box preview-status-card">
            <div class="preview-context-head">
                <div>
                    <small>PRIVATE CONTRACTOR</small>
                    <h2>${escapeHTML(contractor.dailyRouteLabel || 'No Dedicated Route Selected')}</h2>
                </div>
                <span class="preview-pill green">REP ${Number(contractor.rep || 0)}</span>
            </div>
            <p>${escapeHTML(contractor.dailyRouteCompleted ? 'Daily route completed.' : 'Daily assignment ready for private freight.')}</p>
            <div class="preview-metric-grid two">
                ${renderPreviewMetric('Private Fleet', `${ownedCount} / ${contractor.maxOwnedVehicles || ownedCount}`)}
                ${renderPreviewMetric('Dealer Stock', `${marketCount} listed`)}
                ${renderPreviewMetric('Active Unit', activeVehicle ? (activeVehicle.plate || 'Out') : 'None')}
                ${renderPreviewMetric('Daily Bonus', formatMoney(contractor.dailyBonus || 0))}
            </div>
        </div>
    `;
}

function renderPreviewContextPanel() {
    if (!previewContracts || !previewContext) return;

    if (activeDispatchTab === 'dispatch') {
        previewContracts.classList.remove('hidden');
        previewContext.classList.add('hidden');
        return;
    }

    previewContracts.classList.add('hidden');
    previewContext.classList.remove('hidden');

    if (activeDispatchTab === 'home') buildHomePreviewPanel();
    else if (activeDispatchTab === 'current') buildCurrentPreviewPanel();
    else if (activeDispatchTab === 'history') buildHistoryPreviewPanel();
    else if (activeDispatchTab === 'garage') buildGaragePreviewPanel();
    else if (activeDispatchTab === 'contractor') buildContractorPreviewPanel();
    else if (activeDispatchTab === 'company') buildCompanyPreviewPanel();
    else buildCurrentPreviewPanel();
}

function setTab(tab) {
    const page = document.getElementById(`page-${tab}`);
    if (!page) tab = 'home';
    activeDispatchTab = tab;
    document.querySelectorAll('.nav').forEach(el => el.classList.toggle('active', el.dataset.tab === tab));
    document.querySelectorAll('.tab-page').forEach(el => el.classList.add('hidden'));
    document.getElementById(`page-${tab}`).classList.remove('hidden');
    renderPreviewContextPanel();
    post('dispatchTabChanged', { tab });
}

document.querySelectorAll('.nav').forEach(nav => nav.addEventListener('click', () => { playUISound('click'); setTab(nav.dataset.tab); }));

const dispatchHome = document.getElementById('dispatchHome');
if (dispatchHome) {
    dispatchHome.addEventListener('click', event => {
        const zoomButton = event.target.closest('[data-dispatch-map-zoom]');
        if (zoomButton) {
            if (zoomButton.disabled) return;
            const zoomConfig = getDispatchMapZoomConfig(dispatchData || {});
            const action = zoomButton.dataset.dispatchMapZoom;
            const currentZoom = clampDispatchMapZoom(dispatchMapZoom, zoomConfig);

            playUISound('click');

            if (action === 'in') {
                dispatchMapZoom = clampDispatchMapZoom(currentZoom + zoomConfig.step, zoomConfig);
            } else if (action === 'out') {
                dispatchMapZoom = clampDispatchMapZoom(currentZoom - zoomConfig.step, zoomConfig);
            } else {
                dispatchMapZoom = clampDispatchMapZoom(zoomConfig.default, zoomConfig);
                dispatchMapPan = { x: 0, y: 0 };
            }

            dispatchMapPan = clampDispatchMapPan(dispatchMapPan, dispatchMapZoom);
            renderDispatchHome(dispatchData || {});
            return;
        }

        const marker = event.target.closest('[data-dispatch-map-marker]');
        if (marker) {
            playUISound('click');
            selectedDispatchHomePointId = marker.dataset.dispatchMapMarker || null;
            renderDispatchHome(dispatchData || {});
            renderPreviewContextPanel();
            return;
        }

    });

    dispatchHome.addEventListener('pointerdown', event => {
        if (!dispatchHomeMap || event.button !== 0) return;
        if (!event.target.closest('.dispatch-map-shell')) return;
        if (event.target.closest('[data-dispatch-map-marker], [data-dispatch-map-zoom], .dispatch-home-legend')) return;

        const zoomConfig = getDispatchMapZoomConfig(dispatchData || {});
        const zoom = clampDispatchMapZoom(dispatchMapZoom, zoomConfig);
        if (zoom <= zoomConfig.min + 0.01) return;

        dispatchMapDrag = {
            startX: event.clientX,
            startY: event.clientY,
            panX: dispatchMapPan.x,
            panY: dispatchMapPan.y
        };
        try {
            dispatchHomeMap.setPointerCapture?.(event.pointerId);
        } catch {}
        applyDispatchMapTransform();
        event.preventDefault();
    });

    dispatchHome.addEventListener('pointermove', event => {
        if (!dispatchMapDrag) return;

        dispatchMapPan = clampDispatchMapPan({
            x: dispatchMapDrag.panX + event.clientX - dispatchMapDrag.startX,
            y: dispatchMapDrag.panY + event.clientY - dispatchMapDrag.startY
        }, dispatchMapZoom);
        applyDispatchMapTransform();
        event.preventDefault();
    });

    const stopDispatchMapDrag = event => {
        if (!dispatchMapDrag) return;
        dispatchMapDrag = null;
        try {
            dispatchHomeMap?.releasePointerCapture?.(event.pointerId);
        } catch {}
        applyDispatchMapTransform();
    };

    dispatchHome.addEventListener('pointerup', stopDispatchMapDrag);
    dispatchHome.addEventListener('pointercancel', stopDispatchMapDrag);
    window.addEventListener('pointerup', stopDispatchMapDrag);
    window.addEventListener('pointercancel', stopDispatchMapDrag);
}

if (garageList) {
    garageList.addEventListener('click', event => {
        const card = event.target.closest('.garage-card');
        if (!card || !garageList.contains(card)) return;

        playUISound('click');
        selectedGarageKey = card.dataset.garageKey || null;
        renderGarage(dispatchData || {});
        renderPreviewContextPanel();
    });
}

function renderPlayer(data) {
    const p = data.player || {};
    document.getElementById('rankText').innerText = `RANK ${p.rank || 1}`;
    document.getElementById('rankLabel').innerText = p.rankLabel || 'New Hire';
    document.getElementById('repText').innerText = p.reputation || '0';
    const contractorRepText = document.getElementById('contractorRepText');
    if (contractorRepText) contractorRepText.innerText = data.contractor?.rep || 0;
    document.getElementById('walletText').innerText = formatMoney(p.wallet);
    document.getElementById('playerName').innerText = p.name || 'Driver';
    document.getElementById('citizenId').innerText = `CID: ${p.citizenid || 'N/A'}`;
    const jobText = p.jobText || (p.job ? `${p.job.label || p.job.name || 'Unemployed'} - ${p.job.gradeName || p.job.gradeLevel || 'None'}` : 'Unemployed - None');
    document.getElementById('playerJob').innerText = jobText;
    document.getElementById('radioFrequency').innerText = formatMiniFrequency(data.radioFrequency || data.config?.radioFrequency || '68.9');
    renderCompanyDashboard(data);
}


function renderRouteHistory(history) {
    if (!routeHistoryList) return;

    const entries = normalizeRouteHistory(history);
    if (!entries.length) {
        routeHistoryList.innerHTML = '<div class="empty-card">No completed route summaries logged yet.</div>';
        return;
    }

    routeHistoryList.innerHTML = entries.map((summary, index) => {
        return `
            <details class="route-history-card" ${index === 0 ? 'open' : ''}>
                <summary>
                    <div>
                        <small>${escapeHTML(routeSummarySubtitle(summary))}</small>
                        <strong>${escapeHTML(routeSummaryTitle(summary))}</strong>
                    </div>
                    <span>${escapeHTML(formatMoney(summary.payout || 0))}</span>
                </summary>
                ${renderRouteSummaryPrintout(summary)}
            </details>
        `;
    }).join('');
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
    const notice = document.getElementById('currentJobNotice');
    if (notice) notice.innerText = job.notice || 'Follow current dispatch instructions.';
    document.getElementById('currentJobPayout').innerText = formatMoney(job.payout);
    document.getElementById('currentJobCargo').innerText = `${job.loadedCargo || 0} / ${job.requiredCargo || 0}`;
    document.getElementById('currentJobStops').innerText = `${job.currentStop || 0} / ${job.totalStops || 0}`;
    const currentJobCondition = document.getElementById('currentJobCondition');
    if (currentJobCondition) currentJobCondition.innerText = job.cargoConditionLabel || 'Stable';
    setText('currentJobDestination', job.destination || 'N/A');
    setText('currentJobEta', job.expectedCompletion || job.estimatedTime || 'N/A');
    setText('currentJobVehicle', job.vehicleLabel || 'N/A');
    setText('currentJobPlate', job.plate || 'N/A');
    setText('currentJobLength', job.routeLength || 'N/A');
}

function renderGarage(data) {
    if (!garageList) return;

    garageList.innerHTML = '';
    const garage = data.garage || [];

    if (garage.length && !garage.some(vehicle => getGarageVehicleKey(vehicle) === selectedGarageKey)) {
        selectedGarageKey = getGarageVehicleKey(garage[0]);
    }

    garage.forEach(vehicle => {
        const card = document.createElement('div');
        const vehicleKey = getGarageVehicleKey(vehicle);
        card.className = `garage-card ${vehicleKey === selectedGarageKey ? 'selected' : ''}`;
        card.dataset.garageKey = vehicleKey;
        const status = vehicle.stored ? 'Stored' : 'Out';
        const minRank = Number(vehicle.minRank || 1);
        const locked = playerRank() < minRank;
        const image = vehicle.photo || '';

        card.innerHTML = `
            <img src="${image}" alt="${vehicle.label || 'Vehicle'}">
            <strong>${garageDisplayLabel(vehicle.label, vehicle.type)}</strong>
            <small>${titleFromType(vehicle.type)} • ${vehicle.plate || 'NO PLATE'} • ${status}</small>
            <small class="rank-tag ${locked ? 'locked' : ''}">${locked ? `Requires Rank ${minRank}` : `Rank ${minRank}+`}</small>
        `;

        garageList.appendChild(card);
    });
}

function contractorTypeLabel(type) {
    if (type === 'trailer') return 'Tractor';
    return titleFromType(type);
}

function renderContractor(data) {
    if (!contractorContent) return;

    const contractor = data.contractor || {};
    contractorContent.innerHTML = '';

    if (!contractor.enabled) {
        contractorContent.innerHTML = '<div class="empty-card">Private contractor work is disabled.</div>';
        return;
    }

    if (!contractor.unlocked) {
        contractorContent.innerHTML = `
            <div class="contractor-hero">
                <small>PRIVATE AUTHORITY LOCKED</small>
                <h2>Rank ${contractor.unlockRank || 1} Required</h2>
                <p>Reach the required trucking rank to apply for private contractor authority.</p>
            </div>
        `;
        return;
    }

    if (!contractor.licensed) {
        contractorContent.innerHTML = `
            <div class="contractor-hero">
                <small>LOS SANTOS FREIGHT CO</small>
                <h2>Private Contractor Authority</h2>
                <p>Purchase a contractor license to buy approved vehicles, select a daily route assignment, and take higher-risk private contracts.</p>
                <div class="contractor-metrics">
                    <div><small>LICENSE</small><strong>${formatMoney(contractor.licenseCost || 0)}</strong></div>
                    <div><small>MIN FUEL</small><strong>${contractor.minFuel || 0}%</strong></div>
                    <div><small>MIN CONDITION</small><strong>${contractor.minCondition || 0}%</strong></div>
                    <div><small>CANCEL FEE</small><strong>${formatMoney(contractor.cancelFee || 0)}</strong></div>
                </div>
                <button class="contractor-primary" data-contractor-license>Purchase License</button>
            </div>
        `;
        return;
    }

    const dailyRoutes = contractor.dailyRoutes || [];
    const vehicles = contractor.vehicles || [];
    const board = contractor.board || [];
    const market = contractor.market || [];
    const activeOut = vehicles.find(vehicle => vehicle.out);
    syncContractorSelection(contractor);

    const dailyTypes = [];
    dailyRoutes.forEach(route => {
        const type = getContractorDailyRouteType(route);
        if (!dailyTypes.some(entry => entry.type === type)) {
            dailyTypes.push({ type, label: route.typeLabel || contractorTypeLabel(type) });
        }
    });

    const assignedDailyRoute = dailyRoutes.find(route => route.key === contractor.dailyRouteKey);
    if (!selectedContractorDailyType && assignedDailyRoute) selectedContractorDailyType = getContractorDailyRouteType(assignedDailyRoute);
    if (!selectedContractorDailyType && activeOut) selectedContractorDailyType = activeOut.type;
    if (!dailyTypes.some(entry => entry.type === selectedContractorDailyType)) {
        selectedContractorDailyType = dailyTypes[0]?.type || null;
    }

    const filteredDailyRoutes = selectedContractorDailyType
        ? dailyRoutes.filter(route => getContractorDailyRouteType(route) === selectedContractorDailyType)
        : dailyRoutes;

    if (filteredDailyRoutes.length && !filteredDailyRoutes.some(route => route.key === selectedContractorDailyRouteKey)) {
        const assignedInType = filteredDailyRoutes.find(route => route.key === contractor.dailyRouteKey);
        selectedContractorDailyRouteKey = getContractorDailyRouteKey(assignedInType || filteredDailyRoutes[0]);
    }

    const dailyTypeHtml = dailyTypes.map(entry => `
        <button type="button" class="${entry.type === selectedContractorDailyType ? 'is-selected' : ''}" data-contractor-daily-type="${escapeHTML(entry.type)}">
            ${escapeHTML(entry.label)}
        </button>
    `).join('');

    const dailyHtml = filteredDailyRoutes.map(route => {
        const assigned = route.key === contractor.dailyRouteKey;
        const cardSelected = selectedContractorPanel === 'daily' && selectedContractorDailyRouteKey === route.key;
        const completed = assigned && contractor.dailyRouteCompleted;
        const currentJob = dispatchData?.currentJob;
        const routeActive = assigned && currentJob?.contractor && (!currentJob.contractorDailyRouteKey || currentJob.contractorDailyRouteKey === route.key);
        const lockedByCooldown = !assigned && contractor.dailyRouteKey && contractor.dailyRouteCanChange === false;
        return `
            <div class="contractor-option compact ${cardSelected ? 'is-selected' : ''} ${routeActive ? 'is-active-route' : ''} ${route.unlocked ? '' : 'disabled'}" data-contractor-select-daily-route="${escapeHTML(route.key || '')}">
                <span><strong>${route.label || 'Route Board'}</strong><small>${[route.routeLength, route.destination].filter(Boolean).join(' - ') || route.description || ''}</small></span>
                <em>${completed ? 'DONE' : routeActive ? 'ACTIVE' : assigned ? 'ASSIGNED' : lockedByCooldown ? 'WEEKLY LOCK' : route.unlocked ? 'VIEW' : `RANK ${route.minRank || contractor.unlockRank}`}</em>
            </div>
        `;
    }).join('') || '<div class="empty-card">No dedicated routes are configured for this delivery type.</div>';

    const dailySelectorHtml = `
        <div class="contractor-daily-compact">
            <div class="contractor-daily-head">
                <div>
                    <small>DEDICATED ROUTE</small>
                    <strong>${escapeHTML(contractor.dailyRouteLabel || 'Optional Bonus Route')}</strong>
                </div>
                <em>${escapeHTML(contractor.dailyRouteKey ? contractor.dailyRouteCompleted ? 'Completed Today' : 'Assigned' : 'Not Assigned')}</em>
            </div>
            <div class="contractor-daily-types">${dailyTypeHtml}</div>
            <div class="contractor-daily-list">${dailyHtml}</div>
        </div>
    `;

    const fleetHtml = vehicles.length ? vehicles.map(vehicle => {
        const vehicleKey = getContractorVehicleKey(vehicle);
        const selected = selectedContractorPanel === 'vehicle' && selectedContractorVehicleId === vehicleKey;
        const image = vehicle.photo || '';
        const imageHtml = image
            ? `<img src="${escapeHTML(image)}" alt="${escapeHTML(vehicle.label || 'Contractor Vehicle')}">`
            : '<div class="contractor-vehicle-photo-placeholder"><i class="fas fa-truck"></i></div>';
        return `
        <div class="contractor-vehicle-card ${selected ? 'is-selected' : ''}" data-contractor-select-vehicle="${vehicleKey}">
            ${imageHtml}
            <div>
                <small>${vehicle.typeLabel || contractorTypeLabel(vehicle.type)} - ${vehicle.plate || 'NO PLATE'}</small>
                <strong>${vehicle.label || 'Contractor Vehicle'}</strong>
                <span>Fuel ${vehicle.fuel ?? 0}% - Condition ${vehicle.condition ?? 0}% - ${vehicle.out ? 'Out' : 'Stored'}</span>
            </div>
        </div>
    `;
    }).join('') : '<div class="empty-card">No private vehicles owned yet.</div>';

    const emptyBoardText = activeOut
        ? `No ${activeOut.typeLabel || contractorTypeLabel(activeOut.type)} contracts are available right now.`
        : 'Spawn a private vehicle to show available contracts for that vehicle type.';

    const boardHtml = board.length ? board.map(contract => {
        const contractKey = getContractorContractKey(contract);
        const selected = selectedContractorPanel === 'contract' && selectedContractorContractKey === contractKey;
        return `
        <div class="contractor-contract-card ${contract.canStart ? '' : 'disabled'} ${selected ? 'is-selected' : ''}" data-contractor-select-contract="${escapeHTML(contractKey)}">
            <div>
                <small>${contract.typeLabel || contractorTypeLabel(contract.type)} - ${contract.daily ? 'Daily Bonus' : contract.priorityShortLabel || contract.priorityLabel || 'Standard'}${contract.stopCount ? ` - ${contract.stopCount} stop${Number(contract.stopCount) === 1 ? '' : 's'}` : ''}</small>
                <strong>${contract.routeLabel || 'Private Freight Contract'}</strong>
                <span>${[contract.routeLength || 'Route length pending', contract.destination, contract.vehicleLabel || 'Spawn matching vehicle first'].filter(Boolean).join(' - ')}</span>
            </div>
            <div class="contractor-pay">
                <small>PAYOUT</small>
                <strong>${formatMoney(contract.payoutMin || 0)}-${formatMoney(contract.payoutMax || 0)}</strong>
                <span>${contract.xp || 0} XP / ${contract.rep || 0} REP</span>
            </div>
        </div>
    `;
    }).join('') : `<div class="empty-card">${emptyBoardText}</div>`;

    const marketHtml = market.length ? market.map(vehicle => {
        const owned = vehicle.owned;
        const marketKey = getContractorMarketKey(vehicle);
        const selected = selectedContractorPanel === 'market' && selectedContractorMarketKey === marketKey;
        return `
            <div class="contractor-market-card ${selected ? 'is-selected' : ''}" data-contractor-select-market="${escapeHTML(marketKey)}">
                <img src="${vehicle.photo || ''}" alt="${vehicle.label || 'Vehicle'}">
                <div>
                    <small>${vehicle.typeLabel || contractorTypeLabel(vehicle.type)} - Rank ${vehicle.minRank || 1}</small>
                    <strong>${vehicle.label || 'Vehicle'}</strong>
                    <span>${owned ? 'Owned' : formatMoney(vehicle.price || 0)}</span>
                </div>
            </div>
        `;
    }).join('') : '<div class="empty-card">No approved contractor vehicles are configured.</div>';

    const ownedCount = vehicles.length;
    const marketSummaryHtml = `
        <button class="contractor-market-summary" data-contractor-market-toggle>
            <span>
                <small>CONTRACTOR FLEET DEALER</small>
                <strong>${market.length} approved units available</strong>
                <em>${ownedCount} owned / ${contractor.maxOwnedVehicles || ownedCount} fleet slots</em>
            </span>
            <i class="fas fa-chevron-right"></i>
        </button>
    `;

    if (contractorMarketVisible) {
        contractorContent.innerHTML = `
            <div class="contractor-dealer-page">
                <button type="button" class="contractor-dealer-back" data-contractor-market-toggle>
                    <i class="fas fa-chevron-left"></i>
                    <span>Back to Contractor</span>
                </button>
                <div class="contractor-hero compact contractor-dealer-hero">
                    <small>CONTRACTOR FLEET DEALER</small>
                    <h2>Approved Contractor Units</h2>
                    <div class="contractor-metrics">
                        <div><small>STOCK</small><strong>${market.length}</strong></div>
                        <div><small>OWNED</small><strong>${ownedCount}</strong></div>
                        <div><small>SLOTS</small><strong>${contractor.maxOwnedVehicles || ownedCount}</strong></div>
                        <div><small>AUTHORITY</small><strong>ACTIVE</strong></div>
                    </div>
                </div>
                <div class="contractor-market">${marketHtml}</div>
            </div>
        `;
        return;
    }

    contractorContent.innerHTML = `
        <div class="contractor-hero compact">
            <small>PRIVATE CONTRACTOR</small>
            <h2>${contractor.dailyRouteLabel || 'No Dedicated Route Selected'}</h2>
            <div class="contractor-metrics">
                <div><small>REP</small><strong>${contractor.rep || 0}</strong></div>
                <div><small>DAILY BONUS</small><strong>${formatMoney(contractor.dailyBonus || 0)}</strong></div>
                <div><small>MIN FUEL</small><strong>${contractor.minFuel || 0}%</strong></div>
                <div><small>MIN CONDITION</small><strong>${contractor.minCondition || 0}%</strong></div>
            </div>
        </div>
        ${dailySelectorHtml}
        <h2 class="subheading">Available Contracts</h2>
        <div class="contractor-board">${boardHtml}</div>
        <h2 class="subheading">Private Fleet</h2>
        ${activeOut ? '<div class="contractor-actions"><button data-contractor-store-vehicle>Store Current Contractor Vehicle</button></div>' : ''}
        <div class="contractor-fleet">${fleetHtml}</div>
        <h2 class="subheading">Contractor Fleet Dealer</h2>
        ${marketSummaryHtml}
    `;
}

function renderRanks(data) {
    const rankList = document.getElementById('rankList');
    rankList.innerHTML = '';
    const currentRank = Number(data.player?.rank || 1);

    (data.ranks || []).forEach(rank => {
        const row = document.createElement('div');
        row.className = `rank-row${Number(rank.rank) === currentRank ? ' current' : ''}`;
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
    priorityInfo.innerText = `${priority.description || 'Standard route'} - Rank ${req}+ - ${Math.round(mult * 100)}% payout - ${Math.round(xpMult * 100)}% XP`;
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
        const payoutRange = estimateContractPayoutRange(type, contract, priority);
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
                <div class="payout">${payoutRange}</div>
                <small>BEST LOAD</small>
                <div class="difficulty">${priority.shortLabel || priority.label}</div>
            </div>
        `;

        contractList.appendChild(card);
    });
}

if (contractList) {
    contractList.addEventListener('click', event => {
        const card = event.target.closest('.contract-card');
        if (!card || !contractList.contains(card)) return;

        const type = card.dataset.type || 'van';
        const contract = dispatchData?.contracts?.[type];
        if (!contract) return;

        playUISound('click');
        selectedContract = type;
        selectedVehicleIndex = 1;
        renderContracts(dispatchData);
        renderSelected(contract, type);
        renderPrioritySelector(type);
        renderVehicleSelector(type);
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

function estimateContractPayoutRange(type, contract, priority) {
    const payout = dispatchData?.payouts?.[type] || {};
    const multiplier = Number(priority?.payoutMultiplier || 1.0);
    const mileageConfig = dispatchData?.mileagePayout || {};
    const mileageEnabled = mileageConfig.Enabled !== false;
    const mileageRate = Math.max(0, Number(mileageConfig.RatePerMile ?? 100));
    const routes = priority?.routes?.length ? priority.routes : (contract?.routes || []);
    const routeMiles = routes
        .map(route => parseMilesFromLength(route?.routeLength))
        .filter(miles => Number.isFinite(miles) && miles >= 0);
    const minMiles = routeMiles.length ? Math.min(...routeMiles) : 0;
    const maxMiles = routeMiles.length ? Math.max(...routeMiles) : 0;
    const minMileage = mileageEnabled ? Math.round(minMiles * mileageRate) : 0;
    const maxMileage = mileageEnabled ? Math.round(maxMiles * mileageRate) : 0;
    const minimum = Math.floor(Number(payout.min || 0) * multiplier) + minMileage;
    const maximum = Math.floor(Number(payout.max || 0) * multiplier) + maxMileage;

    return `${formatMoney(minimum)} - ${formatMoney(maximum)}`;
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

    if (!pool || pool.length === 0) {
        previewRouteCache[key] = null;
        return null;
    }

    const index = Math.floor(Math.random() * pool.length);
    const route = pool[index];

    // Keep the randomized preview route pinned until the user changes
    // contract type/priority. This index is sent back when starting the job
    // so the server starts the same route the player previewed.
    previewRouteCache[key] = {
        route,
        routeIndex: index + 1
    };

    return previewRouteCache[key];
}

function getPreviewRouteData(contract, type) {
    const preview = getPreviewRoute(contract, type);
    return preview && preview.route ? preview.route : preview;
}

function getPreviewRouteIndex(type) {
    const preview = previewRouteCache[getPreviewRouteCacheKey(type)];
    return preview && preview.routeIndex ? preview.routeIndex : null;
}

function renderRoutePreview(contract, type) {
    const list = document.getElementById('routePreviewList');
    const badge = document.getElementById('routeTypeBadge');
    const priority = getSelectedPriority(type);
    const route = getPreviewRouteData(contract, type);

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
    const route = getPreviewRouteData(contract, type);
    let firstDropoff = 'Selected Route';

    if (route && route.dropoffs && route.dropoffs[0]) firstDropoff = route.dropoffs[0].label;
    else if (route && route.trailerDrop) firstDropoff = route.trailerDrop.label;

    const priority = getSelectedPriority(type);
    document.getElementById('selectedType').innerText = `${titleFromType(type)} - ${priority.shortLabel || priority.label}`;
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

function openUI(data, options = {}) {
    clearTimeout(dispatchHideTimer);
    clearTimeout(dispatchParkTimer);
    clearDispatchCleanupTimers();
    dispatchRenderSignatures = {};
    const wasHidden = app.classList.contains('hidden');
    app.classList.remove('dispatch-closing', 'dispatch-opening', 'dispatch-pre-open', 'dispatch-parked');

    dispatchData = data;
    configureUISounds(data.config || {});
    selectedContract = 'van';
    selectedVehicleIndex = 1;
    selectedPriority = { van: 'standard', boxtruck: 'standard', trailer: 'standard' };
    clearPreviewRoute();
    if (!options.preserveTab) {
        selectedGarageKey = null;
        contractorMarketVisible = false;
        selectedContractorPanel = 'vehicle';
        selectedContractorDailyRouteKey = null;
        selectedContractorDailyType = null;
        selectedContractorVehicleId = null;
        selectedContractorContractKey = null;
        selectedContractorMarketKey = null;
    }

    renderPlayer(data);
    renderDispatchHome(data);
    renderCurrentJob(data);
    renderRouteHistory(data.routeHistory || data.lastRouteSummary);
    renderGarage(data);
    renderContractor(data);
    renderRanks(data);
    renderContracts(data);
    renderPrioritySelector('van');
    renderSelected(data.contracts.van, 'van');
    renderVehicleSelector('van');
    setTab(options.preserveTab ? activeDispatchTab : 'home');
    dispatchRenderChanged('player', data.player || {});
    dispatchRenderChanged('tab:home', dispatchTabSignature(data, 'home'));
    dispatchRenderChanged('currentJob', data.currentJob || null);
    dispatchRenderChanged('tab:history', dispatchTabSignature(data, 'history'));
    dispatchRenderChanged('tab:garage', dispatchTabSignature(data, 'garage'));
    dispatchRenderChanged('tab:contractor', dispatchTabSignature(data, 'contractor'));
    dispatchRenderChanged('tab:company', dispatchTabSignature(data, 'company'));
    dispatchRenderChanged('tab:dispatch', dispatchTabSignature(data, 'dispatch'));
    dispatchRenderChanged(`preview:${activeDispatchTab}`, dispatchTabSignature(data, activeDispatchTab));

    if (wasHidden) app.classList.add('dispatch-pre-open');
    app.classList.remove('hidden', 'dispatch-parked');

    if (wasHidden) {
        requestAnimationFrame(() => {
            if (app.classList.contains('hidden') || app.classList.contains('dispatch-closing')) return;
            app.classList.remove('dispatch-pre-open');
            app.classList.add('dispatch-opening');
            clearTimeout(dispatchHideTimer);
            dispatchHideTimer = setTimeout(() => {
                app.classList.remove('dispatch-opening');
            }, DISPATCH_ANIMATION_MS);
        });
    }
}

function refreshDispatchData(data = {}) {
    if (!data || !app || app.classList.contains('hidden') || app.classList.contains('dispatch-closing')) return;

    dispatchData = data;
    configureUISounds(data.config || {});
    let rendered = false;

    if (dispatchRenderChanged('player', data.player || {})) {
        renderPlayer(data);
        rendered = true;
    }

    if (dispatchRenderChanged('currentJob', data.currentJob || null)) {
        renderCurrentJob(data);
        rendered = true;
    }

    if (activeDispatchTab === 'home') {
        if (dispatchRenderChanged('tab:home', dispatchTabSignature(data, 'home'))) {
            renderDispatchHome(data);
            rendered = true;
        }
    } else if (activeDispatchTab === 'history') {
        if (dispatchRenderChanged('tab:history', dispatchTabSignature(data, 'history'))) {
            renderRouteHistory(data.routeHistory || data.lastRouteSummary);
            rendered = true;
        }
    } else if (activeDispatchTab === 'garage') {
        if (dispatchRenderChanged('tab:garage', dispatchTabSignature(data, 'garage'))) {
            renderGarage(data);
            rendered = true;
        }
    } else if (activeDispatchTab === 'contractor') {
        if (dispatchRenderChanged('tab:contractor', dispatchTabSignature(data, 'contractor'))) {
            renderContractor(data);
            rendered = true;
        }
    } else if (activeDispatchTab === 'company') {
        if (dispatchRenderChanged('tab:company', dispatchTabSignature(data, 'company'))) {
            renderRanks(data);
            rendered = true;
        }
    } else if (activeDispatchTab === 'dispatch') {
        if (dispatchRenderChanged('tab:dispatch', dispatchTabSignature(data, 'dispatch'))) {
            const contracts = data.contracts || {};
            if (!contracts[selectedContract]) selectedContract = 'van';
            renderContracts(data);
            if (contracts[selectedContract]) {
                renderPrioritySelector(selectedContract);
                renderSelected(contracts[selectedContract], selectedContract);
                renderVehicleSelector(selectedContract);
            }
            rendered = true;
        }
    }

    const previewRendered = dispatchRenderChanged(`preview:${activeDispatchTab}`, dispatchTabSignature(data, activeDispatchTab));
    if (rendered || previewRendered) {
        renderPreviewContextPanel();
    }
}

function clearDispatchCleanupTimers() {
    dispatchCleanupTimers.forEach(timer => clearTimeout(timer));
    dispatchCleanupTimers = [];
}

function clearNodeContent(element) {
    if (element) element.textContent = '';
}

function clearImageById(id) {
    const image = document.getElementById(id);
    if (!image) return;

    image.removeAttribute('src');
    image.removeAttribute('srcset');
    image.style.display = 'none';
}

function scheduleDispatchCleanup() {
    clearDispatchCleanupTimers();

    const queue = (delay, cleanup) => {
        const timer = setTimeout(() => {
            if (!app || !app.classList.contains('hidden')) return;
            cleanup();
        }, delay);
        dispatchCleanupTimers.push(timer);
    };

    queue(900, () => {
        clearNodeContent(dispatchHomeMap);
        clearNodeContent(previewContext);
        clearNodeContent(routeHistoryList);
    });

    queue(1300, () => {
        clearNodeContent(garageList);
        clearNodeContent(contractorContent);
    });

    queue(1700, () => {
        clearNodeContent(contractList);
        clearNodeContent(document.getElementById('rankList'));
        clearNodeContent(document.getElementById('routePreviewList'));
    });

    queue(2100, () => {
        if (prioritySelect) prioritySelect.textContent = '';
        if (vehicleSelect) vehicleSelect.textContent = '';
        const trailerPreview = document.getElementById('routeTrailerPreview');
        if (trailerPreview) trailerPreview.remove();
        clearImageById('vehiclePhoto');
        clearImageById('routeTrailerPhoto');
        dispatchCleanupTimers = [];
    });
}

function closeUI() {
    clearTimeout(dispatchHideTimer);
    clearTimeout(dispatchParkTimer);
    app.classList.remove('dispatch-pre-open', 'dispatch-opening');

    if (app.classList.contains('hidden')) return;

    if (document.activeElement && typeof document.activeElement.blur === 'function') {
        document.activeElement.blur();
    }

    app.classList.add('dispatch-closing');
    dispatchHideTimer = setTimeout(() => {
        app.classList.add('hidden', 'dispatch-parked');
        app.classList.remove('dispatch-closing');
        scheduleDispatchCleanup();
        dispatchParkTimer = setTimeout(() => {
            if (app.classList.contains('hidden')) {
                app.classList.remove('dispatch-parked');
            }
        }, DISPATCH_CLEANUP_PARK_MS);
    }, DISPATCH_ANIMATION_MS);
}

function renderMiniDock(contract = {}) {
    if (!miniDock) return;

    const dockSignature = [
        contract.stage,
        contract.notice,
        contract.destination,
        contract.destinationAddress,
        contract.radioChatter,
        contract.currentStop,
        contract.totalStops,
        contract.loadedCargo,
        contract.requiredCargo,
        contract.type,
        contract.loaded,
        contract.cargoReady,
        contract.verifiedCargo,
        contract.trailerAttached,
        contract.trailerHooked,
        contract.cargoConditionLevel,
        contract.cargoConditionLabel,
        contract.loadChecklist?.truckSecure,
        contract.loadChecklist?.trailerSecure
    ].join('|');
    const dockWasHidden = miniDock.classList.contains('hidden');

    const miniDockChannel = document.getElementById('miniDockChannel');
    if (miniDockChannel) miniDockChannel.innerText = formatMiniFrequency(contract.radioFrequency || dispatchData?.radioFrequency || dispatchData?.config?.radioFrequency || '68.9');

    updateReceiverLogo(document.getElementById('miniDockMakerLogo'), contract.logo);
    updateReceiverSignal(document.getElementById('miniDockSignalMeter'), contract);
    updateReceiverRadioLine(document.getElementById('miniDockRadioLine'), contract.radioChatter || 'Dispatch standing by.');
    updateReceiverRouteProgress(document.getElementById('miniDockRouteProgressBar'), contract);

    const miniDockTitle = document.getElementById('miniDockTitle');
    if (miniDockTitle) miniDockTitle.innerText = contract.label || titleFromType(contract.type) || 'Active Contract';

    const cargoTotal = Math.max(0, Number(contract.requiredCargo) || 0);
    const cargoDelivered = Math.max(0, Math.min(cargoTotal, Number(contract.currentStop) || 0));
    const cargoLoaded = Math.max(0, Math.min(cargoTotal - cargoDelivered, Number(contract.loadedCargo) || 0));
    const stopsTotal = Math.max(0, Number(contract.totalStops) || 0);
    const stopsComplete = Math.max(0, Math.min(stopsTotal, Number(contract.currentStop) || 0));

    renderDockProgressIcons(
        document.getElementById('miniDockCargoLoaded'),
        cargoTotal,
        'fas fa-box',
        'Cargo',
        index => {
            if (index < cargoDelivered) return 'is-delivered';
            if (index < cargoDelivered + cargoLoaded) return 'is-loaded';
            return 'is-pending';
        },
        `Cargo: ${cargoDelivered} delivered, ${cargoLoaded} loaded of ${cargoTotal}`
    );

    renderDockLoadStatus(document.getElementById('miniDockLoadStatus'), contract);

    renderDockProgressIcons(
        document.getElementById('miniDockStops'),
        stopsTotal,
        'fas fa-location-dot',
        'Stops',
        index => index < stopsComplete ? 'is-complete' : 'is-upcoming',
        `Stops: ${stopsComplete} complete of ${stopsTotal}`
    );

    const miniDockDestinationName = document.getElementById('miniDockDestinationName');
    if (miniDockDestinationName) {
        miniDockDestinationName.innerText = contract.destination || 'Destination pending';
    }

    const miniDockDestinationStreet = document.getElementById('miniDockDestinationStreet');
    if (miniDockDestinationStreet) {
        if (contract.destinationAddress) {
            miniDockDestinationStreet.innerText = contract.destinationAddress;
            miniDockDestinationStreet.classList.remove('hidden');
        } else {
            miniDockDestinationStreet.innerText = '';
            miniDockDestinationStreet.classList.add('hidden');
        }
    }

    const miniDockLastUpdate = document.getElementById('miniDockLastUpdate');
    if (miniDockLastUpdate) miniDockLastUpdate.innerText = `LAST UPDATE ${contract.lastUpdate || formatMiniClock()}`;

    updateGpsIndicator(document.getElementById('miniDockGpsStatus'), contract.gpsLocked);

    showMiniDockWithAnimation(dockWasHidden);
    if (dockWasHidden || (miniDockLastSignature && miniDockLastSignature !== dockSignature)) flashMiniRadio(contract.radioDirection);
    miniDockLastSignature = dockSignature;
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
    if (startBtn.disabled) return;
    playUISound('confirm');
    startBtn.disabled = true;
    setTimeout(() => { startBtn.disabled = false; }, 8000);

    // Ensure the preview route exists before starting, then send its pool index
    // to the server. This keeps random route preview behavior while preventing
    // a different random route from being assigned on start.
    const contract = dispatchData?.contracts?.[selectedContract];
    if (contract) getPreviewRoute(contract, selectedContract);

    const reuseVehicle = reuseVehicleCheck.checked && canReuseCurrentVehicle(selectedContract);
    post('startContract', {
        contractType: selectedContract,
        vehicleIndex: selectedVehicleIndex,
        priorityKey: selectedPriority[selectedContract] || 'standard',
        routeIndex: getPreviewRouteIndex(selectedContract),
        reuseVehicle
    });
});

cancelJobBtn.addEventListener('click', () => { playUISound('error'); post('cancelCurrentJob'); });
manifestJobBtn.addEventListener('click', () => { playUISound('confirm'); post('openActiveManifest'); });
returnGarageBtn.addEventListener('click', () => { playUISound('confirm'); post('returnGarageVehicle'); });
if (dispatchCloseBtn) {
    dispatchCloseBtn.addEventListener('click', () => {
        playUISound('click');
        post('close');
    });
}

if (previewContext) {
    previewContext.addEventListener('click', event => {
        const gpsButton = event.target.closest('[data-dispatch-set-gps]');
        if (gpsButton) {
            const point = getDispatchMapPointById(gpsButton.dataset.dispatchSetGps);
            if (!point || !point.coords) {
                playUISound('error');
                return;
            }

            playUISound('confirm');
            post('dispatchSetGps', {
                id: point.id || '',
                label: point.label || 'Dispatch location',
                x: Number(point.coords.x || 0),
                y: Number(point.coords.y || 0)
            });
            return;
        }

        const tabButton = event.target.closest('[data-preview-tab]');
        if (tabButton) {
            playUISound('click');
            setTab(tabButton.dataset.previewTab || 'dispatch');
            return;
        }

        const actionButton = event.target.closest('[data-preview-action]');
        if (actionButton) {
            const action = actionButton.dataset.previewAction || '';
            if (action === 'manifest') {
                playUISound('confirm');
                post('openActiveManifest');
                return;
            }
            if (action === 'cancel') {
                playUISound('error');
                post('cancelCurrentJob');
                return;
            }
        }

        const garageSpawn = event.target.closest('[data-preview-spawn-garage]');
        if (garageSpawn) {
            if (garageSpawn.disabled) {
                playUISound('error');
                return;
            }
            playUISound('confirm');
            post('spawnGarageVehicle', {
                vehicleType: garageSpawn.dataset.type || '',
                vehicleIndex: Number(garageSpawn.dataset.index || 1)
            });
            return;
        }

        const license = event.target.closest('[data-contractor-license]');
        if (license) {
            playUISound('confirm');
            post('purchaseContractorLicense');
            return;
        }

        const previewSpawnContractor = event.target.closest('[data-preview-contractor-spawn-vehicle]');
        if (previewSpawnContractor) {
            if (previewSpawnContractor.disabled) {
                playUISound('error');
                return;
            }
            playUISound('confirm');
            post('spawnContractorVehicle', { vehicleId: Number(previewSpawnContractor.dataset.previewContractorSpawnVehicle || 0) });
            return;
        }

        const previewStoreContractor = event.target.closest('[data-preview-contractor-store-vehicle]');
        if (previewStoreContractor) {
            if (previewStoreContractor.disabled) {
                playUISound('error');
                return;
            }
            playUISound('confirm');
            post('storeContractorVehicle');
            return;
        }

        const previewSellContractor = event.target.closest('[data-preview-contractor-sell-vehicle]');
        if (previewSellContractor) {
            if (previewSellContractor.disabled) {
                playUISound('error');
                return;
            }
            playUISound('alert');
            previewSellContractor.disabled = true;
            setTimeout(() => { previewSellContractor.disabled = false; }, 8000);
            post('sellContractorVehicle', {
                vehicleId: Number(previewSellContractor.dataset.previewContractorSellVehicle || 0),
                resalePrice: Number(previewSellContractor.dataset.resalePrice || 0),
                originalPrice: Number(previewSellContractor.dataset.originalPrice || 0),
                mileage: Number(previewSellContractor.dataset.mileage || 0)
            });
            return;
        }

        const previewStartContractor = event.target.closest('[data-preview-contractor-start]');
        if (previewStartContractor) {
            if (previewStartContractor.disabled) {
                playUISound('error');
                return;
            }
            playUISound('confirm');
            previewStartContractor.disabled = true;
            setTimeout(() => { previewStartContractor.disabled = false; }, 8000);
            post('startContractorContract', {
                vehicleId: Number(previewStartContractor.dataset.previewContractorStart || 0),
                priorityKey: previewStartContractor.dataset.priority || 'standard',
                routeIndex: Number(previewStartContractor.dataset.routeIndex || 0) || null,
                dailyRouteKey: previewStartContractor.dataset.dailyRouteKey || null
            });
            return;
        }

        const previewBuyContractor = event.target.closest('[data-preview-contractor-buy-type]');
        if (previewBuyContractor) {
            if (previewBuyContractor.disabled) {
                playUISound('error');
                return;
            }
            playUISound('confirm');
            post('purchaseContractorVehicle', {
                vehicleType: previewBuyContractor.dataset.previewContractorBuyType,
                vehicleIndex: Number(previewBuyContractor.dataset.previewContractorBuyIndex || 1)
            });
            return;
        }

        const previewDailyRoute = event.target.closest('[data-preview-contractor-daily-route]');
        if (previewDailyRoute) {
            if (previewDailyRoute.disabled) {
                playUISound('error');
                return;
            }
            playUISound('confirm');
            post('selectContractorDailyRoute', { routeKey: previewDailyRoute.dataset.previewContractorDailyRoute });
            return;
        }

        const marketToggle = event.target.closest('[data-contractor-market-toggle]');
        if (marketToggle) {
            event.preventDefault();
            event.stopPropagation();
            playUISound('click');
            contractorMarketVisible = !contractorMarketVisible;
            if (contractorMarketVisible) selectedContractorPanel = 'market';
            renderContractor(dispatchData || {});
            renderPreviewContextPanel();
        }
    });
}

if (contractorContent) {
    contractorContent.addEventListener('click', event => {
        const marketToggle = event.target.closest('[data-contractor-market-toggle]');
        if (marketToggle) {
            playUISound('click');
            contractorMarketVisible = !contractorMarketVisible;
            if (contractorMarketVisible) selectedContractorPanel = 'market';
            renderContractor(dispatchData || {});
            renderPreviewContextPanel();
            return;
        }

        const selectedVehicle = event.target.closest('[data-contractor-select-vehicle]');
        if (selectedVehicle) {
            playUISound('click');
            selectedContractorPanel = 'vehicle';
            selectedContractorVehicleId = selectedVehicle.dataset.contractorSelectVehicle || null;
            renderContractor(dispatchData || {});
            renderPreviewContextPanel();
            return;
        }

        const selectedDailyType = event.target.closest('[data-contractor-daily-type]');
        if (selectedDailyType) {
            playUISound('click');
            selectedContractorDailyType = selectedDailyType.dataset.contractorDailyType || null;
            selectedContractorPanel = 'daily';
            selectedContractorDailyRouteKey = null;
            renderContractor(dispatchData || {});
            renderPreviewContextPanel();
            return;
        }

        const selectedDailyRoute = event.target.closest('[data-contractor-select-daily-route]');
        if (selectedDailyRoute) {
            playUISound('click');
            selectedContractorPanel = 'daily';
            selectedContractorDailyRouteKey = selectedDailyRoute.dataset.contractorSelectDailyRoute || null;
            renderContractor(dispatchData || {});
            renderPreviewContextPanel();
            return;
        }

        const selectedContract = event.target.closest('[data-contractor-select-contract]');
        if (selectedContract) {
            playUISound('click');
            selectedContractorPanel = 'contract';
            selectedContractorContractKey = selectedContract.dataset.contractorSelectContract || null;
            renderContractor(dispatchData || {});
            renderPreviewContextPanel();
            return;
        }

        const selectedMarket = event.target.closest('[data-contractor-select-market]');
        if (selectedMarket) {
            playUISound('click');
            selectedContractorPanel = 'market';
            selectedContractorMarketKey = selectedMarket.dataset.contractorSelectMarket || null;
            renderContractor(dispatchData || {});
            renderPreviewContextPanel();
            return;
        }

        const license = event.target.closest('[data-contractor-license]');
        if (license) {
            playUISound('confirm');
            post('purchaseContractorLicense');
            return;
        }

        const buyVehicle = event.target.closest('[data-contractor-buy-type]');
        if (buyVehicle && !buyVehicle.disabled) {
            playUISound('confirm');
            post('purchaseContractorVehicle', {
                vehicleType: buyVehicle.dataset.contractorBuyType,
                vehicleIndex: Number(buyVehicle.dataset.contractorBuyIndex || 1)
            });
            return;
        }

        const spawnVehicle = event.target.closest('[data-contractor-spawn-vehicle]');
        if (spawnVehicle && !spawnVehicle.disabled) {
            playUISound('confirm');
            post('spawnContractorVehicle', { vehicleId: Number(spawnVehicle.dataset.contractorSpawnVehicle || 0) });
            return;
        }

        const storeVehicle = event.target.closest('[data-contractor-store-vehicle]');
        if (storeVehicle && !storeVehicle.disabled) {
            playUISound('confirm');
            post('storeContractorVehicle');
            return;
        }

        const startContract = event.target.closest('[data-contractor-start]');
        if (startContract && !startContract.disabled) {
            playUISound('confirm');
            startContract.disabled = true;
            setTimeout(() => { startContract.disabled = false; }, 8000);
            post('startContractorContract', {
                vehicleId: Number(startContract.dataset.contractorStart || 0),
                priorityKey: startContract.dataset.priority || 'standard',
                routeIndex: Number(startContract.dataset.routeIndex || 0) || null,
                dailyRouteKey: startContract.dataset.dailyRouteKey || null
            });
        }
    });
}

document.addEventListener('click', event => {
    const loadAction = event.target.closest('[data-mini-load-action]');
    if (loadAction && mini && mini.contains(loadAction)) {
        if (loadAction.disabled || loadAction.classList.contains('is-pending')) return;

        playUISound('confirm');
        loadAction.disabled = true;
        loadAction.classList.add('is-pending');
        setTimeout(() => {
            loadAction.disabled = false;
            loadAction.classList.remove('is-pending');
        }, 7000);
        post('receiverLoadAction', { action: loadAction.dataset.miniLoadAction || '' });
        return;
    }

    const movementToggle = event.target.closest('[data-mini-movement-toggle]');
    if (movementToggle && mini && mini.contains(movementToggle)) {
        playUISound('click');
        setMiniMovementUnlocked(!miniMovementUnlocked, true);
        return;
    }

    const dockToggle = event.target.closest('[data-mini-dock-toggle]');
    if (dockToggle && mini && mini.contains(dockToggle)) {
        if (dockToggle.disabled) {
            playUISound('error');
            return;
        }

        playUISound('click');
        dockToggle.disabled = true;
        post('receiverToggleDock');
        setTimeout(() => { dockToggle.disabled = false; }, 700);
        return;
    }

    const vehicleAction = event.target.closest('[data-mini-vehicle-action]');
    if (vehicleAction && mini && mini.contains(vehicleAction)) {
        if (vehicleAction.disabled || vehicleAction.classList.contains('is-pending')) return;

        playUISound('click');
        vehicleAction.disabled = true;
        vehicleAction.classList.add('is-pending');
        setTimeout(() => {
            vehicleAction.disabled = false;
            vehicleAction.classList.remove('is-pending');
        }, 1000);
        post('receiverVehicleControl', { action: vehicleAction.dataset.miniVehicleAction || '' });
        return;
    }

    const priorityButton = event.target.closest('[data-mini-priority]');
    if (priorityButton && mini && mini.contains(priorityButton)) {
        playUISound('click');
        const type = getReceiverVehicleType(miniLastContract);
        if (type) selectedPriority[type] = priorityButton.dataset.miniPriority || 'standard';
        renderMiniLoadPage(miniLastContract);
        return;
    }

    const startCurrentJob = event.target.closest('[data-mini-start-current-job]');
    if (startCurrentJob && mini && mini.contains(startCurrentJob)) {
        if (startCurrentJob.disabled || startCurrentJob.classList.contains('is-pending')) return;
        playUISound('confirm');
        startCurrentJob.disabled = true;
        startCurrentJob.classList.add('is-pending');
        setTimeout(() => {
            startCurrentJob.disabled = false;
            startCurrentJob.classList.remove('is-pending');
        }, 8000);
        const reuse = miniLastContract?.reuseVehicle || {};
        const privateUnit = reuse.contractor || reuse.source === 'contractor';
        post('receiverStartCurrentJob', {
            priorityKey: privateUnit ? 'standard' : getSelectedReceiverPriority(miniLastContract)
        });
        return;
    }

    const cancelRoute = event.target.closest('[data-mini-cancel-route]');
    if (cancelRoute && mini && mini.contains(cancelRoute)) {
        playUISound('alert');
        post('receiverCancelRoute');
        return;
    }

    const pageButton = event.target.closest('[data-mini-page]');
    if (pageButton && mini && mini.contains(pageButton)) {
        playUISound('click');
        setMiniPage(pageButton.dataset.miniPage || 'home');
        return;
    }

    const homeButton = event.target.closest('[data-mini-home]');
    if (homeButton && mini && mini.contains(homeButton)) {
        playUISound('click');
        setMiniPage('home');
    }
});

document.addEventListener('keydown', event => {
    if (event.key !== 'Escape') return;

    // If a Freight Dispatch dialog is open, close the dialog first.
    // This prevents ESC from removing NUI focus while leaving the dialog visible.
    if (freightDialog && !freightDialog.classList.contains('hidden')) {
        event.preventDefault();
        event.stopPropagation();
        closeFreightDialog();
        return;
    }

    if (mini && !mini.classList.contains('hidden') && !mini.classList.contains('receiver-closing')) {
        event.preventDefault();
        event.stopPropagation();
        post('closeReceiver');
        return;
    }

    if (app && app.classList.contains('hidden')) return;

    event.preventDefault();
    event.stopPropagation();
    post('close');
});

window.addEventListener('message', event => {
    const data = event.data;

    if (data.action === 'open') openUI(data.data);
    if (data.action === 'refreshDispatch') refreshDispatchData(data.data);
    if (data.action === 'close') closeUI();
    if (data.action === 'showFreightDialog') showFreightDialog(data);
    if (data.action === 'showFreightCancelDialog') showFreightCancelDialog(data);
    if (data.action === 'showFreightHandoff') showFreightHandoff(data);
    if (data.action === 'hideFreightDialog') hideFreightDialog();
    if (data.action === 'showTrailerCargoEditor') showTrailerCargoEditor(data.state || {});
    if (data.action === 'updateTrailerCargoEditor') renderTrailerCargoEditor(data.state || {});
    if (data.action === 'hideTrailerCargoEditor') hideTrailerCargoEditor();

    if (data.action === 'playSound') {
        playUISound(data.sound || data.type || 'click');
    }

    if (data.action === 'showMiniDock') {
        renderMiniDock(data.contract || {});
    }

    if (data.action === 'hideMiniDock' && miniDock) {
        hideMiniDockWithAnimation(() => {
            miniDock.classList.remove('dispatch-flash', 'radio-rx-flash');
            miniDockLastSignature = '';
        });
    }

    if (data.action === 'showMini') {
        const contract = data.contract || {};
        miniLastContract = contract;
        const miniSignature = miniStructuralSignature(contract);

        const miniWasHidden = mini.classList.contains('hidden');
        const miniStructureChanged = miniWasHidden || miniLastSignature !== miniSignature;
        if (miniWasHidden || (miniLastSignature && miniLastSignature !== miniSignature)) flashMiniRadio(contract.radioDirection);

        if (miniWasHidden) setMiniPage('home', { instant: true });
        updateMiniLiveFields(contract);

        if (miniStructureChanged) {
            renderMiniAppPages(contract);
        }

        miniLastSignature = miniSignature;
        setMiniPage(miniCurrentPage || 'home', { instant: miniWasHidden });
        showReceiverWithAnimation(miniWasHidden);
    }

    if (data.action === 'refreshMini' && mini && !mini.classList.contains('hidden')) {
        const contract = { ...miniLastContract, ...(data.contract || {}) };
        miniLastContract = contract;
        updateMiniLiveFields(contract);
        if (miniCurrentPage === 'vehicle') renderMiniVehiclePage(contract);
        if (miniCurrentPage === 'dispatch') renderMiniDispatchPage(contract);
        if (miniCurrentPage === 'settings') renderMiniSettingsPage(contract);
    }

    if (data.action === 'hideMini') {
        hideReceiverWithAnimation(() => {
            mini.classList.remove('dispatch-flash', 'radio-rx-flash');
            miniLastSignature = '';
            miniLastContract = {};
            setMiniPage('home', { instant: true });
            clearTimeout(miniPulseTimer);
            miniPulseTimer = null;
        });
    }

    if (data.action === 'updateLastRouteSummary') {
        renderRouteHistory(data.summary);
    }

    if (data.action === 'updateRouteHistory') {
        const history = normalizeRouteHistory(data.history || data.summary);
        dispatchData = {
            ...(dispatchData || {}),
            lastRouteSummary: data.summary || (history[0] || null),
            routeHistory: history
        };
        renderRouteHistory(history);
        if (activeDispatchTab === 'history') buildHistoryPreviewPanel();
        if (miniLastContract) {
            miniLastContract = { ...miniLastContract, routeHistory: history };
            if (miniCurrentPage === 'dispatch') renderMiniDispatchPage(miniLastContract);
        }
    }
});

// Shared transform-based dragging for the receiver and compact dock.
// Transform positioning avoids FiveM CEF cases where top/height only move horizontally.
function setupMovablePanel(options) {
    const box = document.getElementById(options.elementId);
    if (!box) return;

    const storageKey = options.storageKey;
    const oldStorageKey = options.oldStorageKey;

    function viewport() {
        return {
            width: Math.max(window.innerWidth || 0, document.documentElement.clientWidth || 0, 1280),
            height: Math.max(window.innerHeight || 0, document.documentElement.clientHeight || 0, 720)
        };
    }

    function clamp(value, min, max) {
        return Math.min(Math.max(value, min), max);
    }

    function boxSize() {
        const rect = box.getBoundingClientRect();
        return {
            width: rect.width || box.offsetWidth || options.fallbackWidth,
            height: rect.height || box.offsetHeight || options.fallbackHeight
        };
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
    let activePointerId = null;

    function defaultPosition() {
        const vp = viewport();
        const size = boxSize();
        return options.defaultPosition(vp, size);
    }

    function applyPosition(save = false) {
        const vp = viewport();
        const size = boxSize();
        const maxX = Math.max(0, vp.width - size.width);
        const maxY = Math.max(0, vp.height - size.height);

        pos.x = clamp(pos.x, 0, maxX);
        pos.y = clamp(pos.y, 0, maxY);

        box.style.setProperty(options.xProperty, `${Math.round(pos.x)}px`);
        box.style.setProperty(options.yProperty, `${Math.round(pos.y)}px`);

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
        if (!raw && oldStorageKey) {
            const oldRaw = localStorage.getItem(oldStorageKey);
            if (oldRaw) {
                try {
                    const old = JSON.parse(oldRaw);
                    if (Number.isFinite(old.left) && Number.isFinite(old.top)) {
                        raw = JSON.stringify({ x: old.left, y: old.top });
                    }
                    } catch {}
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
            } catch {}
        }

        requestAnimationFrame(() => {
            pos = defaultPosition();
            applyPosition(false);
        });
    }

    function startDrag(event) {
        if (!isMiniMovementUnlocked()) return;
        if ((event.type === 'mousedown' || event.type === 'pointerdown') && event.button !== 0) return;
        if (options.blockedSelector && event.target?.closest?.(options.blockedSelector)) return;

        const point = readPoint(event);
        dragging = true;
        last = point;
        activeTouchId = event.touches?.[0]?.identifier ?? null;
        activePointerId = Number.isFinite(event.pointerId) ? event.pointerId : null;
        box.classList.add('dragging');

        if (activePointerId !== null && box.setPointerCapture) {
            try { box.setPointerCapture(activePointerId); } catch {}
        }

        event.preventDefault();
        event.stopPropagation();
    }

    function moveDrag(event) {
        if (!dragging || !last) return;
        if (activePointerId !== null && Number.isFinite(event.pointerId) && event.pointerId !== activePointerId) return;

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
        if (activePointerId !== null && box.releasePointerCapture) {
            try { box.releasePointerCapture(activePointerId); } catch {}
        }
        activePointerId = null;
        box.classList.remove('dragging');
        applyPosition(true);

        if (event) {
            event.preventDefault();
            event.stopPropagation();
        }
    }

    loadPosition();

    if (window.PointerEvent) {
        box.addEventListener('pointerdown', startDrag);
        document.addEventListener('pointermove', moveDrag, true);
        document.addEventListener('pointerup', stopDrag, true);
        document.addEventListener('pointercancel', stopDrag, true);
    } else {
        box.addEventListener('mousedown', startDrag);
        box.addEventListener('touchstart', startDrag, { passive: false });

        document.addEventListener('mousemove', moveDrag, true);
        document.addEventListener('mouseup', stopDrag, true);
        document.addEventListener('touchmove', moveDrag, { passive: false, capture: true });
        document.addEventListener('touchend', stopDrag, true);
        document.addEventListener('touchcancel', stopDrag, true);
    }

    window.addEventListener('blur', stopDrag);

    window.addEventListener('resize', () => applyPosition(true));
}

setupMovablePanel({
    elementId: 'mini',
    storageKey: 'ls_trucking_mini_pos_v3',
    oldStorageKey: 'ls_trucking_mini_pos',
    xProperty: '--mini-x',
    yProperty: '--mini-y',
    fallbackWidth: 330,
    fallbackHeight: 704,
    blockedSelector: '.mini-screen, button, input, select, textarea, a',
    defaultPosition: (viewport, size) => ({
        x: Math.max(20, viewport.width - size.width - Math.round(viewport.width * 0.02)),
        y: Math.max(20, Math.round(viewport.height * 0.18))
    })
});

setupMovablePanel({
    elementId: 'miniDock',
    storageKey: 'ls_trucking_mini_dock_pos_v1',
    xProperty: '--dock-x',
    yProperty: '--dock-y',
    fallbackWidth: 360,
    fallbackHeight: 214,
    defaultPosition: (viewport, size) => ({
        x: Math.max(16, viewport.width - size.width - 22),
        y: Math.max(16, viewport.height - size.height - 34)
    })
});
