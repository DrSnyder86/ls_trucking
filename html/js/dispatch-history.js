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
