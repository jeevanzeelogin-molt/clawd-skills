#!/bin/bash
# Cheddar Flow Hybrid Tracker - Hourly Monitor
# Runs hourly checks and alerts on big moves

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TRACKER="$SCRIPT_DIR/hybrid-tracker.py"
LOG_FILE="/Users/nemotaka/clawd/logs/cheddar-hybrid-monitor.log"
ALERTS_FILE="/Users/nemotaka/clawd/logs/cheddar-big-move-alerts.json"

export PATH="$HOME/.local/bin:$PATH"

# Run hourly check
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Running hourly check..." >> "$LOG_FILE"

uv run --with yfinance --with numpy --with scipy "$TRACKER" hourly 2>&1 | tee -a "$LOG_FILE"

# Check if there are new big move alerts
if [ -f "$ALERTS_FILE" ]; then
    NEW_ALERTS=$(python3 -c "
import json
with open('$ALERTS_FILE', 'r') as f:
    data = json.load(f)
# Get alerts from last hour
from datetime import datetime, timedelta
one_hour_ago = datetime.now() - timedelta(hours=1)
count = 0
for alert in data['alerts']:
    alert_time = datetime.fromisoformat(alert['timestamp'])
    if alert_time > one_hour_ago:
        count += 1
print(count)
" 2>/dev/null)
    
    if [ "$NEW_ALERTS" -gt 0 ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] 🚨 $NEW_ALERTS new big move alerts detected!" >> "$LOG_FILE"
        
        # Send Discord notification (optional)
        # cd /Users/nemotaka/clawd && clawdbot message send --channel discord --target "1466878278592631011" -m "🚨 Big move detected in Cheddar Flow alerts! Check Option Omega."
    fi
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Hourly check complete" >> "$LOG_FILE"
