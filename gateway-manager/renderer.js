// Renderer - Frontend Logic
const { ipcRenderer } = require('electron');

// Supported CLIs for dropdown
const SUPPORTED_CLIS = [
  { id: 'kimi-code', name: 'Kimi Code' },
  { id: 'gemini', name: 'Google Gemini (Free Backup)' },
  { id: 'claude-code', name: 'Claude Code' },
  { id: 'aider', name: 'Aider' },
  { id: 'openai', name: 'OpenAI CLI' },
  { id: 'clawdbot', name: 'Clawdbot' }
];

// State
let currentStatus = { running: false };
let currentProfile = 'default';
let currentProvider = 'Kimi Code';
let backupStatus = { configured: false, monitoring: false };

// DOM Elements
const gatewayToggle = document.getElementById('gateway-toggle');
const gatewayStatus = document.getElementById('gateway-status');
const toggleLabel = document.getElementById('toggle-label');
const profileSelect = document.getElementById('profile-select');
const switchProfileBtn = document.getElementById('switch-profile-btn');
const profileInfo = document.getElementById('profile-info');
const cliSelect = document.getElementById('cli-select');
const cliDetails = document.getElementById('cli-details');
const cliStatusText = document.getElementById('cli-status-text');
const installCliBtn = document.getElementById('install-cli-btn');
const authCliBtn = document.getElementById('auth-cli-btn');
const cliWebsite = document.getElementById('cli-website');
const restartBtn = document.getElementById('restart-btn');
const logsBtn = document.getElementById('logs-btn');
const logsModal = document.getElementById('logs-modal');
const logsContent = document.getElementById('logs-content');
const closeLogs = document.getElementById('close-logs');
const closeLogsBtn = document.getElementById('close-logs-btn');
const refreshLogs = document.getElementById('refresh-logs');

// Initialize
async function init() {
  populateCLIDropdown();
  await updateGatewayStatus();
  await loadProfiles();
  await loadCLIStatuses();
  await loadProviderInfo();
  await loadBackupStatus();
  setupEventListeners();
  
  // Auto-refresh status every 5 seconds
  setInterval(updateGatewayStatus, 5000);
}

// Load Provider Info
async function loadProviderInfo() {
  const result = await ipcRenderer.invoke('get-current-provider');
  currentProvider = result.alias || result.provider;
  
  const providerEl = document.getElementById('current-provider');
  if (providerEl) {
    providerEl.textContent = currentProvider;
    providerEl.className = 'info-value ' + (result.provider.includes('kimi') ? 'kimi' : 'gemini');
  }
}

// Load Backup Status
async function loadBackupStatus() {
  backupStatus = await ipcRenderer.invoke('get-backup-status');
  
  const backupEl = document.getElementById('backup-status');
  if (backupEl) {
    if (backupStatus.configured) {
      backupEl.textContent = backupStatus.monitoring ? '✅ Gemini (Active)' : '⚠️ Gemini (Not monitoring)';
      backupEl.style.color = backupStatus.monitoring ? 'var(--success-color)' : 'var(--warning-color)';
    } else {
      backupEl.textContent = '❌ Not configured';
      backupEl.style.color = 'var(--danger-color)';
    }
  }
}

// Populate CLI Dropdown
function populateCLIDropdown() {
  cliSelect.innerHTML = '<option value="">Select CLI to configure...</option>';
  SUPPORTED_CLIS.forEach(cli => {
    const option = document.createElement('option');
    option.value = cli.id;
    option.textContent = cli.name;
    cliSelect.appendChild(option);
  });
}

// Update Gateway Status
async function updateGatewayStatus() {
  const status = await ipcRenderer.invoke('get-gateway-status');
  currentStatus = status;
  
  if (status.running) {
    gatewayStatus.classList.remove('offline');
    gatewayStatus.querySelector('.status-text').textContent = 'Online';
    gatewayToggle.checked = true;
    toggleLabel.textContent = 'Gateway ON';
    toggleLabel.style.color = 'var(--success-color)';
  } else {
    gatewayStatus.classList.add('offline');
    gatewayStatus.querySelector('.status-text').textContent = 'Offline';
    gatewayToggle.checked = false;
    toggleLabel.textContent = 'Gateway OFF';
    toggleLabel.style.color = 'var(--danger-color)';
  }
}

