#!/bin/bash
# Setup Token Monitor with Auto-Fallback

echo "🔧 Setting up Token Monitor & Auto-Fallback"
echo "============================================"
echo ""

# Make scripts executable
chmod +x /Users/nemotaka/clawd/token-monitor.js
chmod +x /Users/nemotaka/clawd/switch-provider.sh
chmod +x /Users/nemotaka/clawd/setup-gemini-backup.sh

echo "✅ Scripts are executable"
echo ""

# Check if Gemini is configured
if ! grep -q "GEMINI_API_KEY" ~/.clawdbot/.env 2>/dev/null || grep -q 'GEMINI_API_KEY=""' ~/.clawdbot/.env 2>/dev/null; then
    echo "⚠️  Gemini API key not configured!"
    echo ""
    echo "To enable auto-fallback:"
    echo "1. Get free API key: https://aistudio.google.com/app/apikey"
    echo "2. Add to ~/.clawdbot/.env:"
    echo "   export GEMINI_API_KEY='your_key_here'"
    echo "3. Run: ./setup-gemini-backup.sh"
    echo ""
    exit 1
fi

echo "✅ Gemini backup configured"
echo ""

# Add cron job for monitoring
echo "📝 Setting up cron job..."

# Remove old entry if exists
(crontab -l 2>/dev/null | grep -v "token-monitor.js") | crontab -

# Add new entry - check every 5 minutes
(crontab -l 2>/dev/null; echo "*/5 * * * * cd /Users/nemotaka/clawd && /usr/local/bin/node token-monitor.js >> ~/.clawdbot/token-monitor-cron.log 2>&1") | crontab -

echo "✅ Cron job added - checking every 5 minutes"
echo ""

# Create LaunchAgent for macOS (more reliable than cron)
LAUNCHAGENT_DIR="$HOME/Library/LaunchAgents"
PLIST_FILE="$LAUNCHAGENT_DIR/com.nemotrades.token-monitor.plist"

mkdir -p "$LAUNCHAGENT_DIR"

cat > "$PLIST_FILE" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.nemotrades.token-monitor</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/node</string>
        <string>/Users/nemotaka/clawd/token-monitor.js</string>
        <string>daemon</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/Users/nemotaka/.clawdbot/token-monitor-daemon.log</string>
    <key>StandardErrorPath</key>
    <string>/Users/nemotaka/.clawdbot/token-monitor-daemon.error.log</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>HOME</key>
        <string>/Users/nemotaka</string>
        <key>PATH</key>
        <string>/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
    </dict>
</dict>
</plist>
EOF

echo "✅ LaunchAgent created"
echo ""

# Ask if they want to start it now
echo "🚀 Options:"
echo "  1. Start daemon now (recommended)"
echo "  2. Start later manually"
echo ""

# Start the daemon
launchctl load "$PLIST_FILE" 2>/dev/null || true

echo "✅ Token Monitor daemon started!"
echo ""
echo "📊 Commands:"
echo "  Check status:   node token-monitor.js status"
echo "  Run once:       node token-monitor.js"
echo "  Stop daemon:    launchctl unload ~/Library/LaunchAgents/com.nemotrades.token-monitor.plist"
echo "  Start daemon:   launchctl load ~/Library/LaunchAgents/com.nemotrades.token-monitor.plist"
echo ""
echo "📁 Logs:"
echo "  Main log:       ~/.clawdbot/token-monitor.log"
echo "  Daemon log:     ~/.clawdbot/token-monitor-daemon.log"
echo ""
echo "✨ Auto-fallback is now active!"
echo "   When Kimi tokens run low, I'll automatically switch to Gemini."
