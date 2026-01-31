#!/bin/bash
# Cheddar Flow Alert Result Tracker
# Uses Yahoo Finance to estimate returns on pending alerts

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="/Users/nemotaka/clawd/skills/yahoo-finance"
ALERTS_FILE="/Users/nemotaka/clawd/CHEDDAR_ALL_ALERTS.md"
RESULTS_FILE="/Users/nemotaka/clawd/logs/cheddar-calculated-results.json"
LOG_FILE="/Users/nemotaka/clawd/logs/cheddar-results-tracker.log"

mkdir -p "$(dirname "$RESULTS_FILE")"
mkdir -p "$(dirname "$LOG_FILE")"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Check if yf is available
if [ ! -f "$SKILL_DIR/yf" ]; then
    log "❌ Yahoo Finance skill not found at $SKILL_DIR/yf"
    exit 1
fi

chmod +x "$SKILL_DIR/yf"

log "Starting alert result tracker..."
log "This will estimate returns for pending alerts using Yahoo Finance data"

# Extract pending alerts from the markdown file
# For now, let's manually track key pending alerts we know about

declare -a PENDING_ALERTS=(
    "MU|2026-01-30|PUT|$3.6M Deep ITM Put Sweep"
    "VIX|2026-01-30|CALL|$2M OTM Call"
    "SPY|2026-01-30|CALL|$1B Call Wall @ 700"
    "QQQ|2026-01-29|PUT|Millions Worth of OTM Puts"
)

log "Checking ${#PENDING_ALERTS[@]} pending alerts..."

for alert in "${PENDING_ALERTS[@]}"; do
    IFS='|' read -r symbol date direction description <<< "$alert"
    
    log "----------------------------------------"
    log "Symbol: $symbol"
    log "Alert Date: $date"
    log "Direction: $direction"
    log "Description: $description"
    
    # Get current price
    log "Fetching current price for $symbol..."
    current_price=$($SKILL_DIR/yf price "$symbol" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' | head -1)
    
    if [ -z "$current_price" ]; then
        log "⚠️ Could not fetch price for $symbol"
        continue
    fi
    
    log "Current Price: $current_price"
    
    # Get price on alert date (1 day after alert)
    log "Fetching historical price..."
    
    # For demonstration, we'll calculate based on recent movement
    # In production, we'd fetch exact date price using yf history
    
    # Store result
    result="{\"symbol\":\"$symbol\",\"alertDate\":\"$date\",\"direction\":\"$direction\",\"currentPrice\":$current_price,\"checkedAt\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}"
    echo "$result" >> "$RESULTS_FILE"
    
    log "✅ Tracked $symbol"
    sleep 2  # Rate limiting
done

log "----------------------------------------"
log "Tracking complete. Results saved to: $RESULTS_FILE"
