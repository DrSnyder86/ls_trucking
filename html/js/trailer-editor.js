function formatTrailerEditorNumber(value) {
    const number = Number(value);
    return Number.isFinite(number) ? number.toFixed(3) : '0.000';
}

function getTrailerEditorSelectedProp() {
    if (!trailerCargoEditorState?.props?.length) return null;
    const selected = Number(trailerCargoEditorState.selectedIndex || 1);
    return trailerCargoEditorState.props.find(prop => Number(prop.index) === selected) || trailerCargoEditorState.props[0];
}

function renderTrailerCargoEditor(state = {}) {
    trailerCargoEditorState = {
        ...(trailerCargoEditorState || {}),
        ...state,
        props: Array.isArray(state.props) ? state.props : (trailerCargoEditorState?.props || [])
    };

    if (!trailerCargoEditor) return;

    const current = trailerCargoEditorState;
    if (trailerCargoEditorTitle) trailerCargoEditorTitle.innerText = `${current.label || 'Trailer'} (${current.key || 'unknown'})`;
    if (trailerCargoEditorModel) trailerCargoEditorModel.innerText = current.model || 'model';

    if (trailerCargoEditorPropSelect) {
        trailerCargoEditorPropSelect.innerHTML = '';
        (current.props || []).forEach(prop => {
            const option = document.createElement('option');
            option.value = String(prop.index);
            option.innerText = `${prop.index}. ${prop.model || 'prop'}`;
            trailerCargoEditorPropSelect.appendChild(option);
        });
        trailerCargoEditorPropSelect.value = String(current.selectedIndex || 1);
    }

    if (trailerCargoEditorStep) trailerCargoEditorStep.value = current.step || 0.05;

    const prop = getTrailerEditorSelectedProp();
    if (trailerCargoEditorPropModel) trailerCargoEditorPropModel.value = prop?.model || '';
    if (trailerCargoEditorOffset) {
        const offset = prop?.offset || {};
        trailerCargoEditorOffset.innerText = `${formatTrailerEditorNumber(offset.x)} / ${formatTrailerEditorNumber(offset.y)} / ${formatTrailerEditorNumber(offset.z)}`;
    }
    if (trailerCargoEditorRotation) {
        const rotation = prop?.rotation || {};
        trailerCargoEditorRotation.innerText = `${formatTrailerEditorNumber(rotation.x)} / ${formatTrailerEditorNumber(rotation.y)} / ${formatTrailerEditorNumber(rotation.z)}`;
    }
}

function showTrailerCargoEditor(state = {}) {
    renderTrailerCargoEditor(state);
    if (trailerCargoEditor) trailerCargoEditor.classList.remove('hidden');
}

function hideTrailerCargoEditor() {
    if (trailerCargoEditor) trailerCargoEditor.classList.add('hidden');
    trailerCargoEditorState = null;
}

function sendTrailerCargoEditorAction(action, data = {}) {
    const step = Number(trailerCargoEditorStep?.value || trailerCargoEditorState?.step || 0.05);
    post('trailerCargoEditorAction', { action, step, ...data });
}

if (trailerCargoEditor) {
    trailerCargoEditor.addEventListener('click', event => {
        const actionButton = event.target.closest('[data-trailer-editor-action]');
        if (actionButton) {
            const action = actionButton.dataset.trailerEditorAction;
            if (action === 'close') {
                hideTrailerCargoEditor();
                post('trailerCargoEditorClose');
            } else {
                sendTrailerCargoEditorAction(action);
            }
            return;
        }

        const nudgeButton = event.target.closest('[data-trailer-editor-field]');
        if (nudgeButton) {
            sendTrailerCargoEditorAction('nudge', {
                field: nudgeButton.dataset.trailerEditorField,
                axis: nudgeButton.dataset.trailerEditorAxis,
                delta: Number(nudgeButton.dataset.trailerEditorDelta || 0)
            });
        }
    });
}

if (trailerCargoEditorPropSelect) {
    trailerCargoEditorPropSelect.addEventListener('change', () => {
        sendTrailerCargoEditorAction('select', { index: Number(trailerCargoEditorPropSelect.value || 1) });
    });
}

if (trailerCargoEditorStep) {
    trailerCargoEditorStep.addEventListener('change', () => {
        sendTrailerCargoEditorAction('step', { step: Number(trailerCargoEditorStep.value || 0.05) });
    });
}

if (trailerCargoEditorPropModel) {
    trailerCargoEditorPropModel.addEventListener('change', () => {
        sendTrailerCargoEditorAction('setModel', { model: trailerCargoEditorPropModel.value.trim() });
    });
}

window.addEventListener('keydown', event => {
    if (!trailerCargoEditor || trailerCargoEditor.classList.contains('hidden')) return;

    if (event.key === 'Escape') {
        hideTrailerCargoEditor();
        post('trailerCargoEditorClose');
        return;
    }

    const targetTag = (event.target?.tagName || '').toLowerCase();
    if (targetTag === 'input' || targetTag === 'select' || targetTag === 'textarea') return;

    const normalizedKey = event.key.length === 1 ? event.key.toLowerCase() : event.key;
    const cameraKeys = {
        a: 'left',
        ArrowLeft: 'left',
        d: 'right',
        ArrowRight: 'right',
        q: 'zoomOut',
        e: 'zoomIn',
        w: 'up',
        ArrowUp: 'up',
        s: 'down',
        ArrowDown: 'down',
        r: 'reset'
    };
    const control = cameraKeys[normalizedKey];
    if (!control) return;

    event.preventDefault();
    sendTrailerCargoEditorAction('camera', { control });
});
