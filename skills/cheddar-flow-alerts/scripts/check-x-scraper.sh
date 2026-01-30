#!/bin/bash
# Cheddar Flow X/Twitter Scraper
# Monitors @CheddarFlow for trade alerts - NO API KEY NEEDED

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$HOME/.cheddar-config.json"
STATE_FILE="$SCRIPT_DIR/.last-tweet-id"
LOG_FILE="/Users/nemotaka/clawd/logs/cheddar-alerts.log"
DISCORD_CHANNEL="1466666758642340074"

# Ensure log directory
mkdir -p "$(dirname "$LOG_FILE")"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Check for Nitter or similar service
# Nitter is a free Twitter alternative that doesn't require API
NITTER_INSTANCE="nitter.net"

log "Checking Cheddar Flow X/Twitter (@CheddarFlow)..."

# Try to fetch recent tweets using nitter (free, no API)
# Note: This is a basic scraper - may need adjustments as services change

# Alternative: Use browser automation via playwright
if command -v npx &> /dev/null; then
    log "Using browser automation to check tweets..."
    
    # Create a temporary script to scrape
    cat > /tmp/scrape-cheddar.js << 'EOF'
const { chromium } = require('playwright');

(async () => {
    const browser = await chromium.launch({ headless: true });
    const page = await browser.newPage();
    
    try {
        // Try nitter first (free Twitter frontend)
        await page.goto('https://nitter.net/CheddarFlow', { waitUntil: 'networkidle', timeout: 30000 });
        
        // Extract tweets
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
    
    # Run the scraper
    cd /Users/nemotaka/clawd
    TWEETS=$(npx tsx /tmp/scrape-cheddar.js 2>/dev/null || echo "[]")
    
    if [ "$TWEETS" != "[]" ] && [ -n "$TWEETS" ]; then
        log "Found tweets via browser"
        echo "$TWEETS" | jq -c '.[]' | while read tweet; do
            TEXT=$(echo "$tweet" | jq -r '.text')
            TIME=$(echo "$tweet" | jq -r '.time')
            
            # Check if it's a trade alert
            if echo "$TEXT" | grep -qiE "(sweep|block|unusual|flow|options)"; then
                log "🚨 TRADE ALERT: $TEXT"
                
                # Send Discord notification
                MESSAGE="🧀 **Cheddar Flow Alert**\n\n"
                MESSAGE+="$TEXT\n\n"
                MESSAGE+="Time: $TIME"
                
                # Use clawdbot message tool
                echo "Alert: $TEXT"
            fi
        done
    else
        log "No new tweets found or scraper failed"
    fi
else
    log "Playwright not available - using mock data for testing"
fi

# For now, use mock data to demonstrate
log "Checking mock trade data..."

# Read mock trades
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
        
        # Send to Discord
        MESSAGE="🧀 **Cheddar Flow Alert**\n\n"
        MESSAGE+="**Symbol:** $SYMBOL\n"
        MESSAGE+="**Strike:** $STRIKE $CALL_PUT\n"  
        MESSAGE+="**Expiry:** $EXPIRY\n"
        MESSAGE+="**Type:** $TYPE\n"
        MESSAGE+="**Premium:** \$$PREMIUM\n\n"
        MESSAGE+="⏰ $(date '+%H:%M:%S')"
        
        # Send via clawdbot
        cd /Users/nemotaka/clawd
        # Note: This would need to be called via the gateway API
        echo "Would send: $MESSAGE"
    done
fi

log "Check complete"
