#!/bin/bash
# Setup Cheddar Flow Alerts

echo "🧀 Cheddar Flow Alert Setup"
echo "==========================="
echo ""

CONFIG_FILE="$HOME/.cheddar-config.json"

if [ -f "$CONFIG_FILE" ]; then
    echo "Config already exists at $CONFIG_FILE"
    read -p "Overwrite? (y/N): " overwrite
    if [ "$overwrite" != "y" ]; then
        echo "Setup cancelled"
        exit 0
    fi
fi

echo ""
echo "Enter your Cheddar Flow API Key:"
read -s API_KEY
echo ""

echo "Enter Discord Channel ID for alerts:"
read DISCORD_CHANNEL

echo "Enter minimum premium threshold (default 100000):"
read MIN_PREMIUM
MIN_PREMIUM=${MIN_PREMIUM:-100000}

echo "Enter symbols to watch (comma-separated, default: SPY,QQQ,AAPL,TSLA):"
read SYMBOLS
SYMBOLS=${SYMBOLS:-"SPY,QQQ,AAPL,TSLA"}

# Create config
cat > "$CONFIG_FILE" << EOF
{
  "apiKey": "$API_KEY",
  "discordChannel": "$DISCORD_CHANNEL",
  "minPremium": $MIN_PREMIUM,
  "symbols": [$(echo "$SYMBOLS" | sed 's/,/", "/g' | sed 's/^/"/' | sed 's/$/"/')]
}
EOF

echo ""
echo "✅ Config saved to $CONFIG_FILE"
echo ""
echo "Next steps:"
echo "1. Test: ./scripts/check-cheddar.sh"
echo "2. Monitor: ./scripts/monitor-cheddar.sh"
echo "3. Schedule: Add to crontab for automated checks"
