#!/bin/bash
# Cheddar Flow Real Twitter Scraper v3
# Uses bird CLI with auth cookies

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$HOME/.cheddar-config.json"
LOG_FILE="/Users/nemotaka/clawd/logs/cheddar-alerts.log"
ALERT_SENT_FILE="/Users/nemotaka/clawd/logs/cheddar-alerts-sent.json"
BACKTEST_LOG="/Users/nemotaka/clawd/logs/cheddar-backtest.log"

# Get Discord channel from config
CHANNEL_ID=$(cat "$CONFIG_FILE" 2>/dev/null | grep -o '"discordChannel"[^"]*"[^"]*"' | cut -d'"' -f4)
[ -z "$CHANNEL_ID" ] && CHANNEL_ID="1466878278592631011"

# Twitter credentials (set these in environment or ~/.zshrc)
export AUTH_TOKEN="${AUTH_TOKEN:-c1131a325c8ca6253de6d892b5c0afb5b8857650}"
export CT0="${CT0:-59329c445dc9177f254e7fdaa02015728fb2950eb1352dff3d73a668a758c75bee21cfea5db52ef38e17fb2fee6b7b8fcd2babb5b0ce84ff9d5cc9be668e1160a13a17439336d61e5bbe5f19b4acc83d}"

# Ensure log directory
mkdir -p "$(dirname "$LOG_FILE")"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Function to send Discord alert with full details
send_discord_alert() {
    local tweet_text="$1"
    local tweet_date="$2"
    local tweet_url="$3"
    
    # Create unique alert ID
    local alert_id="$(echo "$tweet_text $tweet_date" | openssl dgst -md5 | sed 's/^.*= //' | head -c 16)"
    
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
    local premium=$(echo "$tweet_text" | grep -oE '\$[0-9]+\.?[0-9]*M|\$[0-9]+\.?[0-9]*K|\$[0-9,]+' | head -1)
    local signal_type=$(echo "$tweet_text" | grep -oE -i 'sweep|block|unusual|whale|dark pool|flow' | head -1 | tr '[:lower:]' '[:upper:]')
    
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

⏰ **Posted:** $tweet_date
🔗 **Tweet Link:** $tweet_url"

    # Add backtest info if available
    if [ -f "$BACKTEST_LOG" ]; then
        local win_rate=$(grep "Win Rate:" "$BACKTEST_LOG" | cut -d':' -f2 | xargs)
        local avg_return=$(grep "Average Win:" "$BACKTEST_LOG" | cut -d':' -f2 | xargs)
        local total_return=$(grep "Total Return:" "$BACKTEST_LOG" | cut -d':' -f2 | xargs)
        
        if [ -n "$win_rate" ]; then
            message="$message

📈 **3-Month Backtest:**
• Win Rate: $win_rate
• Avg Return: $avg_return
• Simulated Portfolio Return: $total_return
• Data: 133 alerts analyzed"
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

log "Fetching real Cheddar Flow tweets via bird CLI..."

# Fetch tweets using bird CLI
TWEETS_JSON=$(bird user-tweets @CheddarFlow -n 10 --json 2>&1)

if [ $? -ne 0 ]; then
    log "❌ Failed to fetch tweets: $TWEETS_JSON"
    exit 1
fi

# Save tweets for processing
echo "$TWEETS_JSON" > /tmp/cheddar-tweets-latest.json

# Process tweets
echo "$TWEETS_JSON" | jq -c '.[]' 2>/dev/null | while read tweet; do
    TEXT=$(echo "$tweet" | jq -r '.text')
    CREATED_AT=$(echo "$tweet" | jq -r '.createdAt')
    TWEET_ID=$(echo "$tweet" | jq -r '.id')
    TWEET_URL="https://x.com/CheddarFlow/status/$TWEET_ID"
    
    # Convert Twitter date format
    FORMATTED_DATE=$(date -j -f "%a %b %d %H:%M:%S +0000 %Y" "$CREATED_AT" "+%b %d, %Y at %I:%M %p PST" 2>/dev/null || echo "$CREATED_AT")
    
    # Skip pinned/generic tweets
    if echo "$TEXT" | grep -qi "uncover unusual options"; then
        continue
    fi
    
    # Send alerts for trade-related tweets or all tweets from Cheddar Flow
    if echo "$TEXT" | grep -qiE "(sweep|block|flow|unusual|whale|million|premium|puts?|calls?|\$[A-Z]+|options|dark pool)"; then
        log "🚨 Trade alert found: ${TEXT:0:80}..."
        send_discord_alert "$TEXT" "$FORMATTED_DATE" "$TWEET_URL"
    fi
    
    sleep 1
done

log "Check complete"
