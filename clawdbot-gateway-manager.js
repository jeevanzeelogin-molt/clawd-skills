#!/usr/bin/env node
/**
 * Clawdbot Gateway Manager - Standalone App
 * 
 * Features:
 * - Toggle between profiles
 * - On/off button for each profile's gateway
 * - CLI dropdown with auto-install
 * - Support for Kimi Code CLI
 * - Profile switching
 */

const { execSync, spawn } = require('child_process');
const fs = require('fs');
const path = require('path');
const readline = require('readline');

const CONFIG_DIR = path.join(process.env.HOME, '.clawdbot');
const CONFIG_FILE = path.join(CONFIG_DIR, 'clawdbot.json');

// Supported CLIs
const SUPPORTED_CLIS = [
  { name: 'Kimi Code', cmd: 'kimi', installCmd: 'npm install -g @kimi-cli/cli', authCmd: 'kimi auth login' },
  { name: 'Claude Code', cmd: 'claude', installCmd: 'npm install -g @anthropic-ai/claude-code', authCmd: 'claude auth login' },
  { name: 'Aider', cmd: 'aider', installCmd: 'pip install aider-chat', authCmd: 'aider --help' },
  { name: 'OpenAI CLI', cmd: 'openai', installCmd: 'npm install -g openai', authCmd: 'openai auth login' }
];

// Simple CLI UI
const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

function clearScreen() {
  console.clear();
}

function printHeader() {
  console.log('╔════════════════════════════════════════════════════════╗');
  console.log('║        CLAWDBOT GATEWAY MANAGER v1.0                   ║');
  console.log('║        Profile & CLI Management Dashboard              ║');
  console.log('╚════════════════════════════════════════════════════════╝');
  console.log('');
}

function getConfig() {
  try {
    return JSON.parse(fs.readFileSync(CONFIG_FILE, 'utf8'));
  } catch {
    return { agents: {}, gateway: {} };
  }
}

function saveConfig(config) {
  fs.writeFileSync(CONFIG_FILE, JSON.stringify(config, null, 2));
}

function checkCLInstalled(cmd) {
  try {
    execSync(`which ${cmd}`, { stdio: 'pipe' });
    return true;
  } catch {
    return false;
  }
}

function installCLI(cli) {
  console.log(`\n📦 Installing ${cli.name}...`);
  console.log(`Running: ${cli.installCmd}`);
  
  try {
    execSync(cli.installCmd, { stdio: 'inherit' });
    console.log(`✅ ${cli.name} installed successfully!`);
    return true;
  } catch (error) {
    console.error(`❌ Failed to install ${cli.name}:`, error.message);
    return false;
  }
}

function setupCLIAuth(cli) {
  console.log(`\n🔐 Setting up ${cli.name} authentication...`);
  console.log(`Opening terminal with: ${cli.authCmd}`);
  console.log('Please complete the authentication in the terminal window.\n');
  
  spawn('open', ['-a', 'Terminal', cli.authCmd], { 
    detached: true,
    stdio: 'ignore'
  }).unref();
}

function getGatewayStatus() {
  try {
    const result = execSync('clawdbot gateway status', { encoding: 'utf8' });
    return result.includes('running') ? 'ON' : 'OFF';
  } catch {
    return 'OFF';
  }
}

function toggleGateway() {
  const status = getGatewayStatus();
  
  if (status === 'ON') {
    console.log('🛑 Stopping gateway...');
    execSync('clawdbot gateway stop', { stdio: 'inherit' });
  } else {
    console.log('🚀 Starting gateway...');
    execSync('clawdbot gateway start', { stdio: 'inherit' });
  }
}

function switchProfile(profileName) {
  console.log(`\n🔄 Switching to profile: ${profileName}`);
  
  try {
    // Update config to use this profile
    const config = getConfig();
    config.activeProfile = profileName;
    saveConfig(config);
    
    console.log(`✅ Switched to profile: ${profileName}`);
  } catch (error) {
    console.error(`❌ Failed to switch profile:`, error.message);
  }
}

