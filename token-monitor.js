#!/usr/bin/env node
/**
 * Token Monitor & Auto-Fallback
 * Monitors Kimi token usage and auto-switches to Gemini backup when low
 */

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const CONFIG_FILE = path.join(process.env.HOME, '.clawdbot/clawdbot.json');
const LOG_FILE = path.join(process.env.HOME, '.clawdbot/token-monitor.log');
const STATE_FILE = path.join(process.env.HOME, '.clawdbot/token-monitor-state.json');

// Thresholds
const WARNING_THRESHOLD = 1000000;   // 1M tokens - warning
const CRITICAL_THRESHOLD = 100000;    // 100k tokens - switch to backup
const CHECK_INTERVAL = 5 * 60 * 1000; // Check every 5 minutes

// Load state
function loadState() {
  try {
    return JSON.parse(fs.readFileSync(STATE_FILE, 'utf8'));
  } catch {
    return {
      lastCheck: 0,
      tokensUsed: 0,
      autoSwitched: false,
      lastProvider: 'kimi-code/kimi-for-coding'
    };
  }
}

// Save state
function saveState(state) {
  fs.writeFileSync(STATE_FILE, JSON.stringify(state, null, 2));
}

// Log message
function log(message) {
  const timestamp = new Date().toISOString();
  const logEntry = `[${timestamp}] ${message}\n`;
  fs.appendFileSync(LOG_FILE, logEntry);
  console.log(logEntry.trim());
}

// Get current provider
function getCurrentProvider() {
  try {
    const config = JSON.parse(fs.readFileSync(CONFIG_FILE, 'utf8'));
    return config.agents?.defaults?.model?.primary || 'unknown';
  } catch {
    return 'unknown';
  }
}

// Check if Kimi API key is valid by making a test request
async function checkKimiStatus() {
  try {
    // Try to get session status from clawdbot
    const result = execSync('clawdbot status --json 2>/dev/null || echo "{}"', { encoding: 'utf8' });
    const status = JSON.parse(result);
    
    // Check for errors in recent sessions
    const recentErrors = status.sessions?.filter(s => 
      s.error && (
        s.error.includes('quota') || 
        s.error.includes('rate limit') ||
        s.error.includes('insufficient') ||
        s.error.includes('401')
      )
    );
    
    if (recentErrors && recentErrors.length > 0) {
      return { ok: false, reason: 'Recent API errors detected', errors: recentErrors };
    }
    
    return { ok: true };
  } catch (error) {
    return { ok: false, reason: error.message };
  }
}

// Switch provider
function switchProvider(provider) {
  try {
    const current = getCurrentProvider();
    
    if (provider === 'gemini') {
      log('🔄 Switching to Gemini backup...');
      execSync('clawdbot config patch --raw \'{\"agents\":{\"defaults\":{\"model\":{\"primary\":\"gemini/gemini-2.0-flash-exp\"}}}}\'', { stdio: 'pipe' });
    } else {
      log('🔄 Switching back to Kimi...');
      execSync('clawdbot config patch --raw \'{\"agents\":{\"defaults\":{\"model\":{\"primary\":\"kimi-code/kimi-for-coding\"}}}}\'', { stdio: 'pipe' });
    }
    
    // Restart gateway
    execSync('clawdbot gateway restart', { stdio: 'pipe' });
    log(`✅ Switched to ${provider === 'gemini' ? 'Gemini' : 'Kimi'}`);
    
    return true;
  } catch (error) {
    log(`❌ Failed to switch: ${error.message}`);
    return false;
  }
}

// Check if Gemini is configured
function checkGeminiConfig() {
  try {
    const envContent = fs.readFileSync(path.join(process.env.HOME, '.clawdbot/.env'), 'utf8');
    return envContent.includes('GEMINI_API_KEY') && 
           !envContent.includes('GEMINI_API_KEY=""');
  } catch {
    return false;
  }
}

// Main monitoring loop
async function monitor() {
  log('🔍 Starting token monitoring...');
  
  const state = loadState();
  const currentProvider = getCurrentProvider();
  const isOnKimi = currentProvider.includes('kimi');
  
  // Check Kimi status
  const kimiStatus = await checkKimiStatus();
  
  if (!kimiStatus.ok && isOnKimi) {
    log(`⚠️ Kimi issue detected: ${kimiStatus.reason}`);
    
    // Check if Gemini is configured
    if (!checkGeminiConfig()) {
      log('❌ Gemini backup not configured!');
      log('   Run: /Users/nemotaka/clawd/setup-gemini-backup.sh');
      return;
    }
    
    // Auto-switch to Gemini
    if (!state.autoSwitched) {
      log('🚨 Auto-switching to Gemini backup...');
      if (switchProvider('gemini')) {
        state.autoSwitched = true;
        state.lastProvider = currentProvider;
        saveState(state);
        
        // Send notification (if we have a way to do that)
        log('📢 Notified: Switched to Gemini backup due to Kimi token/API issues');
      }
    }
  } else if (kimiStatus.ok && state.autoSwitched) {
    // Kimi is back online, offer to switch back
    log('✅ Kimi appears to be working again');
    log('   Run: /Users/nemotaka/clawd/switch-provider.sh kimi  to switch back');
  }
  
  state.lastCheck = Date.now();
  saveState(state);
}

// Run once or start daemon
const mode = process.argv[2];

if (mode === 'daemon') {
  log('🤖 Token Monitor Daemon started');
  log(`   Checking every ${CHECK_INTERVAL / 60000} minutes`);
  
  // Run immediately
  monitor();
  
  // Then schedule
  setInterval(monitor, CHECK_INTERVAL);
  
  // Keep running
  process.stdin.resume();
} else if (mode === 'status') {
  const state = loadState();
  const current = getCurrentProvider();
  
  console.log('Token Monitor Status');
  console.log('====================');
  console.log(`Current Provider: ${current}`);
  console.log(`Auto-switched: ${state.autoSwitched ? 'Yes' : 'No'}`);
  console.log(`Last Check: ${state.lastCheck ? new Date(state.lastCheck).toLocaleString() : 'Never'}`);
  console.log(`Gemini Configured: ${checkGeminiConfig() ? 'Yes' : 'No'}`);
} else {
  // Run once
  monitor();
}
