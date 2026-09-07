const miniDispatchOpenHistoryKeys = new Set();
const MINI_WALLPAPER_WIDTH = 720;
const MINI_WALLPAPER_HEIGHT = 1280;
const MINI_WALLPAPER_IMPORT_LIMIT = 12 * 1024 * 1024;

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
    const logoPath = String(value || 'images/badger-logo.webp').trim();
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
    meter.title = contract.signalLabel || uiText('receiver.detail.telemetry', {}, 'Dispatch signal');
}

function updateReceiverRadioLine(line, text) {
    if (!line) return;
    const radioText = text || '';
    line.classList.toggle('hidden', !radioText);
    const dispatchLogLabel = uiText('receiver.panel.dispatchLog', {}, 'Dispatch Log');
    line.title = dispatchLogLabel;
    line.setAttribute('aria-label', radioText ? `${dispatchLogLabel}: ${radioText}` : dispatchLogLabel);
    const target = line.querySelector('span');
    if (target) target.innerText = radioText;
}

function updateReceiverRouteProgress(bar, contract = {}) {
    if (!bar) return;
    const totalStops = Number(contract.totalStops || 0);
    const currentStop = Number(contract.currentStop || 0);
    const loadProgress = miniLoadProgress(contract);
    const showLoadProgress = contract.type !== 'trailer' && contract.verifiedCargo !== true && loadProgress.total > 0;
    const routePercent = showLoadProgress
        ? Math.max(0, Math.min(100, (loadProgress.loaded / loadProgress.total) * 100))
        : totalStops > 0 ? Math.max(0, Math.min(100, (currentStop / totalStops) * 100)) : 0;
    bar.style.width = `${routePercent}%`;
}

function miniLoadProgress(contract = {}) {
    const assisted = contract.autoLoadActive === true || contract.autoLoadPaused === true;
    const loaded = assisted ? contract.autoLoadLoaded ?? contract.loadedCargo : contract.loadedCargo;
    const total = assisted ? contract.autoLoadTotal ?? contract.requiredCargo : contract.requiredCargo;

    return {
        assisted,
        loaded: Math.max(0, Number(loaded) || 0),
        total: Math.max(0, Number(total) || 0)
    };
}

