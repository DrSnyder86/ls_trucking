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
    const adjustments = routeSummaryAdjustments(summary);

    if (Number(summary.mileageBonus || 0) > 0) {
        payoutRows.push(
            ['Contract Base', formatMoney(summary.contractBasePayout || 0)],
            ['Mileage Bonus', `${formatMoney(summary.mileageBonus)} (${Number(summary.routeMiles || 0).toFixed(1)} mi @ ${formatMoney(summary.mileageRate || 0)}/mi)`]
        );
    } else {
        payoutRows.push(['Base Pay', formatMoney(summary.basePayout || summary.payout || 0)]);
    }

    if (adjustments !== 'None') payoutRows.push(['Adjustments', adjustments]);
    if (summary.contractorDailyBonus && Number(summary.contractorDailyBonus) > 0) {
        payoutRows.push(['Daily Bonus', formatMoney(summary.contractorDailyBonus)]);
    }

    payoutRows.push(['Final Payout', formatMoney(summary.payout || 0)]);
    payoutRows.push(['Driver Credit', `${summary.xp || 0} XP / ${summary.rep || 0} Rep`]);

    const routeRows = [
        ['Route', routeSummaryTitle(summary)],
        ['Load', summary.priorityLabel || 'Standard'],
        ['Contents', routeSummaryContents(summary)],
        ['Vehicle', summary.vehicleLabel || 'Company Vehicle'],
        ['Distance', summary.routeLength || 'N/A']
    ];

    if (Number(summary.totalStops || 0) > 0 || Number(summary.requiredCargo || 0) > 0) {
        routeRows.push(['Stops / Cargo', `${summary.totalStops || 0} stops / ${summary.deliveredCargo || 0} of ${summary.requiredCargo || 0}`]);
    }

    if (summary.contractType === 'trailer' && summary.safeSpeed) {
        routeRows.push(['Safe Speed', `${Math.floor(Number(summary.safeSpeed))} MPH`]);
    }

    const exceptionRows = [];
    if (isLateRouteSummary(summary)) exceptionRows.push(['Timing', timeData.label || 'Late delivery']);
    if (!isDamageFreeRouteSummary(summary) && summary.cargoCondition?.label) {
        exceptionRows.push(['Cargo Condition', summary.cargoCondition.label]);
    }
    if (!isDamageFreeRouteSummary(summary) && summary.cargoCondition?.note) {
        exceptionRows.push(['Condition Notes', summary.cargoCondition.note]);
    }
    if (summary.contractType === 'trailer' && Number(summary.damagePercent || 0) > 0) {
        exceptionRows.push(['Trailer Damage', `${Math.floor(Number(summary.damagePercent || 0))}%`]);
    }
    if (summary.randomEvent?.label && String(summary.randomEvent.label).toLowerCase() !== 'none') {
        exceptionRows.push(['Dispatch Event', summary.randomEvent.label]);
        if (summary.randomEvent.description) exceptionRows.push(['Event Details', summary.randomEvent.description]);
    }

    const sections = [
        {
            key: 'assignment',
            title: 'Assignment',
            rows: [
                ['Driver', summary.driverName || 'Driver'],
                ['Type', titleFromType(summary.contractType)],
                ['Completed', summary.completedAt || 'N/A']
            ]
        },
        {
            key: 'route',
            title: 'Route & Equipment',
            rows: routeRows
        },
        {
            key: 'timing',
            title: 'Timing',
            rows: [
                ['Estimated', formatSeconds(timeData.estimatedSeconds || summary.estimatedSeconds || 0)],
                ['Completed In', formatSeconds(timeData.elapsedSeconds || 0)],
                ['Result', timeData.label || 'Complete']
            ]
        },
        {
            key: 'exceptions',
            title: 'Exceptions',
            rows: exceptionRows
        },
        {
            key: 'settlement',
            title: 'Settlement',
            rows: payoutRows
        }
    ];

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
        sections.splice(sections.length - 1, 0, { key: 'handoff', title: 'Handoff Record', rows: paperworkRows });
    }

    return sections;
}

function routeSummaryValueVisible(value) {
    if (value === null || value === undefined || value === '') return false;
    const normalized = String(value).trim().toLowerCase();
    return normalized !== 'n/a' && normalized !== 'none' && normalized !== '-';
}

function renderRouteSummarySection(section = {}) {
    const rows = (section.rows || [])
        .filter(([, value]) => routeSummaryValueVisible(value))
        .map(([label, value]) => `
            <div class="summary-print-row ${label === 'Final Payout' ? 'is-total' : ''}">
                <span>${escapeHTML(label)}</span>
                <strong>${escapeHTML(value)}</strong>
            </div>
        `).join('');

    if (!rows) return '';

    return `
        <section class="summary-print-section summary-print-section-${escapeHTML(section.key || 'details')}">
            <h3>${escapeHTML(section.title)}</h3>
            <div class="summary-print-table">${rows}</div>
        </section>
    `;
}

function renderRouteSummaryPrintout(summary = {}) {
    const sections = routeSummarySections(summary);
    const byKey = key => sections.find(section => section.key === key);
    const assignment = renderRouteSummarySection(byKey('assignment'));
    const route = renderRouteSummarySection(byKey('route'));
    const timing = renderRouteSummarySection(byKey('timing'));
    const exceptions = renderRouteSummarySection(byKey('exceptions'));
    const handoff = renderRouteSummarySection(byKey('handoff'));
    const settlement = renderRouteSummarySection(byKey('settlement'));
    const noExceptions = !exceptions
        ? `<div class="summary-print-clear"><i class="fas fa-circle-check"></i><span><strong>No Exceptions</strong>Freight received without a reported delay, damage claim, or dispatch event.</span></div>`
        : exceptions;

    return `
        <div class="route-summary-printout">
            <div class="summary-print-header">
                <div>
                    <small>LOS SANTOS FREIGHT CO.</small>
                    <strong>Route Completion Report</strong>
                </div>
                <div class="summary-print-stamp">
                    <span>Closed</span>
                    <strong>${escapeHTML(summary.contractId || 'N/A')}</strong>
                </div>
            </div>
            <div class="summary-print-grid summary-print-grid-primary">${assignment}${route}</div>
            <div class="summary-print-grid summary-print-grid-secondary">${timing}${noExceptions}</div>
            ${handoff}
            ${settlement}
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
