#!/bin/bash
# Cheddar Flow Alert Fetcher - Uses browser automation
# Sends alerts to Discord #cheddar-flow channel

CHANNEL_ID="1466878278592631011"
LOG_FILE="/Users/nemotaka/clawd/logs/cheddar-browser.log"
OUTPUT_JSON="/Users/nemotaka/clawd/cheddarflow_browser_alerts.json"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "Starting Cheddar Flow browser fetch..."

# Create a Node.js script to fetch via browser
cat > /tmp/fetch-cheddar.js << 'EOF'
const { chromium } = require('playwright');

(async () => {
    const browser = await chromium.launch({ headless: true });
    const context = await browser.newContext({
        viewport: { width: 1920, height: 1080 },
        userAgent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
    });
    const page = await context.newPage();
    
    try {
        // Try nitter (X/Twitter mirror that doesn't require login)
        console.log('Trying nitter...');
        await page.goto('https://nitter.net/CheddarFlow', { timeout: 30000 });
        await page.waitForTimeout(5000);
        
        // Extract tweets
        const tweets = await page.evaluate(() => {
            const items = [];
            document.querySelectorAll('.timeline-item').forEach(item => {
                const textElem = item.querySelector('.tweet-content');
                const timeElem = item.querySelector('.tweet-date');
                if (textElem) {
                    items.push({
                        text: textElem.innerText,
                        time: timeElem ? timeElem.innerText : '',
                        url: timeElem ? timeElem.href : ''
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
node /tmp/fetch-cheddar.js > "$OUTPUT_JSON" 2>&1

if [ -s "$OUTPUT_JSON" ]; then
    # Parse and send alerts
    log "Fetched $(cat "$OUTPUT_JSON" | grep -c '"text"' || echo 0) tweets"
    
    # Send summary to Discord
    MESSAGE="🧀 Cheddar Flow Browser Fetch Complete

Fetched: $(cat "$OUTPUT_JSON" | grep -c '"text"' || echo 0) tweets
Data saved to: cheddarflow_browser_alerts.json

Run: cat cheddarflow_browser_alerts.json | jq '.[] | select(.text | contains(\"sweep\") or contains(\"block\"))'"
    
    /Users/nemotaka/clawd/skills/cheddar-flow-alerts/scripts/send-dm.sh "$MESSAGE"
    log "Discord notification sent"
else
    log "No data fetched - check log for errors"
fi

log "Done"
