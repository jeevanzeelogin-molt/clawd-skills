#!/bin/bash
# Cheddar Flow Real Twitter Scraper v2
# Fetches actual tweets with full details

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$HOME/.cheddar-config.json"
LOG_FILE="/Users/nemotaka/clawd/logs/cheddar-alerts.log"
ALERT_SENT_FILE="/Users/nemotaka/clawd/logs/cheddar-alerts-sent.json"
BACKTEST_LOG="/Users/nemotaka/clawd/logs/cheddar-backtest.log"

# Get Discord channel from config
CHANNEL_ID=$(cat "$CONFIG_FILE" 2>/dev/null | grep -o '"discordChannel"[^"]*"[^"]*"' | cut -d'"' -f4)
[ -z "$CHANNEL_ID" ] && CHANNEL_ID="1466878278592631011"

# Ensure log directory
mkdir -p "$(dirname "$LOG_FILE")"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Function to send Discord alert with full details
send_discord_alert() {
    local tweet_text="$1"
    local tweet_time="$2"
    local tweet_url="$3"
    local tweet_date="$4"
    
    # Create unique alert ID
    local alert_id="$(echo "$tweet_text" | md5 | head -c 16)_$(date +%Y%m%d)"
    
    # Check if we already sent this alert
    if [ -f "$ALERT_SENT_FILE" ]; then
        if grep -q "$alert_id" "$ALERT_SENT_FILE" 2>/dev/null; then
            log "Alert already sent: $alert_id"
            return 0
        fi
    fi
    
    # Extract trade details from tweet text
    local symbol=$(echo "$tweet_text" | grep -oE '\$[A-Z]+' | head -1 | tr -d '$')
    local strike=$(echo "$tweet_text" | grep -oE '[0-9]+\s*(?:CALL|PUT)' | head -1)
    local expiry=$(echo "$tweet_text" | grep -oE '(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+[0-9]+' | head -1)
    local premium=$(echo "$tweet_text" | grep -oE '\$[0-9]+M|\$[0-9,]+K|\$[0-9,]+' | head -1)
    local signal_type=$(echo "$tweet_text" | grep -oE -i 'sweep|block|unusual|whale|dark pool' | head -1 | tr '[:lower:]' '[:upper:]')
    
    # Build detailed message
    local message="🧀 **Cheddar Flow Alert**

**Tweet:**
$tweet_text

📊 **Trade Details:**"
    
    if [ -n "$symbol" ]; then
        message="$message
• **Symbol:** $symbol"
    fi
    
    if [ -n "$strike" ]; then
        message="$message
• **Strike:** $strike"
    fi
    
    if [ -n "$expiry" ]; then
        message="$message
• **Expiry:** $expiry"
    fi
    
    if [ -n "$premium" ]; then
        message="$message
• **Premium:** $premium"
    fi
    
    if [ -n "$signal_type" ]; then
        message="$message
• **Signal Type:** $signal_type"
    fi
    
    message="$message

⏰ **Posted:** $tweet_date at $tweet_time
🔗 **Tweet Link:** $tweet_url"

    # Add backtest info if available
    if [ -f "$BACKTEST_LOG" ]; then
        local recent_backtest=$(tail -5 "$BACKTEST_LOG" 2>/dev/null | grep -E '(Win Rate|Total Return|Sharpe)' | head -3)
        if [ -n "$recent_backtest" ]; then
            message="$message

📈 **Backtest Context:**
$recent_backtest"
        fi
    fi
    
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

# Check if we have Twitter credentials
AUTH_TOKEN="${AUTH_TOKEN:-}"
CT0="${CT0:-}"

if [ -z "$AUTH_TOKEN" ] || [ -z "$CT0" ]; then
    log "⚠️ No Twitter credentials set. Set AUTH_TOKEN and CT0 environment variables."
    log "To get these: Log into x.com in Chrome → F12 → Application → Cookies → Copy auth_token and ct0"
fi

# Fetch tweets using Node.js + Playwright
cd /Users/nemotaka/clawd
node << 'NODE_SCRIPT'
const { chromium } = require('playwright');
const fs = require('fs');

(async () => {
    const authToken = process.env.AUTH_TOKEN;
    const ct0 = process.env.CT0;
    
    const browser = await chromium.launch({ 
        headless: true,
        args: ['--disable-blink-features=AutomationControlled']
    });
    
    const context = await browser.newContext({
        userAgent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    });
    
    // Add cookies if available
    if (authToken && ct0) {
        await context.addCookies([
            { name: 'auth_token', value: authToken, domain: '.x.com', path: '/' },
            { name: 'ct0', value: ct0, domain: '.x.com', path: '/' }
        ]);
    }
    
    const page = await context.newPage();
    
    try {
        await page.goto('https://x.com/CheddarFlow', { 
            waitUntil: 'networkidle', 
            timeout: 60000 
        });
        
        await page.waitForSelector('article[data-testid="tweet"]', { timeout: 30000 });
        
        const tweets = await page.evaluate(() => {
            return Array.from(document.querySelectorAll('article[data-testid="tweet"]')).map(article => {
                const textEl = article.querySelector('[data-testid="tweetText"]');
                const timeEl = article.querySelector('time');
                const linkEl = article.querySelector('a[href*="/status/"]');
                
                // Get full timestamp
                const timestamp = timeEl?.getAttribute('datetime') || '';
                const dateObj = timestamp ? new Date(timestamp) : null;
                
                return {
                    text: textEl?.innerText || '',
                    time: timeEl?.innerText || '',
                    fullDate: dateObj ? dateObj.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' }) : '',
                    fullTime: dateObj ? dateObj.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit', timeZoneName: 'short' }) : '',
                    url: linkEl ? 'https://x.com' + linkEl.getAttribute('href') : '',
                    timestamp: timestamp
                };
            });
        });
        
        fs.writeFileSync('/tmp/cheddar-tweets-latest.json', JSON.stringify(tweets.slice(0, 10), null, 2));
        console.log('SUCCESS: Found', tweets.length, 'tweets');
        
    } catch (e) {
        console.error('ERROR:', e.message);
        process.exit(1);
    } finally {
        await browser.close();
    }
})();
NODE_SCRIPT

if [ $? -ne 0 ]; then
    log "❌ Failed to fetch tweets - X/Twitter may be blocking access"
    log "💡 Solution: Provide AUTH_TOKEN and CT0 from your logged-in Chrome session"
    exit 1
fi

# Process the tweets
if [ -f /tmp/cheddar-tweets-latest.json ]; then
    log "Processing tweets..."
    
    cat /tmp/cheddar-tweets-latest.json | jq -c '.[]' | while read tweet; do
        TEXT=$(echo "$tweet" | jq -r '.text')
        TIME=$(echo "$tweet" | jq -r '.fullTime')
        DATE=$(echo "$tweet" | jq -r '.fullDate')
        URL=$(echo "$tweet" | jq -r '.url')
        
        # Skip pinned tweet (usually the profile description)
        if echo "$TEXT" | grep -qi "uncover unusual options"; then
            continue
        fi
        
        # Send alerts for trade-related tweets
        if echo "$TEXT" | grep -qiE "(sweep|block|flow|unusual|whale|million|premium|puts?|calls?|\$[A-Z]+)"; then
            log "🚨 Trade alert found: $TEXT"
            send_discord_alert "$TEXT" "$TIME" "$URL" "$DATE"
        fi
        
        sleep 1
    done
fi

log "Check complete"