function miniLoadStatusText(contract = {}) {
    if (contract.autoLoadPaused === true) return uiText('receiver.status.loadingPaused', {}, 'LOADING PAUSED');
    if (contract.autoLoadActive === true) return uiText('receiver.status.loadingCargo', {}, 'LOADING CARGO');
    return contract.cargoConditionLabel || uiText('label.cargoStable', {}, 'CARGO STABLE');
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

function setMiniAppState(id, value, tone = 'neutral') {
    const element = document.getElementById(id);
    if (!element) return;
    element.innerText = value;
    element.dataset.tone = tone;
}

function miniActiveLabel(contract = {}) {
    return contract.hasActiveRoute === false ? uiText('receiver.status.standby', {}, 'STANDBY') : uiText('receiver.status.active', {}, 'ACTIVE');
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
            ${content || `<p>${uiText('empty.noData', {}, 'No data received.')}</p>`}
        </section>
    `;
}

function renderMiniScaleSetting(target, label, icon) {
    const currentScale = getMiniUIScale(target);
    const currentPercent = Math.round(currentScale * 100);
    const options = MINI_SCALE_PRESETS.map(scale => {
        const percent = Math.round(scale * 100);
        const selected = scale === currentScale;

        return `
            <button type="button" class="mini-scale-option ${selected ? 'is-selected' : ''}"
                data-mini-scale-target="${target}" data-mini-scale="${scale}"
                aria-label="${escapeHtml(`${label} ${percent}%`)}" aria-pressed="${selected}">
                ${percent}%
            </button>
        `;
    }).join('');

    return `
        <div class="mini-scale-setting">
            <div class="mini-scale-heading">
                <span><i class="fas ${icon}"></i>${escapeHtml(label)}</span>
                <strong>${currentPercent}%</strong>
            </div>
            <div class="mini-scale-options" role="group" aria-label="${escapeHtml(label)}">
                ${options}
            </div>
        </div>
    `;
}

function renderMiniWallpaperSetting() {
    const custom = hasMiniCustomWallpaper();
    const wallpaperLabel = uiText('receiver.detail.wallpaper', {}, 'Wallpaper');
    const chooseLabel = uiText('receiver.action.chooseWallpaper', {}, 'Choose Image');
    const defaultLabel = uiText('receiver.action.useDefaultWallpaper', {}, 'Use Default');
    const statusLabel = custom
        ? uiText('receiver.status.customWallpaper', {}, 'CUSTOM')
        : uiText('receiver.status.defaultWallpaper', {}, 'DEFAULT');

    return miniPanel(wallpaperLabel, `
        <div class="mini-wallpaper-setting">
            <div class="mini-wallpaper-preview" role="img" aria-label="${escapeHtml(wallpaperLabel)}">
                <span id="miniWallpaperStatus" data-tone="${custom ? 'custom' : 'default'}">${escapeHtml(statusLabel)}</span>
            </div>
            <div class="mini-wallpaper-actions">
                <button type="button" class="mini-wide-action" data-mini-wallpaper-select>
                    <i class="fas fa-image"></i><span>${escapeHtml(chooseLabel)}</span>
                </button>
                <button type="button" class="mini-wide-action" data-mini-wallpaper-reset>
                    <i class="fas fa-rotate-left"></i><span>${escapeHtml(defaultLabel)}</span>
                </button>
            </div>
        </div>
        <input class="mini-wallpaper-input" type="file" accept="image/png,image/jpeg,image/webp" aria-label="${escapeHtml(chooseLabel)}" hidden>
    `, 'mini-wallpaper-panel');
}

async function importMiniWallpaper(file) {
    if (!file || !String(file.type || '').startsWith('image/') || file.size > MINI_WALLPAPER_IMPORT_LIMIT) {
        return false;
    }

    const objectUrl = URL.createObjectURL(file);

    try {
        const image = await new Promise((resolve, reject) => {
            const candidate = new Image();
            candidate.onload = () => resolve(candidate);
            candidate.onerror = reject;
            candidate.src = objectUrl;
        });
        if (!image.naturalWidth || !image.naturalHeight) return false;

        const canvas = document.createElement('canvas');
        canvas.width = MINI_WALLPAPER_WIDTH;
        canvas.height = MINI_WALLPAPER_HEIGHT;
        const context = canvas.getContext('2d');
        if (!context) return false;

        const scale = Math.max(MINI_WALLPAPER_WIDTH / image.naturalWidth, MINI_WALLPAPER_HEIGHT / image.naturalHeight);
        const width = image.naturalWidth * scale;
        const height = image.naturalHeight * scale;
        context.fillStyle = '#020303';
        context.fillRect(0, 0, MINI_WALLPAPER_WIDTH, MINI_WALLPAPER_HEIGHT);
        context.imageSmoothingEnabled = true;
        context.imageSmoothingQuality = 'high';
        context.drawImage(image, (MINI_WALLPAPER_WIDTH - width) / 2, (MINI_WALLPAPER_HEIGHT - height) / 2, width, height);

        return setMiniCustomWallpaper(canvas.toDataURL('image/webp', 0.76), true);
    } catch {
        return false;
    } finally {
        URL.revokeObjectURL(objectUrl);
    }
}

function setMiniWallpaperError() {
    const status = document.getElementById('miniWallpaperStatus');
    if (!status) return;
    status.innerText = uiText('receiver.status.wallpaperError', {}, 'IMAGE NOT SAVED');
    status.dataset.tone = 'error';
}

function miniTrailerPhotoPanel(contract = {}) {
    if (!contract.trailerPhoto) return '';

    const trailerName = contract.trailerLabel || contract.cargo || uiText('receiver.fallback.assignedTrailer', {}, 'Assigned Trailer');
    return `
        <section class="mini-info-panel mini-trailer-photo-panel">
            <small>${escapeHtml(uiText('receiver.fallback.assignedTrailer', {}, 'Assigned Trailer'))}</small>
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

function renderMiniCargoManifestVerificationPanel(contract = {}) {
    if (contract.hasActiveRoute === false) return '';
    if (contract.type === 'trailer') return '';
    if ((contract.loadVerificationMode || 'receiver') !== 'receiver') return '';

    const pendingAction = contract.receiverLoadAction || '';
    const actionPending = Boolean(pendingAction);
    const verified = contract.verifiedCargo === true;
    const ready = contract.cargoReady === true;

    return miniPanel(uiText('receiver.detail.dispatchManifestClearance', {}, 'Dispatch Manifest Clearance'), `
        <div class="mini-load-action-stack">
            ${miniLoadActionButton(
                uiText('receiver.action.verifyCargoManifest', {}, 'Verify Cargo Manifest'),
                verified ? uiText('receiver.status.manifestVerified', {}, 'Manifest verified - route active') : ready ? uiText('receiver.status.loadReadyDispatch', {}, 'Load count ready for dispatch') : uiText('receiver.status.finishLoadingCargo', {}, 'Finish loading all assigned cargo'),
                verified ? 'fa-satellite-dish' : 'fa-clipboard-check',
                'verify_cargo',
                { complete: verified, pending: pendingAction === 'verify_cargo', disabled: actionPending || verified || !ready }
            )}
        </div>
    `, 'mini-load-clearance-panel');
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
        return miniPanel('Route Request', `<p>${uiText('empty.priorityNeedsVehicle', {}, 'No current vehicle detected. Spawn or keep an assigned unit out, then request a load from the receiver.')}</p>`, 'mini-start-panel');
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
        : `<p>${uiText('empty.noPriorityData', {}, 'No priority data received.')}</p>`;

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
    clearTimeout(miniPageTransitionTimer);
    document.querySelectorAll('#mini .mini-app-page').forEach(clearMiniPageMotion);
    mini.classList.remove('receiver-pre-open', 'receiver-opening', 'receiver-closing');

    if (mini.classList.contains('hidden')) {
        if (typeof onHidden === 'function') onHidden();
        return;
    }

    mini.classList.add('hidden');
    window.stopUISounds?.();
    if (typeof onHidden === 'function') onHidden();
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
    miniDock.classList.remove('dock-pre-open', 'dock-closing');

    if (miniDock.classList.contains('hidden')) {
        if (typeof onHidden === 'function') onHidden();
        return;
    }

    miniDock.classList.add('hidden');
    if (typeof onHidden === 'function') onHidden();
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

function manifestStopState(group = {}, contract = {}) {
    const stop = Number(group.stop || 0);
    const currentStop = Number(contract.currentStop || 0);

    if (currentStop > 0 && stop < currentStop) {
        return { key: 'complete', label: uiText('common.completed', {}, 'Completed') };
    }
    if (currentStop > 0 && stop === currentStop) {
        return { key: 'current', label: uiText('common.current', {}, 'Current') };
    }
    return { key: 'pending', label: uiText('receiver.status.pending', {}, 'Pending') };
}

function renderMiniManifestOverview(contract = {}, manifest = [], groups = []) {
    const itemCount = manifest.length || Number(contract.requiredCargo || 0);
    const stopCount = groups.length || Number(contract.totalStops || 0);
    const itemLabel = uiText(itemCount === 1 ? 'serviceBay.cart.item' : 'serviceBay.cart.items', { count: itemCount }, `${itemCount} items`);
    const stopLabel = `${stopCount} ${uiText('receiver.detail.stops', {}, 'Stops').toLowerCase()}`;
    const meta = [
        contract.priorityLabel,
        contract.routeLength,
        contract.payout !== undefined ? formatMoney(contract.payout) : ''
    ].filter(Boolean);

    return `
        <section class="mini-info-panel mini-manifest-overview">
            <div class="mini-manifest-overview-head">
                <div>
                    <small>${escapeHtml(uiText('label.route', {}, 'Route'))}</small>
                    <strong>${escapeHtml(contract.label || uiText('dialog.freightRoute', {}, 'Freight Route'))}</strong>
                </div>
                <span>${escapeHtml(itemLabel)} / ${escapeHtml(stopLabel)}</span>
            </div>
            ${meta.length ? `<div class="mini-manifest-meta">${meta.map(value => `<span>${escapeHtml(value)}</span>`).join('')}</div>` : ''}
        </section>
    `;
}

function renderMiniHome(contract = {}) {
    const active = contract.hasActiveRoute !== false;
    const reuse = contract.reuseVehicle || {};
    const loadingStatus = miniLoadStatusText(contract);
    const loading = contract.autoLoadActive === true || contract.autoLoadPaused === true;
    const loadNeedsAttention = contract.autoLoadPaused === true || /damag|critical|shift|warning/i.test(String(contract.cargoConditionLabel || ''));
    const manifestStatus = loading ? uiText('receiver.status.dockLoading', {}, 'DOCK LOAD') : active ? uiText('receiver.status.ready', {}, 'READY') : uiText('receiver.status.noLoad', {}, 'NO LOAD');
    const loadStatus = loading ? loadingStatus : contract.cargoConditionLabel || (active ? uiText('receiver.status.loaded', {}, 'LOADED') : reuse.available ? uiText('receiver.status.ready', {}, 'READY') : uiText('receiver.status.idle', {}, 'IDLE'));
    const vehicleStatus = active ? (contract.plate || uiText('receiver.status.assigned', {}, 'ASSIGNED')) : reuse.available ? (reuse.plate || uiText('receiver.status.ready', {}, 'READY')) : uiText('common.none', {}, 'NONE');
    const totalStops = Math.max(0, Number(contract.totalStops) || 0);
    const currentStop = Math.max(0, Number(contract.currentStop) || 0);
    const routeWidget = document.querySelector('#miniHomePage .mini-home-status');
    const routeKicker = active ? uiText('label.routeActive', {}, 'Route active') : uiText('receiver.status.standby', {}, 'Standby');
    const routeTitle = active ? (contract.label || uiText('label.routeActive', {}, 'Active route')) : uiText('receiver.status.receiverStandby', {}, 'Receiver standby');
    const routeStage = active ? (contract.stage || uiText('receiver.fallback.routeActive', {}, 'Route active')) : uiText('empty.noRouteAssigned', {}, 'No active route assigned');

    setText('miniAppRouteLabel', uiText('receiver.app.route', {}, 'Route'));
    setText('miniAppManifestLabel', uiText('receiver.app.manifest', {}, 'Manifest'));
    setText('miniAppLoadLabel', uiText('receiver.app.load', {}, 'Load'));
    setText('miniAppVehicleLabel', uiText('receiver.app.vehicle', {}, 'Vehicle'));
    setText('miniAppDispatchLabel', uiText('receiver.app.radio', {}, 'Radio'));
    setText('miniAppSettingsLabel', uiText('receiver.app.settings', {}, 'Settings'));
    setText('miniHomeRouteKicker', routeKicker);
    setText('miniHomeStatus', routeTitle);
    setText('miniHomeSubstatus', routeStage);
    setText('miniHomeStopCount', active && totalStops > 0 ? `${Math.min(currentStop, totalStops)} / ${totalStops}` : '--');
    if (routeWidget) {
        routeWidget.dataset.tone = active ? 'active' : 'standby';
        routeWidget.setAttribute('aria-label', `${routeKicker}: ${routeTitle}. ${routeStage}`);
    }
    setMiniAppState('miniAppRouteBadge', miniActiveLabel(contract), active ? 'active' : 'neutral');
    setMiniAppState('miniAppManifestBadge', manifestStatus, loading ? 'attention' : active ? 'active' : 'neutral');
    setMiniAppState('miniAppLoadBadge', loadStatus, loadNeedsAttention ? 'attention' : active || reuse.available ? 'active' : 'neutral');
    setMiniAppState('miniAppVehicleBadge', vehicleStatus, active || reuse.available ? 'active' : 'neutral');
    setMiniAppState('miniAppDispatchBadge', contract.radioChatter ? uiText('receiver.status.newRx', {}, 'NEW RX') : uiText('receiver.status.rx', {}, 'RX'), contract.radioChatter ? 'attention' : 'neutral');
    updateReceiverRouteProgress(document.getElementById('miniHomeProgressBar'), contract);
}

function renderMiniManifestPage(contract = {}) {
    const content = document.getElementById('miniManifestContent');
    if (!content) return;

    if (contract.hasActiveRoute === false) {
        content.innerHTML = miniPanel(uiText('receiver.panel.manifest', {}, 'Manifest'), `<p>${uiText('empty.manifest', {}, 'No active manifest is assigned.')}</p>`);
        setText('miniPageManifestState', uiText('receiver.status.empty', {}, 'EMPTY'));
        return;
    }

    setText('miniPageManifestState', contract.contractId || uiText('receiver.status.paperwork', {}, 'PAPERWORK'));

    const summaryRows = [
        miniInfoRow(uiText('label.route', {}, 'Route'), contract.label, 'fa-route'),
        miniInfoRow(uiText('receiver.detail.loadType', {}, 'Load Type'), contract.priorityLabel, 'fa-tag'),
        miniInfoRow(uiText('receiver.detail.routeLength', {}, 'Route Length'), contract.routeLength, 'fa-road'),
        miniInfoRow(uiText('receiver.detail.payout', {}, 'Payout'), formatMoney(contract.payout), 'fa-money-bill-wave')
    ];

    if (contract.type === 'trailer') {
        const instructionList = Array.isArray(contract.trailerInstructions)
            ? contract.trailerInstructions.map(item => `<li>${escapeHtml(item)}</li>`).join('')
            : contract.trailerInstructions
                ? `<li>${escapeHtml(contract.trailerInstructions)}</li>`
                : `<li>${escapeHtml(uiText('receiver.fallback.routeInstructions', {}, 'Complete load checklist, deliver trailer, detach in the drop zone, then finalize with receiver.'))}</li>`;

        content.innerHTML = [
            miniPanel(uiText('receiver.panel.contract', {}, 'Contract'), summaryRows),
            miniPanel(uiText('receiver.panel.trailerPaperwork', {}, 'Trailer Paperwork'), [
                miniInfoRow(uiText('receiver.detail.pickupDepot', {}, 'Pickup Depot'), contract.trailerDepotLabel, 'fa-warehouse'),
                miniInfoRow(uiText('label.trailer', {}, 'Trailer'), contract.trailerLabel || contract.cargo, 'fa-trailer'),
                miniInfoRow(uiText('receiver.detail.contents', {}, 'Contents'), contract.trailerContents || contract.cargo, 'fa-boxes-stacked'),
                miniInfoRow(uiText('receiver.detail.receiver', {}, 'Receiver'), contract.trailerDropLabel || contract.destination, 'fa-clipboard-check'),
                miniInfoRow(uiText('receiver.detail.safeSpeed', {}, 'Safe Speed'), contract.safeSpeed ? `${Math.floor(Number(contract.safeSpeed))} MPH` : '', 'fa-gauge-high')
            ]),
            `<section class="mini-info-panel"><small>${escapeHtml(uiText('receiver.panel.instructions', {}, 'Instructions'))}</small><ul class="mini-paper-list">${instructionList}</ul></section>`
        ].join('');
        return;
    }

    const manifest = Array.isArray(contract.manifest) ? contract.manifest : [];
    const groups = groupManifestEntries(manifest);
    const pickupSignature = contract.pickupSignature || null;
    const releasePanel = pickupSignature
        ? `
            <section class="mini-manifest-release">
                <i class="fas fa-signature"></i>
                <div>
                    <small>${escapeHtml(uiText('receiver.detail.pickupRelease', {}, 'Pickup Release'))}</small>
                    <strong>${escapeHtml(pickupSignature.name || uiText('label.driver', {}, 'Driver'))}</strong>
                    <span>${escapeHtml([pickupSignature.signedAt, pickupSignature.location].filter(Boolean).join(' / '))}</span>
                </div>
                <i class="fas fa-circle-check"></i>
            </section>
        `
        : '';
    const stopRows = groups.length
        ? groups.map(group => {
            const cargo = Array.from(group.cargo.entries()).map(([label, count]) => `${label} x${count}`).join(', ') || `${group.count} package`;
            const state = manifestStopState(group, contract);
            return `
                <div class="mini-manifest-stop is-${state.key}">
                    <span class="mini-manifest-stop-number">${escapeHtml(String(group.stop).padStart(2, '0'))}</span>
                    <div class="mini-manifest-stop-copy">
                        <strong>${escapeHtml(group.receiver)}</strong>
                        <em>${escapeHtml(cargo)}</em>
                    </div>
                    <span class="mini-manifest-stop-state">${escapeHtml(state.label)}</span>
                </div>
            `;
        }).join('')
        : `<p>${uiText('empty.noData', {}, 'No stop entries received.')}</p>`;

    content.innerHTML = [
        renderMiniManifestOverview(contract, manifest, groups),
        releasePanel,
        `<section class="mini-info-panel mini-manifest-stops">
            <div class="mini-panel-heading">
                <small>${escapeHtml(uiText('receiver.panel.deliveryStops', {}, 'Delivery Stops'))}</small>
                <span>${escapeHtml(String(groups.length))}</span>
            </div>
            <div class="mini-manifest-stop-list">${stopRows}</div>
        </section>`,
        renderMiniCargoManifestVerificationPanel(contract)
    ].filter(Boolean).join('');
}

function renderMiniLoadPage(contract = {}) {
    const content = document.getElementById('miniLoadContent');
    if (!content) return;

    setText('miniPageLoadState', contract.cargoConditionLabel || (contract.hasActiveRoute === false ? uiText('receiver.status.idle', {}, 'IDLE') : uiText('receiver.status.status', {}, 'STATUS')));

    if (contract.hasActiveRoute === false) {
        content.innerHTML = [
            miniPanel(uiText('receiver.detail.loadStatus', {}, 'Load Status'), `<p>${uiText('receiver.empty.noCargoAssigned', {}, 'No cargo is assigned to this receiver.')}</p>`),
            renderReceiverPriorityPanel(contract)
        ].join('');
        return;
    }

    const checklist = contract.loadChecklist || {};
    const pendingAction = contract.receiverLoadAction || '';
    const actionPending = Boolean(pendingAction);
    const loadProgress = miniLoadProgress(contract);
    const loadStatus = miniLoadStatusText(contract);
    const rows = [
        miniInfoRow(uiText('label.cargo', {}, 'Cargo'), contract.cargo || uiText('label.cargo', {}, 'Cargo'), 'fa-box'),
        miniInfoRow(uiText('receiver.detail.loaded', {}, 'Loaded'), `${loadProgress.loaded} / ${loadProgress.total}`, 'fa-boxes-stacked'),
        miniInfoRow(uiText('receiver.detail.stops', {}, 'Stops'), `${contract.currentStop || 0} / ${contract.totalStops || 0}`, 'fa-map-pin'),
        miniInfoRow(uiText('receiver.detail.condition', {}, 'Condition'), loadStatus, 'fa-shield-halved'),
        miniInfoRow(uiText('receiver.detail.conditionNotes', {}, 'Condition Notes'), contract.cargoConditionNote, 'fa-clipboard-list')
    ];

    if (contract.type === 'trailer') {
        rows.push(
            miniInfoRow(uiText('label.trailer', {}, 'Trailer'), contract.trailerLabel || uiText('receiver.fallback.assignedTrailer', {}, 'Assigned Trailer'), 'fa-trailer'),
            miniInfoRow(uiText('receiver.detail.truckConnection', {}, 'Truck Connection'), checklist.truckSecure ? uiText('receiver.status.secured', {}, 'Secured') : uiText('receiver.status.pending', {}, 'Pending'), 'fa-link'),
            miniInfoRow(uiText('receiver.detail.trailerLoad', {}, 'Trailer Load'), checklist.trailerSecure ? uiText('receiver.status.secured', {}, 'Secured') : uiText('receiver.status.pending', {}, 'Pending'), 'fa-lock'),
            miniInfoRow(uiText('receiver.detail.trailerDrop', {}, 'Trailer Drop'), contract.trailerDropped ? uiText('receiver.status.dropped', {}, 'Dropped') : uiText('receiver.status.notDropped', {}, 'Not dropped'), 'fa-location-dot')
        );
    } else {
        const cargoReadyText = contract.autoLoadPaused === true
            ? uiText('receiver.status.loadingPaused', {}, 'Loading paused')
            : contract.autoLoadActive === true
                ? contract.autoLoadLabel || uiText('common.loading', {}, 'Loading in progress')
                : contract.cargoReady ? uiText('common.ready', {}, 'Ready for verification') : uiText('common.loading', {}, 'Loading in progress');
        rows.push(
            miniInfoRow(uiText('receiver.detail.cargoReady', {}, 'Cargo Ready'), cargoReadyText, 'fa-clipboard-check'),
            miniInfoRow(uiText('receiver.detail.verified', {}, 'Verified'), contract.verifiedCargo ? uiText('receiver.status.loadVerified', {}, 'Load verified') : uiText('receiver.status.pendingVerification', {}, 'Pending verification'), 'fa-check')
        );
    }

    let verificationPanel = '';
    if ((contract.loadVerificationMode || 'receiver') === 'receiver') {
        if (contract.type === 'trailer') {
            const trailerAttached = contract.trailerAttached === true;
            const truckSecure = checklist.truckSecure === true;
            const trailerSecure = checklist.trailerSecure === true;
            const routeCleared = contract.trailerHooked === true;

            verificationPanel = miniPanel(uiText('receiver.detail.dispatchLoadClearance', {}, 'Dispatch Load Clearance'), `
                <div class="mini-load-action-stack">
                    ${miniLoadActionButton(
                        uiText('receiver.action.submitChecklist', {}, 'Submit Checklist'),
                        routeCleared ? uiText('receiver.status.routeCleared', {}, 'Route cleared by dispatch') : truckSecure && trailerSecure ? uiText('receiver.status.readyDispatchReview', {}, 'Ready for dispatch review') : trailerAttached ? uiText('receiver.status.completeTargetChecks', {}, 'Complete trailer inspection first') : uiText('receiver.status.attachTrailerFirst', {}, 'Attach assigned trailer first'),
                        routeCleared ? 'fa-satellite-dish' : 'fa-paper-plane',
                        'submit_checklist',
                        { complete: routeCleared, pending: pendingAction === 'submit_checklist', disabled: actionPending || routeCleared || !truckSecure || !trailerSecure }
                    )}
                </div>
            `, 'mini-load-clearance-panel');
        } else {
            verificationPanel = renderMiniCargoManifestVerificationPanel(contract);
        }
    }

    const cancelRoutePanel = miniPanel(uiText('receiver.panel.routeControl', {}, 'Route Control'), `
        <button class="mini-cancel-route-button" data-mini-cancel-route>
            <i class="fas fa-ban"></i>
            <span>${uiText('action.cancelRoute', {}, 'Cancel Route')}</span>
        </button>
    `, 'mini-route-control-panel');

    content.innerHTML = [
        verificationPanel,
        cancelRoutePanel,
        contract.type === 'trailer' ? miniTrailerPhotoPanel(contract) : '',
        miniPanel(uiText('receiver.detail.loadStatus', {}, 'Load Status'), rows),
        renderReceiverPriorityPanel(contract)
    ].filter(Boolean).join('');
}

function renderMiniVehiclePage(contract = {}) {
    const content = document.getElementById('miniVehicleContent');
    if (!content) return;

    setText('miniPageVehicleState', contract.plate || (contract.hasActiveRoute === false ? uiText('common.none', {}, 'NONE') : uiText('receiver.status.unit', {}, 'UNIT')));

    const rows = [
        miniInfoRow(uiText('receiver.detail.assignedVehicle', {}, 'Assigned Vehicle'), contract.vehicle || uiText('receiver.fallback.handheld', {}, 'Handheld Receiver'), 'fa-truck-fast'),
        miniInfoRow(uiText('serviceBay.summary.plate', {}, 'Plate'), contract.plate, 'fa-id-card'),
        miniInfoRow(uiText('receiver.detail.fuel', {}, 'Fuel'), contract.vehicleFuelLabel || (contract.vehicleFuel !== undefined ? `${Math.round(Number(contract.vehicleFuel) || 0)}%` : uiText('common.na', {}, 'N/A')), 'fa-gas-pump'),
        miniInfoRow(uiText('receiver.detail.condition', {}, 'Condition'), contract.vehicleConditionLabel || uiText('common.na', {}, 'N/A'), 'fa-heart-pulse'),
        miniInfoRow(uiText('receiver.detail.gps', {}, 'GPS'), contract.gpsLocked === false ? uiText('receiver.status.searching', {}, 'Searching') : uiText('receiver.status.locked', {}, 'Locked'), 'fa-location-crosshairs')
    ];

    if (contract.type === 'trailer') {
        rows.push(
            miniInfoRow(uiText('label.trailer', {}, 'Trailer'), contract.trailerLabel || uiText('receiver.fallback.assignedTrailer', {}, 'Assigned Trailer'), 'fa-trailer'),
            miniInfoRow(uiText('receiver.detail.safeSpeed', {}, 'Safe Speed'), contract.safeSpeed ? `${Math.floor(Number(contract.safeSpeed))} MPH` : '', 'fa-gauge-high')
        );
    }

    const hasControlVehicle = contract.hasActiveRoute !== false || contract.reuseVehicle?.available || contract.plate;
    const controlPanel = hasControlVehicle
        ? miniPanel(uiText('receiver.detail.vehicleControls', {}, 'Vehicle Controls'), `
        <div class="mini-action-grid">
            ${miniActionButton(uiText('receiver.action.engine', {}, 'Engine'), 'fa-power-off', 'engine', uiText('receiver.control.toggleEngine', {}, 'Toggle engine'))}
            ${miniActionButton(uiText('receiver.action.locks', {}, 'Locks'), 'fa-lock', 'locks', uiText('receiver.control.toggleDoorLocks', {}, 'Toggle door locks'))}
            ${miniActionButton(uiText('receiver.action.locate', {}, 'Locate'), 'fa-location-crosshairs', 'locate', uiText('receiver.control.locateVehicle', {}, 'Locate vehicle'))}
            ${miniActionButton(uiText('receiver.action.driverDoor', {}, 'Driver'), 'fa-door-open', 'door_0', uiText('receiver.control.toggleDriverDoor', {}, 'Toggle driver door'))}
            ${miniActionButton(uiText('receiver.action.hood', {}, 'Hood'), 'fa-car-burst', 'door_4', uiText('receiver.control.toggleHood', {}, 'Toggle hood'))}
            ${miniActionButton(uiText('receiver.action.passengerDoor', {}, 'Passenger'), 'fa-door-open', 'door_1', uiText('receiver.control.togglePassengerDoor', {}, 'Toggle passenger door'))}
            ${miniActionButton(uiText('receiver.action.rearLeftDoor', {}, 'Rear Left'), 'fa-door-open', 'door_2', uiText('receiver.control.toggleRearLeftDoor', {}, 'Toggle rear left door'))}
            ${miniActionButton(uiText('receiver.action.trunk', {}, 'Trunk'), 'fa-box-open', 'door_5', uiText('receiver.control.toggleTrunk', {}, 'Toggle trunk'))}
            ${miniActionButton(uiText('receiver.action.rearRightDoor', {}, 'Rear Right'), 'fa-door-open', 'door_3', uiText('receiver.control.toggleRearRightDoor', {}, 'Toggle rear right door'))}
            ${miniActionButton(uiText('receiver.action.allDoors', {}, 'All Doors'), 'fa-up-right-from-square', 'doors', uiText('receiver.control.toggleAllDoors', {}, 'Toggle all doors'))}
            ${miniActionButton(uiText('receiver.action.hazards', {}, 'Hazards'), 'fa-triangle-exclamation', 'hazards', uiText('receiver.control.toggleHazards', {}, 'Toggle hazard lights'))}
            ${miniActionButton(uiText('receiver.action.cabLight', {}, 'Cab Light'), 'fa-lightbulb', 'interior', uiText('receiver.control.toggleInteriorLight', {}, 'Toggle interior light'))}
        </div>
    `, 'mini-control-panel')
        : miniPanel(uiText('receiver.detail.vehicleControls', {}, 'Vehicle Controls'), `<p>${uiText('empty.currentVehicleMissing', {}, 'No current vehicle detected.')}</p>`, 'mini-control-panel');

    content.innerHTML = [
        miniPanel(uiText('receiver.detail.vehicleData', {}, 'Vehicle Data'), rows),
        controlPanel
    ].join('');
}

function miniHistoryCardKey(summary = {}) {
    if (typeof routeHistoryCardKey === 'function') return routeHistoryCardKey(summary);

    return [
        summary.contractId,
        summary.completedAt,
        routeSummaryTitle(summary),
        summary.vehicleLabel
    ].filter(Boolean).join('|');
}

function syncMiniDispatchHistoryState() {
    const content = document.getElementById('miniDispatchContent');
    if (!content) return;

    content.querySelectorAll('.mini-history-card[data-mini-history-key]').forEach(card => {
        const key = card.dataset.miniHistoryKey;
        if (!key) return;
        if (card.open) miniDispatchOpenHistoryKeys.add(key);
        else miniDispatchOpenHistoryKeys.delete(key);
    });
}

function renderMiniRadioHistory(contract = {}) {
    const history = Array.isArray(contract.radioHistory)
        ? contract.radioHistory.filter(entry => entry && entry.message).slice(0, 5)
        : [];
    const entries = history.length
        ? history
        : (contract.radioChatter ? [{ message: contract.radioChatter, direction: contract.radioDirection || 'rx', at: contract.lastUpdate || '' }] : []);

    if (!entries.length) {
        return `<p>${uiText('receiver.empty.noRecentTraffic', {}, 'No recent dispatch traffic.')}</p>`;
    }

    return `
        <div class="mini-radio-memory-list">
            ${entries.map(entry => {
                const direction = entry.direction === 'tx' ? 'TX' : 'RX';
                const icon = entry.direction === 'tx' ? 'fa-arrow-up-right-dots' : 'fa-tower-broadcast';
                return `
                    <div class="mini-radio-memory-item ${entry.direction === 'tx' ? 'is-tx' : 'is-rx'}">
                        <i class="fas ${icon}"></i>
                        <div>
                            <small>${escapeHtml([direction, entry.at || entry.time || ''].filter(Boolean).join(' - '))}</small>
                            <strong>${escapeHtml(entry.message)}</strong>
                        </div>
                    </div>
                `;
            }).join('')}
        </div>
    `;
}

function renderMiniHistoryCards(history = []) {
    syncMiniDispatchHistoryState();
    const entries = normalizeRouteHistory(history).slice(0, 5);
    if (!entries.length) return `<p>${uiText('empty.history', {}, 'No completed route summaries logged.')}</p>`;

    return entries.map(summary => {
        const historyKey = miniHistoryCardKey(summary);
        const isOpen = miniDispatchOpenHistoryKeys.has(historyKey);
        const fields = routeSummaryFields(summary)
            .filter(([label]) => ['Contract', 'Load', 'Contents', 'Vehicle', 'Completed In', 'Timing Result', 'Cargo Condition', 'Final Payout', 'XP / Rep'].includes(label))
            .map(([label, value]) => miniInfoRow(label, value, 'fa-circle-info'))
            .join('');

        return `
            <details class="mini-history-card" data-mini-history-key="${escapeHtml(historyKey)}" ${isOpen ? 'open' : ''}>
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

    setText('miniPageDispatchState', contract.radioChatter ? uiText('receiver.status.newRx', {}, 'NEW RX') : uiText('receiver.status.rx', {}, 'RX'));

    const alert = contract.contractAlert;
    const statusMeta = [
        contract.expectedCompletion ? `${uiText('receiver.detail.eta', {}, 'ETA')} ${contract.expectedCompletion}` : '',
        `${uiText('receiver.detail.lastUpdate', {}, 'Last Update')} ${contract.lastUpdate || formatMiniClock()}`
    ].filter(Boolean).join(' / ');
    const routeStatus = `
        <section class="mini-dispatch-status">
            <i class="fas fa-tower-broadcast"></i>
            <div>
                <small>${escapeHtml(uiText('receiver.detail.routeStage', {}, 'Route Stage'))}</small>
                <strong>${escapeHtml(contract.stage || uiText('receiver.status.dispatchStandingBy', {}, 'Dispatch standing by.'))}</strong>
                <span>${escapeHtml(statusMeta)}</span>
            </div>
        </section>
    `;
    const alertPanel = alert
        ? `
            <section class="mini-dispatch-alert">
                <i class="fas fa-triangle-exclamation"></i>
                <div><small>${escapeHtml(alert.label || 'Dispatch Alert')}</small><strong>${escapeHtml(alert.description || 'Route conditions changed.')}</strong></div>
            </section>
        `
        : '';

    content.innerHTML = [
        routeStatus,
        alertPanel,
        miniPanel(uiText('receiver.panel.radioMemory', {}, 'Radio Memory'), renderMiniRadioHistory(contract), 'mini-radio-memory-panel'),
        miniPanel(uiText('receiver.panel.completedRoutes', {}, 'Completed Routes'), renderMiniHistoryCards(contract.routeHistory || dispatchData?.routeHistory || []), 'mini-history-panel')
    ].join('');
}

function renderMiniSettingsPage(contract = {}) {
    const content = document.getElementById('miniSettingsContent');
    if (!content) return;

    const dockCanToggle = contract.hasActiveRoute !== false && contract.dockEnabled !== false;
    const dockVisible = dockCanToggle && contract.dockVisible !== false;
    const dockButtonText = dockCanToggle
        ? (dockVisible ? uiText('receiver.status.hideDock', {}, 'Hide Dock') : uiText('receiver.status.showDock', {}, 'Show Dock'))
        : uiText('receiver.status.dockStandby', {}, 'Dock Standby');

    content.innerHTML = [
        miniPanel(uiText('receiver.detail.receiverSettings', {}, 'Receiver Settings'), [
            miniInfoRow(uiText('receiver.detail.receiverModel', {}, 'Receiver Model'), 'BDG-LSFC-R-1.4', 'fa-microchip'),
            miniInfoRow(uiText('receiver.detail.dockModel', {}, 'Dock Model'), 'BDG-LSFC-D-1.4', 'fa-window-restore'),
            miniInfoRow(uiText('receiver.detail.firmware', {}, 'Firmware'), 'BDG-FW 1.4.0', 'fa-code-branch'),
            `
                <div class="mini-settings-toggle-row">
                    <button class="mini-wide-action mini-settings-toggle mini-movement-toggle ${miniMovementUnlocked ? 'is-enabled' : ''}" data-mini-movement-toggle>
                        <i class="fas ${miniMovementUnlocked ? 'fa-lock' : 'fa-arrows-up-down-left-right'}"></i>
                        <span>${miniMovementUnlocked ? uiText('receiver.status.lockMove', {}, 'Lock Move') : uiText('receiver.status.unlockMove', {}, 'Unlock Move')}</span>
                    </button>
                    <button class="mini-wide-action mini-settings-toggle mini-dock-toggle ${dockVisible ? 'is-enabled' : ''}" data-mini-dock-toggle ${dockCanToggle ? '' : 'disabled'}>
                        <i class="fas ${dockVisible ? 'fa-eye-slash' : 'fa-window-restore'}"></i>
                        <span>${dockButtonText}</span>
                    </button>
                </div>
                <div class="mini-scale-settings">
                    ${renderMiniScaleSetting('receiver', uiText('receiver.detail.receiverSize', {}, 'Receiver Size'), 'fa-mobile-screen-button')}
                    ${renderMiniScaleSetting('dock', uiText('receiver.detail.dockSize', {}, 'Dock Size'), 'fa-window-restore')}
                </div>
            `
        ]),
        renderMiniWallpaperSetting()
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
    const radioHistory = Array.isArray(contract.radioHistory) ? contract.radioHistory : [];
    const radioHistorySignature = radioHistory.map(entry => [
        entry?.at,
        entry?.direction,
        entry?.type,
        entry?.message
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
        contract.autoLoadActive,
        contract.autoLoadPaused,
        contract.autoLoadLoaded,
        contract.autoLoadTotal,
        contract.autoLoadLabel,
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
        historySignature,
        radioHistorySignature
    ].join('|');
}

function updateGpsIndicator(element, locked) {
    if (!element) return;

    const searching = locked === false;
    element.classList.toggle('gps-search', searching);

    const label = element.querySelector('em');
    if (label) {
        label.innerText = searching ? uiText('receiver.gps.search', {}, 'SRCH') : uiText('receiver.gps.lock', {}, 'LOCK');
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
        const loadProgress = miniLoadProgress(contract);
        const loadingActive = contract.autoLoadActive === true;
        const loadingPaused = contract.autoLoadPaused === true;

        if (loadingActive || loadingPaused) {
            icons.push(dockLoadIcon('fas fa-boxes-stacked', loadingPaused ? 'is-pending' : 'is-loaded', loadingPaused ? 'Dock loading paused' : `Dock loading ${loadProgress.loaded}/${loadProgress.total}`));
            labels.push(loadingPaused ? 'loading paused' : `loading ${loadProgress.loaded}/${loadProgress.total}`);
        }

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
    if (miniTitle) miniTitle.innerText = contract.label || titleFromType(contract.type) || uiText('label.activeContract', {}, 'Active Contract');

    const miniChannel = document.getElementById('miniChannel');
    if (miniChannel) miniChannel.innerText = formatMiniFrequency(contract.radioFrequency || dispatchData?.radioFrequency || dispatchData?.config?.radioFrequency || '68.9');

    updateReceiverLogo(document.getElementById('miniMakerLogo'), contract.logo);
    setText('miniPayout', formatMoney(contract.payout));
    const miniInstructionLabel = document.getElementById('miniInstructionLabel');
    if (miniInstructionLabel) {
        miniInstructionLabel.innerHTML = `<i class="fas fa-location-arrow"></i>${escapeHtml(uiText('receiver.detail.currentInstruction', {}, 'Current Instruction'))}`;
    }

    setText('miniNotice', contract.notice || uiText('receiver.fallback.notice', {}, 'Follow your route instructions.'));
    setText('miniStage', contract.stage || 'Active');

    const miniExpected = document.getElementById('miniExpected');
    const miniExpectedText = document.getElementById('miniExpectedText');
    const miniExpectedLabel = document.getElementById('miniExpectedLabel');
    if (miniExpectedLabel) {
        miniExpectedLabel.innerHTML = `<i class="fas fa-clock"></i>${escapeHtml(uiText('receiver.detail.eta', {}, 'ETA'))}`;
    }
    if (miniExpected && miniExpectedText) {
        if (contract.expectedCompletion) {
            miniExpectedText.innerText = contract.expectedCompletion;
            miniExpected.classList.remove('hidden');
        } else {
            miniExpected.classList.add('hidden');
        }
    }

    const miniDestinationLabel = document.getElementById('miniDestinationLabel');
    if (miniDestinationLabel) {
        miniDestinationLabel.innerHTML = `<i class="fas fa-location-dot"></i>${escapeHtml(uiText('receiver.detail.destination', {}, 'Destination'))}`;
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

    const loadProgress = miniLoadProgress(contract);
    setText('miniCargoLoaded', `${loadProgress.loaded} / ${loadProgress.total}`);
    setText('miniProgress', `${contract.currentStop || 0} / ${contract.totalStops || 0}`);
    setText('miniCargo', contract.cargo || 'Cargo');

    const miniCargoCondition = document.getElementById('miniCargoCondition');
    if (miniCargoCondition) {
        miniCargoCondition.innerText = miniLoadStatusText(contract);
        miniCargoCondition.dataset.level = contract.autoLoadPaused === true ? 'warning' : contract.autoLoadActive === true ? 'loading' : contract.cargoConditionLevel || 'stable';
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
