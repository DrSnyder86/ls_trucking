const contractMeta = {
    van: { number: '01', accent: '#e6ab00', badge: 'LOCAL' },
    boxtruck: { number: '02', accent: '#3f8cff', badge: 'FREIGHT' },
    trailer: { number: '03', accent: '#a263ff', badge: 'TRAILER' }
};

let freightDialogCleanupTimer = null;
let freightDialogCleanupToken = 0;

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

function createFreightButton(label, className, onClick) {
    const button = document.createElement('button');
    button.innerText = label || uiText('action.close', {}, 'Close');
    button.className = className || '';
    button.addEventListener('click', onClick);
    return button;
}

function escapeHTML(value) {
    return String(value ?? '')
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#039;');
}

function formatFreightPrintout(content = '') {
    const rawLines = String(content || '').replace(/\r/g, '').split('\n');
    const html = [];
    let activeSection = '';

    const slugSection = (value = '') => String(value)
        .toLowerCase()
        .replace(/[^a-z0-9]+/g, '-')
        .replace(/^-+|-+$/g, '');

    // All key/value printout rows use left labels with right-aligned data values.
    // This gives route summaries, manifests, and checklists a cleaner official printout layout.
    const rightAlignedSections = 'all';

    const pushSection = (title) => {
        activeSection = slugSection(title);
        html.push(`<div class="print-section print-section-${activeSection}">${escapeHTML(title)}</div>`);
    };

    for (let i = 0; i < rawLines.length; i += 1) {
        const raw = rawLines[i] || '';
        const line = raw.trim();
        const nextLine = (rawLines[i + 1] || '').trim();

        if (!line) {
            html.push('<div class="print-spacer"></div>');
            continue;
        }

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
            html.push(`<div class="print-row print-row-right print-stop-row"><span>STOP ${escapeHTML(stopNumber)}</span><strong>${escapeHTML(stopName)}</strong></div>`);
            continue;
        }

        const colonIndex = line.indexOf(':');
        if (colonIndex > 0) {
            const label = line.slice(0, colonIndex).replace(/^[-*]\s*/, '').trim();
            const value = line.slice(colonIndex + 1).trim() || '-';
            const rowClass = rightAlignedSections === 'all' || rightAlignedSections.has?.(activeSection) ? 'print-row print-row-right' : 'print-row';
            html.push(`<div class="${rowClass}"><span>${escapeHTML(label)}</span><strong>${escapeHTML(value)}</strong></div>`);
            continue;
        }

        if (/^[-*]\s+/.test(line) || /^\d+\.\s+/.test(line)) {
            const noteClass = rightAlignedSections === 'all' || rightAlignedSections.has?.(activeSection) ? 'print-note print-note-right' : 'print-note';
            html.push(`<div class="${noteClass}">${escapeHTML(line)}</div>`);
            continue;
        }

        html.push(`<div class="print-line">${escapeHTML(line)}</div>`);
    }

    return `<div class="printout-paper">${html.join('')}</div>`;
}

function showFreightDialog(data = {}) {
    if (!freightDialog) return;

    configureUILocale(data);
    cancelFreightDialogCleanup();
    freightDialog.classList.remove('dialog-summary', 'dialog-manifest', 'dialog-checklist', 'dialog-handoff');
    const dialogHeaderText = String(data.header || '').toLowerCase();
    if (dialogHeaderText.includes('summary')) {
        freightDialog.classList.add('dialog-summary');
    } else if (dialogHeaderText.includes('manifest')) {
        freightDialog.classList.add('dialog-manifest');
    } else if (dialogHeaderText.includes('checklist')) {
        freightDialog.classList.add('dialog-checklist');
    }

    freightDialogTitle.innerText = data.header || uiText('dialog.freightDispatchTitle', {}, 'Freight Dispatch');
    freightDialogContent.classList.remove('with-form');
    freightDialogContent.classList.add('printout');
    freightDialogContent.innerHTML = formatFreightPrintout(data.content || '');
    clearFreightDialogActions();

    const actions = document.getElementById('freightDialogActions');
    const mode = data.mode || 'info';

    if (mode === 'confirm') {
        actions.appendChild(createFreightButton(data.cancelLabel || uiText('action.cancel', {}, 'Cancel'), 'secondary', () => {
            playUISound('click');
            post('freightDialogResult', { confirmed: false });
        }));

        actions.appendChild(createFreightButton(data.confirmLabel || uiText('action.confirm', {}, 'Confirm'), '', () => {
            playUISound('confirm');
            post('freightDialogResult', { confirmed: true });
        }));
    } else {
        actions.appendChild(createFreightButton(data.closeLabel || uiText('action.close', {}, 'Close'), '', closeFreightDialog));
    }

    freightDialog.classList.remove('hidden');
    playUISound('confirm');
}

function showFreightCancelDialog(data = {}) {
    if (!freightDialog) return;

    configureUILocale(data);
    cancelFreightDialogCleanup();
    freightDialog.classList.remove('dialog-summary', 'dialog-manifest', 'dialog-checklist', 'dialog-handoff');
    freightDialogTitle.innerText = data.header || uiText('dialog.cancelRouteTitle', {}, 'Cancel Freight Route');
    clearFreightDialogActions();

    const repLoss = Number(data.repLoss || 0);
    const reasons = Array.isArray(data.reasons) ? data.reasons : [];

    freightDialogContent.classList.remove('printout');
    freightDialogContent.classList.add('with-form');

    const options = reasons.map((reason) => {
        const value = String(reason.value || reason.label || 'other');
        const label = String(reason.label || reason.value || 'Other');
        return `<option value="${value}">${label}</option>`;
    }).join('');

    freightDialogContent.innerHTML = `
        <div class="freight-form">
            <div class="freight-form-warning">
                ${uiText('dialog.cancelWarning', { repLoss }, `Cancelling this route will remove <strong>${repLoss}</strong> reputation.`)}
            </div>

            <label class="freight-form-label" for="freightCancelReason">${uiText('dialog.reasonForCancel', {}, 'Reason for cancel')}</label>
            <select id="freightCancelReason" class="freight-form-select">
                ${options}
            </select>

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
    }));

    actions.appendChild(createFreightButton(uiText('action.cancelRoute', {}, 'Cancel Route'), 'danger', () => {
        const reason = document.getElementById('freightCancelReason')?.value;
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
    }));

    freightDialog.classList.remove('hidden');
    playUISound('alert');
}

function showFreightHandoff(data = {}) {
    if (!freightDialog) return;

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

    freightDialog.classList.remove('dialog-summary', 'dialog-manifest', 'dialog-checklist');
    freightDialog.classList.add('dialog-handoff');
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
    }));

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
    });
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

function hideFreightDialog() {
    if (!freightDialog) return;
    freightDialog.classList.add('hidden');
    freightDialog.classList.remove('dialog-handoff');
    freightDialogContent.classList.remove('with-form');
    freightDialogContent.classList.remove('printout');
    scheduleFreightDialogCleanup();
}

function closeFreightDialog() {
    playUISound('click');
    hideFreightDialog();
    post('freightDialogClose');
}

if (freightDialog) {
    freightDialog.addEventListener('click', (event) => {
        if (event.target === freightDialog) closeFreightDialog();
    });
}

function post(name, data = {}) {
    fetch(`https://${GetParentResourceName()}/${name}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data)
    });
}
