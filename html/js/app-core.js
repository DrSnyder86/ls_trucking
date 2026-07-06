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
let uiSoundCache = {};

function configureUISounds(config) {
    const soundConfig = config?.uiSounds || {};
    const previousPath = uiSoundSettings.path;
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
    if (previousPath !== uiSoundSettings.path) uiSoundCache = {};
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
        const src = `${uiSoundSettings.path}${filename}`;
        let audio = uiSoundCache[src];
        if (!audio) {
            audio = new Audio(src);
            uiSoundCache[src] = audio;
        }

        audio.pause();
        audio.currentTime = 0;
        audio.volume = Math.max(0, Math.min(1, uiSoundSettings.volume));
        audio.play().catch(() => {});
    } catch {}
}
