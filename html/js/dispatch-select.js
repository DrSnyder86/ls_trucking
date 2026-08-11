const dispatchSelectControllers = new Map();
let openDispatchSelectController = null;

function setDispatchSelectOpen(controller, open, focusSelected = false) {
    if (!controller) return;

    if (openDispatchSelectController && openDispatchSelectController !== controller) {
        setDispatchSelectOpen(openDispatchSelectController, false);
    }

    controller.control.classList.toggle('open', open);
    controller.trigger.setAttribute('aria-expanded', String(open));
    controller.menu.hidden = !open;
    openDispatchSelectController = open ? controller : null;

    if (!open || !focusSelected) return;

    const selected = controller.menu.querySelector('.dispatch-select-option[aria-selected="true"]');
    const fallback = controller.menu.querySelector('.dispatch-select-option:not(:disabled)');
    (selected || fallback)?.focus();
}

function closeOpenDispatchSelect() {
    if (!openDispatchSelectController) return false;
    setDispatchSelectOpen(openDispatchSelectController, false);
    return true;
}

function selectDispatchOption(controller, value) {
    const option = Array.from(controller.select.options).find(entry => entry.value === value);
    if (!option || option.disabled) return;

    const changed = controller.select.value !== value;
    controller.select.value = value;
    setDispatchSelectOpen(controller, false);
    controller.trigger.focus();

    if (changed) {
        controller.select.dispatchEvent(new Event('change', { bubbles: true }));
    }

    syncDispatchSelect(controller.select);
}

function moveDispatchSelectFocus(controller, direction) {
    const options = Array.from(controller.menu.querySelectorAll('.dispatch-select-option:not(:disabled)'));
    if (!options.length) return;

    const currentIndex = options.indexOf(document.activeElement);
    let nextIndex = currentIndex;

    if (direction === 'first') nextIndex = 0;
    else if (direction === 'last') nextIndex = options.length - 1;
    else if (direction === 'next') nextIndex = currentIndex < 0 ? 0 : (currentIndex + 1) % options.length;
    else if (direction === 'previous') nextIndex = currentIndex <= 0 ? options.length - 1 : currentIndex - 1;

    options[nextIndex]?.focus();
}

function syncDispatchSelect(select) {
    const controller = dispatchSelectControllers.get(select);
    if (!controller) return;

    const options = Array.from(select.options);
    const selected = options.find(option => option.selected) || options.find(option => !option.disabled) || options[0];
    controller.label.textContent = selected?.textContent?.trim() || select.getAttribute('aria-label') || 'Select option';
    controller.trigger.disabled = select.disabled || options.length === 0;
    controller.menu.textContent = '';

    options.forEach(option => {
        const button = document.createElement('button');
        const text = document.createElement('span');
        const status = document.createElement('i');

        button.type = 'button';
        button.className = 'dispatch-select-option';
        button.dataset.value = option.value;
        button.disabled = option.disabled;
        button.setAttribute('role', 'option');
        button.setAttribute('aria-selected', String(option === selected));
        text.textContent = option.textContent.trim();
        status.className = option.disabled ? 'fas fa-lock' : option === selected ? 'fas fa-check' : '';
        status.setAttribute('aria-hidden', 'true');
        button.append(text, status);
        controller.menu.appendChild(button);
    });

    if (!options.length) setDispatchSelectOpen(controller, false);
}

function setupDispatchSelect(select) {
    const control = select?.closest('.dispatch-select-control');
    if (!select || !control || dispatchSelectControllers.has(select)) return;

    const trigger = document.createElement('button');
    const label = document.createElement('span');
    const menu = document.createElement('div');
    const menuId = `${select.id}Menu`;
    const controller = { select, control, trigger, label, menu };

    select.classList.add('dispatch-select-native');
    select.tabIndex = -1;
    select.setAttribute('aria-hidden', 'true');

    trigger.type = 'button';
    trigger.className = 'dispatch-select-trigger';
    trigger.setAttribute('aria-label', select.getAttribute('aria-label') || 'Select option');
    trigger.setAttribute('aria-haspopup', 'listbox');
    trigger.setAttribute('aria-expanded', 'false');
    trigger.setAttribute('aria-controls', menuId);
    label.className = 'dispatch-select-value';
    trigger.appendChild(label);

    menu.id = menuId;
    menu.className = 'dispatch-select-menu';
    menu.setAttribute('role', 'listbox');
    menu.hidden = true;
    control.insertBefore(trigger, control.querySelector('.dispatch-select-chevron'));
    control.appendChild(menu);
    dispatchSelectControllers.set(select, controller);

    trigger.addEventListener('click', () => {
        if (trigger.disabled) return;
        setDispatchSelectOpen(controller, !control.classList.contains('open'));
    });

    trigger.addEventListener('keydown', event => {
        if (event.key !== 'ArrowDown' && event.key !== 'ArrowUp') return;
        event.preventDefault();
        setDispatchSelectOpen(controller, true, true);
    });

    menu.addEventListener('click', event => {
        const option = event.target.closest('.dispatch-select-option');
        if (!option || option.disabled || !menu.contains(option)) return;
        selectDispatchOption(controller, option.dataset.value);
    });

    menu.addEventListener('keydown', event => {
        if (event.key === 'ArrowDown') {
            event.preventDefault();
            moveDispatchSelectFocus(controller, 'next');
        } else if (event.key === 'ArrowUp') {
            event.preventDefault();
            moveDispatchSelectFocus(controller, 'previous');
        } else if (event.key === 'Home') {
            event.preventDefault();
            moveDispatchSelectFocus(controller, 'first');
        } else if (event.key === 'End') {
            event.preventDefault();
            moveDispatchSelectFocus(controller, 'last');
        } else if (event.key === 'Escape') {
            event.preventDefault();
            event.stopPropagation();
            setDispatchSelectOpen(controller, false);
            trigger.focus();
        }
    });

    select.addEventListener('change', () => syncDispatchSelect(select));
    syncDispatchSelect(select);
}

[vehicleSelect, prioritySelect].forEach(setupDispatchSelect);

document.addEventListener('click', event => {
    if (openDispatchSelectController?.control.contains(event.target)) return;
    closeOpenDispatchSelect();
});
