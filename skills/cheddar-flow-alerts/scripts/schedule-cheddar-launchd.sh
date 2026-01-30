#!/bin/bash
# Schedule Cheddar Flow alerts via Launchd

echo "🧀 Setting up Cheddar Flow automated alerts..."
echo ""

PLIST_SOURCE="/Users/nemotaka/clawd/skills/cheddar-flow-alerts/scripts/com.clawd.cheddar-alerts.plist"
PLIST_DEST="$HOME/Library/LaunchAgents/com.clawd.cheddar-alerts.plist"

# Copy plist
cp "$PLIST_SOURCE" "$PLIST_DEST"

# Load the job
launchctl load "$PLIST_DEST"

echo "✅ Cheddar Flow alerts scheduled!"
echo ""
echo "Schedule: Every 5 minutes"
echo "Logs: /Users/nemotaka/clawd/logs/cheddar-alerts.log"
echo ""
echo "To check status:"
echo "  launchctl list | grep cheddar"
echo ""
echo "To stop:"
echo "  launchctl unload ~/Library/LaunchAgents/com.clawd.cheddar-alerts.plist"
