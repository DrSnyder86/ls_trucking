const contractMeta = {
    van: { number: '01', accent: '#e6ab00', badge: 'LOCAL' },
    boxtruck: { number: '02', accent: '#3f8cff', badge: 'FREIGHT' },
    trailer: { number: '03', accent: '#a263ff', badge: 'TRAILER' }
};

let freightDialogCleanupTimer = null;
let freightDialogCleanupToken = 0;
let freightInspectionToken = null;
let freightDialogLocalResult = null;

function clearFreightDialogActions() {
    const actions = document.getElementById('freightDialogActions');
    if (!actions) return;
    actions.innerHTML = '';
}

function cancelFreightDialogCleanup() {
    freightDialogCleanupToken += 1;
    if (freightDialogCleanupTimer) clearTimeout(freightDialogCleanupTimer);
    freightDialogCleanupTimer = null;
}

function scheduleFreightDialogCleanup() {
    cancelFreightDialogCleanup();
    const token = freightDialogCleanupToken;
    freightDialogCleanupTimer = setTimeout(() => {
        freightDialogCleanupTimer = null;
        if (token !== freightDialogCleanupToken || !freightDialog?.classList.contains('hidden')) return;
        freightDialogContent.innerHTML = '';
        clearFreightDialogActions();
    }, 120);
}

function createFreightButton(label, className, onClick, icon = '') {
    const button = document.createElement('button');
    button.className = className || '';
    button.innerHTML = `${icon ? `<i class="fas ${icon}"></i>` : ''}<span>${escapeHTML(label || uiText('action.close', {}, 'Close'))}</span>`;
    button.addEventListener('click', onClick);
    return button;
}

function resolveFreightDialogResult(result = {}) {
    if (freightDialogLocalResult) {
        const callback = freightDialogLocalResult;
        freightDialogLocalResult = null;
        hideFreightDialog();
        callback(result);
        return;
    }

    post('freightDialogResult', result);
}

function cancelFreightDialogLocalResult() {
    if (!freightDialogLocalResult) return;
    const callback = freightDialogLocalResult;
    freightDialogLocalResult = null;
    callback({ confirmed: false });
}

function escapeHTML(value) {
    return String(value ?? '')
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#039;');
}

const freightDialogIcons = {
    info: 'fa-truck-fast',
    confirm: 'fa-circle-question',
    summary: 'fa-file-circle-check',
    manifest: 'fa-file-lines',
    checklist: 'fa-clipboard-check',
    handoff: 'fa-signature',
    cancel: 'fa-triangle-exclamation'
};

function setFreightDialogVariant(variant = 'info') {
    const normalized = freightDialogIcons[variant] ? variant : 'info';
    Object.keys(freightDialogIcons).forEach(key => freightDialog.classList.remove(`dialog-${key}`));
    freightDialog.classList.add(`dialog-${normalized}`);

    const icon = freightDialog.querySelector('.freight-dialog-logo i');
    if (icon) icon.className = `fas ${freightDialogIcons[normalized]}`;
    return normalized;
}

