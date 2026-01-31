const { app, BrowserWindow, ipcMain, shell } = require('electron');
const { exec, execSync, spawn } = require('child_process');
const path = require('path');
const fs = require('fs');

const CONFIG_DIR = path.join(process.env.HOME, '.clawdbot');
const CONFIG_FILE = path.join(CONFIG_DIR, 'clawdbot.json');

// Supported CLIs
const SUPPORTED_CLIS = [
  { 
    id: 'kimi-code',
    name: 'Kimi Code', 
    cmd: 'kimi', 
    installCmd: 'npm install -g kimi-code && npm install -g @anthropic-ai/claude-code',
    authCmd: 'kimi -k YOUR_API_KEY --base-url https://api.moonshot.ai/v1',
    website: 'https://kimi.com',
    note: 'Also requires claude-code'
  },
  { 
    id: 'gemini',
    name: 'Google Gemini', 
    cmd: 'gemini', 
    installCmd: 'npm install -g @google/generative-ai',
    authCmd: null,
    website: 'https://aistudio.google.com/app/apikey',
    note: 'Free tier available'
  },
  { 
    id: 'claude-code',
    name: 'Claude Code', 
    cmd: 'claude', 
    installCmd: 'npm install -g @anthropic-ai/claude-code',
    authCmd: 'claude auth login',
    website: 'https://claude.ai'
  },
  { 
    id: 'aider',
    name: 'Aider', 
    cmd: 'aider', 
    installCmd: 'pip install aider-chat',
    authCmd: null,
    website: 'https://aider.chat'
  },
  { 
    id: 'openai',
    name: 'OpenAI CLI', 
    cmd: 'openai', 
    installCmd: 'npm install -g openai',
    authCmd: 'openai api auth',
    website: 'https://openai.com'
  },
  { 
    id: 'clawdbot',
    name: 'Clawdbot', 
    cmd: 'clawdbot', 
    installCmd: 'npm install -g clawdbot',
    authCmd: 'clawdbot doctor',
    website: 'https://clawd.bot'
  }
];

let mainWindow;

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 900,
    height: 700,
    minWidth: 700,
    minHeight: 500,
    titleBarStyle: 'hiddenInset',
    webPreferences: {
      nodeIntegration: true,
      contextIsolation: false,
      enableRemoteModule: true
    },
    icon: path.join(__dirname, 'icon.png')
  });

  mainWindow.loadFile('index.html');
  
  if (process.argv.includes('--dev')) {
    mainWindow.webContents.openDevTools();
  }
}

app.whenReady().then(createWindow);

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});

app.on('activate', () => {
  if (BrowserWindow.getAllWindows().length === 0) createWindow();
});

// IPC Handlers

// Get gateway status
ipcMain.handle('get-gateway-status', async () => {
  return new Promise((resolve) => {
    exec('clawdbot gateway status', (error, stdout) => {
      if (error) {
        resolve({ running: false, error: error.message });
      } else {
        const running = stdout.includes('running') || stdout.includes('active');
        resolve({ running, output: stdout });
      }
    });
  });
});

// Toggle gateway
ipcMain.handle('toggle-gateway', async (event, action) => {
  return new Promise((resolve) => {
    const cmd = action === 'start' ? 'clawdbot gateway start' : 'clawdbot gateway stop';
    exec(cmd, (error, stdout, stderr) => {
      if (error) {
        resolve({ success: false, error: stderr || error.message });
      } else {
        resolve({ success: true, output: stdout });
      }
    });
  });
});

// Get profiles
ipcMain.handle('get-profiles', async () => {
  try {
    const config = JSON.parse(fs.readFileSync(CONFIG_FILE, 'utf8'));
    const profiles = Object.keys(config.agents?.profiles || {});
    const activeProfile = config.activeProfile || 'default';
    return { profiles, activeProfile };
  } catch {
    return { profiles: ['default'], activeProfile: 'default' };
  }
});

// Switch profile
ipcMain.handle('switch-profile', async (event, profileName) => {
  try {
    const config = JSON.parse(fs.readFileSync(CONFIG_FILE, 'utf8'));
    config.activeProfile = profileName;
    fs.writeFileSync(CONFIG_FILE, JSON.stringify(config, null, 2));
    return { success: true };
  } catch (error) {
    return { success: false, error: error.message };
  }
});

// Check CLI installed
ipcMain.handle('check-cli', async (event, cliId) => {
  const cli = SUPPORTED_CLIS.find(c => c.id === cliId);
  if (!cli) return { installed: false };
  
  return new Promise((resolve) => {
    exec(`which ${cli.cmd}`, (error) => {
      resolve({ installed: !error, cli });
    });
  });
});

// Get all CLI statuses
ipcMain.handle('get-all-cli-status', async () => {
  const results = [];
  
  for (const cli of SUPPORTED_CLIS) {
    const installed = await new Promise(resolve => {
      exec(`which ${cli.cmd}`, (error) => resolve(!error));
    });
    results.push({ ...cli, installed });
  }
  
  return results;
});

