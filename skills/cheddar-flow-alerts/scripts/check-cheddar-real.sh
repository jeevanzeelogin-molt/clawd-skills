#!/bin/bash
# Cheddar Flow Real Twitter Scraper
# Uses Clawdbot browser to fetch actual tweets

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$HOME/.cheddar-config.json"
STATE_FILE="/tmp/cheddar-last-tweets.json"
LOG_FILE="/Users/nemotaka/clawd/logs/cheddar-alerts.log"
ALERT_SENT_FILE="/Users/nemotaka/clawd/logs/cheddar-alerts-sent.json"

# Get Discord channel from config
CHANNEL_ID=$(cat "$CONFIG_FILE" 2>/dev/null | grep -o '"discordChannel"[^"]*"[^"]*"' | cut -d'"' -f4)
[ -z "$CHANNEL_ID" ] && CHANNEL_ID="1466878278592631011"

# Ensure log directory
mkdir -p "$(dirname "$LOG_FILE")"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Function to send Discord alert via Clawdbot Gateway API
send_discord_alert() {
    local tweet_text="$1"
    local tweet_time="$2"
    local tweet_url="$3"
    
    local alert_id="$(echo "$tweet_text" | md5 | head -c 16)_$(date +%Y%m%d)"
    
    # Check if we already sent this alert
    if [ -f "$ALERT_SENT_FILE" ]; then
        if grep -q "$alert_id" "$ALERT_SENT_FILE" 2>/dev/null; then
            log "Alert already sent: $alert_id"
            return 0
        fi
    fi
    
    # Build message
    local message="🧀 **Cheddar Flow Alert**

$tweet_text

⏰ $tweet_time
🔗 $tweet_url"
    
    # Send via clawdbot
    cd /Users/nemotaka/clawd
    clawdbot message send --channel discord --target "$CHANNEL_ID" -m "$message" 2>&1 | tee -a "$LOG_FILE"
    
    if [ $? -eq 0 ]; then
        log "✅ Discord alert sent: $alert_id"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - $alert_id" >> "$ALERT_SENT_FILE"
        return 0
    else
        log "❌ Failed to send Discord alert"
        return 1
    fi
}

log "Fetching real Cheddar Flow tweets..."

# Use Playwright/Node.js to fetch tweets via browser
cd /Users/nemotaka/clawd
node << 'NODE_SCRIPT'
const { chromium } = require('playwright');

(async () => {
    const browser = await chromium.launch({ headless: true });
    const page = await browser.newPage();
    
    try {
        await page.goto('https://x.com/CheddarFlow', { waitUntil: 'networkidle', timeout: 60000 });
        
        // Wait for tweets to load
        await page.waitForSelector('article[data-testid="tweet"]', { timeout: 30000 });
        
        const tweets = await page.evaluate(() => {
            const items = [];
            document.querySelectorAll('article[data-testid="tweet"]').forEach(article => {
                const textEl = article.querySelector('[data-testid="tweetText"]');
                const timeEl = article.querySelector('time');
                const linkEl = article.querySelector('a[href*="/status/"]');
                
                if (textEl && timeEl) {
                    const tweetUrl = linkEl ? 'https://x.com' + linkEl.getAttribute('href') : '';
                    items.push({
                        text: textEl.innerText,
                        time: timeEl.getAttribute('datetime'),
                        displayTime: timeEl.innerText,
                        url: tweetUrl
                    });
                }
            });
            return items;
        });
        
        // Save tweets to file for bash script to process
        const fs = require('fs');
        fs.writeFileSync('/tmp/cheddar-tweets-latest.json', JSON.stringify(tweets.slice(0, 5), null, 2));
        console.log('SUCCESS');
        
    } catch (e) {
        console.error('Error:', e.message);
        process.exit(1);
    } finally {
        await browser.close();
    }
})();
NODE_SCRIPT

if [ $? -ne 0 ]; then
    log "❌ Failed to fetch tweets"
    exit 1
fi

# Process the tweets
if [ -f /tmp/cheddar-tweets-latest.json ]; then
    log "Processing tweets..."
    
    # Read tweets and send alerts for new ones
    cat /tmp/cheddar-tweets-latest.json | jq -c '.[]' | while read tweet; do
        TEXT=$(echo "$tweet" | jq -r '.text')
        TIME=$(echo "$tweet" | jq -r '.displayTime')
        URL=$(echo "$tweet" | jq -r '.url')
        
        # Only send alerts for trade-related tweets
        if echo "$TEXT" | grep -qiE "(sweep|block|flow|unusual|whale|million|premium|puts?|calls?)"; then
            log "🚨 Trade alert found: $TEXT"
            send_discord_alert "$TEXT" "$TIME" "$URL"
        fi
        
        sleep 1
    done
fi

log "Check complete"
