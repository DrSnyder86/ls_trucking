(() => {
    const root = document.getElementById('serviceBay');
    if (!root) return;

    const state = {
        open: false,
        data: null,
        page: 'service',
        cart: [],
        selected: {},
        paymentMethod: 'cash',
        processing: false,
        installProgress: null
    };

    const money = value => `$${Math.max(0, Math.floor(Number(value) || 0)).toLocaleString()}`;
    const pct = value => `${Math.max(0, Math.floor(Number(value) || 0))}%`;
    const safe = value => String(value ?? '').replace(/[&<>"']/g, char => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#039;' }[char]));
    const t = (key, params = {}, fallback = '') => (typeof uiText === 'function' ? uiText(key, params, fallback) : fallback || key);
    const selectorLabel = value => String(value ?? '').replace(/\s+(Turbo|Tires)$/i, '');
    let closeCleanupTimer = null;
    let closeCleanupToken = 0;

    function post(name, data = {}) {
        return fetch(`https://${GetParentResourceName()}/${name}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify(data)
        }).then(response => response.json().catch(() => ({}))).catch(() => ({}));
    }

    function cartKey(item) {
        if (item.kind === 'appearance' && item.key === 'extra') return `appearance:extra:${item.extraId}`;
        return `${item.kind}:${item.key}`;
    }

    function calculateCart() {
        let subtotal = 0;
        state.cart.forEach(item => { subtotal += Number(item.price) || 0; });
        const discountPercent = Number(state.data?.invoice?.discountPercent) || 0;
        const discount = Math.floor(subtotal * (discountPercent / 100));
        return { subtotal, discountPercent, discount, total: Math.max(0, subtotal - discount) };
    }

    function preview(cart = state.cart) {
        if (!state.open) return;
        post('serviceBayPreview', { cart });
    }

    function cancelCloseCleanup() {
        closeCleanupToken += 1;
        if (closeCleanupTimer) clearTimeout(closeCleanupTimer);
        closeCleanupTimer = null;
    }

    function scheduleCloseCleanup() {
        cancelCloseCleanup();
        const token = closeCleanupToken;
        closeCleanupTimer = setTimeout(() => {
            closeCleanupTimer = null;
            if (token !== closeCleanupToken || state.open) return;
            root.innerHTML = '';
        }, 120);
    }

    function hideServiceBaySurface() {
        root.classList.add('hidden');
        document.body.classList.remove('service-bay-active');
        scheduleCloseCleanup();
    }

    function previewCartItem(item) {
        const key = cartKey(item);
        const cart = state.cart.filter(existing => cartKey(existing) !== key);
        cart.push(item);
        preview(cart);
    }

    function setPage(page) {
        state.page = page;
        render({ preserveScroll: false });
    }

    function addToCart(item) {
        const key = cartKey(item);
        state.cart = state.cart.filter(existing => cartKey(existing) !== key);

        if (item.kind === 'service' && item.key === 'full') {
            state.cart = state.cart.filter(existing => !(existing.kind === 'service' && (existing.key === 'drivetrain' || existing.key === 'body')));
        }
        if (item.kind === 'service' && (item.key === 'drivetrain' || item.key === 'body')) {
            state.cart = state.cart.filter(existing => !(existing.kind === 'service' && existing.key === 'full'));
        }

        state.cart.push(item);
        render();
        preview();
    }

    function removeFromCart(key) {
        state.cart = state.cart.filter(item => cartKey(item) !== key);
        render();
        preview();
    }

    function clearCart() {
        state.cart = [];
        render();
        preview();
    }

    function cycleOption(key, direction) {
        const option = findCyclingOption(key);
        if (!option?.levels?.length) return;
        const currentIndex = Number(state.selected[key] || 0);
        const nextIndex = (currentIndex + direction + option.levels.length) % option.levels.length;
        state.selected[key] = nextIndex;
        render();
    }

    function findCyclingOption(key) {
        const upgrades = state.data?.upgradeOptions || [];
        const appearance = state.data?.appearanceOptions || [];
        return [...upgrades, ...appearance].find(option => option.key === key);
    }

    function getSelectedLevel(option) {
        const current = Number(state.selected[option.key] || 0);
        return option.levels?.[current] || option.levels?.[0];
    }

    function levelNumber(level) {
        if (!level) return 0;
        const value = Number(level.level ?? level.target ?? 0);
        return Number.isFinite(value) ? value : 0;
    }

    function optionCurrentLevel(option) {
        const value = Number(option?.current ?? 0);
        return Number.isFinite(value) ? value : 0;
    }

    function isCurrentLevel(option, level) {
        if (!option || !level) return false;
        return levelNumber(level) === optionCurrentLevel(option);
    }

    function optionActionLabel(option, level, kind) {
        if (!level) return t('common.unavailable', {}, 'Unavailable');
        if (isCurrentLevel(option, level)) return t('common.installed', {}, 'Installed');
        if (kind === 'appearance') return t('action.change', {}, 'Change');
        const current = optionCurrentLevel(option);
        const target = levelNumber(level);
        if (target <= 0) return t('action.remove', {}, 'Remove');
        if (current <= 0) return t('action.install', {}, 'Install');
        return target > current ? t('action.upgrade', {}, 'Upgrade') : t('action.downgrade', {}, 'Downgrade');
    }

    function optionActionClass(option, level, kind) {
        if (!level || isCurrentLevel(option, level)) return 'is-current';
        if (kind === 'appearance') return 'is-change';
        const current = optionCurrentLevel(option);
        const target = levelNumber(level);
        if (target <= 0 || target < current) return 'is-remove';
        return 'is-upgrade';
    }

    function renderOptionMeta(option, level, kind) {
        const selectedLabel = level?.label || t('common.unavailable', {}, 'Unavailable');
        const action = optionActionLabel(option, level, kind);
        return `
            <div class="service-bay-option-meta">
                <span><small>${safe(t('common.current', {}, 'Current'))}</small><strong>${safe(option.currentLabel || t('common.stock', {}, 'Stock'))}</strong></span>
                <span><small>${safe(t('serviceBay.meta.selected', {}, 'Selected'))}</small><strong>${safe(selectedLabel)}</strong></span>
                <span class="${safe(optionActionClass(option, level, kind))}"><small>${safe(t('serviceBay.meta.action', {}, 'Action'))}</small><strong>${safe(action)}</strong></span>
            </div>`;
    }

    let progressAnimation = null;

    function stopProgressAnimation() {
        if (progressAnimation && typeof cancelAnimationFrame === 'function') cancelAnimationFrame(progressAnimation);
        progressAnimation = null;
    }

    function setProgressBarPercent(percent) {
        const clamped = Math.max(0, Math.min(100, Number(percent) || 0));
        const fill = root.querySelector('.service-bay-install-fill');
        const pctText = root.querySelector('.service-bay-install-percent');
        if (fill) fill.style.width = `${clamped}%`;
        if (pctText) pctText.textContent = `${Math.round(clamped)}%`;
    }

    function animateInstallProgress(duration) {
        stopProgressAnimation();
        const start = performance.now();
        const total = Math.max(250, Number(duration) || 1000);
        const tick = now => {
            const percent = Math.min(100, ((now - start) / total) * 100);
            setProgressBarPercent(percent);
            if (percent < 100 && state.processing) progressAnimation = requestAnimationFrame(tick);
        };
        setProgressBarPercent(0);
        progressAnimation = requestAnimationFrame(tick);
    }

    function handleInstallProgress(payload = {}) {
        const phase = payload.phase || payload.state || 'start';
        if (phase === 'clear') {
            stopProgressAnimation();
            state.installProgress = null;
            state.processing = false;
            if (state.open) render();
            return;
        }
        if (!state.open) return;

        state.processing = true;
        state.installProgress = {
            active: true,
            label: payload.label || t('serviceBay.progress.processing', {}, 'Processing service bay work order'),
            detail: payload.detail || '',
            index: Number(payload.index) || 0,
            total: Number(payload.total) || Math.max(1, state.cart.length),
            percent: phase === 'complete' || phase === 'saving' ? 100 : Number(payload.percent) || 0,
            phase
        };
        render();

        if (phase === 'start') {
            animateInstallProgress(payload.duration);
        } else if (phase === 'complete' || phase === 'saving') {
            stopProgressAnimation();
            setProgressBarPercent(100);
        }
    }

    function renderSummary() {
        const vehicle = state.data?.vehicle || {};
        const vehicleState = state.data?.state || {};
        const installed = state.data?.installed || [];
        const summaryRows = [
            [t('serviceBay.summary.plate', {}, 'Plate'), vehicle.plate || t('common.na', {}, 'N/A')],
            [t('serviceBay.summary.engine', {}, 'Engine'), `${Math.floor((Number(vehicleState.engineHealth) || 0) / 10)}%`],
            [t('serviceBay.summary.body', {}, 'Body'), `${Math.floor((Number(vehicleState.bodyHealth) || 0) / 10)}%`],
            [t('serviceBay.summary.fuel', {}, 'Fuel'), pct(vehicleState.fuel)],
            [t('serviceBay.summary.mileage', {}, 'Mileage'), `${(Number(vehicleState.mileage) || 0).toFixed(1)} mi`],
            ...installed.map(item => [item.label, item.value])
        ];
        const columns = [summaryRows.filter((_, index) => index % 2 === 0), summaryRows.filter((_, index) => index % 2 === 1)];

        return `
            <div class="service-bay-summary">
                <div class="service-bay-summary-list">
                    ${columns.map(column => `<div class="service-bay-summary-column">${column.map(([label, value]) => `<span><small>${safe(label)}</small><strong>${safe(value)}</strong></span>`).join('')}</div>`).join('')}
                </div>
            </div>`;
    }

    function renderService() {
        const options = state.data?.serviceOptions || [];
        return `<div class="service-bay-page">${options.map(item => `
            <div class="service-bay-option service-bay-option-service">
                <div class="service-bay-option-head"><i class="fas ${safe(item.icon || 'fa-wrench')}"></i><div class="service-bay-option-copy"><strong>${safe(item.label)}</strong><p>${safe(item.description)}</p></div><div class="service-bay-service-action"><span class="service-bay-tile-price">${money(item.price)}</span><button class="service-bay-add" data-service-add="${safe(item.key)}"><i class="fas fa-plus"></i>${safe(t('action.add', {}, 'Add'))}</button></div></div>
            </div>`).join('')}</div>`;
    }

    function renderCyclingOption(option, kind) {
        const selected = getSelectedLevel(option) || {};
        const hasLevels = Array.isArray(option.levels) && option.levels.length > 0;
        const canRemove = kind === 'upgrade' && (Number(option.current || 0) > 0 || option.removable === true);
        const currentLabel = option.currentLabel || (Number(option.current || 0) > 0 ? `Stage ${option.current}` : t('common.stock', {}, 'Stock'));
        const isCurrent = hasLevels && isCurrentLevel(option, selected);
        const actionLabel = optionActionLabel(option, selected, kind);
        const description = hasLevels
            ? (selected.description || t('serviceBay.option.currentPrefix', { value: currentLabel }, `Current: ${currentLabel}`))
            : (canRemove ? t('serviceBay.option.currentPrefix', { value: currentLabel }, `Current: ${currentLabel}`) : t('serviceBay.option.noStages', {}, 'No additional stages available.'));
        const priceLabel = hasLevels && !isCurrent ? money(selected.price) : (hasLevels ? t('common.installed', {}, 'Installed') : t('common.complete', {}, 'Complete'));
        const addDisabled = !hasLevels || isCurrent;
        const selectedLabel = selected.label || t('common.select', {}, 'Select');
        const addLabel = isCurrent ? t('common.installed', {}, 'Installed') : t('action.apply', {}, 'Apply');

        return `
            <div class="service-bay-option service-bay-option-cycling ${isCurrent ? 'is-current' : ''}">
                <div class="service-bay-option-head"><i class="fas ${safe(option.icon || 'fa-wrench')}"></i><div class="service-bay-option-copy"><strong>${safe(option.label)}</strong><p>${safe(description)}</p></div><span class="service-bay-tile-price ${isCurrent || !hasLevels ? 'is-muted' : ''}">${safe(priceLabel)}</span></div>
                ${hasLevels ? renderOptionMeta(option, selected, kind) : ''}
                <div class="service-bay-option-footer service-bay-option-footer-cycle">
                    ${hasLevels ? `<div class="service-bay-cycle"><button data-cycle="${safe(option.key)}" data-dir="-1"><i class="fas fa-chevron-left"></i></button><span title="${safe(selectedLabel)}">${safe(selectorLabel(selectedLabel))}</span><button data-cycle="${safe(option.key)}" data-dir="1"><i class="fas fa-chevron-right"></i></button></div>` : `<span class="service-bay-current">${safe(currentLabel)}</span>`}
                    <div class="service-bay-option-actions">
                        ${canRemove ? `<button class="service-bay-remove" data-cycle-remove="${safe(option.key)}" data-kind="${kind}"><i class="fas fa-rotate-left"></i>${safe(t('action.remove', {}, 'Remove'))}</button>` : ''}
                        ${kind === 'appearance' && hasLevels ? `<button class="service-bay-preview" data-cycle-preview="${safe(option.key)}" data-kind="${kind}" ${isCurrent ? 'disabled' : ''}><i class="fas fa-eye"></i>${safe(t('action.preview', {}, 'Preview'))}</button>` : ''}
                        ${hasLevels ? `<button class="service-bay-add" data-cycle-add="${safe(option.key)}" data-kind="${kind}" title="${safe(actionLabel)}" ${addDisabled ? 'disabled' : ''}><i class="fas ${isCurrent ? 'fa-check' : 'fa-plus'}"></i>${safe(addLabel)}</button>` : ''}
                    </div>
                </div>
            </div>`;
    }

    function renderUpgrades() {
        const options = state.data?.upgradeOptions || [];
        if (!options.length) return `<div class="service-bay-empty">${safe(t('serviceBay.empty.upgrades', {}, 'No upgrade options are available for this vehicle.'))}</div>`;
        return `<div class="service-bay-page">${options.map(option => renderCyclingOption(option, 'upgrade')).join('')}</div>`;
    }

    function renderAppearance() {
        const options = state.data?.appearanceOptions || [];
        const extras = state.data?.extraOptions || [];
        const optionHtml = options.map(option => renderCyclingOption(option, 'appearance')).join('');
        const extraHtml = extras.map(item => `
            <div class="service-bay-option">
                <div class="service-bay-option-head"><i class="fas ${safe(item.icon || 'fa-puzzle-piece')}"></i><div class="service-bay-option-copy"><strong>${safe(item.label)}</strong><p>${safe(item.description)}</p></div><span class="service-bay-tile-price">${money(item.price)}</span></div>
                <div class="service-bay-option-footer service-bay-option-footer-simple"><div class="service-bay-option-actions"><button class="service-bay-preview" data-extra-preview="${Number(item.extraId)}"><i class="fas fa-eye"></i>${safe(t('action.preview', {}, 'Preview'))}</button><button class="service-bay-add" data-extra-add="${Number(item.extraId)}"><i class="fas ${item.target ? 'fa-plus' : 'fa-minus'}"></i>${safe(item.target ? t('action.install', {}, 'Install') : t('action.remove', {}, 'Remove'))}</button></div></div>
            </div>`).join('');
        return `<div class="service-bay-page">${optionHtml}${extraHtml || (!optionHtml ? `<div class="service-bay-empty">${safe(t('serviceBay.empty.appearance', {}, 'No appearance options are available for this vehicle.'))}</div>` : '')}</div>`;
    }

    function renderInstallProgress() {
        const progress = state.installProgress;
        if (!progress?.active) return '';
        const indexText = progress.index && progress.total ? `${progress.index}/${progress.total}` : t('serviceBay.cart.workOrder', {}, 'Work Order').toUpperCase();
        const phaseLabel = progress.phase === 'saving' ? t('common.finalizing', {}, 'Finalizing') : t('common.installing', {}, 'Installing');
        return `
            <div class="service-bay-install-progress">
                <div class="service-bay-install-head"><small>${safe(phaseLabel)}</small><strong>${safe(indexText)}</strong></div>
                <div class="service-bay-install-label">${safe(progress.label)}</div>
                <div class="service-bay-install-track"><span class="service-bay-install-fill" style="width:${Math.max(0, Math.min(100, Number(progress.percent) || 0))}%"></span></div>
                <div class="service-bay-install-foot"><span>${safe(progress.detail || t('serviceBay.progress.workInProgress', {}, 'Service bay work in progress'))}</span><b class="service-bay-install-percent">${Math.round(Number(progress.percent) || 0)}%</b></div>
            </div>`;
    }

    function renderCart() {
        const totals = calculateCart();
        const paymentLabel = state.paymentMethod === 'bank' ? t('common.bankAccount', {}, 'Bank Account') : t('common.cashAccount', {}, 'Cash Account');
        const itemCount = state.cart.length;
        const itemCountLabel = itemCount === 1
            ? t('serviceBay.cart.item', { count: itemCount }, '1 item')
            : t('serviceBay.cart.items', { count: itemCount }, `${itemCount} items`);
        const items = state.cart.length
            ? state.cart.map(item => `<div class="service-bay-cart-item"><span><b>${safe(item.label)}</b><small>${safe(item.detail || (item.remove ? t('serviceBay.cart.removeStock', {}, 'Remove / restore stock') : t('serviceBay.cart.defaultDetail', {}, 'Service bay work')))}</small></span><strong>${money(item.price)}</strong><button data-cart-remove="${safe(cartKey(item))}" title="${safe(t('serviceBay.cart.removeTitle', {}, 'Remove item'))}"><i class="fas fa-xmark"></i></button></div>`).join('')
            : `<div class="service-bay-empty">${safe(t('serviceBay.cart.empty', {}, 'No work order items selected.'))}</div>`;

        return `
            <div class="service-bay-cart">
                <div class="service-bay-cart-head"><small>${safe(t('serviceBay.cart.workOrder', {}, 'Work Order'))}</small><span>${safe(itemCountLabel)}</span></div>
                ${renderInstallProgress()}
                <div class="service-bay-cart-list">${items}</div>
                <div class="service-bay-total">
                    <div><span>${safe(t('serviceBay.cart.subtotal', {}, 'Subtotal'))}</span><b>${money(totals.subtotal)}</b></div>
                    <div><span>${safe(t('serviceBay.cart.repDiscount', { percent: pct(totals.discountPercent) }, `Rep discount ${pct(totals.discountPercent)}`))}</span><b>-${money(totals.discount)}</b></div>
                    <div><span>${safe(paymentLabel)}</span><strong>${money(totals.total)}</strong></div>
                </div>
                <div class="service-bay-payment"><button class="${state.paymentMethod === 'cash' ? 'active' : ''}" data-payment="cash" ${state.processing ? 'disabled' : ''}><i class="fas fa-money-bill-wave"></i>${safe(t('action.cash', {}, 'Cash'))}</button><button class="${state.paymentMethod === 'bank' ? 'active' : ''}" data-payment="bank" ${state.processing ? 'disabled' : ''}><i class="fas fa-building-columns"></i>${safe(t('action.bank', {}, 'Bank'))}</button></div>
                <div class="service-bay-pay"><button data-checkout ${state.cart.length && !state.processing ? '' : 'disabled'}><i class="fas fa-credit-card"></i>${safe(state.processing ? t('action.processing', {}, 'Processing') : t('action.payInvoice', {}, 'Pay Invoice'))}</button><button data-clear-cart ${state.cart.length && !state.processing ? '' : 'disabled'}><i class="fas fa-trash-can"></i>${safe(t('action.clear', {}, 'Clear'))}</button></div>
            </div>`;
    }

    function renderPage() {
        if (state.page === 'upgrades') return renderUpgrades();
        if (state.page === 'appearance') return renderAppearance();
        return renderService();
    }

    function render(options = {}) {
        if (!state.data) return;
        const preserveScroll = options.preserveScroll !== false;
        const previousScroll = preserveScroll ? (root.querySelector('.service-bay-options-scroll')?.scrollTop || 0) : 0;
        const vehicle = state.data.vehicle || {};
        root.innerHTML = `
            <div class="service-bay-panel${state.processing ? ' service-bay-processing' : ''}">
                <div class="service-bay-header">
                    <div class="service-bay-title"><i class="fas fa-screwdriver-wrench service-bay-title-icon"></i><div><small>${safe(t('serviceBay.title', {}, 'LSFC Service Bay'))}</small><strong>${safe(vehicle.label || t('serviceBay.vehicleFallback', {}, 'LSFC Vehicle'))}</strong></div></div>
                    <button class="service-bay-close" data-close-service><i class="fas fa-xmark"></i></button>
                </div>
                <div class="service-bay-body">
                    ${renderSummary()}
                    <p class="service-bay-hint">${safe(t('serviceBay.hint', {}, 'Left-click and drag to rotate the camera. Use the mouse wheel to zoom while reviewing work.'))}</p>
                    <div class="service-bay-tabs">
                        <button class="${state.page === 'service' ? 'active' : ''}" data-page="service"><i class="fas fa-screwdriver-wrench"></i> ${safe(t('serviceBay.tab.service', {}, 'Service'))}</button>
                        <button class="${state.page === 'upgrades' ? 'active' : ''}" data-page="upgrades"><i class="fas fa-gauge-high"></i> ${safe(t('serviceBay.tab.upgrades', {}, 'Upgrades'))}</button>
                        <button class="${state.page === 'appearance' ? 'active' : ''}" data-page="appearance"><i class="fas fa-spray-can-sparkles"></i> ${safe(t('serviceBay.tab.appearance', {}, 'Appearance'))}</button>
                    </div>
                    <div class="service-bay-options-scroll">
                        ${renderPage()}
                    </div>
                    ${renderCart()}
                </div>
            </div>`;

        const restoreScroll = () => {
            const scrollEl = root.querySelector('.service-bay-options-scroll');
            if (scrollEl) scrollEl.scrollTop = previousScroll;
        };
        if (preserveScroll && typeof requestAnimationFrame === 'function') {
            requestAnimationFrame(restoreScroll);
        } else if (preserveScroll) {
            setTimeout(restoreScroll, 0);
        }
    }

    function open(payload) {
        cancelCloseCleanup();
        if (typeof configureUILocale === 'function') configureUILocale(payload || {});
        state.open = true;
        state.data = payload || {};
        state.page = 'service';
        state.cart = [];
        state.selected = {};
        state.paymentMethod = state.data?.invoice?.paymentMethod || 'cash';
        state.processing = false;
        state.installProgress = null;
        stopProgressAnimation();
        [...(state.data.upgradeOptions || []), ...(state.data.appearanceOptions || [])].forEach(option => {
            const levels = option.levels || [];
            let index = levels.findIndex(level => Number(level.level) > Number(option.current || 0));
            if (index < 0) index = 0;
            state.selected[option.key] = index;
        });
        root.classList.remove('hidden');
        document.body.classList.add('service-bay-active');
        render({ preserveScroll: false });
    }

    function close(restore = true) {
        if (!state.open || state.processing) return;
        stopProgressAnimation();
        state.open = false;
        state.data = null;
        state.cart = [];
        state.processing = false;
        state.installProgress = null;
        hideServiceBaySurface();
        post('serviceBayClose', { restore });
    }

    root.addEventListener('click', event => {
        const closeButton = event.target.closest('[data-close-service]');
        if (closeButton) {
            close(true);
            return;
        }

        if (state.processing) return;

        const pageButton = event.target.closest('[data-page]');
        if (pageButton) {
            setPage(pageButton.dataset.page || 'service');
            return;
        }

        const serviceButton = event.target.closest('[data-service-add]');
        if (serviceButton) {
            const item = (state.data?.serviceOptions || []).find(option => option.key === serviceButton.dataset.serviceAdd);
            if (item) addToCart({ kind: 'service', key: item.key, label: item.label, price: item.price });
            return;
        }

        const cycleButton = event.target.closest('[data-cycle]');
        if (cycleButton) {
            cycleOption(cycleButton.dataset.cycle, Number(cycleButton.dataset.dir) || 1);
            return;
        }

        const cycleRemove = event.target.closest('[data-cycle-remove]');
        if (cycleRemove) {
            const option = findCyclingOption(cycleRemove.dataset.cycleRemove);
            if (!option) return;
            addToCart({ kind: 'upgrade', key: option.key, label: `${t('action.remove', {}, 'Remove')} ${option.label}`, detail: t('common.stock', {}, 'Stock'), target: 0, remove: true, price: 0 });
            return;
        }

        const cyclePreview = event.target.closest('[data-cycle-preview]');
        if (cyclePreview) {
            const option = findCyclingOption(cyclePreview.dataset.cyclePreview);
            const level = option && getSelectedLevel(option);
            if (!option || !level) return;
            if (isCurrentLevel(option, level)) return;
            previewCartItem({
                kind: cyclePreview.dataset.kind,
                key: option.key,
                label: option.label,
                detail: level.label,
                target: level.level,
                mode: level.mode,
                price: 0
            });
            return;
        }

        const cycleAdd = event.target.closest('[data-cycle-add]');
        if (cycleAdd) {
            const option = findCyclingOption(cycleAdd.dataset.cycleAdd);
            const level = option && getSelectedLevel(option);
            if (!option || !level) return;
            if (isCurrentLevel(option, level)) return;
            addToCart({
                kind: cycleAdd.dataset.kind,
                key: option.key,
                label: option.label,
                detail: level.label,
                target: level.level,
                mode: level.mode,
                price: level.price
            });
            return;
        }

        const extraPreview = event.target.closest('[data-extra-preview]');
        if (extraPreview) {
            const extraId = Number(extraPreview.dataset.extraPreview);
            const item = (state.data?.extraOptions || []).find(option => Number(option.extraId) === extraId);
            if (item) {
                previewCartItem({ kind: 'appearance', key: 'extra', extraId, target: item.target, label: item.label, detail: item.target ? t('action.install', {}, 'Install') : t('action.remove', {}, 'Remove'), price: 0 });
            }
            return;
        }

        const extraButton = event.target.closest('[data-extra-add]');
        if (extraButton) {
            const extraId = Number(extraButton.dataset.extraAdd);
            const item = (state.data?.extraOptions || []).find(option => Number(option.extraId) === extraId);
            if (item) {
                addToCart({ kind: 'appearance', key: 'extra', extraId, target: item.target, label: item.label, detail: item.target ? t('action.install', {}, 'Install') : t('action.remove', {}, 'Remove'), price: item.price });
            }
            return;
        }

        const removeButton = event.target.closest('[data-cart-remove]');
        if (removeButton) {
            removeFromCart(removeButton.dataset.cartRemove);
            return;
        }

        const paymentButton = event.target.closest('[data-payment]');
        if (paymentButton) {
            state.paymentMethod = paymentButton.dataset.payment || 'cash';
            render();
            return;
        }

        const clearButton = event.target.closest('[data-clear-cart]');
        if (clearButton) {
            clearCart();
            return;
        }

        const checkoutButton = event.target.closest('[data-checkout]');
        if (checkoutButton && state.cart.length && !state.processing) {
            state.processing = true;
            state.installProgress = {
                active: true,
                label: t('serviceBay.progress.preparing', {}, 'Preparing service bay work order'),
                detail: t('serviceBay.progress.waitingTech', {}, 'Waiting for technician assignment'),
                index: 0,
                total: state.cart.length,
                percent: 0,
                phase: 'prepare'
            };
            render();
            post('serviceBayCheckout', { cart: state.cart, paymentMethod: state.paymentMethod }).then(result => {
                if (result?.success) {
                    stopProgressAnimation();
                    state.open = false;
                    state.data = null;
                    state.cart = [];
                    state.processing = false;
                    state.installProgress = null;
                    hideServiceBaySurface();
                } else {
                    stopProgressAnimation();
                    state.processing = false;
                    state.installProgress = null;
                    render();
                }
            });
        }
    });

    root.addEventListener('contextmenu', event => {
        if (state.open) event.preventDefault();
    });

    document.addEventListener('keydown', event => {
        if (!state.open || event.key !== 'Escape') return;
        event.preventDefault();
        event.stopPropagation();
        close(true);
    });

    window.addEventListener('message', event => {
        const data = event.data || {};
        if (data.action === 'serviceBayOpen') open(data.data || {});
        if (data.action === 'serviceBayInstallProgress') handleInstallProgress(data);
        if (data.action === 'serviceBayClose') {
            state.open = false;
            state.data = null;
            state.cart = [];
            state.processing = false;
            state.installProgress = null;
            stopProgressAnimation();
            hideServiceBaySurface();
        }
    });
})();
