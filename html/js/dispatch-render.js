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

    if (garage.length && !garage.some(vehicle => getGarageVehicleKey(vehicle) === selectedGarageKey)) {
        selectedGarageKey = getGarageVehicleKey(garage[0]);
    }

    garage.forEach(vehicle => {
        const card = document.createElement('div');
        const vehicleKey = getGarageVehicleKey(vehicle);
        card.className = `garage-card ${vehicleKey === selectedGarageKey ? 'selected' : ''}`;
        card.dataset.garageKey = vehicleKey;
        const status = vehicle.stored ? uiText('common.stored', {}, 'Stored') : uiText('common.out', {}, 'Out');
        const minRank = Number(vehicle.minRank || 1);
        const locked = playerRank() < minRank;
        const image = vehicle.photo || '';

        card.innerHTML = `
            <img src="${image}" alt="${vehicle.label || 'Vehicle'}">
            <strong>${garageDisplayLabel(vehicle.label, vehicle.type)}</strong>
            <small>${titleFromType(vehicle.type)} - ${vehicle.plate || 'NO PLATE'} - ${status}</small>
            <small class="rank-tag ${locked ? 'locked' : ''}">${locked ? uiText('status.requiresRank', { rank: minRank }, `Requires Rank ${minRank}`) : uiText('status.rankPlus', { rank: minRank }, `Rank ${minRank}+`)}</small>
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
                <div class="businesses">${(contract.businesses || []).join(' - ')}</div>
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
    clearTimeout(dispatchParkTimer);
    clearDispatchCleanupTimers();
    dispatchRenderSignatures = {};
    const wasHidden = app.classList.contains('hidden');
    app.classList.remove('dispatch-closing', 'dispatch-opening', 'dispatch-pre-open', 'dispatch-parked');

    dispatchData = data;
    configureUILocale(data);
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