// Load Profiles
async function loadProfiles() {
  const { profiles, activeProfile } = await ipcRenderer.invoke('get-profiles');
  currentProfile = activeProfile;
  
  profileSelect.innerHTML = '';
  profiles.forEach(profile => {
    const option = document.createElement('option');
    option.value = profile;
    option.textContent = profile;
    if (profile === activeProfile) option.selected = true;
    profileSelect.appendChild(option);
  });
  
  profileInfo.innerHTML = `Current: <strong>${activeProfile}</strong>`;
}

// Load CLI Statuses
async function loadCLIStatuses() {
  // This will be used to pre-populate installation status
}

// Check selected CLI status
async function checkSelectedCLI() {
  const cliId = cliSelect.value;
  if (!cliId) {
    cliDetails.classList.add('hidden');
    return;
  }
  
  const result = await ipcRenderer.invoke('check-cli', cliId);
  cliDetails.classList.remove('hidden');
  
  if (result.installed) {
    cliStatusText.textContent = 'Installed ✅';
    cliStatusText.className = 'status-value installed';
    installCliBtn.innerHTML = '<span>✅</span> Installed';
    installCliBtn.disabled = true;
    authCliBtn.style.display = 'inline-flex';
  } else {
    cliStatusText.textContent = 'Not Installed ❌';
    cliStatusText.className = 'status-value not-installed';
    installCliBtn.innerHTML = '<span>📦</span> Install';
    installCliBtn.disabled = false;
    authCliBtn.style.display = 'none';
  }
  
  // Set website link
  const cli = SUPPORTED_CLIS.find(c => c.id === cliId);
  if (cli) {
    cliWebsite.href = '#';
    cliWebsite.onclick = () => ipcRenderer.invoke('open-external', cli.website);
  }
}