function showCLIMenu() {
  console.log('\n📋 Supported CLIs:');
  console.log('─────────────────────────────────────────────────');
  
  SUPPORTED_CLIS.forEach((cli, index) => {
    const installed = checkCLInstalled(cli.cmd);
    const status = installed ? '✅ Installed' : '❌ Not installed';
    console.log(`${index + 1}. ${cli.name.padEnd(15)} ${status}`);
  });
  
  console.log('');
  console.log('0. Back to main menu');
}

function showMainMenu() {
  clearScreen();
  printHeader();
  
  const config = getConfig();
  const gatewayStatus = getGatewayStatus();
  const activeProfile = config.activeProfile || 'default';
  
  console.log(`📊 Gateway Status: ${gatewayStatus === 'ON' ? '🟢 ON' : '🔴 OFF'}`);
  console.log(`👤 Active Profile: ${activeProfile}`);
  console.log('');
  console.log('─────────────────────────────────────────────────');
  console.log('');
  console.log('1. Toggle Gateway (ON/OFF)');
  console.log('2. Switch Profile');
  console.log('3. Manage CLIs (Install/Configure)');
  console.log('4. View Gateway Logs');
  console.log('5. Restart Gateway');
  console.log('');
  console.log('0. Exit');
  console.log('');
}

async function main() {
  while (true) {
    showMainMenu();
    
    const choice = await new Promise(resolve => {
      rl.question('Select option: ', resolve);
    });
    
    switch(choice.trim()) {
      case '1':
        toggleGateway();
        await new Promise(r => setTimeout(r, 2000));
        break;
        
      case '2':
        // Show profile switcher
        console.log('\nAvailable profiles:');
        // This would list profiles from config
        rl.question('Enter profile name: ', (profile) => {
          switchProfile(profile.trim());
        });
        await new Promise(r => setTimeout(r, 1000));
        break;
        
      case '3':
        // CLI Management
        while (true) {
          showCLIMenu();
          const cliChoice = await new Promise(resolve => {
            rl.question('Select CLI to install/configure: ', resolve);
          });
          
          if (cliChoice.trim() === '0') break;
          
          const cliIndex = parseInt(cliChoice.trim()) - 1;
          if (cliIndex >= 0 && cliIndex < SUPPORTED_CLIS.length) {
            const cli = SUPPORTED_CLIS[cliIndex];
            
            if (checkCLInstalled(cli.cmd)) {
              console.log(`\n✅ ${cli.name} is already installed!`);
              const setupAuth = await new Promise(resolve => {
                rl.question('Setup/update authentication? (y/n): ', resolve);
              });
              
              if (setupAuth.toLowerCase() === 'y') {
                setupCLIAuth(cli);
              }
            } else {
              const confirm = await new Promise(resolve => {
                rl.question(`Install ${cli.name}? (y/n): `, resolve);
              });
              
              if (confirm.toLowerCase() === 'y') {
                if (installCLI(cli)) {
                  setupCLIAuth(cli);
                }
              }
            }
          }
        }
        break;
        
      case '4':
        console.log('\n📜 Gateway Logs (last 50 lines):');
        console.log('─────────────────────────────────────────────────');
        try {
          const logs = execSync('clawdbot gateway logs --tail 50', { encoding: 'utf8' });
          console.log(logs);
        } catch {
          console.log('No logs available.');
        }
        await new Promise(resolve => {
          rl.question('\nPress Enter to continue...', resolve);
        });
        break;
        
      case '5':
        console.log('\n🔄 Restarting gateway...');
        try {
          execSync('clawdbot gateway restart', { stdio: 'inherit' });
          console.log('✅ Gateway restarted!');
        } catch (error) {
          console.error('❌ Failed to restart gateway:', error.message);
        }
        await new Promise(r => setTimeout(r, 2000));
        break;
        
      case '0':
        console.log('\n👋 Goodbye!');
        rl.close();
        process.exit(0);
        
      default:
        console.log('\n❌ Invalid option');
        await new Promise(r => setTimeout(r, 1000));
    }
  }
}

// Run the app
main().catch(error => {
  console.error('Error:', error);
  process.exit(1);
});
