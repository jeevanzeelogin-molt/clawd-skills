#!/bin/bash
# Send Discord alert to #general channel in Nemo's server

CHANNEL_ID=$(cat ~/.cheddar-config.json 2>/dev/null | grep -o '"discordChannel"[^"]*"[^"]*"' | cut -d'"' -f4)
[ -z "$CHANNEL_ID" ] && CHANNEL_ID="1143404804157227030"
MESSAGE="$1"

# Use clawdbot CLI to send the message
cd /Users/nemotaka/clawd
clawdbot message send --channel discord --target "$CHANNEL_ID" -m "$MESSAGE" 2>&1