function formatFreightPrintout(content = '') {
    const rawLines = String(content || '').replace(/\r/g, '').split('\n');
    const groups = [];
    let activeGroup = { title: '', slug: 'overview', items: [] };

    const slugSection = (value = '') => String(value)
        .toLowerCase()
        .replace(/[^a-z0-9]+/g, '-')
        .replace(/^-+|-+$/g, '');

    const cleanText = (value = '') => String(value).replace(/\*\*/g, '').trim();

    const saveGroup = () => {
        if (activeGroup.items.length) groups.push(activeGroup);
    };

    const pushSection = (title) => {
        saveGroup();
        activeGroup = {
            title: cleanText(title),
            slug: slugSection(cleanText(title)) || 'details',
            items: []
        };
    };

    for (let i = 0; i < rawLines.length; i += 1) {
        const raw = rawLines[i] || '';
        const line = raw.trim();
        const nextLine = (rawLines[i + 1] || '').trim();

        if (!line) continue;

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
            let cargo = '';
            const nextColon = nextLine.indexOf(':');
            if (nextColon > 0) {
                const nextLabel = cleanText(nextLine.slice(0, nextColon).replace(/^[-*]\s*/, ''));
                if (/^(packages?|cargo|items?|contents)$/i.test(nextLabel)) {
                    cargo = cleanText(nextLine.slice(nextColon + 1)) || '-';
                    i += 1;
                }
            }
            activeGroup.items.push({ type: 'stop', number: stopNumber, name: stopName, cargo });
            continue;
        }

        const colonIndex = line.indexOf(':');
        if (colonIndex > 0) {
            const label = cleanText(line.slice(0, colonIndex).replace(/^[-*]\s*/, ''));
            const value = cleanText(line.slice(colonIndex + 1)) || '-';
            const normalizedValue = value.toLowerCase();
            const state = /pending|incomplete|failed|late/.test(normalizedValue)
                ? 'pending'
                : /complete|secured|verified|ready|on-time/.test(normalizedValue) ? 'complete' : '';
            activeGroup.items.push({ type: 'row', label, value, state });
            continue;
        }

        if (/^[-*]\s+/.test(line) || /^\d+\.\s+/.test(line)) {
            activeGroup.items.push({ type: 'note', value: cleanText(line.replace(/^[-*]\s+/, '')) });
            continue;
        }

        activeGroup.items.push({ type: 'line', value: cleanText(line) });
    }

    saveGroup();

    const html = groups.map(group => {
        const items = group.items.map(item => {
            if (item.type === 'stop') {
                return `
                    <div class="print-stop-entry">
                        <span>${escapeHTML(item.number)}</span>
                        <div><strong>${escapeHTML(item.name)}</strong>${item.cargo ? `<small>${escapeHTML(item.cargo)}</small>` : ''}</div>
                    </div>
                `;
            }
            if (item.type === 'row') {
                return `<div class="print-row ${item.state ? `is-${item.state}` : ''}"><span>${escapeHTML(item.label)}</span><strong>${escapeHTML(item.value)}</strong></div>`;
            }
            if (item.type === 'note') return `<div class="print-note">${escapeHTML(item.value)}</div>`;
            return `<div class="print-line">${escapeHTML(item.value)}</div>`;
        }).join('');

        return `
            <section class="print-group print-group-${escapeHTML(group.slug)}">
                ${group.title ? `<div class="print-section">${escapeHTML(group.title)}</div>` : ''}
                <div class="print-group-body">${items}</div>
            </section>
        `;
    }).join('');

    return `<div class="printout-paper">${html}</div>`;
}

function showFreightDialog(data = {}) {
    if (!freightDialog) return;
    if (!data.local) cancelFreightDialogLocalResult();
    freightInspectionToken = null;

    configureUILocale(data);
    cancelFreightDialogCleanup();
    const mode = data.mode || 'info';
    const dialogHeaderText = String(data.header || '').toLowerCase();
    const variant = data.variant
        || (dialogHeaderText.includes('summary') ? 'summary' : '')
        || (dialogHeaderText.includes('manifest') ? 'manifest' : '')
        || (dialogHeaderText.includes('checklist') ? 'checklist' : '')
        || (mode === 'confirm' ? 'confirm' : 'info');
    setFreightDialogVariant(variant);

    freightDialogTitle.innerText = data.header || uiText('dialog.freightDispatchTitle', {}, 'Freight Dispatch');
    freightDialogContent.classList.remove('with-form');
    freightDialogContent.classList.add('printout');
    freightDialogContent.innerHTML = formatFreightPrintout(data.content || '');
    clearFreightDialogActions();

    const actions = document.getElementById('freightDialogActions');
    if (mode === 'confirm') {
        actions.appendChild(createFreightButton(data.cancelLabel || uiText('action.cancel', {}, 'Cancel'), 'secondary', () => {
            playUISound('click');
            resolveFreightDialogResult({ confirmed: false });
        }, 'fa-arrow-left'));

        actions.appendChild(createFreightButton(data.confirmLabel || uiText('action.confirm', {}, 'Confirm'), data.confirmClass || '', () => {
            playUISound(data.confirmSound || 'confirm');
            resolveFreightDialogResult({ confirmed: true });
        }, data.confirmIcon || 'fa-check'));
    } else {
        actions.appendChild(createFreightButton(data.closeLabel || uiText('action.close', {}, 'Close'), '', closeFreightDialog, 'fa-xmark'));
    }

    freightDialog.classList.remove('hidden');
    playUISound(data.openSound || 'confirm');
}

