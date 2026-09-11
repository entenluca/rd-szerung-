const app = document.getElementById('app');
const selectorView = document.getElementById('selector-view');
const controlView = document.getElementById('control-view');
const gateList = document.getElementById('gate-list');
const gateCount = document.getElementById('gate-count');
const gateLabel = document.getElementById('gate-label');
const gateStatus = document.getElementById('gate-status');
const progressFill = document.getElementById('progress-fill');
const progressLabel = document.getElementById('progress-label');
const warningIndicator = document.getElementById('warning-indicator');
const backBtn = document.getElementById('btn-back');

let currentGateId = null;
let currentState = 'closed';
let showBackButton = false;

function post(action, data = {}) {
    return fetch(`https://${GetParentResourceName()}/${action}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
    });
}

function getStateClass(state) {
    if (state === 'opening' || state === 'closing') return 'moving';
    if (state === 'open') return 'open';
    return 'closed';
}

function getStateText(progressLabel, state) {
    if (progressLabel) return progressLabel;
    if (state === 'open') return 'Geöffnet';
    if (state === 'opening') return 'Öffnet...';
    if (state === 'closing') return 'Schließt...';
    if (state === 'stopped') return 'Angehalten';
    return 'Geschlossen';
}

function renderGateList(gates) {
    gateList.innerHTML = '';

    gates.forEach((gate) => {
        const item = document.createElement('button');
        item.className = 'gate-item';
        item.type = 'button';
        item.dataset.gateId = gate.id;

        const stateClass = getStateClass(gate.state);
        const statusText = getStateText(gate.progressLabel, gate.state);
        const percent = Math.round((gate.progress || 0) * 100);

        item.innerHTML = `
            <div class="gate-item-main">
                <span class="gate-item-title">${gate.label}</span>
                <span class="gate-item-distance">${Math.round(gate.distance)}m</span>
            </div>
            <div class="gate-item-meta">
                <span class="gate-item-status status-${stateClass}">${statusText}</span>
                <span class="gate-item-percent">${percent}%</span>
            </div>
        `;

        item.addEventListener('click', () => {
            post('selectGate', { gateId: gate.id });
        });

        gateList.appendChild(item);
    });

    gateCount.textContent = `${gates.length} Tor${gates.length === 1 ? '' : 'e'} in Reichweite`;
}

function updateControlUI(data) {
    if (data.label) {
        gateLabel.textContent = data.label;
    }

    if (data.progressLabel) {
        gateStatus.textContent = data.progressLabel;
    }

    if (typeof data.progress === 'number') {
        const percent = Math.round(data.progress * 100);
        progressFill.style.width = `${percent}%`;
        progressLabel.textContent = `${percent}%`;
    }

    if (data.state) {
        currentState = data.state;
        gateStatus.classList.remove('status-moving', 'status-open', 'status-closed');

        if (data.state === 'opening' || data.state === 'closing') {
            gateStatus.classList.add('status-moving');
            warningIndicator.classList.add('active');
        } else {
            warningIndicator.classList.remove('active');

            if (data.state === 'open') {
                gateStatus.classList.add('status-open');
            } else {
                gateStatus.classList.add('status-closed');
            }
        }
    }

    if (typeof data.showBack === 'boolean') {
        showBackButton = data.showBack;
        backBtn.classList.toggle('hidden', !showBackButton);
    }
}

function showSelector(gates) {
    app.classList.remove('hidden');
    selectorView.classList.remove('hidden');
    controlView.classList.add('hidden');
    currentGateId = null;
    renderGateList(gates || []);
}

function showControl(data) {
    app.classList.remove('hidden');
    selectorView.classList.add('hidden');
    controlView.classList.remove('hidden');
    currentGateId = data.gateId;
    updateControlUI(data);
}

function closePanel() {
    currentGateId = null;
    app.classList.add('hidden');
    selectorView.classList.add('hidden');
    controlView.classList.add('hidden');
}

function sendAction(action) {
    if (!currentGateId) return;
    post('action', { gateId: currentGateId, action });
}

document.getElementById('btn-open').addEventListener('click', () => sendAction('open'));
document.getElementById('btn-stop').addEventListener('click', () => sendAction('stop'));
document.getElementById('btn-close-gate').addEventListener('click', () => sendAction('close'));
document.getElementById('btn-close').addEventListener('click', () => post('close'));
document.getElementById('btn-close-selector').addEventListener('click', () => post('close'));
document.getElementById('btn-back').addEventListener('click', () => post('backToSelector'));

document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') {
        post('close');
    }
});

window.addEventListener('message', (event) => {
    const data = event.data;

    switch (data.action) {
        case 'openSelector':
            showSelector(data.gates);
            break;
        case 'updateSelector':
            if (!selectorView.classList.contains('hidden')) {
                renderGateList(data.gates || []);
            }
            break;
        case 'openControl':
        case 'open':
            showControl(data);
            break;
        case 'close':
            closePanel();
            break;
        case 'updateState':
            updateControlUI(data);
            break;
        case 'playLoop':
            break;
        case 'stopLoop':
            break;
    }
});
