#!/bin/bash
# Cheddar Flow X/Twitter Scraper
# Monitors @CheddarFlow for trade alerts - NO API KEY NEEDED

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$HOME/.cheddar-config.json"
STATE_FILE="$SCRIPT_DIR/.last-tweet-id"
LOG_FILE="/Users/nemotaka/clawd/logs/cheddar-alerts.log"
ALERT_SENT_FILE="/Users/nemotaka/clawd/logs/cheddar-alerts-sent.json"

# Get Discord channel from config
CHANNEL_ID=$(cat "$CONFIG_FILE" 2>/dev/null | grep -o '"discordChannel"[^"]*"[^"]*"' | cut -d'"' -f4)
[ -z "$CHANNEL_ID" ] && CHANNEL_ID="1143404804157227030"

GATEWAY_URL="http://127.0.0.1:18789"
GATEWAY_TOKEN="3ae38e29e53b0e7a4dfe19ffe7466d4d7821d01b618c41ba"

# Ensure log directory
mkdir -p "$(dirname "$LOG_FILE")"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Function to send Discord alert via Clawdbot Gateway API
send_discord_alert() {
    local symbol="$1"
    local strike="$2"
    local call_put="$3"
    local expiry="$4"
    local type="$5"
    local premium="$6"
    
    local alert_id="${symbol}_${strike}_${call_put}_${expiry}_$(date +%Y%m%d)"
    
    # Check if we already sent this alert
    if [ -f "$ALERT_SENT_FILE" ]; then
        if grep -q "$alert_id" "$ALERT_SENT_FILE" 2>/dev/null; then
            log "Alert already sent: $alert_id"
            return 0
        fi
    fi
    
    # Build message (JSON escaped)
    local message="🧀 **Cheddar Flow Alert**

**Symbol:** $symbol
**Strike:** $strike $call_put
**Expiry:** $expiry
**Type:** $(echo $type | tr '[:lower:]' '[:upper:]')
**Premium:** $$premium

⏰ $(date '+%H:%M %Z')"
    
    # Use the send-dm.sh script
    "$SCRIPT_DIR/send-dm.sh" "$message"
    
    if [ $? -eq 0 ]; then
        log "✅ Discord alert sent: $alert_id"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - $alert_id" >> "$ALERT_SENT_FILE"
        return 0
    else
        log "❌ Failed to send Discord alert"
        return 1
    fi
}

log "Checking Cheddar Flow X/Twitter (@CheddarFlow)..."

# Try to fetch recent tweets using nitter (free, no API)
if command -v npx &> /dev/null; then
    log "Using browser automation to check tweets..."
    
    # Create a temporary script to scrape
    cat > /tmp/scrape-cheddar.js << 'EOF'
const { chromium } = require('playwright');

(async () => {
    const browser = await chromium.launch({ headless: true });
    const page = await browser.newPage();
    
    try {
        await page.goto('https://nitter.net/CheddarFlow', { waitUntil: 'networkidle', timeout: 30000 });
        
        const tweets = await page.evaluate(() => {
            const items = [];
            document.querySelectorAll('.timeline-item').forEach(item => {
                const content = item.querySelector('.tweet-content');
                if (content) {
                    items.push({
                        text: content.innerText,
                        time: item.querySelector('.tweet-date')?.innerText || 'unknown'
                    });
                }
            });
            return items;
        });
        
        console.log(JSON.stringify(tweets, null, 2));
    } catch (e) {
        console.error('Error:', e.message);
    } finally {
        await browser.close();
    }
})();
EOF
    
    cd /Users/nemotaka/clawd
    TWEETS=$(npx tsx /tmp/scrape-cheddar.js 2>/dev/null || echo "[]")
    
    if [ "$TWEETS" != "[]" ] && [ -n "$TWEETS" ]; then
        log "Found tweets via browser"
        echo "$TWEETS" | jq -c '.[]' 2>/dev/null | while read tweet; do
            TEXT=$(echo "$tweet" | jq -r '.text' 2>/dev/null)
            TIME=$(echo "$tweet" | jq -r '.time' 2>/dev/null)
            
            if echo "$TEXT" | grep -qiE "(sweep|block|unusual|flow|options)"; then
                log "🚨 TRADE ALERT: $TEXT"
                
                ALERT_MSG="🧀 **Cheddar Flow Alert**

$TEXT

⏰ $TIME"
                
                "$SCRIPT_DIR/send-dm.sh" "$ALERT_MSG" && log "✅ Tweet alert sent" || log "❌ Failed to send tweet alert"
            fi
        done
    else
        log "No new tweets found or scraper failed"
    fi
else
    log "Playwright not available - using mock data for testing"
fi

# Process mock trades for demonstration
log "Checking for trade alerts..."

MOCK_FILE="$SCRIPT_DIR/mock-trades.json"
if [ -f "$MOCK_FILE" ]; then
    TRADES=$(cat "$MOCK_FILE")
    echo "$TRADES" | jq -c '.[]' | while read trade; do
        SYMBOL=$(echo "$trade" | jq -r '.symbol')
        PREMIUM=$(echo "$trade" | jq -r '.premium')
        TYPE=$(echo "$trade" | jq -r '.type')
        STRIKE=$(echo "$trade" | jq -r '.strike')
        EXPIRY=$(echo "$trade" | jq -r '.expiry')
        CALL_PUT=$(echo "$trade" | jq -r '.callPut')
        
        log "🚨 ALERT: $SYMBOL $STRIKE $CALL_PUT $EXPIRY - $TYPE - \$$PREMIUM"
        
        send_discord_alert "$SYMBOL" "$STRIKE" "$CALL_PUT" "$EXPIRY" "$TYPE" "$PREMIUM"
        
        # Small delay to avoid rate limiting
        sleep 1
    done
fi

log "Check complete"
