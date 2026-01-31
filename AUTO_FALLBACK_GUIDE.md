# 🤖 Token Monitor & Auto-Fallback Setup

## Overview
Automatically monitors your Kimi token usage and switches to **FREE Gemini backup** when tokens run low.

## 📋 What Was Created

| File | Purpose |
|------|---------|
| `token-monitor.js` | Monitors tokens & auto-switches |
| `setup-token-monitor.sh` | Sets up the monitor daemon |
| `switch-provider.sh` | Manual provider switching |
| `setup-gemini-backup.sh` | Configure Gemini as backup |

## 🚀 Quick Setup

### Step 1: Add Gemini API Key
```bash
# Edit your .env file
nano ~/.clawdbot/.env

# Add your free Gemini API key:
export GEMINI_API_KEY="your_key_here"
```
**Get free key at:** https://aistudio.google.com/app/apikey

### Step 2: Run Setup
```bash
cd /Users/nemotaka/clawd
./setup-token-monitor.sh
```

This will:
- ✅ Configure Gemini as backup provider
- ✅ Add monitoring cron job
- ✅ Create LaunchAgent daemon
- ✅ Start monitoring automatically

## 🎛️ How It Works

### Automatic Fallback
1. **Monitors every 5 minutes** for token/API issues
2. **Detects when Kimi fails** (quota, rate limit, errors)
3. **Auto-switches to Gemini** (free tier)
4. **Notifies you** of the switch
5. **Can switch back** when Kimi recovers

### Manual Control
```bash
# Check status
node token-monitor.js status

# Switch to Gemini manually
./switch-provider.sh gemini

# Switch back to Kimi
./switch-provider.sh kimi

# Auto-detect best provider
./switch-provider.sh auto
```

## 📊 Gateway Manager Integration

The Gateway Manager app now shows:
- 🟣 **Kimi Code** (Primary)
- 🔵 **Gemini Flash** (Backup)
- **Auto-fallback toggle** switch
- **One-click provider switching**

## 🔄 Provider Comparison

| Feature | Kimi Code | Gemini Flash |
|---------|-----------|--------------|
| **Cost** | Your credits | **FREE** |
| **Context** | 256K tokens | **1M tokens** |
| **Speed** | Fast | **Very Fast** |
| **Images** | ❌ | ✅ |
| **Reasoning** | ✅ | ✅ |

## 📁 Log Files

| File | Description |
|------|-------------|
| `~/.clawdbot/token-monitor.log` | Monitor activity log |
| `~/.clawdbot/token-monitor-daemon.log` | Daemon output |
| `~/.clawdbot/token-monitor-state.json` | Current state |

## 🛑 Stopping/Starting

```bash
# Stop monitor
launchctl unload ~/Library/LaunchAgents/com.nemotrades.token-monitor.plist

# Start monitor
launchctl load ~/Library/LaunchAgents/com.nemotrades.token-monitor.plist

# Check if running
launchctl list | grep token-monitor
```

## ⚡ One-Liner Setup

```bash
cd /Users/nemotaka/clawd && ./setup-token-monitor.sh
```

**That's it!** You're now protected from running out of tokens. 🎉
