function formatTrailerEditorNumber(value) {
    const number = Number(value);
    return Number.isFinite(number) ? number.toFixed(3) : '0.000';
}

function normalizeTrailerEditorAxis(axis) {
    if (axis === 'pitch') return 'x';
    if (axis === 'roll') return 'y';
    if (axis === 'yaw') return 'z';
    return axis;
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

    trailerCargoEditor?.querySelectorAll('[data-trailer-editor-value-field]').forEach(input => {
        if (document.activeElement === input) return;

        const field = input.dataset.trailerEditorValueField === 'rotation' ? 'rotation' : 'offset';
        const axis = normalizeTrailerEditorAxis(input.dataset.trailerEditorValueAxis);
        input.value = formatTrailerEditorNumber(prop?.[field]?.[axis]);
    });

    trailerCargoEditor?.querySelectorAll('[data-trailer-editor-step-preset]').forEach(button => {
        const preset = Number(button.dataset.trailerEditorStepPreset);
        const currentStep = Number(current.step || 0.05);
        button.classList.toggle('is-active', Number.isFinite(preset) && Math.abs(preset - currentStep) < 0.0005);
    });
}

function showTrailerCargoEditor(state = {}) {
    renderTrailerCargoEditor(state);
    if (trailerCargoEditor) trailerCargoEditor.classList.remove('hidden');
}

function hideTrailerCargoEditor() {
    if (trailerCargoEditor) trailerCargoEditor.classList.add('hidden');
    stopTrailerEditorCameraDrag();
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
            } else if (action === 'camera') {
                sendTrailerCargoEditorAction('camera', { control: actionButton.dataset.trailerEditorControl });
            } else {
                sendTrailerCargoEditorAction(action);
            }
            return;
        }

        const stepPreset = event.target.closest('[data-trailer-editor-step-preset]');
        if (stepPreset) {
            const step = Number(stepPreset.dataset.trailerEditorStepPreset || 0.05);
            if (trailerCargoEditorStep) trailerCargoEditorStep.value = step;
            sendTrailerCargoEditorAction('step', { step });
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

    trailerCargoEditor.addEventListener('change', event => {
        const valueInput = event.target.closest('[data-trailer-editor-value-field]');
        if (!valueInput) return;

        sendTrailerCargoEditorAction('setValue', {
            field: valueInput.dataset.trailerEditorValueField,
            axis: valueInput.dataset.trailerEditorValueAxis,
            value: Number(valueInput.value)
        });
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

let trailerEditorCameraDrag = null;
let trailerEditorCameraFrame = null;
let trailerEditorCameraDeltaX = 0;
let trailerEditorCameraDeltaY = 0;

function flushTrailerEditorCameraDrag() {
    trailerEditorCameraFrame = null;

    const deltaX = trailerEditorCameraDeltaX;
    const deltaY = trailerEditorCameraDeltaY;
    trailerEditorCameraDeltaX = 0;
    trailerEditorCameraDeltaY = 0;

    if (Math.abs(deltaX) < 0.1 && Math.abs(deltaY) < 0.1) return;
    sendTrailerCargoEditorAction('camera', { control: 'drag', deltaX, deltaY });
}

function queueTrailerEditorCameraDrag(deltaX, deltaY) {
    trailerEditorCameraDeltaX += deltaX;
    trailerEditorCameraDeltaY += deltaY;

    if (!trailerEditorCameraFrame) {
        trailerEditorCameraFrame = window.requestAnimationFrame(flushTrailerEditorCameraDrag);
    }
}

function stopTrailerEditorCameraDrag() {
    trailerEditorCameraDrag = null;
    trailerCargoEditor?.querySelector('[data-trailer-editor-camera-pad]')?.classList.remove('is-dragging');
}

const trailerEditorCameraPad = trailerCargoEditor?.querySelector('[data-trailer-editor-camera-pad]');
if (trailerEditorCameraPad) {
    trailerEditorCameraPad.addEventListener('pointerdown', event => {
        if (event.button !== 0) return;

        trailerEditorCameraDrag = {
            pointerId: event.pointerId,
            x: event.clientX,
            y: event.clientY
        };
        trailerEditorCameraPad.setPointerCapture(event.pointerId);
        trailerEditorCameraPad.classList.add('is-dragging');
        event.preventDefault();
    });

    trailerEditorCameraPad.addEventListener('pointermove', event => {
        if (!trailerEditorCameraDrag || event.pointerId !== trailerEditorCameraDrag.pointerId) return;

        const deltaX = event.clientX - trailerEditorCameraDrag.x;
        const deltaY = event.clientY - trailerEditorCameraDrag.y;
        trailerEditorCameraDrag.x = event.clientX;
        trailerEditorCameraDrag.y = event.clientY;
        queueTrailerEditorCameraDrag(deltaX, deltaY);
        event.preventDefault();
    });

    trailerEditorCameraPad.addEventListener('pointerup', stopTrailerEditorCameraDrag);
    trailerEditorCameraPad.addEventListener('pointercancel', stopTrailerEditorCameraDrag);
    trailerEditorCameraPad.addEventListener('wheel', event => {
        sendTrailerCargoEditorAction('camera', { control: 'wheel', deltaY: event.deltaY });
        event.preventDefault();
    }, { passive: false });
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
