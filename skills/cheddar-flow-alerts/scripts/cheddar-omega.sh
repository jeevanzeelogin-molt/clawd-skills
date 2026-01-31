#!/bin/bash
# Cheddar Flow + Option Omega Integration
# Automatically creates models from alerts and monitors hourly

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODELER="$SCRIPT_DIR/omega-modeler.py"
LOG_FILE="/Users/nemotaka/clawd/logs/cheddar-omega-monitor.log"
DB_FILE="/Users/nemotaka/clawd/logs/cheddar-omega-models.json"

mkdir -p "$(dirname "$LOG_FILE")"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Function to estimate strike from alert description
estimate_strike() {
    local symbol=$1
    local description=$2
    local current_price=$3
    
    # Try to extract strike from description
    if echo "$description" | grep -qE '[0-9]+(\.[0-9]+)?'; then
        strike=$(echo "$description" | grep -oE '[0-9]+(\.[0-9]+)?' | head -1)
        echo "$strike"
    else
        # Default to ATM
        echo "$current_price"
    fi
}

# Function to estimate expiry
estimate_expiry() {
    local alert_date=$1
    local signal=$2
    
    # Default to 30 days for most alerts
    # Could be smarter based on signal type
    python3 -c "
from datetime import datetime, timedelta
date = datetime.strptime('$alert_date', '%Y-%m-%d')
expiry = date + timedelta(days=30)
print(expiry.strftime('%Y-%m-%d'))
"
}

# Process new alert and create model
create_model_from_alert() {
    local symbol=$1
    local direction=$2
    local signal=$3
    local description=$4
    local alert_date=$5
    
    log "Creating Option Omega model for $symbol..."
    
    # Get current price
    current_price=$(python3 -c "
import yfinance as yf
try:
    ticker = yf.Ticker('$symbol')
    hist = ticker.history(period='1d')
    print(round(hist['Close'].iloc[-1], 2))
except:
    print('0')
" 2>/dev/null)
    
    if [ "$current_price" = "0" ] || [ -z "$current_price" ]; then
        log "❌ Could not get price for $symbol"
        return 1
    fi
    
    # Estimate strike
    strike=$(estimate_strike "$symbol" "$description" "$current_price")
    
    # Estimate expiry
    expiry=$(estimate_expiry "$alert_date" "$signal")
    
    log "   Symbol: $symbol"
    log "   Current Price: $current_price"
    log "   Estimated Strike: $strike"
    log "   Estimated Expiry: $expiry"
    
    # Create model
    export PATH="$HOME/.local/bin:$PATH"
    result=$(uv run --with yfinance --with numpy --with scipy "$MODELER" create "$symbol" "$direction" "$strike" "$expiry" "$signal" 2>&1)
    
    if echo "$result" | grep -q "Model created"; then
        model_id=$(echo "$result" | grep "Model created:" | cut -d':' -f2 | tr -d ' ')
        log "✅ Model created: $model_id"
        echo "$model_id"
    else
        log "❌ Failed to create model: $result"
        return 1
    fi
}

# Hourly monitoring - take snapshots of all active models
hourly_monitor() {
    log "Running hourly snapshot for all active models..."
    
    export PATH="$HOME/.local/bin:$PATH"
    
    # Get list of active models
    models=$(uv run --with yfinance --with numpy --with scipy "$MODELER" list 2>&1 | grep -E '^\s+.*ACTIVE' | awk '{print $1}')
    
    if [ -z "$models" ]; then
        log "No active models to monitor"
        return 0
    fi
    
    log "Monitoring $(echo "$models" | wc -l) active models..."
    
    for model_id in $models; do
        log "  Taking snapshot for $model_id..."
        snapshot=$(uv run --with yfinance --with numpy --with scipy "$MODELER" snapshot "$model_id" 2>&1)
        
        if echo "$snapshot" | grep -q "Snapshot taken"; then
            pnl=$(echo "$snapshot" | grep "P/L:" | grep -oE '[+-][0-9]+\.[0-9]+')
            log "    P/L: ${pnl}%"
        else
            log "    ⚠️ Snapshot failed"
        fi
        
        sleep 2  # Rate limiting
    done
    
    log "Hourly monitoring complete"
}

# Generate reports for models ready for documentation
update_backtest_docs() {
    log "Updating backtest documentation..."
    
    export PATH="$HOME/.local/bin:$PATH"
    
    # Find models with sufficient snapshots (monitored for at least 3 days)
    python3 << 'PYTHON_SCRIPT'
import json
from datetime import datetime, timedelta

db_file = '/Users/nemotaka/clawd/logs/cheddar-omega-models.json'
backtest_updates = '/Users/nemotaka/clawd/logs/cheddar-omega-backtest-updates.md'

try:
    with open(db_file, 'r') as f:
        data = json.load(f)
except:
    print("No models to process")
    exit(0)

models = data.get('models', [])
now = datetime.now()
updates = []

for model in models:
    if model['status'] != 'ACTIVE':
        continue
    
    entry_date = datetime.fromisoformat(model['entry_date'])
    days_active = (now - entry_date).days
    
    if days_active >= 3 and len(model.get('snapshots', [])) >= 3:
        # Model has been monitored for 3+ days
        last_snap = model['snapshots'][-1]
        
        update = f"""
### Omega-Modeled Result: ${model['symbol']} {model['option_type']}

| Field | Value |
|-------|-------|
| **Symbol** | ${model['symbol']} |
| **Type** | ${model['option_type']} |
| **Strike** | $${model['strike']} |
| **Entry Date** | ${model['entry_date'][:10]} |
| **Modeled Return** | {last_snap['pnl_percent']:+.2f}% |
| **Days Monitored** | {days_active} |
| **Snapshots** | {len(model['snapshots'])} |
| **Model ID** | ${model['id']} |

**Greeks at Last Snapshot:**
- Delta: {last_snap['greeks']['delta']}
- Theta: ${last_snap['greeks']['theta']}/day
- Current Price: $${last_snap['stock_price']}

"""
        updates.append(update)

if updates:
    with open(backtest_updates, 'a') as f:
        f.write('\n'.join(updates))
    print(f"Added {len(updates)} model updates to backtest docs")
else:
    print("No models ready for documentation update")

PYTHON_SCRIPT

    log "Backtest documentation updated"
}

# Main command handler
case "${1:-help}" in
    create)
        shift
        if [ $# -lt 3 ]; then
            echo "Usage: $0 create <symbol> <direction> <signal> [description] [date]"
            exit 1
        fi
        create_model_from_alert "$1" "$2" "$3" "${4:-}" "${5:-$(date +%Y-%m-%d)}"
        ;;
    
    hourly)
        hourly_monitor
        ;;
    
    update-docs)
        update_backtest_docs
        ;;
    
    full-cycle)
        # For alerts that are 3 days old, update docs
        update_backtest_docs
        # Take hourly snapshots
        hourly_monitor
        ;;
    
    help|--help|-h|*)
        cat << 'EOF'
Cheddar Flow + Option Omega Integration

Commands:
  create <symbol> <direction> <signal> [desc] [date]
    Create Option Omega model from Cheddar Flow alert
    Example: create SLV BEARISH "Put Sweep" "1.3M" 2026-01-29

  hourly
    Take snapshots of all active models (run every hour)

  update-docs
    Update backtest documentation with 3-day model results

  full-cycle
    Run hourly monitoring + doc updates

EOF
        ;;
esac