function showLocalFreightConfirm(data = {}, onResult) {
    if (typeof onResult !== 'function') return;
    cancelFreightDialogLocalResult();
    freightDialogLocalResult = onResult;
    showFreightDialog({
        ...data,
        mode: 'confirm',
        local: true
    });
}

function showFreightCancelDialog(data = {}) {
    if (!freightDialog) return;
    cancelFreightDialogLocalResult();
    freightInspectionToken = null;

    configureUILocale(data);
    cancelFreightDialogCleanup();
    setFreightDialogVariant('cancel');
    freightDialogTitle.innerText = data.header || uiText('dialog.cancelRouteTitle', {}, 'Cancel Freight Route');
    clearFreightDialogActions();

    const repLoss = Number(data.repLoss || 0);
    const reasons = Array.isArray(data.reasons) ? data.reasons : [];

    freightDialogContent.classList.remove('printout');
    freightDialogContent.classList.add('with-form');

    const options = reasons.map((reason) => {
        const value = String(reason.value || reason.label || 'other');
        const label = String(reason.label || reason.value || 'Other');
        return `
            <label class="freight-reason-option">
                <input type="radio" name="freightCancelReason" value="${escapeHTML(value)}">
                <span><i class="fas fa-circle"></i>${escapeHTML(label)}</span>
            </label>
        `;
    }).join('');

    freightDialogContent.innerHTML = `
        <div class="freight-form">
            <div class="freight-form-warning">
                ${uiText('dialog.cancelWarning', { repLoss }, `Cancelling this route will remove <strong>${repLoss}</strong> reputation.`)}
            </div>

            <div class="freight-form-label">${uiText('dialog.reasonForCancel', {}, 'Reason for cancel')}</div>
            <div class="freight-reason-list" role="radiogroup" aria-label="${escapeHTML(uiText('dialog.reasonForCancel', {}, 'Reason for cancel'))}">${options}</div>

            <label class="freight-form-check">
                <input id="freightCancelConfirm" type="checkbox">
                <span>${uiText('dialog.cancelConfirm', {}, 'I understand this route will be cancelled and reputation will be lost.')}</span>
            </label>

            <div id="freightCancelError" class="freight-form-error hidden">
                ${uiText('dialog.selectCancelReason', {}, 'Select a reason and check the confirmation box before cancelling.')}
            </div>
        </div>
    `;

    const actions = document.getElementById('freightDialogActions');

    actions.appendChild(createFreightButton(uiText('action.goBack', {}, 'Go Back'), 'secondary', () => {
        playUISound('click');
        post('freightDialogResult', { confirmed: false });
    }, 'fa-arrow-left'));

    actions.appendChild(createFreightButton(uiText('action.cancelRoute', {}, 'Cancel Route'), 'danger', () => {
        const reason = document.querySelector('input[name="freightCancelReason"]:checked')?.value;
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
    }, 'fa-ban'));

    freightDialog.classList.remove('hidden');
    playUISound('alert');
}

