#!/bin/bash
# Cheddar Flow Trade Checker
# Checks for new trade entries and sends alerts

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$HOME/.cheddar-config.json"
LOG_FILE="/Users/nemotaka/clawd/logs/cheddar-alerts.log"
STATE_FILE="$SCRIPT_DIR/.last-check"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Check if config exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}Error: Config file not found at $CONFIG_FILE${NC}"
    echo "Create it with:"
    echo '{'
    echo '  "apiKey": "your_cheddar_api_key",'
    echo '  "discordChannel": "your_discord_channel_id",'
    echo '  "minPremium": 100000,'
    echo '  "symbols": ["SPY", "QQQ", "AAPL", "TSLA"]'
    echo '}'
    exit 1
fi

# Read config
API_KEY=$(cat "$CONFIG_FILE" | grep -o '"apiKey"[^"]*"[^"]*"' | cut -d'"' -f4)
DISCORD_CHANNEL=$(cat "$CONFIG_FILE" | grep -o '"discordChannel"[^"]*"[^"]*"' | cut -d'"' -f4)
MIN_PREMIUM=$(cat "$CONFIG_FILE" | grep -o '"minPremium"[^:]*:[^0-9]*[0-9]*' | grep -o '[0-9]*')

if [ -z "$API_KEY" ]; then
    echo -e "${RED}Error: API key not found in config${NC}"
    exit 1
fi

log "Checking Cheddar Flow for new trades..."

# TODO: Replace with actual Cheddar Flow API call
# For now, this is a template that shows the structure

# Example API call (replace with real endpoint):
# curl -s -H "Authorization: Bearer $API_KEY" \
#   "https://api.cheddarflow.com/v1/trades?minPremium=$MIN_PREMIUM" \
#   -o /tmp/cheddar-trades.json

# For demo purposes, check if we have a mock response
if [ -f "$SCRIPT_DIR/mock-trades.json" ]; then
    TRADES=$(cat "$SCRIPT_DIR/mock-trades.json")
    log "Found $(echo "$TRADES" | jq length) trades"
    
    # Process each trade
    echo "$TRADES" | jq -c '.[]' | while read trade; do
        SYMBOL=$(echo "$trade" | jq -r '.symbol')
        PREMIUM=$(echo "$trade" | jq -r '.premium')
        TYPE=$(echo "$trade" | jq -r '.type')
        STRIKE=$(echo "$trade" | jq -r '.strike')
        EXPIRY=$(echo "$trade" | jq -r '.expiry')
        CALL_PUT=$(echo "$trade" | jq -r '.callPut')
        
        log "Alert: $SYMBOL $STRIKE $CALL_PUT $EXPIRY - $TYPE - \$$PREMIUM"
        
        # Send Discord alert
        if [ -n "$DISCORD_CHANNEL" ]; then
            MESSAGE="🧀 **Cheddar Flow Alert**\n"
            MESSAGE+="**$SYMBOL** $STRIKE $CALL_PUT $EXPIRY\n"
            MESSAGE+="Type: $TYPE | Premium: \$$PREMIUM\n"
            MESSAGE+="Time: $(date '+%H:%M:%S')"
            
            # Send via Clawdbot message tool
            echo "Would send to Discord: $MESSAGE"
        fi
    done
else
    log "No mock trades file found. Create $SCRIPT_DIR/mock-trades.json for testing"
    log "Or implement actual Cheddar Flow API integration"
fi

# Update last check time
date +%s > "$STATE_FILE"
log "Check complete"
