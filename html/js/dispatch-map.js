const DISPATCH_MAP_BOUNDS = {
    minX: -4300,
    maxX: 4500,
    minY: -4300,
    maxY: 8300
};

const DISPATCH_MAP_ZOOM = {
    default: 1,
    min: 1,
    max: 2.8,
    step: 0.25
};

const DISPATCH_MAP_CATEGORIES = {
    terminal: { label: 'Terminal', icon: 'fas fa-tower-broadcast' },
    vehicle: { label: 'Vehicle Spawn', icon: 'fas fa-truck-fast' },
    garage: { label: 'Garage Spawn', icon: 'fas fa-warehouse' },
    van: { label: 'Van Pickup', icon: 'fas fa-box' },
    boxtruck: { label: 'Box Truck Pickup', icon: 'fas fa-truck-moving' },
    trailer: { label: 'Trailer Depot', icon: 'fas fa-trailer' }
};

function getDispatchHomePoints(data = dispatchData) {
    return Array.isArray(data?.dispatchHome?.points) ? data.dispatchHome.points.filter(Boolean) : [];
}

function getDispatchMapPointById(id, data = dispatchData) {
    const points = getDispatchHomePoints(data);
    return points.find(point => String(point.id || '') === String(id || '')) || null;
}

function getDispatchMapBounds(data = dispatchData) {
    return {
        ...DISPATCH_MAP_BOUNDS,
        ...(data?.dispatchHome?.mapBounds || {})
    };
}

function getDispatchMapZoomConfig(data = dispatchData) {
    const home = data?.dispatchHome || {};
    const zoomDefault = Number(home.mapZoom ?? DISPATCH_MAP_ZOOM.default);
    const min = Number(home.mapZoomMin ?? DISPATCH_MAP_ZOOM.min);
    const max = Number(home.mapZoomMax ?? DISPATCH_MAP_ZOOM.max);
    const step = Number(home.mapZoomStep ?? DISPATCH_MAP_ZOOM.step);

    return {
        default: Number.isFinite(zoomDefault) ? zoomDefault : DISPATCH_MAP_ZOOM.default,
        min: Number.isFinite(min) ? min : DISPATCH_MAP_ZOOM.min,
        max: Number.isFinite(max) ? max : DISPATCH_MAP_ZOOM.max,
        step: Number.isFinite(step) && step > 0 ? step : DISPATCH_MAP_ZOOM.step
    };
}

function clampDispatchMapZoom(value, config = getDispatchMapZoomConfig()) {
    const zoom = Number(value);
    const min = Math.min(config.min, config.max);
    const max = Math.max(config.min, config.max);
    if (!Number.isFinite(zoom)) return config.default;
    return Math.max(min, Math.min(max, zoom));
}

function getDispatchMapPanLimit(zoom = dispatchMapZoom) {
    if (!dispatchHomeMap || zoom <= 1) return { x: 0, y: 0 };
    const rect = dispatchHomeMap.getBoundingClientRect();
    return {
        x: Math.max(0, (rect.width * (zoom - 1)) / 2),
        y: Math.max(0, (rect.height * (zoom - 1)) / 2)
    };
}

function clampDispatchMapPan(pan = dispatchMapPan, zoom = dispatchMapZoom) {
    const currentZoom = Number(zoom) || 1;
    if (currentZoom <= 1.01) return { x: 0, y: 0 };

    const limit = getDispatchMapPanLimit(currentZoom);
    const x = Number(pan?.x || 0);
    const y = Number(pan?.y || 0);

    return {
        x: Math.max(-limit.x, Math.min(limit.x, x)),
        y: Math.max(-limit.y, Math.min(limit.y, y))
    };
}

function applyDispatchMapTransform() {
    if (!dispatchHomeMap) return;
    const viewport = dispatchHomeMap.querySelector('.dispatch-map-viewport');
    if (!viewport) return;

    const zoomConfig = getDispatchMapZoomConfig(dispatchData || {});
    dispatchMapZoom = clampDispatchMapZoom(dispatchMapZoom, zoomConfig);
    dispatchMapPan = clampDispatchMapPan(dispatchMapPan, dispatchMapZoom);

    viewport.style.setProperty('--map-zoom', dispatchMapZoom.toFixed(2));
    viewport.style.setProperty('--map-pan-x', `${dispatchMapPan.x.toFixed(0)}px`);
    viewport.style.setProperty('--map-pan-y', `${dispatchMapPan.y.toFixed(0)}px`);
    viewport.style.setProperty('--marker-scale', (1 / dispatchMapZoom).toFixed(3));
    dispatchHomeMap.classList.toggle('is-pannable', dispatchMapZoom > zoomConfig.min + 0.01);
    dispatchHomeMap.classList.toggle('is-panning', Boolean(dispatchMapDrag));
}

