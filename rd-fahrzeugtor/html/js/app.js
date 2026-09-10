const app = document.getElementById('app');
const gateLabel = document.getElementById('gate-label');
const gateStatus = document.getElementById('gate-status');
const progressFill = document.getElementById('progress-fill');
const progressLabel = document.getElementById('progress-label');
const warningIndicator = document.getElementById('warning-indicator');
let currentGateId = null;
let currentState = 'closed';

function post(action, data = {}) {
    return fetch(`https://${GetParentResourceName()}/${action}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
    });
}

function updateUI(data) {
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
}

function openPanel(data) {
    currentGateId = data.gateId;
    app.classList.remove('hidden');
    updateUI(data);
}

function closePanel() {
    currentGateId = null;
    app.classList.add('hidden');
    stopSound();
}

function sendAction(action) {
    if (!currentGateId) return;
    post('action', { gateId: currentGateId, action });
}

function playSound() {
    // Zusätzliche NUI-Sounds können hier ergänzt werden
}

function stopSound() {
    // Zusätzliche NUI-Sounds können hier gestoppt werden
}

document.getElementById('btn-open').addEventListener('click', () => sendAction('open'));
document.getElementById('btn-stop').addEventListener('click', () => sendAction('stop'));
document.getElementById('btn-close-gate').addEventListener('click', () => sendAction('close'));
document.getElementById('btn-close').addEventListener('click', () => post('close'));

document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') {
        post('close');
    }
});

window.addEventListener('message', (event) => {
    const data = event.data;

    switch (data.action) {
        case 'open':
            openPanel(data);
            break;
        case 'close':
            closePanel();
            break;
        case 'updateState':
            updateUI(data);
            break;
        case 'playLoop':
            playSound(data.volume);
            break;
        case 'stopLoop':
            stopSound();
            break;
    }
});
