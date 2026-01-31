#!/bin/bash
# Cheddar Flow Auto 3-Day Result Calculator
# Runs daily to check if any alerts are 3 days old and calculates results

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ALERTS_DB="/Users/nemotaka/clawd/logs/cheddar-tracker-db.json"
RESULTS_FILE="/Users/nemotaka/clawd/logs/cheddar-auto-results.json"
LOG_FILE="/Users/nemotaka/clawd/logs/cheddar-auto-calc.log"
BACKTEST_MD="/Users/nemotaka/clawd/CHEDDAR_BACKTEST_DETAILED.md"

mkdir -p "$(dirname "$LOG_FILE")"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "Starting auto 3-day result check..."

# Check if there are alerts that are exactly 3 days old
python3 << 'PYTHON_SCRIPT'
import json
from datetime import datetime, timedelta
import subprocess

db_file = '/Users/nemotaka/clawd/logs/cheddar-tracker-db.json'
results_file = '/Users/nemotaka/clawd/logs/cheddar-auto-results.json'

try:
    with open(db_file, 'r') as f:
        db = json.load(f)
except:
    db = {'alerts': []}

alerts = db.get('alerts', [])
today = datetime.now().date()

# Find alerts that are 3 days old and still open
alerts_to_check = []
for alert in alerts:
    if alert.get('status') != 'OPEN':
        continue
    
    entry_date = datetime.strptime(alert['entry_date'], '%Y-%m-%d').date()
    days_since = (today - entry_date).days
    
    if days_since >= 3:
        alerts_to_check.append(alert)

if not alerts_to_check:
    print("No alerts ready for 3-day calculation")
else:
    print(f"Found {len(alerts_to_check)} alerts ready for 3-day calculation")
    
    # Calculate results for each
    for alert in alerts_to_check:
        symbol = alert['symbol']
        entry_date = alert['entry_date']
        direction = alert['direction']
        alert_id = alert['id']
        
        print(f"\nCalculating: ${symbol} (Alert #{alert_id})")
        
        # Run Python calculator
        result = subprocess.run([
            'python3', '/Users/nemotaka/clawd/skills/cheddar-flow-alerts/scripts/calc-return.py',
            symbol,
            str(alert.get('entry_price', 0)),
            str(alert.get('strike_price', alert.get('entry_price', 0))),
            '0',  # Will be fetched
            '3',
            'CALL' if direction == 'BULLISH' else 'PUT'
        ], capture_output=True, text=True)
        
        print(result.stdout)
        if result.stderr:
            print(f"Errors: {result.stderr}")

PYTHON_SCRIPT

log "Auto check complete"

# Update backtest MD with new results if available
if [ -f "$RESULTS_FILE" ]; then
    log "Updating backtest document with calculated results..."
    # Append calculated results to the backtest MD
fi

log "Done"