function renderDispatchMapControls(config) {
    const zoom = clampDispatchMapZoom(dispatchMapZoom, config);
    const canZoomOut = zoom > config.min + 0.01;
    const canZoomIn = zoom < config.max - 0.01;

    return `
        <div class="dispatch-map-controls">
            <button type="button" data-dispatch-map-zoom="out" ${canZoomOut ? '' : 'disabled'} title="Zoom out"><i class="fas fa-minus"></i></button>
            <span data-dispatch-map-zoom-label>${Math.round(zoom * 100)}%</span>
            <button type="button" data-dispatch-map-zoom="in" ${canZoomIn ? '' : 'disabled'} title="Zoom in"><i class="fas fa-plus"></i></button>
            <button type="button" data-dispatch-map-zoom="reset" title="Reset zoom"><i class="fas fa-compress"></i></button>
        </div>
    `;
}

function updateDispatchMapControls(config = getDispatchMapZoomConfig(dispatchData || {})) {
    if (!dispatchHomeMap) return;
    const zoom = clampDispatchMapZoom(dispatchMapZoom, config);
    const canZoomOut = zoom > config.min + 0.01;
    const canZoomIn = zoom < config.max - 0.01;
    const label = dispatchHomeMap.querySelector('[data-dispatch-map-zoom-label]');
    const outButton = dispatchHomeMap.querySelector('[data-dispatch-map-zoom="out"]');
    const inButton = dispatchHomeMap.querySelector('[data-dispatch-map-zoom="in"]');

    if (label) label.textContent = `${Math.round(zoom * 100)}%`;
    if (outButton) outButton.disabled = !canZoomOut;
    if (inButton) inButton.disabled = !canZoomIn;
}

function getSelectedDispatchMapPoint(data = dispatchData) {
    const points = getDispatchHomePoints(data);
    if (!points.length) {
        selectedDispatchHomePointId = null;
        return null;
    }

    let point = getDispatchMapPointById(selectedDispatchHomePointId, data);
    if (!point) {
        point = points.find(entry => entry.category === 'terminal') || points[0];
        selectedDispatchHomePointId = point.id || null;
    }

    return point;
}

function dispatchMapPosition(coords = {}, overlapIndex = 0, data = dispatchData) {
    const bounds = getDispatchMapBounds(data);
    const rawX = Number(coords.x || 0);
    const rawY = Number(coords.y || 0);
    const xRange = bounds.maxX - bounds.minX;
    const yRange = bounds.maxY - bounds.minY;
    const left = ((rawX - bounds.minX) / xRange) * 100;
    const top = 100 - (((rawY - bounds.minY) / yRange) * 100);
    const offsets = [
        [0, 0],
        [13, -8],
        [-13, 8],
        [13, 9],
        [-13, -9],
        [0, 15]
    ];
    const offset = offsets[overlapIndex % offsets.length];

    return {
        left: Math.max(4, Math.min(96, left)),
        top: Math.max(4, Math.min(96, top)),
        offsetX: offset[0],
        offsetY: offset[1]
    };
}

function displayDispatchAddress(point = {}) {
    return displayText(point.address || point.street || point.zone, 'Address unavailable');
}

function renderDispatchMapArt() {
    return `
        <div class="dispatch-map-art" aria-hidden="true">
            <svg viewBox="0 0 100 140" preserveAspectRatio="none">
                <path class="map-land map-land-main" d="M52 3 C65 8 72 19 76 35 C83 45 85 59 80 75 C84 91 78 104 70 113 C66 125 53 136 39 132 C28 129 22 116 20 103 C13 93 14 78 19 65 C13 53 16 38 24 29 C29 15 39 6 52 3 Z"/>
                <path class="map-land map-land-city" d="M35 95 C45 90 61 92 68 102 C66 114 55 122 43 121 C33 118 28 106 35 95 Z"/>
                <path class="map-road" d="M53 9 C49 26 47 39 51 55 C57 74 50 89 44 103 C39 114 43 124 48 132"/>
                <path class="map-road" d="M25 70 C37 69 47 73 58 81 C66 87 72 95 77 106"/>
                <path class="map-road" d="M28 34 C39 42 48 46 61 45 C69 45 75 49 80 55"/>
                <path class="map-road soft" d="M19 102 C30 99 44 100 57 107 C64 111 69 116 73 122"/>
            </svg>
            <span class="map-region city">LOS SANTOS</span>
            <span class="map-region county">BLAINE COUNTY</span>
            <span class="map-region ocean">PACIFIC</span>
        </div>
    `;
}

function renderDispatchHomeLegend() {
    const legendHtml = Object.entries(DISPATCH_MAP_CATEGORIES).map(([category, meta]) => `
        <span class="dispatch-legend-pill ${category}">
            <i class="${meta.icon}"></i>
            ${escapeHTML(meta.label)}
        </span>
    `).join('');

    return legendHtml;
}

