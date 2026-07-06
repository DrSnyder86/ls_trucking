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
    updateReceiverRadioLine(document.getElementById('miniDockRadioLine'), contract.radioChatter || uiText('receiver.status.dispatchStandingBy', {}, 'Dispatch standing by.'));
    updateReceiverRouteProgress(document.getElementById('miniDockRouteProgressBar'), contract);

    const miniDockTitle = document.getElementById('miniDockTitle');
    if (miniDockTitle) miniDockTitle.innerText = contract.label || titleFromType(contract.type) || uiText('label.activeContract', {}, 'Active Contract');

    const cargoTotal = Math.max(0, Number(contract.requiredCargo) || 0);
    const cargoDelivered = Math.max(0, Math.min(cargoTotal, Number(contract.currentStop) || 0));
    const cargoLoaded = Math.max(0, Math.min(cargoTotal - cargoDelivered, Number(contract.loadedCargo) || 0));
    const stopsTotal = Math.max(0, Number(contract.totalStops) || 0);
    const stopsComplete = Math.max(0, Math.min(stopsTotal, Number(contract.currentStop) || 0));

    renderDockProgressIcons(
        document.getElementById('miniDockCargoLoaded'),
        cargoTotal,
        'fas fa-box',
        uiText('label.cargo', {}, 'Cargo'),
        index => {
            if (index < cargoDelivered) return 'is-delivered';
            if (index < cargoDelivered + cargoLoaded) return 'is-loaded';
            return 'is-pending';
        },
        uiText('receiver.aria.cargoProgress', { delivered: cargoDelivered, loaded: cargoLoaded, total: cargoTotal }, `Cargo: ${cargoDelivered} delivered, ${cargoLoaded} loaded of ${cargoTotal}`)
    );

    renderDockLoadStatus(document.getElementById('miniDockLoadStatus'), contract);

    renderDockProgressIcons(
        document.getElementById('miniDockStops'),
        stopsTotal,
        'fas fa-location-dot',
        uiText('receiver.detail.stops', {}, 'Stops'),
        index => index < stopsComplete ? 'is-complete' : 'is-upcoming',
        uiText('receiver.aria.stopProgress', { complete: stopsComplete, total: stopsTotal }, `Stops: ${stopsComplete} complete of ${stopsTotal}`)
    );

    const miniDockDestinationName = document.getElementById('miniDockDestinationName');
    if (miniDockDestinationName) {
        miniDockDestinationName.innerText = contract.destination || uiText('common.destinationPending', {}, 'Destination pending');
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
    if (miniDockLastUpdate) miniDockLastUpdate.innerText = uiText('receiver.status.lastUpdate', { time: contract.lastUpdate || formatMiniClock() }, `LAST UPDATE ${contract.lastUpdate || formatMiniClock()}`);

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
        closeUI();
        post('close');
    });
}

function hideMiniReceiverSurface() {
    hideReceiverWithAnimation(() => {
        mini.classList.remove('dispatch-flash', 'radio-rx-flash');
        miniLastSignature = '';
        miniLastContract = {};
        setMiniPage('home', { instant: true });
        clearTimeout(miniPulseTimer);
        miniPulseTimer = null;
    });
}

function hideMiniDockSurface() {
    hideMiniDockWithAnimation(() => {
        miniDock.classList.remove('dispatch-flash', 'radio-rx-flash');
        miniDockLastSignature = '';
    });
}

let pendingDispatchRefreshData = null;
let dispatchRefreshFrame = null;
let pendingMiniRefreshContract = null;
let miniRefreshFrame = null;

function scheduleUIFrame(callback) {
    return typeof requestAnimationFrame === 'function'
        ? requestAnimationFrame(callback)
        : setTimeout(callback, 0);
}

function queueDispatchRefresh(data) {
    pendingDispatchRefreshData = data || {};
    if (dispatchRefreshFrame) return;

    dispatchRefreshFrame = scheduleUIFrame(() => {
        dispatchRefreshFrame = null;
        const refreshData = pendingDispatchRefreshData;
        pendingDispatchRefreshData = null;
        if (!refreshData || !app || app.classList.contains('hidden') || app.classList.contains('dispatch-closing')) return;
        refreshDispatchData(refreshData);
    });
}

function queueMiniRefresh(contract = {}) {
    pendingMiniRefreshContract = { ...(pendingMiniRefreshContract || {}), ...contract };
    if (miniRefreshFrame) return;

    miniRefreshFrame = scheduleUIFrame(() => {
        miniRefreshFrame = null;
        const refreshContract = pendingMiniRefreshContract || {};
        pendingMiniRefreshContract = null;
        if (!mini || mini.classList.contains('hidden') || mini.classList.contains('receiver-closing')) return;

        const contract = { ...miniLastContract, ...refreshContract };
        miniLastContract = contract;
        updateMiniLiveFields(contract);
        if (miniCurrentPage === 'vehicle') renderMiniVehiclePage(contract);
        if (miniCurrentPage === 'dispatch') renderMiniDispatchPage(contract);
        if (miniCurrentPage === 'settings') renderMiniSettingsPage(contract);
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
        if (dockToggle.classList.contains('is-enabled') && miniDock && !miniDock.classList.contains('hidden')) {
            hideMiniDockSurface();
        }
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
        hideMiniReceiverSurface();
        post('closeReceiver');
        return;
    }

    if (app && app.classList.contains('hidden')) return;

    event.preventDefault();
    event.stopPropagation();
    closeUI();
    post('close');
});

window.addEventListener('message', event => {
    const data = event.data;

    if (data.action === 'open') openUI(data.data);
    if (data.action === 'refreshDispatch') queueDispatchRefresh(data.data);
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
        configureUILocale(data.contract || data);
        renderMiniDock(data.contract || {});
    }

    if (data.action === 'hideMiniDock' && miniDock) {
        hideMiniDockSurface();
    }

    if (data.action === 'showMini') {
        const contract = data.contract || {};
        configureUILocale(contract);
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
        configureUILocale(data.contract || data);
        queueMiniRefresh(data.contract || {});
    }

    if (data.action === 'hideMini') {
        hideMiniReceiverSurface();
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
