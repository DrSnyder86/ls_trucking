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
                        <h2>${uiText('empty.noLocationSelected', {}, 'No Location Selected')}</h2>
                    </div>
                    <span class="preview-pill">STANDBY</span>
                </div>
                <p>${uiText('empty.dispatchMap', {}, 'No LSFC operating locations are available for the home map.')}</p>
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
    const repeatedDetailLabels = new Set(['type', 'street address', 'address', 'use']);
    const detailRows = details
        .filter(row => {
            const label = String(row?.label || '').trim().toLowerCase();
            const value = String(row?.value ?? '').trim();
            return value && value.toLowerCase() !== 'n/a' && !repeatedDetailLabels.has(label);
        })
        .map(row => renderPreviewInfo(row.icon || 'fa-circle-info', row.label || 'Info', row.value, row.subtext || ''))
        .join('');
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
            ${detailRows ? `<div class="dispatch-location-details">${detailRows}</div>` : ''}
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
    return vehicle.garageId || `${vehicle.type || 'vehicle'}:${Number(vehicle.index || 0)}`;
}

function getSelectedGarageVehicle() {
    const fullGarage = dispatchData?.garage || [];
    const garage = selectedGarageType === 'all'
        ? fullGarage
        : fullGarage.filter(vehicle => vehicle.type === selectedGarageType);
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

function getSelectedContractorPickupDepot(contractor) {
    const depots = contractor?.pickupDepots || [];
    const vehicleType = contractor?.pickupDepotVehicleType || getActiveContractorVehicle(contractor)?.type;
    if (!vehicleType || !depots.length) return null;

    const selectedKey = selectedContractorPickupDepotByType[vehicleType] || contractor?.defaultPickupDepotKey;
    const selected = depots.find(depot => String(depot.key || '') === String(selectedKey || '')) || depots[0];
    selectedContractorPickupDepotByType[vehicleType] = selected.key;
    return selected;
}

function getContractorBoard(contractor) {
    const pickupDepot = getSelectedContractorPickupDepot(contractor);
    const board = pickupDepot && contractor?.boardsByDepot?.[pickupDepot.key];
    return Array.isArray(board) ? board : contractor?.board || [];
}

function getPrimaryContractorBoard(contractor) {
    const board = getContractorBoard(contractor);
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
    if (!selected && contractor?.dailyRouteKey) {
        const assignedRouteKey = String(contractor.dailyRouteKey || '');
        selected = routes.find(route => getContractorDailyRouteKey(route) === assignedRouteKey);
    }
    if (!selected) selected = routes[0];
    selectedContractorDailyRouteKey = getContractorDailyRouteKey(selected);
    return selected;
}

function getSelectedContractorContract(contractor) {
    const board = getContractorBoard(contractor);
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

function renderContractorStopsOrDepot(route) {
    if (route?.pickupDepotLabel) {
        return renderPreviewMetric(uiText('contractor.pickup', {}, 'Pickup'), route.pickupDepotLabel);
    }

    if (route?.type === 'trailer' && route.trailerDepotLabel) {
        return renderPreviewMetric(uiText('contractor.pickup', {}, 'Pickup'), route.trailerDepotLabel);
    }

    return renderPreviewMetric('Stops', route?.stopCount || 0);
}

function renderContractorDailyRoutePreview(contractor, route) {
    if (!route) return '';

    const routeKey = getContractorDailyRouteKey(route);
    const assignedRouteKey = String(contractor.dailyRouteKey || '');
    const currentJob = dispatchData?.currentJob;
    const currentJobDailyRouteKey = String(currentJob?.contractorDailyRouteKey || '');
    const selected = routeKey && routeKey === assignedRouteKey;
    const completed = selected && contractor.dailyRouteCompleted;
    const hasJob = Boolean(currentJob);
    const routeActive = selected && currentJob?.contractor && (!currentJobDailyRouteKey || currentJobDailyRouteKey === routeKey);
    const lockedByCooldown = !selected && contractor.dailyRouteKey && contractor.dailyRouteCanChange === false;
    const canSelect = routeKey && route.unlocked && !selected && !hasJob && !lockedByCooldown;
    const actionText = routeActive
        ? uiText('action.routeActive', {}, 'Route Active')
        : completed
            ? uiText('common.completed', {}, 'Completed')
            : selected
                ? uiText('status.assigned', {}, 'Assigned')
                : lockedByCooldown
                    ? uiText('common.weeklyLock', {}, 'Weekly Lock')
                    : route.unlocked
                        ? uiText('action.assignDedicatedRoute', {}, 'Assign Dedicated Route')
                        : `${uiText('common.rank', {}, 'Rank')} ${route.minRank || contractor.unlockRank || 1} ${uiText('common.locked', {}, 'Locked')}`;

    return `
        <div class="route-box preview-status-card">
            <div class="preview-context-head">
                <div>
                    <small>DAILY ROUTE BOARD</small>
                    <h2>${escapeHTML(route.label || 'Dedicated Route Assignment')}</h2>
                </div>
                <span class="preview-pill ${selected ? 'green' : ''}">${escapeHTML(selected ? completed ? uiText('common.done', {}, 'Done') : uiText('status.assigned', {}, 'Assigned') : route.unlocked ? uiText('common.available', {}, 'Available') : `${uiText('common.rank', {}, 'Rank')} ${route.minRank || 1}`)}</span>
            </div>
            <p>${escapeHTML(route.description || 'Dedicated private freight assignment.')}</p>
            ${renderContractorTrailerPreview(route)}
            <div class="preview-metric-grid two">
                ${renderPreviewMetric('Type', route.typeLabel || contractorTypeLabel(route.type))}
                ${renderPreviewMetric('Priority', route.priorityShortLabel || route.priorityLabel || 'Standard')}
                ${renderContractorStopsOrDepot(route)}
                ${renderPreviewMetric('Length', route.routeLength || 'Pending')}
                ${renderPreviewMetric('Destination', route.destination || 'Assigned route')}
                ${renderPreviewMetric('Required Rank', `Rank ${route.minRank || contractor.unlockRank || 1}`)}
            </div>
            <div class="preview-action-row single">
                <button class="preview-action" data-preview-contractor-daily-route="${escapeHTML(routeKey)}" ${canSelect ? '' : 'disabled'}>
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
    const spawnLabel = hasJob ? uiText('action.routeActive', {}, 'Route Active') : vehicle.out ? uiText('action.unitOut', {}, 'Unit Out') : anotherOut ? uiText('action.unitOut', {}, 'Unit Out') : uiText('action.request', {}, 'Request');
    const image = vehicle.photo || '';

    return `
        <div class="route-box preview-status-card">
            <div class="preview-context-head">
                <div>
                    <small>SELECTED PRIVATE UNIT</small>
                    <h2>${escapeHTML(vehicle.label || 'Contractor Vehicle')}</h2>
                </div>
                <span class="preview-pill ${vehicle.out ? 'green' : ''}">${escapeHTML(vehicle.out ? uiText('common.out', {}, 'Out') : uiText('common.stored', {}, 'Stored'))}</span>
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
                    <i class="fas fa-warehouse"></i>${escapeHTML(uiText('action.storeUnit', {}, 'Store Unit'))}
                </button>
                <button class="preview-action danger" data-preview-contractor-sell-vehicle="${escapeHTML(getContractorVehicleKey(vehicle))}" data-vehicle-label="${escapeHTML(vehicle.label || 'Contractor Vehicle')}" data-vehicle-plate="${escapeHTML(vehicle.plate || 'NO PLATE')}" data-resale-price="${Number(vehicle.resalePrice || 0)}" data-original-price="${Number(vehicle.originalPrice || 0)}" data-mileage="${Number(vehicle.mileage || 0)}" ${sellDisabled ? 'disabled' : ''}>
                    <i class="fas fa-dollar-sign"></i>${escapeHTML(uiText('action.sellVehicle', {}, 'Sell Vehicle'))}
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
    const startLabel = hasJob
        ? uiText('action.routeActive', {}, 'Route Active')
        : contract.canStart
            ? contract.daily ? uiText('action.acceptDailyRoute', {}, 'Accept Daily Route') : uiText('action.acceptContract', {}, 'Accept Contract')
            : uiText('action.spawnMatchingUnit', {}, 'Spawn Matching Unit');

    return `
        <div class="route-box preview-status-card">
            <div class="preview-context-head">
                <div>
                    <small>${contract.daily ? 'DEDICATED DAILY ROUTE' : 'SELECTED PRIVATE CONTRACT'}</small>
                    <h2>${escapeHTML(contract.routeLabel || 'Private Freight Contract')}</h2>
                </div>
                <span class="preview-pill ${contract.canStart ? 'green' : ''}">${escapeHTML(contract.daily ? 'Daily' : contract.priorityShortLabel || contract.priorityLabel || 'Standard')}</span>
            </div>
            <p>${escapeHTML([contract.typeLabel || contractorTypeLabel(contract.type), contract.pickupDepotLabel, contract.destination].filter(Boolean).join(' - '))}</p>
            ${renderContractorTrailerPreview(contract)}
            <div class="preview-metric-grid two">
                ${renderPreviewMetric('Payout', `${formatMoney(contract.payoutMin || 0)}-${formatMoney(contract.payoutMax || 0)}`)}
                ${renderPreviewMetric('XP / Rep', `${contract.xp || 0} XP / ${contract.rep || 0} REP`)}
                ${renderContractorStopsOrDepot(contract)}
                ${renderPreviewMetric('Length', contract.routeLength || 'Pending')}
            </div>
            <div class="preview-action-row single">
                <button class="preview-action" data-preview-contractor-start="${Number(contract.vehicleId || 0)}" data-priority="${escapeHTML(contract.priorityKey || 'standard')}" data-route-index="${Number(contract.routeIndex || 0)}" data-daily-route-key="${escapeHTML(contract.dailyRouteKey || '')}" data-pickup-depot-key="${escapeHTML(contract.pickupDepotKey || '')}" ${canStart ? '' : 'disabled'}>
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
                <span class="preview-pill ${owned ? 'green' : ''}">${escapeHTML(owned ? uiText('common.owned', {}, 'Owned') : locked ? `${uiText('common.rank', {}, 'Rank')} ${vehicle.minRank || 1}` : formatMoney(vehicle.price || 0))}</span>
            </div>
            ${image ? `<img class="preview-vehicle-image" src="${escapeHTML(image)}" alt="${escapeHTML(vehicle.label || 'Vehicle')}">` : ''}
            <div class="preview-metric-grid two">
                ${renderPreviewMetric('Type', vehicle.typeLabel || contractorTypeLabel(vehicle.type))}
                ${renderPreviewMetric('Required Rank', `Rank ${vehicle.minRank || 1}`)}
                ${renderPreviewMetric('Price', formatMoney(vehicle.price || 0))}
                ${renderPreviewMetric('Fleet Slots', `${(contractor.vehicles || []).length} / ${contractor.maxOwnedVehicles || 0}`)}
            </div>
            <div class="preview-action-row single">
                <button
                    class="preview-action"
                    data-preview-contractor-buy-type="${escapeHTML(vehicle.type || '')}"
                    data-preview-contractor-buy-index="${Number(vehicle.index || 1)}"
                    data-vehicle-label="${escapeHTML(vehicle.label || 'Contractor Vehicle')}"
                    data-vehicle-type-label="${escapeHTML(vehicle.typeLabel || contractorTypeLabel(vehicle.type))}"
                    data-vehicle-price="${Number(vehicle.price || 0)}"
                    data-min-rank="${Number(vehicle.minRank || 1)}"
                    data-fleet-count="${Number((contractor.vehicles || []).length)}"
                    data-fleet-max="${Number(contractor.maxOwnedVehicles || 0)}"
                    ${disabled ? 'disabled' : ''}
                >
                    <i class="fas fa-key"></i>${owned ? uiText('common.owned', {}, 'Owned') : locked ? uiText('common.rankLocked', {}, 'Rank Locked') : uiText('action.purchaseVehicle', {}, 'Purchase Vehicle')}
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

        const progressLabel = `${displayProgress}%`;
        const cargoLabel = job.cargo || 'Assigned freight';
        const conditionLabel = job.cargoConditionLabel || 'Stable';

        previewContext.innerHTML = `
            <div class="route-box preview-status-card">
                <div class="preview-context-head">
                    <div>
                        <small>DISPATCH LINK</small>
                        <h2>${escapeHTML(job.id || 'Active Contract')}</h2>
                    </div>
                    <span class="preview-pill green">ACTIVE</span>
                </div>
                <p>Receiver and dock telemetry are online for this assignment.</p>
                <div class="company-progress-bar"><span style="width:${displayProgress}%"></span></div>
                <div class="preview-metric-grid two">
                    ${renderPreviewMetric('Route Progress', progressLabel)}
                    ${renderPreviewMetric('Priority', job.priorityLabel || 'Standard')}
                </div>
            </div>
            <div class="selected preview-brief-card">
                <div class="preview-card-title"><i class="fas fa-clipboard-list"></i><span>Assignment Brief</span></div>
                ${renderPreviewInfo('fa-boxes-stacked', 'Freight', cargoLabel)}
                ${renderPreviewInfo('fa-shield-halved', 'Cargo Status', conditionLabel, job.cargoConditionNote || '')}
                ${renderPreviewInfo('fa-tower-broadcast', 'Signal', 'Telemetry connected', job.lastUpdate ? `Updated ${job.lastUpdate}` : '')}
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
            <p>${uiText('empty.historyLong', {}, 'Completed route summaries will appear here after dispatch closes out a paid route.')}</p>
            </div>
        `;
        return;
    }

    const totalPayout = history.reduce((total, summary) => total + Number(summary?.payout || 0), 0);
    const onTimeCount = history.filter(summary => summary?.time?.late !== true).length;
    const cleanCount = history.filter(summary => Number(summary?.cargoCondition?.damagePercent || 0) <= 0).length;
    const exceptionCount = history.filter(summary => summary?.time?.late === true || Number(summary?.cargoCondition?.damagePercent || 0) > 0 || summary?.event?.label).length;
    previewContext.innerHTML = `
        <div class="route-box preview-status-card">
            <div class="preview-context-head">
                <div>
                    <small>CLOSEOUT ARCHIVE</small>
                    <h2>${history.length} Completed ${history.length === 1 ? 'Route' : 'Routes'}</h2>
                </div>
                <span class="preview-pill green">CURRENT</span>
            </div>
            <p>Recent dispatch records retained on this terminal.</p>
            <div class="preview-metric-grid two">
                ${renderPreviewMetric('Logged Payout', formatMoney(totalPayout))}
                ${renderPreviewMetric('On Time', `${onTimeCount} / ${history.length}`)}
                ${renderPreviewMetric('Clean Cargo', `${cleanCount} / ${history.length}`)}
                ${renderPreviewMetric('Exceptions', exceptionCount)}
            </div>
        </div>
        <div class="selected preview-brief-card">
            <div class="preview-card-title"><i class="fas fa-clock-rotate-left"></i><span>Latest Closeout</span></div>
            ${renderPreviewInfo('fa-route', 'Route', routeSummaryTitle(latest), latest.completedAt || '')}
            ${renderPreviewInfo('fa-money-bill-wave', 'Final Payout', formatMoney(latest.payout || 0), `${latest.xp || 0} XP / ${latest.rep || 0} REP`)}
        </div>
    `;
}

function buildGaragePreviewPanel() {
    const vehicle = getSelectedGarageVehicle();

    if (!vehicle) {
        previewContext.innerHTML = `
            <div class="route-box preview-status-card">
                <div class="preview-context-head">
                    <div><small>${uiText('garage.assignedFleet', {}, 'ASSIGNED COMPANY FLEET')}</small><h2>${uiText('empty.fleetDataTitle', {}, 'No Fleet Data')}</h2></div>
                    <span class="preview-pill">OFFLINE</span>
                </div>
                <p>${uiText('empty.fleetData', {}, 'No company vehicles are currently configured.')}</p>
            </div>
        `;
        return;
    }

    const minRank = Number(vehicle.minRank || 1);
    const locked = playerRank() < minRank;
    const garageState = dispatchData?.garageState || {};
    const status = vehicle.stored ? uiText('common.available', {}, 'Available') : uiText('garage.checkedOut', {}, 'Checked Out');
    const image = vehicle.photo || '';
    const plate = vehicle.plate || uiText('garage.assignedOnCheckout', {}, 'Assigned on checkout');
    const blockedByOtherUnit = garageState.blocked && vehicle.stored;
    const activeRoute = Boolean(dispatchData?.currentJob);
    const requestDisabled = locked || !vehicle.stored || blockedByOtherUnit || activeRoute;
    let requestLabel = uiText('action.request', {}, 'Request');
    if (locked) requestLabel = uiText('common.rankLocked', {}, 'Rank Locked');
    else if (!vehicle.stored) requestLabel = uiText('action.unitOut', {}, 'Unit Out');
    else if (activeRoute) requestLabel = uiText('action.routeActive', {}, 'Route Active');
    else if (blockedByOtherUnit) requestLabel = uiText('garage.otherUnitOut', {}, 'Another Unit Is Out');

    previewContext.innerHTML = `
        <div class="route-box preview-status-card">
            <div class="preview-context-head">
                <div>
                    <small>${uiText('garage.selectedUnit', {}, 'SELECTED UNIT')}</small>
                    <h2>${escapeHTML(garageDisplayLabel(vehicle.label, vehicle.type))}</h2>
                </div>
                <span class="preview-pill ${vehicle.stored ? 'green' : ''}">${escapeHTML(status)}</span>
            </div>
            ${image ? `<img class="preview-vehicle-image" src="${escapeHTML(image)}" alt="${escapeHTML(vehicle.label || 'Vehicle')}">` : ''}
            <div class="preview-metric-grid two">
                ${renderPreviewMetric(uiText('serviceBay.summary.plate', {}, 'Plate'), plate)}
                ${renderPreviewMetric(uiText('contractor.purchaseRequiredRank', {}, 'Required Rank'), uiText('status.rankPlus', { rank: minRank }, `Rank ${minRank}+`))}
                ${renderPreviewMetric(uiText('contractor.purchaseVehicleType', {}, 'Vehicle Class'), titleFromType(vehicle.type))}
                ${renderPreviewMetric(uiText('garage.access', {}, 'Access'), locked ? uiText('common.locked', {}, 'Locked') : uiText('garage.cleared', {}, 'Cleared'))}
            </div>
            <div class="preview-action-row">
                <button class="preview-action" data-preview-spawn-garage data-type="${escapeHTML(vehicle.type || '')}" data-index="${Number(vehicle.index || 1)}" ${requestDisabled ? 'disabled' : ''}>
                    <i class="fas fa-key"></i>${escapeHTML(requestLabel)}
                </button>
            </div>
        </div>
        <div class="selected preview-brief-card">
            ${renderPreviewInfo('fa-screwdriver-wrench', uiText('garage.companyMaintained', {}, 'Company Maintained'), uiText('garage.companyMaintainedDescription', {}, 'Fuel and mechanical condition are refreshed by the depot.'))}
            ${renderPreviewInfo('fa-floppy-disk', uiText('garage.savedProfile', {}, 'Saved Vehicle Profile'), vehicle.assigned ? uiText('garage.savedProfileDescription', {}, 'Plate and approved modifications are retained for this driver.') : uiText('garage.profileOnCheckout', {}, 'A plate and saved profile will be created on first checkout.'))}
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
    const player = dispatchData?.player || {};
    const contractor = dispatchData?.contractor || {};
    const rankProgress = getCompanyRankProgress(dispatchData || {});
    const routeCount = normalizeRouteHistory(dispatchData?.routeHistory || dispatchData?.lastRouteSummary).length;
    const contractorStatus = contractor.licensed ? 'Licensed' : contractor.unlocked ? 'License Available' : `Unlocks Rank ${contractor.unlockRank || 1}`;

    previewContext.innerHTML = `
        <div class="selected preview-brief-card">
            <div class="preview-card-title"><i class="fas fa-id-card-clip"></i><span>Driver Credentials</span></div>
            ${renderPreviewInfo('fa-ranking-star', 'Company Clearance', `Rank ${player.rank || 1}`, player.rankLabel || 'Company Driver')}
            ${renderPreviewInfo('fa-arrow-trend-up', 'Next Rank', rankProgress.remaining > 0 ? `${formatInteger(rankProgress.remaining)} XP required` : 'Current rank complete')}
            ${renderPreviewInfo('fa-id-badge', 'Private Authority', contractorStatus, contractor.licensed ? `${formatInteger(contractor.rep || 0)} contractor rep` : '')}
            ${renderPreviewInfo('fa-box-archive', 'Route Archive', `${routeCount} recent ${routeCount === 1 ? 'record' : 'records'}`)}
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
    document.querySelector('.left-panel')?.classList.toggle('home-map-active', tab === 'home');
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
            applyDispatchMapTransform();
            updateDispatchMapControls(zoomConfig);
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

    dispatchHome.addEventListener('wheel', event => {
        if (!dispatchHomeMap || !event.target.closest('.dispatch-map-shell')) return;
        if (event.target.closest('[data-dispatch-map-marker], [data-dispatch-map-zoom], .dispatch-home-legend')) return;

        const zoomConfig = getDispatchMapZoomConfig(dispatchData || {});
        const currentZoom = clampDispatchMapZoom(dispatchMapZoom, zoomConfig);
        const direction = event.deltaY < 0 ? 1 : -1;

        dispatchMapZoom = clampDispatchMapZoom(currentZoom + (zoomConfig.step * direction), zoomConfig);
        dispatchMapPan = clampDispatchMapPan(dispatchMapPan, dispatchMapZoom);
        applyDispatchMapTransform();
        updateDispatchMapControls(zoomConfig);
        event.preventDefault();
    }, { passive: false });

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
    const selectGarageCard = event => {
        const card = event.target.closest('.garage-card');
        if (!card || !garageList.contains(card)) return;

        if (event.type === 'keydown' && event.key !== 'Enter' && event.key !== ' ') return;
        if (event.type === 'keydown') event.preventDefault();

        playUISound('click');
        selectedGarageKey = card.dataset.garageKey || null;
        renderGarage(dispatchData || {});
        renderPreviewContextPanel();
    };

    garageList.addEventListener('click', selectGarageCard);
    garageList.addEventListener('keydown', selectGarageCard);
}

if (garageToolbar) {
    garageToolbar.addEventListener('click', event => {
        const filter = event.target.closest('[data-garage-filter]');
        if (!filter || !garageToolbar.contains(filter)) return;

        playUISound('click');
        selectedGarageType = filter.dataset.garageFilter || 'all';
        renderGarage(dispatchData || {});
        renderPreviewContextPanel();
    });
}
