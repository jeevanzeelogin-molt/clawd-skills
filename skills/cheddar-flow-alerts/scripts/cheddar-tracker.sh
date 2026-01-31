#!/bin/bash
# Cheddar Flow Alert Tracker with Manual Strike Entry
# Tracks alerts and calculates returns based on user-entered strikes

CONFIG_FILE="$HOME/.cheddar-tracker-config.json"
ALERTS_DB="/Users/nemotaka/clawd/logs/cheddar-tracker-db.json"
RESULTS_LOG="/Users/nemotaka/clawd/logs/cheddar-tracker-results.log"

mkdir -p "$(dirname "$ALERTS_DB")"

# Initialize DB if not exists
if [ ! -f "$ALERTS_DB" ]; then
    echo '{"alerts": [], "active_trades": []}' > "$ALERTS_DB"
fi

show_help() {
    cat << 'EOF'
Cheddar Flow Alert Tracker
==========================

Commands:
  add <symbol> <direction> <signal_type> [premium]
    Add a new alert to track
    Example: add SPY CALL SWEEP $2.5M

  strike <alert_id> <strike_price> <expiry_date>
    Enter strike price for an alert
    Example: strike 1 450 2026-02-14

  status
    Show all active trades and their current status

  close <alert_id> <exit_price> [return_pct]
    Close a trade with final price/return
    Example: close 1 28.50 +150

  list
    List all tracked alerts

  result <symbol> <return_pct>
    Quick result entry for a symbol
    Example: result SPY +75

  calc <symbol> <entry> <strike> <exit> <days> <type>
    Calculate option return
    Example: calc SPY 450 455 460 5 CALL

EOF
}