function renderDispatchHome(data = dispatchData) {
    if (!dispatchHomeMap) return;
    const points = getDispatchHomePoints(data);
    const overlapCounts = {};
    const mapImage = data?.dispatchHome?.mapImage;
    const zoomConfig = getDispatchMapZoomConfig(data);

    if (dispatchMapZoom === null) dispatchMapZoom = zoomConfig.default;
    dispatchMapZoom = clampDispatchMapZoom(dispatchMapZoom, zoomConfig);
    dispatchMapPan = clampDispatchMapPan(dispatchMapPan, dispatchMapZoom);

    getSelectedDispatchMapPoint(data);
    const legendHtml = renderDispatchHomeLegend();
    dispatchHomeMap.classList.toggle('has-map-image', Boolean(mapImage));

    if (!points.length) {
        dispatchHomeMap.innerHTML = `<div class="dispatch-map-empty">${uiText('empty.dispatchMap', {}, 'No dispatch map locations are configured.')}</div>`;
        return;
    }

    const markerHtml = points.map(point => {
        const coords = point.coords || {};
        const coordKey = `${Math.round(Number(coords.x || 0) / 6)}:${Math.round(Number(coords.y || 0) / 6)}`;
        const overlapIndex = overlapCounts[coordKey] || 0;
        overlapCounts[coordKey] = overlapIndex + 1;
        const pos = dispatchMapPosition(coords, overlapIndex, data);
        const category = point.category || 'terminal';
        const meta = DISPATCH_MAP_CATEGORIES[category] || DISPATCH_MAP_CATEGORIES.terminal;
        const selected = String(point.id || '') === String(selectedDispatchHomePointId || '');

        return `
            <button class="dispatch-map-marker ${category} ${selected ? 'selected' : ''}"
                data-dispatch-map-marker="${escapeHTML(point.id || '')}"
                style="--x:${pos.left.toFixed(2)}%;--y:${pos.top.toFixed(2)}%;--ox:${pos.offsetX}px;--oy:${pos.offsetY}px"
                title="${escapeHTML(point.label || meta.label)}">
                <i class="${escapeHTML(point.icon || meta.icon)}"></i>
            </button>
        `;
    }).join('');

    dispatchHomeMap.innerHTML = `
        <div class="dispatch-map-viewport" style="--map-zoom:${dispatchMapZoom.toFixed(2)};--map-pan-x:${dispatchMapPan.x.toFixed(0)}px;--map-pan-y:${dispatchMapPan.y.toFixed(0)}px;--marker-scale:${(1 / dispatchMapZoom).toFixed(3)}">
            ${mapImage ? `<img class="dispatch-map-image" src="${escapeHTML(mapImage)}" alt="" aria-hidden="true">` : ''}
            ${renderDispatchMapArt()}
            <div class="dispatch-map-markers">${markerHtml}</div>
        </div>
        <div class="dispatch-home-legend">${legendHtml}</div>
        ${renderDispatchMapControls(zoomConfig)}
    `;
    applyDispatchMapTransform();
    updateDispatchMapControls(zoomConfig);
}

function stableDispatchSignature(value) {
    try {
        return JSON.stringify(value ?? null);
    } catch {
        return String(value ?? '');
    }
}

function dispatchRenderChanged(key, value) {
    const signature = stableDispatchSignature(value);
    if (dispatchRenderSignatures[key] === signature) return false;
    dispatchRenderSignatures[key] = signature;
    return true;
}

function dispatchTabSignature(data = {}, tab = activeDispatchTab) {
    if (tab === 'home') {
        return {
            dispatchHome: data.dispatchHome || {},
            currentJob: data.currentJob || null,
            routeHistory: data.routeHistory || data.lastRouteSummary || null,
            garage: data.garage || [],
            contractor: data.contractor || null
        };
    }

    if (tab === 'history') {
        return data.routeHistory || data.lastRouteSummary || null;
    }

    if (tab === 'garage') {
        return { garage: data.garage || [] };
    }

    if (tab === 'contractor') {
        return {
            contractor: data.contractor || {},
            currentJob: data.currentJob || null
        };
    }

    if (tab === 'company') {
        return {
            player: data.player || {},
            contractor: data.contractor || {},
            companyStats: data.companyStats || {},
            routeHistory: data.routeHistory || data.lastRouteSummary || null,
            currentJob: data.currentJob || null,
            ranks: data.ranks || []
        };
    }

    if (tab === 'dispatch') {
        return {
            playerRank: data.player?.rank || 1,
            contracts: data.contracts || {},
            vehicles: data.vehicles || {},
            priorityLoads: data.priorityLoads || {},
            reuse: data.reuse || {}
        };
    }

    return data.currentJob || null;
}
