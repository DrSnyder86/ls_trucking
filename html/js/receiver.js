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
    meter.title = contract.signalLabel || uiText('receiver.detail.telemetry', {}, 'Dispatch signal');
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
    setText('miniHomeStatus', active ? (contract.label || uiText('label.routeActive', {}, 'Active route')) : uiText('receiver.status.receiverStandby', {}, 'Receiver standby'));
    setText('miniHomeSubstatus', active ? (contract.stage || uiText('receiver.fallback.routeActive', {}, 'Route active')) : uiText('empty.noRouteAssigned', {}, 'No active route assigned'));
    setText('miniAppRouteBadge', miniActiveLabel(contract));
    setText('miniAppManifestBadge', active ? uiText('receiver.status.ready', {}, 'READY') : uiText('receiver.status.noLoad', {}, 'NO LOAD'));
    setText('miniAppLoadBadge', contract.cargoConditionLabel || (active ? uiText('receiver.status.loaded', {}, 'LOADED') : reuse.available ? uiText('receiver.status.ready', {}, 'READY') : uiText('receiver.status.idle', {}, 'IDLE')));
    setText('miniAppVehicleBadge', active ? (contract.plate || uiText('receiver.status.assigned', {}, 'ASSIGNED')) : reuse.available ? (reuse.plate || uiText('receiver.status.ready', {}, 'READY')) : uiText('common.none', {}, 'NONE'));
    setText('miniAppDispatchBadge', contract.radioChatter ? uiText('receiver.status.newRx', {}, 'NEW RX') : uiText('receiver.status.rx', {}, 'RX'));
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
        miniInfoRow(uiText('receiver.detail.contract', {}, 'Contract'), contract.contractId, 'fa-hashtag'),
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
        ? miniPanel(uiText('receiver.detail.pickupRelease', {}, 'Pickup Release'), [
            miniInfoRow(uiText('receiver.detail.signedBy', {}, 'Signed By'), pickupSignature.name, 'fa-signature'),
            miniInfoRow(uiText('receiver.detail.signedAt', {}, 'Signed At'), pickupSignature.signedAt, 'fa-clock'),
            miniInfoRow(uiText('receiver.detail.location', {}, 'Location'), pickupSignature.location, 'fa-location-dot')
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
        : `<p>${uiText('empty.noData', {}, 'No stop entries received.')}</p>`;

    content.innerHTML = [
        miniPanel(uiText('receiver.panel.contract', {}, 'Contract'), summaryRows),
        releasePanel,
        `<section class="mini-info-panel"><small>${escapeHtml(uiText('receiver.panel.deliveryStops', {}, 'Delivery Stops'))}</small>${stopRows}</section>`
    ].join('');
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
    const rows = [
        miniInfoRow(uiText('label.cargo', {}, 'Cargo'), contract.cargo || uiText('label.cargo', {}, 'Cargo'), 'fa-box'),
        miniInfoRow(uiText('receiver.detail.loaded', {}, 'Loaded'), `${contract.loadedCargo || 0} / ${contract.requiredCargo || 0}`, 'fa-boxes-stacked'),
        miniInfoRow(uiText('receiver.detail.stops', {}, 'Stops'), `${contract.currentStop || 0} / ${contract.totalStops || 0}`, 'fa-map-pin'),
        miniInfoRow(uiText('receiver.detail.condition', {}, 'Condition'), contract.cargoConditionLabel || uiText('label.cargoStable', {}, 'CARGO STABLE'), 'fa-shield-halved'),
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
        rows.push(
            miniInfoRow(uiText('receiver.detail.cargoReady', {}, 'Cargo Ready'), contract.cargoReady ? uiText('common.ready', {}, 'Ready for verification') : uiText('common.loading', {}, 'Loading in progress'), 'fa-clipboard-check'),
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
                        routeCleared ? uiText('receiver.status.routeCleared', {}, 'Route cleared by dispatch') : truckSecure && trailerSecure ? uiText('receiver.status.readyDispatchReview', {}, 'Ready for dispatch review') : trailerAttached ? uiText('receiver.status.completeTargetChecks', {}, 'Complete physical target checks first') : uiText('receiver.status.attachTrailerFirst', {}, 'Attach assigned trailer first'),
                        routeCleared ? 'fa-satellite-dish' : 'fa-paper-plane',
                        'submit_checklist',
                        { complete: routeCleared, pending: pendingAction === 'submit_checklist', disabled: actionPending || routeCleared || !truckSecure || !trailerSecure }
                    )}
                </div>
            `, 'mini-load-clearance-panel');
        } else {
            const verified = contract.verifiedCargo === true;
            const ready = contract.cargoReady === true;
            verificationPanel = miniPanel(uiText('receiver.detail.dispatchManifestClearance', {}, 'Dispatch Manifest Clearance'), `
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
    }

    content.innerHTML = [
        verificationPanel,
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

function renderMiniHistoryCards(history = []) {
    const entries = normalizeRouteHistory(history).slice(0, 5);
    if (!entries.length) return `<p>${uiText('empty.history', {}, 'No completed route summaries logged.')}</p>`;

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

    setText('miniPageDispatchState', contract.radioChatter ? uiText('receiver.status.newRx', {}, 'NEW RX') : uiText('receiver.status.rx', {}, 'RX'));

    const alert = contract.contractAlert;
    const rows = [
        miniInfoRow(uiText('receiver.detail.latestRadio', {}, 'Latest Radio'), contract.radioChatter || uiText('receiver.empty.noRecentTraffic', {}, 'No recent dispatch traffic.'), 'fa-tower-broadcast'),
        miniInfoRow(uiText('receiver.detail.routeStage', {}, 'Route Stage'), contract.stage, 'fa-location-arrow'),
        miniInfoRow(uiText('receiver.detail.eta', {}, 'ETA'), contract.expectedCompletion, 'fa-clock'),
        alert ? miniInfoRow(alert.label || 'Dispatch Alert', alert.description || 'Route conditions changed.', 'fa-triangle-exclamation') : '',
        miniInfoRow(uiText('receiver.detail.lastUpdate', {}, 'Last Update'), contract.lastUpdate || formatMiniClock(), 'fa-rotate')
    ];

    content.innerHTML = [
        miniPanel(uiText('receiver.panel.dispatchLog', {}, 'Dispatch Log'), rows),
        miniPanel(uiText('receiver.panel.completedRoutes', {}, 'Completed Routes'), renderMiniHistoryCards(contract.routeHistory || dispatchData?.routeHistory || []), 'mini-history-panel')
    ].join('');
}

function renderMiniSettingsPage(contract = {}) {
    const content = document.getElementById('miniSettingsContent');
    if (!content) return;

    const player = contract.player || dispatchData?.player || {};
    const rankText = player.rank
        ? `Rank ${player.rank}${player.rankLabel ? ` - ${player.rankLabel}` : ''}`
        : player.rankLabel || uiText('receiver.fallback.rankUnavailable', {}, 'Rank unavailable');
    const xp = Number(player.xp || 0);
    const nextRankXp = Number(player.nextRankXp || 0);
    const xpText = nextRankXp > xp
        ? `${formatInteger(xp)} / ${formatInteger(nextRankXp)} XP`
        : `${formatInteger(xp)} XP`;
    const dockCanToggle = contract.hasActiveRoute !== false && contract.dockEnabled !== false;
    const dockVisible = dockCanToggle && contract.dockVisible !== false;
    const dockButtonText = dockCanToggle
        ? (dockVisible ? uiText('receiver.status.hideDock', {}, 'Hide Dock') : uiText('receiver.status.showDock', {}, 'Show Dock'))
        : uiText('receiver.status.dockStandby', {}, 'Dock Standby');

    content.innerHTML = [
        miniPanel(uiText('receiver.detail.receiverSettings', {}, 'Receiver Settings'), [
            miniInfoRow(uiText('receiver.detail.receiverModel', {}, 'Receiver Model'), 'BDG-LSFC-R-1.1', 'fa-microchip'),
            miniInfoRow(uiText('receiver.detail.dockModel', {}, 'Dock Model'), 'BDG-LSFC-D-1.1', 'fa-window-restore'),
            miniInfoRow(uiText('receiver.detail.firmware', {}, 'Firmware'), 'BDG-FW 1.1.4', 'fa-code-branch'),
            miniInfoRow(uiText('receiver.detail.frequency', {}, 'Frequency'), formatMiniFrequency(contract.radioFrequency || dispatchData?.radioFrequency || dispatchData?.config?.radioFrequency || '68.9'), 'fa-wave-square'),
            miniInfoRow(uiText('receiver.detail.telemetry', {}, 'Telemetry'), contract.signalLabel || uiText('receiver.status.signalLocked', {}, 'Dispatch signal locked'), 'fa-satellite-dish'),
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
            `
        ]),
        miniPanel(uiText('receiver.detail.driverProfile', {}, 'Driver Profile'), [
            miniInfoRow(uiText('receiver.detail.receiverAssignedTo', {}, 'Receiver Assigned To'), player.name || uiText('label.driver', {}, 'Driver'), 'fa-user'),
            miniInfoRow(uiText('common.rank', {}, 'Rank'), rankText, 'fa-ranking-star'),
            miniInfoRow('XP', xpText, 'fa-gauge-high'),
            miniInfoRow(uiText('receiver.detail.reputation', {}, 'Reputation'), formatInteger(player.reputation || 0), 'fa-star'),
            miniInfoRow(uiText('receiver.detail.jobGrade', {}, 'Job / Grade'), player.jobText, 'fa-id-badge')
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
        miniCargoCondition.innerText = contract.cargoConditionLabel || uiText('label.cargoStable', {}, 'CARGO STABLE');
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
