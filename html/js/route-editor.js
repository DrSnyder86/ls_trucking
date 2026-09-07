(() => {
    const root = document.getElementById('routeEditor');
    const panel = document.getElementById('routeEditorPanel');
    if (!root || !panel) return;

    let editorState = null;
    let discardArmed = false;
    let discardTimer = null;
    let openRouteEditorSelect = null;
    let routeEditorSelectId = 0;

    const escape = (value) =>
        String(value ?? '')
            .replaceAll('&', '&amp;')
            .replaceAll('<', '&lt;')
            .replaceAll('>', '&gt;')
            .replaceAll('"', '&quot;')
            .replaceAll("'", '&#039;');

    const number = (value, digits = 3) => {
        const parsed = Number(value);
        return Number.isFinite(parsed) ? parsed.toFixed(digits) : (0).toFixed(digits);
    };

    const routeEditorPost = (name, data = {}) => {
        const resource = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'ls_trucking';
        return fetch(`https://${resource}/${name}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify(data)
        }).catch(() => null);
    };

    const iconButton = (action, icon, title, extra = '', disabled = false) => `
        <button type="button" class="route-editor-icon-button" data-route-editor-action="${action}"
            title="${escape(title)}" aria-label="${escape(title)}" ${extra} ${disabled ? 'disabled' : ''}>
            <i class="fas ${icon}"></i>
        </button>`;

    const pointActionButton = (action, icon, label, title, extra = '') => `
        <button type="button" class="route-editor-point-action" data-route-editor-action="${action}"
            title="${escape(title)}" aria-label="${escape(title)}" ${extra}>
            <i class="fas ${icon}"></i><span>${escape(label)}</span>
        </button>`;

    const catalogOptions = (items, selected, placeholder = '', describe = null) => {
        const options = [];
        if (placeholder) options.push(`<option value="" data-label="${escape(placeholder)}">${escape(placeholder)}</option>`);
        (items || []).forEach((item) => {
            const value = item.key ?? item.index ?? '';
            const label = item.label || value;
            const suffix = !describe && item.stops ? ` | ${item.stops} point${Number(item.stops) === 1 ? '' : 's'}` : '';
            const displayLabel = label + suffix;
            const description = typeof describe === 'function' ? describe(item) : '';
            const fallbackLabel = description ? `${displayLabel} - ${description}` : displayLabel;
            options.push(
                `<option value="${escape(value)}" data-label="${escape(displayLabel)}" data-description="${escape(description)}" ${String(value) === String(selected ?? '') ? 'selected' : ''}>${escape(fallbackLabel)}</option>`
            );
        });
        return options.join('');
    };

    const trailerDescription = (item) => [item.model, item.contents].filter(Boolean).join(' | ');
    const configuredRouteDescription = (item) => {
        const points = Number(item.stops) || 0;
        return [item.routeLength, points ? `${points} route point${points === 1 ? '' : 's'}` : ''].filter(Boolean).join(' | ');
    };

    function closeRouteEditorSelect({ focusTrigger = false, removeMenu = false } = {}) {
        const controller = openRouteEditorSelect;
        if (!controller) return;

        controller.control.classList.remove('is-open');
        controller.trigger.setAttribute('aria-expanded', 'false');
        controller.menu.hidden = true;
        if (removeMenu) controller.menu.remove();
        if (focusTrigger && controller.trigger.isConnected) controller.trigger.focus();
        openRouteEditorSelect = null;
    }

    function positionRouteEditorSelect(controller) {
        const rect = controller.trigger.getBoundingClientRect();
        const viewportMargin = 8;
        const menuGap = 5;
        const viewportWidth = Math.max(0, window.innerWidth - viewportMargin * 2);
        const preferredWidth = controller.hasDescriptions ? Math.max(rect.width, 320) : Math.max(rect.width, 210);
        const width = Math.min(preferredWidth, viewportWidth);
        const left = Math.min(Math.max(viewportMargin, rect.left), window.innerWidth - width - viewportMargin);
        const availableBelow = Math.max(0, window.innerHeight - rect.bottom - menuGap - viewportMargin);
        const availableAbove = Math.max(0, rect.top - menuGap - viewportMargin);
        const openAbove = availableBelow < 150 && availableAbove > availableBelow;
        const availableHeight = openAbove ? availableAbove : availableBelow;
        const maxHeight = Math.max(80, Math.min(280, availableHeight));

        controller.menu.style.width = `${width}px`;
        controller.menu.style.left = `${left}px`;
        controller.menu.style.maxHeight = `${maxHeight}px`;
        const menuHeight = Math.min(controller.menu.scrollHeight, maxHeight);
        const top = openAbove ? rect.top - menuGap - menuHeight : rect.bottom + menuGap;
        controller.menu.style.top = `${Math.max(viewportMargin, top)}px`;
    }

    function moveRouteEditorSelectFocus(controller, direction) {
        const options = Array.from(controller.menu.querySelectorAll('.route-editor-select-option:not(:disabled)'));
        if (!options.length) return;

        const currentIndex = options.indexOf(document.activeElement);
        let nextIndex = currentIndex;
        if (direction === 'first') nextIndex = 0;
        else if (direction === 'last') nextIndex = options.length - 1;
        else if (direction === 'next') nextIndex = currentIndex < 0 ? 0 : (currentIndex + 1) % options.length;
        else if (direction === 'previous') nextIndex = currentIndex <= 0 ? options.length - 1 : currentIndex - 1;
        options[nextIndex]?.focus();
    }

    function setRouteEditorSelectOpen(controller, open, focusSelected = false) {
        if (!controller || controller.trigger.disabled) return;
        if (openRouteEditorSelect && openRouteEditorSelect !== controller) closeRouteEditorSelect();

        controller.control.classList.toggle('is-open', open);
        controller.trigger.setAttribute('aria-expanded', String(open));
        controller.menu.hidden = !open;
        openRouteEditorSelect = open ? controller : null;
        if (!open) return;

        positionRouteEditorSelect(controller);
        const selected = controller.menu.querySelector('.route-editor-select-option[aria-selected="true"]');
        selected?.scrollIntoView({ block: 'nearest' });
        if (focusSelected) (selected || controller.menu.querySelector('.route-editor-select-option:not(:disabled)'))?.focus();
    }

    function syncRouteEditorSelect(controller) {
        const selected = controller.select.selectedOptions[0] || controller.select.options[0];
        const label = selected?.dataset.label || selected?.textContent?.trim() || 'Select option';
        const description = selected?.dataset.description || '';

        controller.primary.textContent = label;
        controller.secondary.textContent = description;
        controller.secondary.hidden = !description;
        controller.trigger.title = [label, description].filter(Boolean).join(' - ');
        controller.menu.querySelectorAll('.route-editor-select-option').forEach((button) => {
            const isSelected = button.dataset.value === selected?.value;
            button.setAttribute('aria-selected', String(isSelected));
            const marker = button.querySelector(':scope > i');
            if (marker) marker.className = isSelected ? 'fas fa-check' : '';
        });
    }

    function selectRouteEditorOption(controller, value) {
        const option = Array.from(controller.select.options).find((entry) => entry.value === value);
        if (!option || option.disabled) return;

        const changed = controller.select.value !== value;
        controller.select.value = value;
        syncRouteEditorSelect(controller);
        closeRouteEditorSelect({ focusTrigger: true });
        if (changed) controller.select.dispatchEvent(new Event('change', { bubbles: true }));
    }

    function setupRouteEditorSelect(select) {
        const control = select.closest('.route-editor-select');
        if (!control) return;

        const selected = select.selectedOptions[0] || select.options[0];
        const trigger = document.createElement('button');
        const copy = document.createElement('span');
        const primary = document.createElement('strong');
        const secondary = document.createElement('small');
        const menu = document.createElement('div');
        const menuId = `routeEditorSelectMenu${++routeEditorSelectId}`;
        const hasDescriptions = Array.from(select.options).some((option) => option.dataset.description);
        const controller = { select, control, trigger, menu, primary, secondary, hasDescriptions };

        select.classList.add('route-editor-select-native');
        select.tabIndex = -1;
        select.setAttribute('aria-hidden', 'true');
        control.classList.toggle('has-description', hasDescriptions);

        trigger.type = 'button';
        trigger.className = 'route-editor-select-trigger';
        trigger.setAttribute('aria-label', select.getAttribute('aria-label') || 'Select option');
        trigger.setAttribute('aria-haspopup', 'listbox');
        trigger.setAttribute('aria-expanded', 'false');
        trigger.setAttribute('aria-controls', menuId);
        copy.className = 'route-editor-select-copy';
        primary.textContent = selected?.dataset.label || selected?.textContent?.trim() || 'Select option';
        secondary.textContent = selected?.dataset.description || '';
        secondary.hidden = !secondary.textContent;
        copy.append(primary, secondary);
        trigger.appendChild(copy);

        menu.id = menuId;
        menu.className = `route-editor-select-menu${hasDescriptions ? ' has-descriptions' : ''}`;
        menu.setAttribute('role', 'listbox');
        menu.setAttribute('aria-label', select.getAttribute('aria-label') || 'Select option');
        menu.hidden = true;

        Array.from(select.options).forEach((option) => {
            const button = document.createElement('button');
            const optionCopy = document.createElement('span');
            const optionPrimary = document.createElement('strong');
            const optionSecondary = document.createElement('small');
            const marker = document.createElement('i');

            button.type = 'button';
            button.className = 'route-editor-select-option';
            button.dataset.value = option.value;
            button.disabled = option.disabled;
            button.setAttribute('role', 'option');
            button.setAttribute('aria-selected', String(option === selected));
            optionCopy.className = 'route-editor-select-option-copy';
            optionPrimary.textContent = option.dataset.label || option.textContent.trim();
            optionSecondary.textContent = option.dataset.description || '';
            optionSecondary.hidden = !optionSecondary.textContent;
            marker.className = option === selected ? 'fas fa-check' : '';
            marker.setAttribute('aria-hidden', 'true');
            optionCopy.append(optionPrimary, optionSecondary);
            button.append(optionCopy, marker);
            menu.appendChild(button);
        });

        control.insertBefore(trigger, control.querySelector(':scope > i:last-child'));
        root.appendChild(menu);

        trigger.addEventListener('click', () => setRouteEditorSelectOpen(controller, openRouteEditorSelect !== controller));
        trigger.addEventListener('keydown', (event) => {
            if (event.key !== 'ArrowDown' && event.key !== 'ArrowUp') return;
            event.preventDefault();
            setRouteEditorSelectOpen(controller, true, true);
        });
        menu.addEventListener('click', (event) => {
            const option = event.target.closest('.route-editor-select-option');
            if (!option || option.disabled || !menu.contains(option)) return;
            selectRouteEditorOption(controller, option.dataset.value);
        });
        menu.addEventListener('keydown', (event) => {
            if (event.key === 'ArrowDown') {
                event.preventDefault();
                moveRouteEditorSelectFocus(controller, 'next');
            } else if (event.key === 'ArrowUp') {
                event.preventDefault();
                moveRouteEditorSelectFocus(controller, 'previous');
            } else if (event.key === 'Home') {
                event.preventDefault();
                moveRouteEditorSelectFocus(controller, 'first');
            } else if (event.key === 'End') {
                event.preventDefault();
                moveRouteEditorSelectFocus(controller, 'last');
            } else if (event.key === 'Escape') {
                event.preventDefault();
                event.stopPropagation();
                closeRouteEditorSelect({ focusTrigger: true });
            } else if (event.key === 'Tab') {
                closeRouteEditorSelect();
            }
        });
        select.addEventListener('change', () => syncRouteEditorSelect(controller));
        syncRouteEditorSelect(controller);
    }

    function setupRouteEditorSelects() {
        panel.querySelectorAll('.route-editor-select select').forEach(setupRouteEditorSelect);
    }

    function teardownRouteEditorSelects() {
        closeRouteEditorSelect({ removeMenu: true });
        root.querySelectorAll(':scope > .route-editor-select-menu').forEach((menu) => menu.remove());
    }

    const positionText = (coords) => {
        if (!coords) return 'Position not captured';
        return `${number(coords.x)} / ${number(coords.y)} / ${number(coords.z)}`;
    };

    const coordinateInputs = (coords, attributes, heading = false) => {
        const axes = heading ? ['x', 'y', 'z', 'w'] : ['x', 'y', 'z'];
        const labels = { x: 'X', y: 'Y', z: 'Z', w: 'Heading' };
        return `
            <div class="route-editor-coordinate-grid ${heading ? 'has-heading' : ''}">
                ${axes
                    .map(
                        (axis) => `
                    <label>
                        <span>${labels[axis]}</span>
                        <input type="number" step="${axis === 'w' ? '0.01' : '0.001'}" value="${number(coords?.[axis], axis === 'w' ? 2 : 3)}"
                            ${attributes(axis)} aria-label="${labels[axis]} coordinate">
                    </label>`
                    )
                    .join('')}
            </div>`;
    };

    const renderContext = (state) => `
        <section class="route-editor-context" aria-label="Route source">
            <label>
                <span>Contract Type</span>
                <div class="route-editor-select">
                    <i class="fas fa-truck"></i>
                    <select data-route-editor-context="routeType" aria-label="Contract type">
                        ${catalogOptions(state.types, state.routeType)}
                    </select>
                    <i class="fas fa-chevron-down"></i>
                </div>
            </label>
            <label>
                <span>Route Pool</span>
                <div class="route-editor-select">
                    <i class="fas fa-layer-group"></i>
                    <select data-route-editor-context="pool" aria-label="Route pool">
                        ${catalogOptions(state.pools, state.pool)}
                    </select>
                    <i class="fas fa-chevron-down"></i>
                </div>
            </label>
            <label class="route-editor-existing-field">
                <span>Configured Route</span>
                <div class="route-editor-select">
                    <i class="fas fa-folder-open"></i>
                    <select data-route-editor-existing aria-label="Configured route">
                        ${catalogOptions(state.existingRoutes, state.sourceIndex, 'Select a route to load', configuredRouteDescription)}
                    </select>
                    <i class="fas fa-chevron-down"></i>
                </div>
            </label>
            <div class="route-editor-context-actions">
                <button type="button" data-route-editor-action="new"><i class="fas fa-file-circle-plus"></i><span>New</span></button>
                <button type="button" data-route-editor-action="duplicate"><i class="fas fa-copy"></i><span>Duplicate</span></button>
            </div>
        </section>`;

    const renderRouteDetails = (state) => `
        <section class="route-editor-section route-editor-details">
            <div class="route-editor-section-heading">
                <div><small>ROUTE RECORD</small><strong>Assignment Details</strong></div>
                <span class="route-editor-mode">${escape(state.mode || 'new')}</span>
            </div>
            <div class="route-editor-field-grid">
                <label class="route-editor-wide-field">
                    <span>Route Name</span>
                    <input type="text" value="${escape(state.route?.label)}" data-route-editor-field="label" spellcheck="false">
                </label>
                <label>
                    <span>Displayed Distance</span>
                    <input type="text" value="${escape(state.route?.routeLength)}" data-route-editor-field="routeLength" placeholder="3.5 mi" spellcheck="false">
                </label>
                <button type="button" class="route-editor-estimate" data-route-editor-action="estimateDistance">
                    <i class="fas fa-route"></i><span>Estimate</span>
                </button>
            </div>
        </section>`;

    const renderStopList = (state) => {
        const stops = state.route?.dropoffs || [];
        if (!stops.length) {
            return `<div class="route-editor-empty"><i class="fas fa-location-crosshairs"></i><strong>No delivery points</strong><span>Stand at the first handoff point and capture it.</span></div>`;
        }

        return `<div class="route-editor-stop-list">
            ${stops
                .map((stop, index) => {
                    const itemIndex = index + 1;
                    const selected = Number(state.selectedIndex) === itemIndex;
                    return `
                    <div class="route-editor-stop ${selected ? 'is-selected' : ''}">
                        <button type="button" class="route-editor-stop-main" data-route-editor-action="selectStop" data-index="${itemIndex}">
                            <span class="route-editor-stop-number">${String(itemIndex).padStart(2, '0')}</span>
                            <span class="route-editor-stop-copy">
                                <strong>${escape(stop.label || `Stop ${itemIndex}`)}</strong>
                                <small>${escape(positionText(stop.coords))} | ${Number(stop.unload) || 0} unit${Number(stop.unload) === 1 ? '' : 's'}</small>
                            </span>
                        </button>
                        <div class="route-editor-stop-actions">
                            ${iconButton('moveStop', 'fa-arrow-up', 'Move stop up', `data-index="${itemIndex}" data-direction="up"`, itemIndex === 1)}
                            ${iconButton('moveStop', 'fa-arrow-down', 'Move stop down', `data-index="${itemIndex}" data-direction="down"`, itemIndex === stops.length)}
                            ${iconButton('deleteStop', 'fa-trash', 'Delete stop', `data-index="${itemIndex}"`)}
                        </div>
                    </div>`;
                })
                .join('')}
        </div>`;
    };

    const renderSelectedStop = (state) => {
        const stops = state.route?.dropoffs || [];
        const index = Math.max(1, Number(state.selectedIndex) || 1);
        const stop = stops[index - 1];
        if (!stop) {
            return `<section class="route-editor-section route-editor-point-editor"><div class="route-editor-empty compact"><span>Capture a stop to edit its delivery data.</span></div></section>`;
        }

        const attributes = (axis) => `data-route-stop-field="${axis}" data-route-stop-index="${index}"`;
        return `
            <section class="route-editor-section route-editor-point-editor">
                <div class="route-editor-section-heading">
                    <div><small>SELECTED POINT ${String(index).padStart(2, '0')}</small><strong>${escape(stop.label || `Stop ${index}`)}</strong></div>
                    <div class="route-editor-heading-actions">
                        ${pointActionButton('setGps', 'fa-location-arrow', 'Set GPS', 'Set GPS to this stop')}
                        ${pointActionButton('captureSelectedStop', 'fa-crosshairs', 'Use Current', 'Replace this stop with your current position')}
                    </div>
                </div>
                <label class="route-editor-input-field">
                    <span>Delivery Label</span>
                    <input type="text" value="${escape(stop.label)}" data-route-stop-field="label" data-route-stop-index="${index}" spellcheck="false">
                </label>
                <label class="route-editor-input-field route-editor-unload-field">
                    <span>Units Delivered At Stop</span>
                    <input type="number" min="1" step="1" value="${Math.max(1, Number(stop.unload) || 1)}" data-route-stop-field="unload" data-route-stop-index="${index}">
                </label>
                <div class="route-editor-coordinate-label"><span>Drop Position</span><code>${escape(positionText(stop.coords))}</code></div>
                ${coordinateInputs(stop.coords, attributes)}
            </section>`;
    };

    const renderDeliveryBuilder = (state) => `
        <div class="route-editor-builder-column">
            ${renderRouteDetails(state)}
            <section class="route-editor-section route-editor-points">
                <div class="route-editor-section-heading">
                    <div><small>DELIVERY SEQUENCE</small><strong>Route Stops</strong></div>
                    <button type="button" class="route-editor-capture" data-route-editor-action="captureStop"><i class="fas fa-location-crosshairs"></i><span>Capture Here</span></button>
                </div>
                ${renderStopList(state)}
            </section>
        </div>
        <div class="route-editor-inspector-column">
            ${renderSelectedStop(state)}
            ${renderValidation(state)}
        </div>`;

    const renderTrailerAssignment = (state) => `
        <section class="route-editor-section route-editor-trailer-assignment">
            <div class="route-editor-section-heading"><div><small>EQUIPMENT ASSIGNMENT</small><strong>Depot &amp; Trailer</strong></div></div>
            <div class="route-editor-field-grid two-column">
                <label>
                    <span>Pickup Depot</span>
                    <div class="route-editor-select plain">
                        <select data-route-editor-field="pickupDepot" aria-label="Pickup depot">${catalogOptions(state.depots, state.route?.pickupDepot)}</select>
                        <i class="fas fa-chevron-down"></i>
                    </div>
                </label>
                <label>
                    <span>Trailer Configuration</span>
                    <div class="route-editor-select plain">
                        <select data-route-editor-field="trailerKey" aria-label="Trailer configuration">${catalogOptions(state.trailers, state.route?.trailerKey, '', trailerDescription)}</select>
                        <i class="fas fa-chevron-down"></i>
                    </div>
                </label>
                <label class="route-editor-wide-field">
                    <span>Manifest Contents</span>
                    <input type="text" value="${escape(state.route?.trailerContents)}" data-route-editor-field="trailerContents" spellcheck="false">
                </label>
            </div>
        </section>`;

    const renderTrailerPoints = (state) => {
        const route = state.route || {};
        const entries = [
            { target: 'drop', index: 1, icon: 'fa-trailer', title: 'Trailer Drop', point: route.trailerDrop },
            { target: 'receiver', index: 2, icon: 'fa-user-check', title: 'Receiver Ped', point: route.receiverPed }
        ];
        return `
            <section class="route-editor-section route-editor-points">
                <div class="route-editor-section-heading"><div><small>DESTINATION SETUP</small><strong>Route Points</strong></div></div>
                <div class="route-editor-trailer-points">
                    ${entries
                        .map(
                            (entry) => `
                        <button type="button" class="route-editor-trailer-point ${Number(state.selectedIndex) === entry.index ? 'is-selected' : ''}"
                            data-route-editor-action="selectTrailerPoint" data-target="${entry.target}">
                            <i class="fas ${entry.icon}"></i>
                            <span><strong>${escape(entry.point?.label || entry.title)}</strong><small>${escape(positionText(entry.point?.coords))}</small></span>
                            <em>${entry.point?.coords ? 'SET' : 'OPEN'}</em>
                        </button>`
                        )
                        .join('')}
                </div>
            </section>`;
    };

    const renderSelectedTrailerPoint = (state) => {
        const isReceiver = Number(state.selectedIndex) === 2;
        const target = isReceiver ? 'receiver' : 'drop';
        const point = isReceiver ? state.route?.receiverPed : state.route?.trailerDrop;
        const attributes = (axis) => `data-route-point-field="${axis}" data-route-point-target="${target}"`;
        return `
            <section class="route-editor-section route-editor-point-editor">
                <div class="route-editor-section-heading">
                    <div><small>${isReceiver ? 'RECEIVER HANDOFF' : 'TRAILER PLACEMENT'}</small><strong>${isReceiver ? 'Receiver Ped' : 'Drop Zone'}</strong></div>
                    <div class="route-editor-heading-actions">
                        ${pointActionButton('setGps', 'fa-location-arrow', 'Set GPS', 'Set GPS to this route point')}
                        ${pointActionButton('captureTrailerPoint', 'fa-crosshairs', 'Use Current', 'Use your current position for this route point', `data-target="${target}"`)}
                    </div>
                </div>
                <label class="route-editor-input-field">
                    <span>${isReceiver ? 'Receiver Label' : 'Destination Label'}</span>
                    <input type="text" value="${escape(point?.label)}" data-route-point-field="label" data-route-point-target="${target}" spellcheck="false">
                </label>
                ${
                    isReceiver
                        ? `
                    <div class="route-editor-field-grid two-column compact-fields">
                        <label><span>Ped Model</span><input type="text" value="${escape(point?.model)}" data-route-point-field="model" data-route-point-target="receiver" spellcheck="false"></label>
                        <label><span>Scenario</span><input type="text" value="${escape(point?.scenario)}" data-route-point-field="scenario" data-route-point-target="receiver" spellcheck="false"></label>
                    </div>`
                        : `
                    <label class="route-editor-input-field route-editor-radius-field">
                        <span>Acceptance Radius (meters)</span>
                        <input type="number" min="1" step="0.5" value="${number(point?.radius, 1)}" data-route-point-field="radius" data-route-point-target="drop">
                    </label>`
                }
                <div class="route-editor-coordinate-label"><span>${isReceiver ? 'Ped Position & Heading' : 'Drop Position'}</span><code>${escape(positionText(point?.coords))}</code></div>
                ${coordinateInputs(point?.coords, attributes, isReceiver)}
            </section>`;
    };

    const renderTrailerBuilder = (state) => `
        <div class="route-editor-builder-column">
            ${renderRouteDetails(state)}
            ${renderTrailerAssignment(state)}
            ${renderTrailerPoints(state)}
        </div>
        <div class="route-editor-inspector-column">
            ${renderSelectedTrailerPoint(state)}
            ${renderValidation(state)}
        </div>`;

    function renderValidation(state) {
        const issues = state.issues || [];
        const summary = state.summary || {};
        const cargoText =
            state.routeType === 'trailer'
                ? 'Trailer handoff'
                : `${Number(summary.totalUnload) || 0} / ${Number(summary.requiredCargo) || 0} cargo units`;
        return `
            <section class="route-editor-section route-editor-validation">
                <div class="route-editor-section-heading">
                    <div><small>PREFLIGHT REVIEW</small><strong>Route Validation</strong></div>
                    <span class="route-editor-validation-count ${state.errorCount ? 'has-errors' : state.warningCount ? 'has-warnings' : 'is-clear'}">
                        ${Number(state.errorCount) || 0} ERR / ${Number(state.warningCount) || 0} WARN
                    </span>
                </div>
                <div class="route-editor-summary-row">
                    <span><i class="fas fa-location-dot"></i><b>${Number(summary.points) || 0}</b> route points</span>
                    <span><i class="fas fa-box"></i>${escape(cargoText)}</span>
                </div>
                <div class="route-editor-issue-list">
                    ${
                        issues.length
                            ? issues
                                  .map(
                                      (issue) => `
                        <div class="route-editor-issue is-${issue.level === 'error' ? 'error' : 'warning'}">
                            <i class="fas ${issue.level === 'error' ? 'fa-circle-exclamation' : 'fa-triangle-exclamation'}"></i>
                            <span>${escape(issue.message)}</span>
                        </div>`
                                  )
                                  .join('')
                            : `
                        <div class="route-editor-issue is-clear"><i class="fas fa-circle-check"></i><span>Route data is ready to export.</span></div>`
                    }
                </div>
            </section>`;
    }

    const renderExport = (state) => `
        <details class="route-editor-export">
            <summary>
                <span><i class="fas fa-code"></i><strong>Lua Config Preview</strong><small>${escape(state.path)}</small></span>
                <i class="fas fa-chevron-down"></i>
            </summary>
            <div class="route-editor-export-body">
                <textarea readonly spellcheck="false" aria-label="Generated Lua route config">${escape(state.exportText)}</textarea>
                <button type="button" data-route-editor-action="copy" ${state.canExport ? '' : 'disabled'}><i class="fas fa-copy"></i><span>Copy Config</span></button>
            </div>
        </details>`;

    const renderFooter = (state) => `
        <footer class="route-editor-footer">
            ${renderExport(state)}
            <div class="route-editor-footer-actions">
                <button type="button" class="route-editor-secondary ${state.preview ? 'is-active' : ''}" data-route-editor-action="togglePreview">
                    <i class="fas ${state.preview ? 'fa-eye-slash' : 'fa-eye'}"></i><span>${state.preview ? 'Hide Preview' : 'Preview Route'}</span>
                </button>
                <button type="button" class="route-editor-secondary" data-route-editor-action="validate"><i class="fas fa-list-check"></i><span>Validate</span></button>
                <button type="button" class="route-editor-primary" data-route-editor-action="print" ${state.canExport ? '' : 'disabled'}><i class="fas fa-terminal"></i><span>Print to F8</span></button>
                <button type="button" class="route-editor-danger" data-route-editor-action="discard"><i class="fas fa-trash"></i><span>${discardArmed ? 'Confirm Discard' : 'Discard'}</span></button>
            </div>
        </footer>`;

    function renderRouteEditor(state = {}) {
        teardownRouteEditorSelects();
        editorState = state;
        const current = state.currentPosition || {};
        panel.innerHTML = `
            <header class="route-editor-header">
                <div class="route-editor-title-icon"><i class="fas fa-route"></i></div>
                <div class="route-editor-title">
                    <small>LSFC ADMIN PLANNING TOOL</small>
                    <strong>Contract Route Editor</strong>
                    <span>${escape(state.path || 'Config.Contracts')}</span>
                </div>
                <div class="route-editor-current-position" title="Current player position">
                    <small>LIVE POSITION</small>
                    <code>${number(current.x)} / ${number(current.y)} / ${number(current.z)}</code>
                </div>
                <button type="button" class="route-editor-close" data-route-editor-action="minimize" title="Minimize editor" aria-label="Minimize editor"><i class="fas fa-window-minimize"></i></button>
            </header>
            ${renderContext(state)}
            <main class="route-editor-workspace">
                ${state.routeType === 'trailer' ? renderTrailerBuilder(state) : renderDeliveryBuilder(state)}
            </main>
            ${renderFooter(state)}`;
        setupRouteEditorSelects();
    }

    function showRouteEditor(state = {}) {
        discardArmed = false;
        clearTimeout(discardTimer);
        renderRouteEditor(state);
        root.classList.remove('hidden');
    }

    function hideRouteEditor() {
        teardownRouteEditorSelects();
        root.classList.add('hidden');
        discardArmed = false;
        clearTimeout(discardTimer);
    }

    async function copyExport(button) {
        const text = editorState?.exportText || '';
        if (!text) return;

        let copied = false;
        try {
            await navigator.clipboard.writeText(text);
            copied = true;
        } catch {
            const textarea = panel.querySelector('.route-editor-export textarea');
            if (textarea) {
                textarea.focus();
                textarea.select();
                copied = document.execCommand('copy');
            }
        }

        if (!button) return;
        button.innerHTML = copied
            ? '<i class="fas fa-check"></i><span>Copied</span>'
            : '<i class="fas fa-triangle-exclamation"></i><span>Copy Failed</span>';
        window.setTimeout(() => {
            if (editorState && !root.classList.contains('hidden')) renderRouteEditor(editorState);
        }, 1200);
    }

    function payloadFromButton(button) {
        const payload = { action: button.dataset.routeEditorAction || '' };
        if (button.dataset.index) payload.index = Number(button.dataset.index);
        if (button.dataset.direction) payload.direction = button.dataset.direction;
        if (button.dataset.target) payload.target = button.dataset.target;
        return payload;
    }

    panel.addEventListener('click', (event) => {
        const button = event.target.closest('[data-route-editor-action]');
        if (!button || button.disabled) return;
        const action = button.dataset.routeEditorAction;

        if (typeof playUISound === 'function') playUISound(action === 'discard' ? 'error' : 'click');

        if (action === 'copy') {
            copyExport(button);
            return;
        }

        if (action === 'discard' && !discardArmed) {
            discardArmed = true;
            renderRouteEditor(editorState || {});
            discardTimer = window.setTimeout(() => {
                discardArmed = false;
                if (editorState && !root.classList.contains('hidden')) renderRouteEditor(editorState);
            }, 3000);
            return;
        }

        if (action === 'minimize' || action === 'discard') hideRouteEditor();
        routeEditorPost('routeEditorAction', payloadFromButton(button));
    });

    panel.addEventListener('change', (event) => {
        const target = event.target;
        const context = target.dataset.routeEditorContext;
        if (context) {
            routeEditorPost('routeEditorAction', {
                action: 'setContext',
                routeType: context === 'routeType' ? target.value : editorState?.routeType,
                pool: context === 'pool' ? target.value : editorState?.pool
            });
            return;
        }

        if (target.matches('[data-route-editor-existing]')) {
            if (target.value) routeEditorPost('routeEditorAction', { action: 'loadExisting', index: Number(target.value) });
            return;
        }

        const routeField = target.dataset.routeEditorField;
        if (routeField) {
            routeEditorPost('routeEditorAction', { action: 'setField', field: routeField, value: target.value });
            return;
        }

        const stopField = target.dataset.routeStopField;
        if (stopField) {
            routeEditorPost('routeEditorAction', {
                action: 'updateStop',
                index: Number(target.dataset.routeStopIndex),
                field: stopField,
                value: target.value
            });
            return;
        }

        const pointField = target.dataset.routePointField;
        if (pointField) {
            routeEditorPost('routeEditorAction', {
                action: 'updateTrailerPoint',
                target: target.dataset.routePointTarget,
                field: pointField,
                value: target.value
            });
        }
    });

    document.addEventListener('click', (event) => {
        if (!openRouteEditorSelect) return;
        if (openRouteEditorSelect.control.contains(event.target) || openRouteEditorSelect.menu.contains(event.target)) return;
        closeRouteEditorSelect();
    });

    document.addEventListener('focusin', (event) => {
        if (!openRouteEditorSelect) return;
        if (openRouteEditorSelect.control.contains(event.target) || openRouteEditorSelect.menu.contains(event.target)) return;
        closeRouteEditorSelect();
    });

    window.addEventListener('resize', () => closeRouteEditorSelect());
    panel.addEventListener('scroll', () => closeRouteEditorSelect(), true);

    window.addEventListener('message', (event) => {
        const data = event.data || {};
        if (data.action === 'showRouteEditor') showRouteEditor(data.state || {});
        if (data.action === 'updateRouteEditor') renderRouteEditor(data.state || {});
        if (data.action === 'hideRouteEditor') hideRouteEditor();
    });

    window.addEventListener('keydown', (event) => {
        if (event.key !== 'Escape' || root.classList.contains('hidden')) return;
        event.preventDefault();
        if (openRouteEditorSelect) {
            closeRouteEditorSelect({ focusTrigger: true });
            return;
        }
        hideRouteEditor();
        routeEditorPost('routeEditorClose');
    });
})();