// Install CLI
ipcMain.handle('install-cli', async (event, cliId) => {
  const cli = SUPPORTED_CLIS.find(c => c.id === cliId);
  if (!cli) return { success: false, error: 'CLI not found' };
  
  return new Promise((resolve) => {
    // Open terminal with install command
    const terminalCmd = process.platform === 'darwin' 
      ? `open -a Terminal "${cli.installCmd}"`
      : `start cmd /k "${cli.installCmd}"`;
    
    exec(terminalCmd, (error) => {
      if (error) {
        resolve({ success: false, error: error.message });
      } else {
        resolve({ success: true, message: `Installing ${cli.name}...` });
      }
    });
  });
});

// Setup CLI auth
ipcMain.handle('setup-cli-auth', async (event, cliId) => {
  const cli = SUPPORTED_CLIS.find(c => c.id === cliId);
  if (!cli || !cli.authCmd) return { success: false, error: 'No auth command' };
  
  return new Promise((resolve) => {
    const terminalCmd = process.platform === 'darwin'
      ? `open -a Terminal "${cli.authCmd}"`
      : `start cmd /k "${cli.authCmd}"`;
    
    exec(terminalCmd, (error) => {
      if (error) {
        resolve({ success: false, error: error.message });
      } else {
        resolve({ success: true, message: `Opening auth for ${cli.name}` });
      }
    });
  });
});

// Open external link
ipcMain.handle('open-external', async (event, url) => {
  shell.openExternal(url);
});

// Get gateway logs
ipcMain.handle('get-logs', async () => {
  return new Promise((resolve) => {
    exec('clawdbot gateway logs --tail 100 2>&1 || echo "No logs available"', (error, stdout) => {
      resolve(stdout || 'No logs available');
    });
  });
});

// Restart gateway
ipcMain.handle('restart-gateway', async () => {
  return new Promise((resolve) => {
    exec('clawdbot gateway restart', (error, stdout, stderr) => {
      if (error) {
        resolve({ success: false, error: stderr || error.message });
      } else {
        resolve({ success: true, output: stdout });
      }
    });
  });
});

// Switch AI Provider
ipcMain.handle('switch-provider', async (event, provider) => {
  return new Promise((resolve) => {
    const scriptPath = path.join(process.env.HOME, 'clawd', 'switch-provider.sh');
    exec(`${scriptPath} ${provider}`, (error, stdout, stderr) => {
      if (error) {
        resolve({ success: false, error: stderr || error.message });
      } else {
        resolve({ success: true, output: stdout });
      }
    });
  });
});

// Get current provider
ipcMain.handle('get-current-provider', async () => {
  try {
    const config = JSON.parse(fs.readFileSync(CONFIG_FILE, 'utf8'));
    const provider = config.agents?.defaults?.model?.primary || 'unknown';
    const alias = config.agents?.defaults?.models?.[provider]?.alias || provider;
    return { provider, alias };
  } catch (error) {
    return { provider: 'unknown', alias: 'Unknown', error: error.message };
  }
});

// Check Gemini backup status
ipcMain.handle('get-backup-status', async () => {
  try {
    const envPath = path.join(CONFIG_DIR, '.env');
    const envContent = fs.readFileSync(envPath, 'utf8');
    const hasGeminiKey = envContent.includes('GEMINI_API_KEY') && 
                         !envContent.match(/GEMINI_API_KEY="?"?\s*$/m);
    
    // Check if monitor is running
    const monitorRunning = await new Promise(resolve => {
      exec('launchctl list | grep com.nemotrades.token-monitor', (error) => {
        resolve(!error);
      });
    });
    
    return { 
      configured: hasGeminiKey, 
      monitoring: monitorRunning,
      message: hasGeminiKey ? 'Gemini backup ready' : 'Gemini not configured'
    };
  } catch (error) {
    return { configured: false, monitoring: false, error: error.message };
  }
});

// Setup Gemini backup
ipcMain.handle('setup-gemini-backup', async () => {
  return new Promise((resolve) => {
    const scriptPath = path.join(process.env.HOME, 'clawd', 'setup-gemini-backup.sh');
    exec(`open -a Terminal "${scriptPath}"`, (error) => {
      if (error) {
        resolve({ success: false, error: error.message });
      } else {
        resolve({ success: true, message: 'Setup started in terminal' });
      }
    });
  });
});

// Toggle auto-fallback monitor
ipcMain.handle('toggle-monitor', async (event, enable) => {
  return new Promise((resolve) => {
    const plistPath = path.join(process.env.HOME, 'Library/LaunchAgents/com.nemotrades.token-monitor.plist');
    
    if (enable) {
      exec(`launchctl load ${plistPath} 2>/dev/null || launchctl start com.nemotrades.token-monitor`, (error) => {
        resolve({ success: !error, enabled: true, error: error?.message });
      });
    } else {
      exec(`launchctl unload ${plistPath} 2>/dev/null; launchctl stop com.nemotrades.token-monitor 2>/dev/null`, (error) => {
        resolve({ success: true, enabled: false });
      });
    }
  });
});