function showFreightHandoff(data = {}) {
    if (!freightDialog) return;
    cancelFreightDialogLocalResult();
    freightInspectionToken = null;

    configureUILocale(data);
    cancelFreightDialogCleanup();
    const records = Array.isArray(data.contracts) ? data.contracts.filter(Boolean) : [];
    const mode = data.mode === 'trailer' ? 'trailer' : 'pickup';
    const signerName = String(data.signerName || uiText('label.driver', {}, 'Driver'));
    const actionLabel = mode === 'trailer'
        ? uiText('action.completeTrailerDropoff', {}, 'Complete Trailer Drop-Off')
        : uiText('action.confirmCargoPickup', {}, 'Confirm Cargo Pickup');
    const handoffType = mode === 'trailer'
        ? uiText('dialog.handoffType.proofOfDelivery', {}, 'Proof of Delivery')
        : uiText('dialog.handoffType.cargoRelease', {}, 'Cargo Release');

    setFreightDialogVariant('handoff');
    freightDialogTitle.innerText = data.header || uiText('dialog.handoffTitle', { type: handoffType }, `${handoffType} Handoff`);
    freightDialogContent.classList.remove('printout');
    freightDialogContent.classList.add('with-form');
    clearFreightDialogActions();

    const options = records.map(record => {
        const id = String(record.contractId || 'UNASSIGNED');
        return `<option value="${escapeHTML(id)}">${escapeHTML(id)} - ${escapeHTML(record.routeLabel || uiText('dialog.freightRoute', {}, 'Freight Route'))}</option>`;
    }).join('');

    freightDialogContent.innerHTML = `
        <div class="handoff-form">
            <div class="handoff-status-line">
                <span><i class="fas fa-user-tie"></i>${escapeHTML(data.pedLabel || uiText('dialog.freightClerk', {}, 'Freight Clerk'))}</span>
                <strong>${escapeHTML(handoffType)}</strong>
            </div>

            <label class="freight-form-label" for="handoffContractSelect">${uiText('dialog.selectManifest', {}, 'Select manifest')}</label>
            <select id="handoffContractSelect" class="freight-form-select" ${records.length <= 1 ? 'disabled' : ''}>
                ${options || `<option value="">${uiText('dialog.noActiveManifest', {}, 'No active manifest')}</option>`}
            </select>

            <section id="handoffManifestDetails" class="handoff-manifest-details"></section>

            <label class="freight-form-check handoff-sign-check">
                <input id="handoffSignatureConfirm" type="checkbox" ${records.length ? '' : 'disabled'}>
                <span>${uiText('dialog.handoffAuthorize', {}, 'I authorize this electronic freight handoff and certify the manifest information above.')}</span>
            </label>

            <div id="handoffSignaturePad" class="handoff-signature-pad">
                <small>AUTHORIZED SIGNATURE</small>
                <strong id="handoffSignatureName">${uiText('dialog.awaitingAuthorization', {}, 'Awaiting driver authorization')}</strong>
                <span id="handoffSignatureTime">${uiText('dialog.signaturePrompt', {}, 'Check the authorization box to sign')}</span>
            </div>

            <div id="handoffFormError" class="freight-form-error hidden">
                ${uiText('dialog.selectManifestError', {}, 'Select a manifest and authorize the electronic signature before continuing.')}
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
            if (details) details.innerHTML = `<p>${uiText('dialog.noManifestReceived', {}, 'No active freight manifest was received.')}</p>`;
            return;
        }

        const detailRows = [
            [uiText('dialog.detail.contract', {}, 'Contract'), record.contractId],
            [uiText('label.route', {}, 'Route'), record.routeLabel],
            [uiText('dialog.detail.load', {}, 'Load'), record.loadLabel],
            [uiText('dialog.detail.quantity', {}, 'Quantity'), record.quantityLabel],
            [uiText('label.vehicle', {}, 'Vehicle'), record.vehicleLabel],
            [uiText('serviceBay.summary.plate', {}, 'Plate'), record.plate],
            [uiText('dialog.detail.handoffLocation', {}, 'Handoff Location'), record.locationLabel]
        ].filter(([, value]) => value !== undefined && value !== null && value !== '');

        details.innerHTML = detailRows.map(([label, value]) => `
            <div class="handoff-detail-row">
                <span>${escapeHTML(label)}</span>
                <strong>${escapeHTML(value)}</strong>
            </div>
        `).join('');
    };

    const actions = document.getElementById('freightDialogActions');
    actions.appendChild(createFreightButton(uiText('action.goBack', {}, 'Go Back'), 'secondary', () => {
        playUISound('click');
        post('freightDialogResult', { confirmed: false });
    }, 'fa-arrow-left'));

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
    }, 'fa-signature');
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

        if (signatureName) signatureName.textContent = signed ? signerName : uiText('dialog.awaitingAuthorization', {}, 'Awaiting driver authorization');
        if (signatureTime) {
            const signedTime = new Date().toLocaleString([], { dateStyle: 'short', timeStyle: 'short' });
            signatureTime.textContent = signed
                ? uiText('dialog.signedAt', { time: signedTime }, `Electronically authorized ${signedTime}`)
                : uiText('dialog.signaturePrompt', {}, 'Check the authorization box to sign');
        }

        playUISound(signed ? 'confirm' : 'click');
    });

    renderDetails();
    freightDialog.classList.remove('hidden');
    playUISound('click');
}

window.showTrailerInspection = function (data = {}) {
    if (!freightDialog) return;
    cancelFreightDialogLocalResult();
    const opening = freightInspectionToken !== data.token;
    freightInspectionToken = data.token;
    configureUILocale(data);
    cancelFreightDialogCleanup();
    setFreightDialogVariant('checklist');
    freightDialogTitle.textContent = data.title;
    freightDialogContent.classList.remove('with-form');
    freightDialogContent.classList.add('printout');
    const icons = { complete: 'fa-circle-check', running: 'fa-spinner fa-spin', pending: 'fa-circle' };
    freightDialogContent.innerHTML = `
        <div class="trailer-inspection">
            <h2>${escapeHTML(data.trailer)}</h2>
            <div class="inspection-checks" aria-live="polite">
                ${(data.rows || []).map(row => `
                    <div class="inspection-check is-${icons[row.state] ? row.state : 'pending'}">
                        <i class="fas ${icons[row.state] || icons.pending}" aria-hidden="true"></i>
                        <span>${escapeHTML(row.label)}</span><strong>${escapeHTML(row.status)}</strong>
                    </div>
                `).join('')}
            </div>
            <p role="status">${escapeHTML(data.message)}</p>
        </div>`;
    clearFreightDialogActions();
    const actions = document.getElementById('freightDialogActions');
    actions.appendChild(createFreightButton(data.closeLabel, 'secondary', closeFreightDialog, 'fa-xmark'));
    if (data.primaryAction !== 'close') {
        const button = createFreightButton(data.primaryLabel, '', () => {
            button.disabled = true;
            post('trailerInspectionAction', { token: data.token, action: data.primaryAction });
        }, data.primaryAction === 'submit' ? 'fa-paper-plane' : 'fa-clipboard-check');
        button.disabled = data.busy === true;
        actions.appendChild(button);
    }
    freightDialog.classList.remove('hidden');
    if (opening) playUISound('click');
};

function hideFreightDialog() {
    if (!freightDialog) return;
    freightInspectionToken = null;
    freightDialog.classList.add('hidden');
    freightDialog.classList.remove('dialog-handoff');
    freightDialogContent.classList.remove('with-form');
    freightDialogContent.classList.remove('printout');
    scheduleFreightDialogCleanup();
}

function closeFreightDialog() {
    const inspectionToken = freightInspectionToken;
    playUISound('click');
    if (freightDialogLocalResult) {
        resolveFreightDialogResult({ confirmed: false });
        return;
    }
    hideFreightDialog();
    if (inspectionToken !== null) post('trailerInspectionAction', { token: inspectionToken, action: 'close' });
    else post('freightDialogClose');
}

if (freightDialog) {
    freightDialog.addEventListener('click', (event) => {
        if (event.target === freightDialog) closeFreightDialog();
    });
}

function post(name, data = {}) {
    return fetch(`https://${GetParentResourceName()}/${name}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data)
    }).catch(() => null);
}
