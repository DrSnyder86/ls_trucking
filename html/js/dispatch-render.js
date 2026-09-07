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


function routeHistoryCardKey(summary = {}) {
    return [
        summary.contractId,
        summary.completedAt,
        routeSummaryTitle(summary),
        summary.vehicleLabel
    ].filter(Boolean).join('|');
}

function getRouteHistoryCardState() {
    if (!routeHistoryList) return null;

    const cards = Array.from(routeHistoryList.querySelectorAll('.route-history-card'));
    if (!cards.length) return null;

    return {
        keys: new Set(cards.map(card => card.dataset.routeHistoryKey).filter(Boolean)),
        openKeys: new Set(cards.filter(card => card.open).map(card => card.dataset.routeHistoryKey).filter(Boolean))
    };
}

function renderRouteHistory(history) {
    if (!routeHistoryList) return;

    const entries = normalizeRouteHistory(history);
    const cardState = getRouteHistoryCardState();
    if (!entries.length) {
        routeHistoryList.innerHTML = '<div class="empty-card">No completed route summaries logged yet.</div>';
        return;
    }

    routeHistoryList.innerHTML = entries.map(summary => {
        const historyKey = routeHistoryCardKey(summary);
        const isOpen = cardState ? cardState.openKeys.has(historyKey) : false;
        const routeMeta = [
            summary.vehicleLabel ? `<span><i class="fas fa-truck"></i>${escapeHTML(summary.vehicleLabel)}</span>` : '',
            summary.routeLength && summary.routeLength !== 'N/A' ? `<span><i class="fas fa-road"></i>${escapeHTML(summary.routeLength)}</span>` : '',
            Number(summary.totalStops || 0) > 0 ? `<span><i class="fas fa-location-dot"></i>${escapeHTML(`${summary.totalStops} ${uiText('receiver.detail.stops', {}, 'Stops').toLowerCase()}`)}</span>` : ''
        ].filter(Boolean).join('');
        return `
            <details class="route-history-card" data-route-history-key="${escapeHTML(historyKey)}" ${isOpen ? 'open' : ''}>
                <summary>
                    <div class="route-history-summary-copy">
                        <div class="route-history-summary-line">
                            <span class="route-history-status">${escapeHTML(uiText('common.completed', {}, 'Completed'))}</span>
                            <small>${escapeHTML([summary.contractId, summary.completedAt].filter(Boolean).join(' / '))}</small>
                        </div>
                        <strong>${escapeHTML(routeSummaryTitle(summary))}</strong>
                        <div class="route-history-summary-meta">${routeMeta}</div>
                    </div>
                    <div class="route-history-summary-result">
                        <small>${escapeHTML(uiText('receiver.detail.payout', {}, 'Payout'))}</small>
                        <strong>${escapeHTML(formatMoney(summary.payout || 0))}</strong>
                        <i class="fas fa-chevron-down" aria-hidden="true"></i>
                    </div>
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
        noCurrentJob.innerText = uiText('empty.noActiveJob', {}, 'No active job.');
        return;
    }

    currentJobBox.classList.remove('hidden');
    noCurrentJob.classList.add('hidden');
    document.getElementById('currentJobTitle').innerText = job.label || uiText('label.activeJob', {}, 'Active Job');
    document.getElementById('currentJobStage').innerText = job.stage || uiText('label.routeActive', {}, 'Active route');
    const notice = document.getElementById('currentJobNotice');
    if (notice) notice.innerText = job.notice || uiText('label.followDispatch', {}, 'Follow current dispatch instructions.');
    document.getElementById('currentJobPayout').innerText = formatMoney(job.payout);
    document.getElementById('currentJobCargo').innerText = `${job.loadedCargo || 0} / ${job.requiredCargo || 0}`;
    document.getElementById('currentJobStops').innerText = `${job.currentStop || 0} / ${job.totalStops || 0}`;
    const currentJobCondition = document.getElementById('currentJobCondition');
    if (currentJobCondition) currentJobCondition.innerText = job.cargoConditionLabel || uiText('common.stable', {}, 'Stable');
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
    const garageState = data.garageState || {};
    const validTypes = new Set(['all', 'van', 'boxtruck', 'trailer']);
    if (!validTypes.has(selectedGarageType)) selectedGarageType = 'all';

    setText('garagePageTitle', uiText('garage.assignedFleet', {}, 'ASSIGNED COMPANY FLEET'));
    setText('garagePageDescription', uiText('garage.assignedFleetDescription', {}, 'Company assets assigned to this driver profile.'));
    setText('garageCheckoutLabel', uiText('garage.checkoutStatus', {}, 'CHECKOUT STATUS'));

    const companyVehicleOut = garageState.companyVehicleOut
        ? garage.find(vehicle => vehicle.garageId === garageState.garageId) || garage.find(vehicle => !vehicle.stored)
        : null;
    const checkoutName = companyVehicleOut
        ? `${garageDisplayLabel(companyVehicleOut.label, companyVehicleOut.type)} / ${companyVehicleOut.plate || uiText('garage.assignedOnCheckout', {}, 'Assigned on checkout')}`
        : garageState.contractorVehicleOut
            ? uiText('garage.privateUnitOut', {}, 'Private fleet unit currently checked out')
            : uiText('garage.noUnitOut', {}, 'No company unit checked out');
    setText('garageCheckoutName', checkoutName);

    if (garageActions) {
        garageActions.classList.toggle('has-unit', Boolean(companyVehicleOut));
        garageActions.classList.toggle('is-blocked', garageState.blocked && !companyVehicleOut);
    }
    if (returnGarageBtn) {
        returnGarageBtn.disabled = !companyVehicleOut || Boolean(data.currentJob);
        returnGarageBtn.title = data.currentJob
            ? uiText('garage.finishRouteBeforeReturn', {}, 'Finish or cancel the active route before returning this unit.')
            : companyVehicleOut
                ? uiText('action.returnVehicle', {}, 'Return Vehicle')
                : uiText('garage.noUnitOut', {}, 'No company unit checked out');
        const returnLabel = returnGarageBtn.querySelector('span');
        if (returnLabel) returnLabel.textContent = uiText('action.returnVehicle', {}, 'Return Vehicle');
    }

    if (garageToolbar) {
        const filters = [
            ['all', 'fa-layer-group', uiText('garage.filterAll', {}, 'All Units')],
            ['van', 'fa-van-shuttle', uiText('garage.filterVans', {}, 'Vans')],
            ['boxtruck', 'fa-truck', uiText('garage.filterBoxTrucks', {}, 'Box Trucks')],
            ['trailer', 'fa-truck-front', uiText('garage.filterTractors', {}, 'Tractors')]
        ];
        garageToolbar.innerHTML = filters.map(([type, icon, label]) => `
            <button type="button" class="garage-filter ${selectedGarageType === type ? 'active' : ''}" data-garage-filter="${type}" aria-pressed="${selectedGarageType === type}">
                <i class="fas ${icon}" aria-hidden="true"></i><span>${escapeHTML(label)}</span>
            </button>
        `).join('');
    }

    const visibleGarage = selectedGarageType === 'all'
        ? garage
        : garage.filter(vehicle => vehicle.type === selectedGarageType);

    if (visibleGarage.length && !visibleGarage.some(vehicle => getGarageVehicleKey(vehicle) === selectedGarageKey)) {
        selectedGarageKey = getGarageVehicleKey(visibleGarage[0]);
    }

    if (garage.length) {
        const storedCount = garage.filter(vehicle => vehicle.stored).length;
        const outCount = garage.length - storedCount;
        const lockedCount = garage.filter(vehicle => playerRank() < Number(vehicle.minRank || 1)).length;
        const summary = document.createElement('div');
        summary.className = 'garage-fleet-summary';
        summary.innerHTML = `
            <div class="garage-fleet-summary-title">
                <i class="fas fa-warehouse" aria-hidden="true"></i>
                <span><small>${uiText('garage.yourFleet', {}, 'Your Fleet')}</small><strong>${uiText('garage.units', { count: garage.length }, `${garage.length} units`)}</strong></span>
            </div>
            <div><small>${uiText('common.available', {}, 'Available')}</small><strong>${storedCount}</strong></div>
            <div><small>${uiText('garage.checkedOut', {}, 'Checked Out')}</small><strong>${outCount}</strong></div>
            <div><small>${uiText('garage.accessLocked', {}, 'Access Locked')}</small><strong>${lockedCount}</strong></div>
        `;
        garageList.appendChild(summary);
    }

    if (!visibleGarage.length && garage.length) {
        garageList.insertAdjacentHTML('beforeend', `<div class="empty-card garage-filter-empty">${escapeHTML(uiText('garage.noUnitsInClass', {}, 'No units are configured in this class.'))}</div>`);
    }

    visibleGarage.forEach(vehicle => {
        const card = document.createElement('div');
        const vehicleKey = getGarageVehicleKey(vehicle);
        card.className = `garage-card ${vehicleKey === selectedGarageKey ? 'selected' : ''}`;
        card.dataset.garageKey = vehicleKey;
        card.dataset.garageType = vehicle.type || '';
        card.tabIndex = 0;
        card.setAttribute('role', 'button');
        card.setAttribute('aria-pressed', String(vehicleKey === selectedGarageKey));
        const status = vehicle.stored ? uiText('common.available', {}, 'Available') : uiText('garage.checkedOut', {}, 'Checked Out');
        const minRank = Number(vehicle.minRank || 1);
        const locked = playerRank() < minRank;
        const image = vehicle.photo || '';
        const plate = vehicle.plate || uiText('garage.assignedOnCheckout', {}, 'Assigned on checkout');

        const displayLabel = garageDisplayLabel(vehicle.label, vehicle.type);
        card.setAttribute('aria-label', `${displayLabel}, ${status}`);
        card.innerHTML = `
            <div class="garage-card-media">
                ${image ? `<img src="${escapeHTML(image)}" alt="${escapeHTML(displayLabel)}">` : '<div class="garage-card-photo-placeholder"><i class="fas fa-truck" aria-hidden="true"></i></div>'}
                <span class="garage-status-badge ${vehicle.stored ? 'is-stored' : 'is-out'}"><i class="fas ${vehicle.stored ? 'fa-warehouse' : 'fa-road'}" aria-hidden="true"></i>${escapeHTML(status)}</span>
            </div>
            <div class="garage-card-copy">
                <small class="garage-card-type">${escapeHTML(titleFromType(vehicle.type))}</small>
                <strong>${escapeHTML(displayLabel)}</strong>
                <div class="garage-card-meta">
                    <span><i class="fas fa-id-card" aria-hidden="true"></i>${escapeHTML(plate)}</span>
                    ${locked ? `<span class="garage-card-lock"><i class="fas fa-lock" aria-hidden="true"></i>${escapeHTML(uiText('status.rankPlus', { rank: minRank }, `Rank ${minRank}+`))}</span>` : ''}
                </div>
            </div>
        `;

        garageList.appendChild(card);
    });
}

function getDispatchScrollState(tab = activeDispatchTab) {
    const panel = document.querySelector('.left-panel');
    const page = document.getElementById(`page-${tab}`);
    const previewPanel = tab === 'dispatch' ? previewContracts : previewContext;

    return {
        tab,
        panelTop: panel?.scrollTop || 0,
        pageTop: page?.scrollTop || 0,
        previewTop: previewPanel?.scrollTop || 0
    };
}

function restoreDispatchScrollState(state) {
    if (!state || state.tab !== activeDispatchTab) return;

    const applyScroll = () => {
        const panel = document.querySelector('.left-panel');
        const page = document.getElementById(`page-${state.tab}`);
        const previewPanel = state.tab === 'dispatch' ? previewContracts : previewContext;
        if (panel) panel.scrollTop = state.panelTop || 0;
        if (page) page.scrollTop = state.pageTop || 0;
        if (previewPanel) previewPanel.scrollTop = state.previewTop || 0;
    };

    applyScroll();
    if (typeof requestAnimationFrame === 'function') requestAnimationFrame(applyScroll);
}

function contractorTypeLabel(type) {
    if (type === 'trailer') return 'Tractor';
    return titleFromType(type);
}

function contractorCardPercent(value) {
    return Math.max(0, Math.min(100, Number(value) || 0));
}

function renderContractorCardFact(icon, value, className = '') {
    if (value === undefined || value === null || value === '') return '';
    return `<span class="${escapeHTML(className)}"><i class="fas ${escapeHTML(icon)}" aria-hidden="true"></i>${escapeHTML(value)}</span>`;
}

function getContractorScrollState() {
    const panel = contractorContent?.closest('.left-panel');
    const dailyList = contractorContent?.querySelector('.contractor-daily-list');
    return {
        panelTop: panel?.scrollTop || 0,
        contentTop: contractorContent?.scrollTop || 0,
        dailyType: dailyList?.dataset.contractorDailyType || '',
        dailyTop: dailyList?.scrollTop || 0
    };
}

function restoreContractorScrollState(state, dailyType) {
    if (!state) return;

    const applyScroll = () => {
        const panel = contractorContent?.closest('.left-panel');
        const dailyList = contractorContent?.querySelector('.contractor-daily-list');
        if (panel) panel.scrollTop = state.panelTop || 0;
        if (contractorContent) contractorContent.scrollTop = state.contentTop || 0;
        if (dailyList && state.dailyType === (dailyType || '')) dailyList.scrollTop = state.dailyTop || 0;
    };

    applyScroll();
    if (typeof requestAnimationFrame === 'function') requestAnimationFrame(applyScroll);
}

function renderContractor(data) {
    if (!contractorContent) return;

    const contractor = data.contractor || {};
    const scrollState = getContractorScrollState();
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
    const market = contractor.market || [];
    const activeOut = vehicles.find(vehicle => vehicle.out);
    const pickupDepots = contractor.pickupDepots || [];
    const selectedPickupDepot = getSelectedContractorPickupDepot(contractor);
    const board = getContractorBoard(contractor);
    const validContractorViews = ['contracts', 'dedicated', 'fleet'];
    if (!validContractorViews.includes(selectedContractorView)) selectedContractorView = 'contracts';
    if (selectedContractorView !== 'fleet') contractorMarketVisible = false;
    if (selectedContractorView === 'contracts') selectedContractorPanel = 'contract';
    else if (selectedContractorView === 'dedicated') selectedContractorPanel = 'daily';
    else if (contractorMarketVisible) selectedContractorPanel = 'market';
    else selectedContractorPanel = 'vehicle';
    syncContractorSelection(contractor);

    const dailyTypes = [];
    dailyRoutes.forEach(route => {
        const type = getContractorDailyRouteType(route);
        if (!dailyTypes.some(entry => entry.type === type)) {
            dailyTypes.push({ type, label: route.typeLabel || contractorTypeLabel(type) });
        }
    });

    const assignedDailyRouteKey = String(contractor.dailyRouteKey || '');
    const assignedDailyRoute = dailyRoutes.find(route => getContractorDailyRouteKey(route) === assignedDailyRouteKey);
    if (!selectedContractorDailyType && assignedDailyRoute) selectedContractorDailyType = getContractorDailyRouteType(assignedDailyRoute);
    if (!selectedContractorDailyType && activeOut) selectedContractorDailyType = activeOut.type;
    if (!dailyTypes.some(entry => entry.type === selectedContractorDailyType)) {
        selectedContractorDailyType = dailyTypes[0]?.type || null;
    }

    const filteredDailyRoutes = selectedContractorDailyType
        ? dailyRoutes.filter(route => getContractorDailyRouteType(route) === selectedContractorDailyType)
        : dailyRoutes;

    if (filteredDailyRoutes.length && !filteredDailyRoutes.some(route => getContractorDailyRouteKey(route) === String(selectedContractorDailyRouteKey || ''))) {
        const assignedInType = filteredDailyRoutes.find(route => getContractorDailyRouteKey(route) === assignedDailyRouteKey);
        selectedContractorDailyRouteKey = getContractorDailyRouteKey(assignedInType || filteredDailyRoutes[0]);
    }

    const dailyTypeHtml = dailyTypes.map(entry => `
        <button type="button" class="${entry.type === selectedContractorDailyType ? 'is-selected' : ''}" data-contractor-daily-type="${escapeHTML(entry.type)}">
            ${escapeHTML(entry.label)}
        </button>
    `).join('');

    const dailyHtml = filteredDailyRoutes.map(route => {
        const routeKey = getContractorDailyRouteKey(route);
        const selectedRouteKey = String(selectedContractorDailyRouteKey || '');
        const currentJob = dispatchData?.currentJob;
        const currentJobDailyRouteKey = String(currentJob?.contractorDailyRouteKey || '');
        const assigned = routeKey && routeKey === assignedDailyRouteKey;
        const cardSelected = selectedContractorPanel === 'daily' && selectedRouteKey === routeKey;
        const completed = assigned && contractor.dailyRouteCompleted;
        const routeActive = assigned && currentJob?.contractor && (!currentJobDailyRouteKey || currentJobDailyRouteKey === routeKey);
        const lockedByCooldown = !assigned && contractor.dailyRouteKey && contractor.dailyRouteCanChange === false;
        return `
            <button type="button" class="contractor-option compact ${cardSelected ? 'is-selected' : ''} ${routeActive ? 'is-active-route' : ''} ${route.unlocked ? '' : 'disabled'}" data-contractor-select-daily-route="${escapeHTML(routeKey)}" data-contractor-daily-route-type="${escapeHTML(getContractorDailyRouteType(route))}">
                <span class="contractor-option-main">
                    <strong>${escapeHTML(route.label || 'Route Board')}</strong>
                    <small class="contractor-option-facts">
                        ${renderContractorCardFact('fa-route', route.routeLength || route.description || 'Route pending')}
                        ${renderContractorCardFact('fa-location-dot', route.destination)}
                    </small>
                </span>
                <em>${completed ? 'DONE' : routeActive ? 'ACTIVE' : assigned ? 'ASSIGNED' : lockedByCooldown ? 'WEEKLY LOCK' : route.unlocked ? 'VIEW' : `RANK ${route.minRank || contractor.unlockRank}`}</em>
            </button>
        `;
    }).join('') || '<div class="empty-card">No dedicated routes are configured for this delivery type.</div>';

    const dailySelectorHtml = `
        <div class="contractor-daily-compact">
            <div class="contractor-daily-head">
                <div>
                    <small>${uiText('contractor.weeklyProgram', {}, 'Weekly Route Program')}</small>
                    <strong>${uiText('contractor.dedicatedAssignment', {}, 'Dedicated Assignment')}</strong>
                </div>
                <em>${escapeHTML(contractor.dailyRouteKey ? contractor.dailyRouteCompleted ? 'Completed Today' : 'Assigned' : 'Not Assigned')}</em>
            </div>
            <div class="contractor-daily-types">${dailyTypeHtml}</div>
            <div class="contractor-daily-list" data-contractor-daily-type="${escapeHTML(selectedContractorDailyType || '')}">${dailyHtml}</div>
        </div>
    `;

    const pickupSelectorHtml = activeOut && pickupDepots.length ? `
        <section class="contractor-pickup-selector" aria-label="${escapeHTML(uiText('contractor.pickupTerminal', {}, 'Pickup Terminal'))}">
            <div class="contractor-pickup-head">
                <small>${escapeHTML(uiText('contractor.pickupTerminal', {}, 'Pickup Terminal'))}</small>
                <em>${escapeHTML(activeOut.typeLabel || contractorTypeLabel(activeOut.type))}</em>
            </div>
            <div class="contractor-pickup-options">
                ${pickupDepots.map(depot => {
                    const selected = depot.key === selectedPickupDepot?.key;
                    return `
                        <button type="button" class="${selected ? 'is-selected' : ''}" data-contractor-pickup-depot="${escapeHTML(depot.key || '')}" data-contractor-pickup-type="${escapeHTML(depot.type || activeOut.type || '')}" aria-pressed="${selected}">
                            <i class="fas fa-warehouse" aria-hidden="true"></i>
                            <span>
                                <strong>${escapeHTML(depot.label || 'Freight Terminal')}</strong>
                                <small>${escapeHTML(depot.area || '')}</small>
                            </span>
                            <em>${escapeHTML(uiText('contractor.offerCount', { count: Number(depot.offerCount || 0) }, `${Number(depot.offerCount || 0)} offers`))}</em>
                        </button>
                    `;
                }).join('')}
            </div>
        </section>
    ` : `
        <section class="contractor-pickup-selector is-disabled">
            <div class="contractor-pickup-head">
                <small>${escapeHTML(uiText('contractor.pickupTerminal', {}, 'Pickup Terminal'))}</small>
            </div>
            <button type="button" class="contractor-pickup-empty" data-contractor-view="fleet">
                <i class="fas fa-truck-arrow-right" aria-hidden="true"></i>
                <span>${escapeHTML(uiText('contractor.checkoutForOffers', {}, 'Check out a private unit to view matching terminal offers.'))}</span>
            </button>
        </section>
    `;

    const fleetHtml = vehicles.length ? vehicles.map(vehicle => {
        const vehicleKey = getContractorVehicleKey(vehicle);
        const selected = selectedContractorPanel === 'vehicle' && selectedContractorVehicleId === vehicleKey;
        const image = vehicle.photo || '';
        const imageHtml = image
            ? `<img src="${escapeHTML(image)}" alt="${escapeHTML(vehicle.label || 'Contractor Vehicle')}">`
            : '<div class="contractor-vehicle-photo-placeholder"><i class="fas fa-truck"></i></div>';
        const fuel = contractorCardPercent(vehicle.fuel);
        const condition = contractorCardPercent(vehicle.condition);
        const mileage = Math.max(0, Number(vehicle.mileage) || 0);
        const mileageLabel = uiText('contractor.saleMileage', {}, 'Recorded mileage');
        return `
        <div class="contractor-vehicle-card ${selected ? 'is-selected' : ''}" data-contractor-select-vehicle="${vehicleKey}">
            <div class="contractor-vehicle-media">
                ${imageHtml}
                <span class="contractor-unit-state ${vehicle.out ? 'is-out' : 'is-stored'}">${vehicle.out ? uiText('common.out', {}, 'Out') : uiText('common.stored', {}, 'Stored')}</span>
            </div>
            <div class="contractor-vehicle-copy">
                <div class="contractor-vehicle-card-head">
                    <small>${escapeHTML(vehicle.typeLabel || contractorTypeLabel(vehicle.type))}</small>
                    <span class="contractor-vehicle-mileage" title="${escapeHTML(mileageLabel)}" aria-label="${escapeHTML(`${mileageLabel}: ${mileage.toFixed(1)} mi`)}">
                        <i class="fas fa-gauge-high" aria-hidden="true"></i>${mileage.toFixed(1)} MI
                    </span>
                </div>
                <strong>${escapeHTML(vehicle.label || 'Contractor Vehicle')}</strong>
                <div class="contractor-vehicle-plate"><i class="fas fa-id-card" aria-hidden="true"></i>${escapeHTML(vehicle.plate || 'NO PLATE')}</div>
                <div class="contractor-unit-health">
                    <span><small>FUEL</small><i><b style="width:${fuel}%"></b></i><em>${fuel}%</em></span>
                    <span><small>CONDITION</small><i><b style="width:${condition}%"></b></i><em>${condition}%</em></span>
                </div>
            </div>
        </div>
    `;
    }).join('') : '<div class="empty-card">No private vehicles owned yet.</div>';

    const emptyBoardText = activeOut
        ? uiText('contractor.noPickupContracts', {
            type: activeOut.typeLabel || contractorTypeLabel(activeOut.type),
            depot: selectedPickupDepot?.label || uiText('contractor.pickupTerminal', {}, 'pickup terminal')
        }, `No ${activeOut.typeLabel || contractorTypeLabel(activeOut.type)} contracts are available from ${selectedPickupDepot?.label || 'this terminal'} right now.`)
        : 'Spawn a private vehicle to show available contracts for that vehicle type.';

    const boardHtml = board.length ? board.map(contract => {
        const contractKey = getContractorContractKey(contract);
        const selected = selectedContractorPanel === 'contract' && selectedContractorContractKey === contractKey;
        const priorityLabel = contract.daily ? 'Daily Bonus' : contract.priorityShortLabel || contract.priorityLabel || 'Standard';
        const destinations = (Array.isArray(contract.destinations) ? contract.destinations : [contract.destination])
            .filter(destination => typeof destination === 'string' && destination.trim());
        const stopCount = Number(contract.stopCount) || destinations.length;
        const stopLabel = stopCount ? `${stopCount} stop${stopCount === 1 ? '' : 's'}` : '';
        const destinationRows = destinations.length
            ? destinations.map((destination, index) => `
                <li><b>${index + 1}</b><span>${escapeHTML(destination)}</span></li>
            `).join('')
            : `<li><b>1</b><span>${escapeHTML(contract.destination || 'Assigned destination')}</span></li>`;
        return `
        <div class="contractor-contract-card ${contract.canStart ? '' : 'disabled'} ${selected ? 'is-selected' : ''}" data-contractor-select-contract="${escapeHTML(contractKey)}">
            <div class="contractor-contract-copy">
                <div class="contractor-contract-badges">
                    <span>${escapeHTML(contract.typeLabel || contractorTypeLabel(contract.type))}</span>
                    <span>${escapeHTML(priorityLabel)}</span>
                    ${stopLabel ? `<span>${escapeHTML(stopLabel)}</span>` : ''}
                </div>
                <strong>${escapeHTML(contract.routeLabel || 'Private Freight Contract')}</strong>
                <div class="contractor-contract-pickup">
                    <small>${escapeHTML(uiText('contractor.pickup', {}, 'Pickup'))}</small>
                    <span><i class="fas fa-warehouse" aria-hidden="true"></i>${escapeHTML(contract.pickupDepotLabel || 'Pickup terminal')}</span>
                </div>
            </div>
            <div class="contractor-contract-distance">
                <small>${escapeHTML(uiText('contractor.routeLength', {}, 'Route Length'))}</small>
                <strong>${escapeHTML(contract.routeLength || 'Pending')}</strong>
            </div>
            <div class="contractor-contract-destinations">
                <small>${escapeHTML(uiText('contractor.dropLocations', {}, 'Drop Locations'))}</small>
                <ol>${destinationRows}</ol>
            </div>
            <div class="contractor-pay">
                <small>PAYOUT</small>
                <strong>${formatMoney(contract.payoutMin || 0)}-${formatMoney(contract.payoutMax || 0)}</strong>
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
    const maxOwnedVehicles = contractor.maxOwnedVehicles || ownedCount;
    const dailyStatus = contractor.dailyRouteCompleted
        ? uiText('common.done', {}, 'Done')
        : contractor.dailyRouteKey
            ? uiText('status.assigned', {}, 'Assigned')
            : uiText('common.available', {}, 'Available');
    const authorityHtml = `
        <section class="contractor-authority-bar">
            <div class="contractor-authority-identity">
                <i class="fas fa-id-card" aria-hidden="true"></i>
                <span>
                    <small>${escapeHTML(uiText('contractor.authorityTitle', {}, 'Private Carrier Authority'))}</small>
                    <strong>${escapeHTML(uiText('contractor.authorityActive', {}, 'Authority Active'))}</strong>
                </span>
            </div>
            <div><small>REP</small><strong>${Number(contractor.rep || 0)}</strong></div>
            <div><small>DAILY BONUS</small><strong>${formatMoney(contractor.dailyBonus || 0)}</strong></div>
            <div><small>${escapeHTML(uiText('contractor.fleetUsage', {}, 'Fleet Usage'))}</small><strong>${ownedCount} / ${maxOwnedVehicles}</strong></div>
        </section>
    `;
    const viewTabsHtml = `
        <div class="contractor-view-tabs" role="tablist" aria-label="${escapeHTML(uiText('contractor.authorityTitle', {}, 'Private Carrier Authority'))}">
            <button type="button" class="contractor-view-tab is-board ${selectedContractorView === 'contracts' ? 'is-active' : ''}" data-contractor-view="contracts" role="tab" aria-selected="${selectedContractorView === 'contracts'}">
                <i class="fas fa-file-contract" aria-hidden="true"></i>
                <span>
                    <strong>${escapeHTML(uiText('contractor.tabContractBoard', {}, 'Contract Board'))}</strong>
                    <small>${escapeHTML(uiText('contractor.tabContractBoardHint', {}, 'Terminal offers'))}</small>
                </span>
                <em>${board.length}</em>
            </button>
            <button type="button" class="contractor-view-tab is-dedicated ${selectedContractorView === 'dedicated' ? 'is-active' : ''}" data-contractor-view="dedicated" role="tab" aria-selected="${selectedContractorView === 'dedicated'}">
                <i class="fas fa-route" aria-hidden="true"></i>
                <span>
                    <strong>${escapeHTML(uiText('contractor.tabDedicatedRoutes', {}, 'Dedicated Routes'))}</strong>
                    <small>${escapeHTML(uiText('contractor.tabDedicatedRoutesHint', {}, 'Weekly assignment'))}</small>
                </span>
                <em title="${escapeHTML(dailyStatus)}" aria-label="${escapeHTML(dailyStatus)}"><i class="fas ${contractor.dailyRouteCompleted ? 'fa-check' : contractor.dailyRouteKey ? 'fa-thumbtack' : 'fa-circle'}" aria-hidden="true"></i></em>
            </button>
            <button type="button" class="contractor-view-tab is-fleet ${selectedContractorView === 'fleet' ? 'is-active' : ''}" data-contractor-view="fleet" role="tab" aria-selected="${selectedContractorView === 'fleet'}">
                <i class="fas fa-truck" aria-hidden="true"></i>
                <span>
                    <strong>${escapeHTML(uiText('contractor.tabPrivateFleet', {}, 'Private Fleet'))}</strong>
                    <small>${escapeHTML(uiText('contractor.tabPrivateFleetHint', {}, 'Owned equipment'))}</small>
                </span>
                <em>${ownedCount}/${maxOwnedVehicles}</em>
            </button>
        </div>
    `;
    const activeUnitHtml = `
        <button type="button" class="contractor-active-unit ${activeOut ? 'has-unit' : 'is-empty'}" data-contractor-view="fleet">
            <i class="fas ${activeOut ? 'fa-truck-fast' : 'fa-truck-arrow-right'}" aria-hidden="true"></i>
            <span>
                <small>${escapeHTML(uiText('contractor.activeUnit', {}, 'Active Unit'))}</small>
                <strong>${escapeHTML(activeOut?.label || uiText('contractor.noActiveUnit', {}, 'No Unit Checked Out'))}</strong>
                ${activeOut ? `<em>${escapeHTML(activeOut.typeLabel || contractorTypeLabel(activeOut.type))} / ${escapeHTML(activeOut.plate || 'NO PLATE')}</em>` : ''}
            </span>
            ${activeOut ? '' : `<b>${escapeHTML(uiText('common.select', {}, 'Select'))}</b>`}
        </button>
    `;
    const contractsViewHtml = `
        <div class="contractor-contracts-view">
            <div class="contractor-board-controls">
                <section class="contractor-operation-setup">
                    ${activeUnitHtml}
                    ${pickupSelectorHtml}
                </section>
                <div class="contractor-section-heading">
                    <span>
                        <small>${escapeHTML(uiText('contractor.tabContractBoard', {}, 'Contract Board'))}</small>
                        <strong>${escapeHTML(uiText('contractor.availableContracts', {}, 'Available Contracts'))}</strong>
                    </span>
                    <em>${escapeHTML(uiText('contractor.offerCount', { count: board.length }, `${board.length} offers`))}</em>
                </div>
            </div>
            <div class="contractor-board">${boardHtml}</div>
        </div>
    `;
    const dedicatedViewHtml = `
        <div class="contractor-dedicated-view">
            ${dailySelectorHtml}
        </div>
    `;
    const fleetToolbarHtml = contractorMarketVisible ? `
        <section class="contractor-fleet-toolbar">
            <span>
                <small>${escapeHTML(uiText('contractor.fleetDealer', {}, 'Fleet Dealer'))}</small>
                <strong>${escapeHTML(uiText('contractor.approvedUnits', {}, 'Approved Units'))}</strong>
                <em>${escapeHTML(uiText('garage.units', { count: market.length }, `${market.length} units`))}</em>
            </span>
            <button type="button" class="contractor-toolbar-action" data-contractor-market-toggle>
                <i class="fas fa-chevron-left" aria-hidden="true"></i>
                ${escapeHTML(uiText('contractor.backToPrivateFleet', {}, 'Back to Private Fleet'))}
            </button>
        </section>
    ` : `
        <section class="contractor-fleet-toolbar">
            <span>
                <small>${escapeHTML(uiText('contractor.activeUnit', {}, 'Active Unit'))}</small>
                <strong>${escapeHTML(activeOut?.label || uiText('contractor.noActiveUnit', {}, 'No Unit Checked Out'))}</strong>
                <em>${activeOut ? `${escapeHTML(activeOut.typeLabel || contractorTypeLabel(activeOut.type))} / ${escapeHTML(activeOut.plate || 'NO PLATE')}` : `${ownedCount} / ${maxOwnedVehicles}`}</em>
            </span>
            <div class="contractor-fleet-toolbar-actions">
                ${activeOut ? `<button type="button" class="contractor-toolbar-action" data-contractor-store-vehicle><i class="fas fa-warehouse" aria-hidden="true"></i>${escapeHTML(uiText('action.storeUnit', {}, 'Store Unit'))}</button>` : ''}
                <button type="button" class="contractor-toolbar-action is-primary" data-contractor-market-toggle>
                    <i class="fas fa-shop" aria-hidden="true"></i>
                    ${escapeHTML(uiText('contractor.fleetDealer', {}, 'Fleet Dealer'))}
                </button>
            </div>
        </section>
    `;
    const fleetViewHtml = `
        <div class="contractor-fleet-view">
            ${fleetToolbarHtml}
            ${contractorMarketVisible
                ? `<div class="contractor-market">${marketHtml}</div>`
                : `<div class="contractor-section-heading"><span><small>${escapeHTML(uiText('contractor.tabPrivateFleet', {}, 'Private Fleet'))}</small><strong>${escapeHTML(uiText('contractor.ownedUnits', {}, 'Owned Units'))}</strong></span><em>${escapeHTML(uiText('garage.units', { count: ownedCount }, `${ownedCount} units`))}</em></div><div class="contractor-fleet">${fleetHtml}</div>`}
        </div>
    `;
    const contractorViewHtml = selectedContractorView === 'dedicated'
        ? dedicatedViewHtml
        : selectedContractorView === 'fleet'
            ? fleetViewHtml
            : contractsViewHtml;

    contractorContent.innerHTML = `
        <div class="contractor-workspace" data-contractor-active-view="${escapeHTML(selectedContractorView)}">
            ${authorityHtml}
            ${viewTabsHtml}
            ${contractorViewHtml}
        </div>
    `;
    restoreContractorScrollState(scrollState, selectedContractorDailyType);
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
    syncDispatchSelect(prioritySelect);
    updatePriorityInfo();
}

function updatePriorityInfo() {
    const priority = getSelectedPriority(selectedContract);
    const mult = Number(priority.payoutMultiplier || 1.0);
    const xpMult = Number(priority.xpMultiplier || 1.0);
    const req = Number(priority.minRank || 1);
    priorityInfo.innerText = `${priority.description || uiText('label.standardRoute', {}, 'Standard route')} - ${uiText('status.rankPlus', { rank: req }, `Rank ${req}+`)} - ${Math.round(mult * 100)}% payout - ${Math.round(xpMult * 100)}% XP`;
}

function renderVehicleSelector(type) {
    const vehicles = getVehicles(type);
    vehicleSelect.innerHTML = '';

    vehicles.forEach((vehicle, index) => {
        const option = document.createElement('option');
        option.value = index + 1;
        const locked = !canUseVehicle(vehicle);
        option.disabled = locked;
        option.innerText = `${vehicle.label || `${uiText('label.vehicle', {}, 'Vehicle')} ${index + 1}`} ${locked ? `(${uiText('common.rank', {}, 'Rank')} ${vehicle.minRank})` : ''}`;
        vehicleSelect.appendChild(option);
    });

    selectedVehicleIndex = 1;
    const firstUnlocked = vehicles.findIndex(canUseVehicle);
    if (firstUnlocked >= 0) selectedVehicleIndex = firstUnlocked + 1;
    vehicleSelect.value = String(selectedVehicleIndex);
    syncDispatchSelect(vehicleSelect);

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
    reuseVehicleText.innerText = `${uiText('common.available', {}, 'Available')}: ${reuse.vehicleLabel || uiText('label.currentCompanyVehicle', {}, 'Current Company Vehicle')}`;
    vehicleSelectWrap.classList.remove('hidden');
}

function updateVehiclePreview() {
    const usingReuse = reuseVehicleCheck.checked && canReuseCurrentVehicle(selectedContract);

    if (usingReuse) {
        document.getElementById('selectedVehicleName').innerText = dispatchData.reuse.vehicleLabel || uiText('label.currentCompanyVehicle', {}, 'Current Company Vehicle');
        const img = document.getElementById('vehiclePhoto');
        img.src = '';
        img.style.display = 'none';
        vehicleSelectWrap.classList.add('hidden');
        return;
    }

    vehicleSelectWrap.classList.remove('hidden');
    const vehicle = getSelectedVehicle(selectedContract);
    document.getElementById('selectedVehicleName').innerText = vehicle.label || uiText('label.companyVehicle', {}, 'Company Vehicle');

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
        const vehicleRanks = getVehicles(type).map(entry => Number(entry.minRank || 1));
        const minimumRank = vehicleRanks.length ? Math.max(1, Math.min(...vehicleRanks)) : 1;
        const available = playerRank() >= minimumRank;
        const routeCount = Array.isArray(contract.routes) ? contract.routes.length : 0;
        const cargoLabel = contract.cargo || uiText('empty.noData', {}, 'No data');
        const freightClass = (contract.tags || [])[0] || uiText('empty.noData', {}, 'No data');
        const card = document.createElement('div');
        card.className = `contract-card ${selectedContract === type ? 'selected' : ''}`;
        card.style.setProperty('--accent', contract.cardColor || meta.accent);
        card.dataset.type = type;

        card.innerHTML = `
            <div class="contract-card-header">
                <div class="contract-card-kicker">
                    <span>${escapeHTML(meta.badge)}</span>
                    <small>${escapeHTML(uiText('status.rankPlus', { rank: minimumRank }, `Rank ${minimumRank}+`))}</small>
                </div>
                <div class="contract-card-access ${available ? 'is-available' : 'is-locked'}">
                    <i class="fas ${available ? 'fa-circle-check' : 'fa-lock'}"></i>
                    <span>${escapeHTML(available ? uiText('common.available', {}, 'Available') : uiText('status.requiresRank', { rank: minimumRank }, `Requires Rank ${minimumRank}`))}</span>
                </div>
            </div>
            <div class="contract-card-body">
                <div class="contract-card-vehicle">
                    <img class="vehicle-photo-card" src="${escapeHTML(cardImage)}" alt="${escapeHTML(vehicle.label || 'Vehicle')}">
                </div>
                <div class="contract-card-copy">
                    <div class="card-title">${escapeHTML(contract.label)}</div>
                    <div class="card-desc">${escapeHTML(contract.description)}</div>
                </div>
            </div>
            <div class="contract-card-specs">
                <div class="contract-card-spec">
                    <small><i class="fas fa-box"></i>${escapeHTML(uiText('label.cargo', {}, 'Cargo'))}</small>
                    <strong>${escapeHTML(cargoLabel)}</strong>
                </div>
                <div class="contract-card-spec">
                    <small><i class="fas fa-route"></i>${escapeHTML(uiText('label.routes', {}, 'Routes'))}</small>
                    <strong>${escapeHTML(String(routeCount))}</strong>
                </div>
                <div class="contract-card-spec">
                    <small><i class="fas fa-layer-group"></i>${escapeHTML(uiText('label.freightClass', {}, 'Freight Class'))}</small>
                    <strong>${escapeHTML(freightClass)}</strong>
                </div>
                <div class="contract-card-spec contract-card-spec-payout">
                    <small>${escapeHTML(uiText('receiver.detail.payout', {}, 'Payout'))}</small>
                    <strong>${payoutRange}</strong>
                </div>
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
    badge.innerText = priority.badge || contractMeta[type]?.badge || uiText('label.route', {}, 'ROUTE');

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

    if (name) name.innerText = assignedTrailer.label || uiText('label.routeTrailer', {}, 'Route Trailer');
    wrap.classList.remove('hidden');
}

function renderSelected(contract, type) {
    const route = getPreviewRouteData(contract, type);
    let firstDropoff = 'Selected Route';

    if (route && route.dropoffs && route.dropoffs[0]) firstDropoff = route.dropoffs[0].label;
    else if (route && route.trailerDrop) firstDropoff = route.trailerDrop.label;

    const priority = getSelectedPriority(type);
    document.getElementById('selectedType').innerText = `${titleFromType(type)} - ${priority.shortLabel || priority.label}`;
    document.getElementById('pickupText').innerText = contract.pickup?.label || uiText('label.pickupLocation', {}, 'Pickup Location');
    document.getElementById('dropoffText').innerText = firstDropoff;
    
    if (type === 'trailer') {
        const assignedTrailer = getRouteTrailer(route, priority);
        document.getElementById('cargoText').innerText = assignedTrailer ? assignedTrailer.label : `${contract.cargo || uiText('label.trailer', {}, 'Trailer')} x1`;
    } else {
        document.getElementById('cargoText').innerText = `${contract.cargo || uiText('label.cargo', {}, 'Cargo')} x${contract.requiredCargo || 1}`;
    }

    updateSelectedRouteTrailerPreview(contract, type, route, priority);
    renderRoutePreview(contract, type);
    updatePriorityInfo();
}

function openUI(data, options = {}) {
    clearTimeout(dispatchHideTimer);
    clearDispatchCleanupTimers();
    dispatchRenderSignatures = {};
    const wasHidden = app.classList.contains('hidden');
    app.classList.remove('dispatch-closing', 'dispatch-opening', 'dispatch-pre-open');

    dispatchData = data;
    configureUILocale(data);
    configureUISounds(data.config || {});
    selectedContract = 'van';
    selectedVehicleIndex = 1;
    selectedPriority = { van: 'standard', boxtruck: 'standard', trailer: 'standard' };
    clearPreviewRoute();
    if (!options.preserveTab) {
        selectedGarageKey = null;
        selectedGarageType = 'all';
        contractorMarketVisible = false;
        selectedContractorView = 'contracts';
        contractorViewScrollTop = { contracts: 0, dedicated: 0, fleet: 0 };
        selectedContractorPanel = 'vehicle';
        selectedContractorDailyRouteKey = null;
        selectedContractorDailyType = null;
        selectedContractorVehicleId = null;
        selectedContractorContractKey = null;
        selectedContractorMarketKey = null;
        selectedContractorPickupDepotByType = {};
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
    app.classList.remove('hidden');

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

    const scrollState = getDispatchScrollState();
    dispatchData = data;
    configureUILocale(data);
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
        restoreDispatchScrollState(scrollState);
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
    closeOpenDispatchSelect();
    app.classList.remove('dispatch-pre-open', 'dispatch-opening');

    if (app.classList.contains('hidden')) return;

    if (document.activeElement && typeof document.activeElement.blur === 'function') {
        document.activeElement.blur();
    }

    app.classList.add('hidden');
    app.classList.remove('dispatch-closing');
    window.stopUISounds?.();
    scheduleDispatchCleanup();
}