add_alert() {
    local symbol=$1
    local direction=$2
    local signal=$3
    local premium=$4
    
    if [ -z "$symbol" ] || [ -z "$direction" ] || [ -z "$signal" ]; then
        echo "❌ Usage: add <symbol> <direction> <signal_type> [premium]"
        return 1
    fi
    
    local alert_id=$(date +%s)
    local entry_date=$(date '+%Y-%m-%d')
    local entry_time=$(date '+%H:%M:%S')
    
    # Get current stock price
    local entry_price=$(python3 -c "
import yfinance as yf
try:
    ticker = yf.Ticker('$symbol')
    hist = ticker.history(period='1d')
    print(round(hist['Close'].iloc[-1], 2))
except:
    print('N/A')
" 2>/dev/null)
    
    local alert=$(cat << EOF
{
  "id": $alert_id,
  "symbol": "$symbol",
  "direction": "$direction",
  "signal": "$signal",
  "premium": "${premium:-N/A}",
  "entry_date": "$entry_date",
  "entry_time": "$entry_time",
  "entry_price": "$entry_price",
  "strike_price": null,
  "expiry": null,
  "status": "OPEN",
  "exit_price": null,
  "return_pct": null,
  "notes": ""
}
EOF
)
    
    # Add to DB
    python3 -c "
import json
db = json.load(open('$ALERTS_DB'))
alerts = db['alerts']
alerts.append(json.loads('''$alert'''))
db['alerts'] = alerts
json.dump(db, open('$ALERTS_DB', 'w'), indent=2)
"
    
    echo "✅ Alert #${alert_id} added for $symbol"
    echo "   Direction: $direction | Signal: $signal"
    echo "   Entry Price: $entry_price"
    echo "   ⚠️ Use: cheddar-tracker strike $alert_id <strike> <expiry>"
}

enter_strike() {
    local alert_id=$1
    local strike=$2
    local expiry=$3
    
    if [ -z "$alert_id" ] || [ -z "$strike" ] || [ -z "$expiry" ]; then
        echo "❌ Usage: strike <alert_id> <strike_price> <expiry_date>"
        echo "   Example: strike 1738341600 450 2026-02-14"
        return 1
    fi
    
    python3 -c "
import json
db = json.load(open('$ALERTS_DB'))
found = False
for alert in db['alerts']:
    if str(alert['id']) == '$alert_id':
        alert['strike_price'] = $strike
        alert['expiry'] = '$expiry'
        found = True
        break
if found:
    json.dump(db, open('$ALERTS_DB', 'w'), indent=2)
    print(f'✅ Strike ${strike} with expiry {expiry} added to alert #{$alert_id}')
else:
    print(f'❌ Alert #{$alert_id} not found')
"
}

show_status() {
    echo "📊 CHEDDAR FLOW TRACKER - ACTIVE TRADES"
    echo "========================================"
    echo ""
    
    python3 << 'PYTHON_SCRIPT'
import json
from datetime import datetime

db = json.load(open('/Users/nemotaka/clawd/logs/cheddar-tracker-db.json'))
alerts = db['alerts']

open_alerts = [a for a in alerts if a['status'] == 'OPEN']

if not open_alerts:
    print("No active trades. Use 'add' to track new alerts.")
else:
    for alert in open_alerts:
        symbol = alert['symbol']
        strike = alert['strike_price'] or 'N/A'
        expiry = alert['expiry'] or 'N/A'
        entry = alert['entry_price']
        direction = alert['direction']
        signal = alert['signal']
        
        print(f"Alert #{alert['id']}: ${symbol}")
        print(f"  Direction: {direction} | Signal: {signal}")
        print(f"  Entry: ${entry} @ {alert['entry_date']} {alert['entry_time']}")
        print(f"  Strike: ${strike} | Expiry: {expiry}")
        if strike != 'N/A' and entry != 'N/A':
            try:
                moneyness = ((float(strike) - float(entry)) / float(entry)) * 100
                if direction == 'CALL':
                    status = 'ITM' if moneyness < 0 else 'OTM' if moneyness > 5 else 'ATM'
                else:  # PUT
                    status = 'ITM' if moneyness > 0 else 'OTM' if moneyness < -5 else 'ATM'
                print(f"  Moneyness: {moneyness:+.1f}% ({status})")
            except:
                pass
        print()
PYTHON_SCRIPT
}

list_alerts() {
    python3 << 'PYTHON_SCRIPT'
import json
from datetime import datetime

db = json.load(open('/Users/nemotaka/clawd/logs/cheddar-tracker-db.json'))
alerts = db['alerts']

print(f"{'ID':<15} {'Symbol':<8} {'Dir':<8} {'Signal':<12} {'Strike':<10} {'Status':<8} {'Return':<10}")
print("-" * 80)

for alert in alerts[-20:]:  # Show last 20
    symbol = alert['symbol']
    direction = alert['direction'][:6]
    signal = alert['signal'][:10]
    strike = f"${alert['strike_price']}" if alert['strike_price'] else "N/A"
    status = alert['status']
    ret = f"{alert['return_pct']:+.0f}%" if alert['return_pct'] else "N/A"
    
    print(f"{alert['id']:<15} {symbol:<8} {direction:<8} {signal:<12} {strike:<10} {status:<8} {ret:<10}")
PYTHON_SCRIPT
}

close_trade() {
    local alert_id=$1
    local exit_price=$2
    local return_pct=$3
    
    if [ -z "$alert_id" ]; then
        echo "❌ Usage: close <alert_id> [exit_price] [return_pct]"
        return 1
    fi
    
    python3 -c "
import json
from datetime import datetime

db = json.load(open('$ALERTS_DB'))
found = False
for alert in db['alerts']:
    if str(alert['id']) == '$alert_id':
        alert['status'] = 'CLOSED'
        alert['exit_date'] = datetime.now().strftime('%Y-%m-%d')
        alert['exit_time'] = datetime.now().strftime('%H:%M:%S')
        if '$exit_price':
            alert['exit_price'] = $exit_price
        if '$return_pct':
            alert['return_pct'] = $return_pct
        found = True
        
        # Log to results
        result_line = f\"{datetime.now().isoformat()} | #{alert['id']} | {alert['symbol']} | {alert['return_pct']} or {alert.get('return_pct', 'N/A')}%\"
        with open('$RESULTS_LOG', 'a') as f:
            f.write(result_line + '\n')
        break

if found:
    json.dump(db, open('$ALERTS_DB', 'w'), indent=2)
    print(f'✅ Alert #{$alert_id} closed')
else:
    print(f'❌ Alert #{$alert_id} not found')
"
}

quick_result() {
    local symbol=$1
    local return_pct=$2
    
    if [ -z "$symbol" ] || [ -z "$return_pct" ]; then
        echo "❌ Usage: result <symbol> <return_pct>"
        return 1
    fi
    
    python3 -c "
import json
from datetime import datetime

db = json.load(open('$ALERTS_DB'))
found = False
for alert in reversed(db['alerts']):
    if alert['symbol'] == '$symbol' and alert['status'] == 'OPEN':
        alert['status'] = 'CLOSED'
        alert['return_pct'] = $return_pct
        alert['exit_date'] = datetime.now().strftime('%Y-%m-%d')
        alert['exit_time'] = datetime.now().strftime('%H:%M:%S')
        found = True
        
        result_line = f\"{datetime.now().isoformat()} | Quick Result | {symbol} | {return_pct}%\"
        with open('$RESULTS_LOG', 'a') as f:
            f.write(result_line + '\n')
        break

if found:
    json.dump(db, open('$ALERTS_DB', 'w'), indent=2)
    print(f'✅ Recorded ${symbol} result: {return_pct}%')
else:
    print(f'❌ No open trade found for ${symbol}')
"
}

calculate_return() {
    local symbol=$1
    local entry=$2
    local strike=$3
    local current=$4
    local days=$5
    local type=$6
    
    if [ -z "$symbol" ] || [ -z "$entry" ] || [ -z "$strike" ] || [ -z "$current" ]; then
        echo "❌ Usage: calc <symbol> <entry_price> <strike> <current_price> [days] [CALL|PUT]"
        return 1
    fi
    
    python3 "$(dirname "$0")/calc-return.py" "$symbol" "$entry" "$strike" "$current" "${days:-5}" "${type:-CALL}"
}

# Main command handler
case "${1:-help}" in
    add)
        shift
        add_alert "$@"
        ;;
    strike)
        shift
        enter_strike "$@"
        ;;
    status)
        show_status
        ;;
    list)
        list_alerts
        ;;
    close)
        shift
        close_trade "$@"
        ;;
    result)
        shift
        quick_result "$@"
        ;;
    calc)
        shift
        calculate_return "$@"
        ;;
    help|--help|-h|*)
        show_help
        ;;
esac