// Setup Event Listeners
function setupEventListeners() {
  // Gateway Toggle
  gatewayToggle.addEventListener('change', async () => {
    const action = gatewayToggle.checked ? 'start' : 'stop';
    showToast(`${action === 'start' ? 'Starting' : 'Stopping'} gateway...`, 'info');
    
    const result = await ipcRenderer.invoke('toggle-gateway', action);
    
    if (result.success) {
      showToast(`Gateway ${action === 'start' ? 'started' : 'stopped'}!`, 'success');
      await updateGatewayStatus();
    } else {
      showToast(`Failed: ${result.error}`, 'error');
      gatewayToggle.checked = !gatewayToggle.checked;
    }
  });
  
  // Switch Profile
  switchProfileBtn.addEventListener('click', async () => {
    const profile = profileSelect.value;
    if (profile === currentProfile) {
      showToast('Already on this profile', 'info');
      return;
    }
    
    const result = await ipcRenderer.invoke('switch-profile', profile);
    if (result.success) {
      currentProfile = profile;
      profileInfo.innerHTML = `Current: <strong>${profile}</strong>`;
      showToast(`Switched to profile: ${profile}`, 'success');
    } else {
      showToast(`Failed: ${result.error}`, 'error');
    }
  });
  
  // CLI Selection
  cliSelect.addEventListener('change', checkSelectedCLI);
  
  // Install CLI
  installCliBtn.addEventListener('click', async () => {
    const cliId = cliSelect.value;
    if (!cliId) return;
    
    showToast('Opening terminal for installation...', 'info');
    const result = await ipcRenderer.invoke('install-cli', cliId);
    
    if (result.success) {
      showToast(result.message, 'success');
    } else {
      showToast(`Error: ${result.error}`, 'error');
    }
  });
  
  // Setup CLI Auth
  authCliBtn.addEventListener('click', async () => {
    const cliId = cliSelect.value;
    if (!cliId) return;
    
    showToast('Opening terminal for authentication...', 'info');
    const result = await ipcRenderer.invoke('setup-cli-auth', cliId);
    
    if (result.success) {
      showToast(result.message, 'success');
    } else {
      showToast(`Error: ${result.error}`, 'error');
    }
  });
  
  // Restart Gateway
  restartBtn.addEventListener('click', async () => {
    showToast('Restarting gateway...', 'info');
    const result = await ipcRenderer.invoke('restart-gateway');
    
    if (result.success) {
      showToast('Gateway restarted!', 'success');
      await updateGatewayStatus();
    } else {
      showToast(`Failed: ${result.error}`, 'error');
    }
  });
  
  // View Logs
  logsBtn.addEventListener('click', async () => {
    logsModal.classList.remove('hidden');
    await refreshLogsContent();
  });
  
  // Close Logs
  closeLogs.addEventListener('click', () => {
    logsModal.classList.add('hidden');
  });
  
  closeLogsBtn.addEventListener('click', () => {
    logsModal.classList.add('hidden');
  });
  
  // Refresh Logs
  refreshLogs.addEventListener('click', refreshLogsContent);
  
  // Close modal on outside click
  logsModal.addEventListener('click', (e) => {
    if (e.target === logsModal) {
      logsModal.classList.add('hidden');
    }
  });
  
  // Provider Switching
  const switchKimiBtn = document.getElementById('switch-kimi-btn');
  const switchGeminiBtn = document.getElementById('switch-gemini-btn');
  const autoFallbackToggle = document.getElementById('auto-fallback-toggle');
  
  if (switchKimiBtn) {
    switchKimiBtn.addEventListener('click', async () => {
      showToast('Switching to Kimi...', 'info');
      const result = await ipcRenderer.invoke('switch-provider', 'kimi');
      if (result.success) {
        showToast('Switched to Kimi Code!', 'success');
        await loadProviderInfo();
        updateProviderUI('kimi');
      } else {
        showToast(`Failed: ${result.error}`, 'error');
      }
    });
  }
  
  if (switchGeminiBtn) {
    switchGeminiBtn.addEventListener('click', async () => {
      showToast('Switching to Gemini...', 'info');
      const result = await ipcRenderer.invoke('switch-provider', 'gemini');
      if (result.success) {
        showToast('Switched to Gemini!', 'success');
        await loadProviderInfo();
        updateProviderUI('gemini');
      } else {
        showToast(`Failed: ${result.error}`, 'error');
      }
    });
  }
  
  if (autoFallbackToggle) {
    autoFallbackToggle.addEventListener('change', async () => {
      const enabled = autoFallbackToggle.checked;
      showToast(`${enabled ? 'Enabling' : 'Disabling'} auto-fallback...`, 'info');
      const result = await ipcRenderer.invoke('toggle-monitor', enabled);
      if (result.success) {
        showToast(`Auto-fallback ${result.enabled ? 'enabled' : 'disabled'}!`, 'success');
      } else {
        showToast(`Failed: ${result.error}`, 'error');
        autoFallbackToggle.checked = !enabled;
      }
    });
  }
}

// Update Provider UI
function updateProviderUI(activeProvider) {
  const kimiItem = document.getElementById('kimi-provider');
  const geminiItem = document.getElementById('gemini-provider');
  
  if (activeProvider === 'kimi') {
    kimiItem.classList.add('active');
    kimiItem.classList.remove('inactive');
    geminiItem.classList.remove('active');
    geminiItem.classList.add('inactive');
  } else {
    geminiItem.classList.add('active');
    geminiItem.classList.remove('inactive');
    kimiItem.classList.remove('active');
    kimiItem.classList.add('inactive');
  }
}

// Refresh Logs Content
async function refreshLogsContent() {
  logsContent.textContent = 'Loading...';
  const logs = await ipcRenderer.invoke('get-logs');
  logsContent.textContent = logs;
  logsContent.scrollTop = logsContent.scrollHeight;
}

// Show Toast Notification
function showToast(message, type = 'info') {
  const container = document.getElementById('toast-container');
  const toast = document.createElement('div');
  toast.className = `toast ${type}`;
  toast.textContent = message;
  
  container.appendChild(toast);
  
  setTimeout(() => {
    toast.style.animation = 'slideIn 0.3s ease reverse';
    setTimeout(() => toast.remove(), 300);
  }, 3000);
}

// Start
init();
