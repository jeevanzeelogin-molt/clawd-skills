#!/bin/bash
# Quick cookie extractor for X/Twitter
# Run this in Terminal while Chrome is open and you're logged into x.com

echo "=== X/Twitter Cookie Extractor ==="
echo ""
echo "Make sure you're logged into x.com in Chrome first!"
echo ""

# Try to extract from Chrome's SQLite DB
COOKIES_DB="$HOME/Library/Application Support/Google/Chrome/Default/Cookies"

if [ ! -f "$COOKIES_DB" ]; then
    echo "❌ Chrome cookies database not found"
    echo "   Location: $COOKIES_DB"
    exit 1
fi

echo "Found Chrome cookies database"
echo ""
echo "To extract cookies manually:"
echo ""
echo "1. Open Chrome and go to: https://x.com/CheddarFlow"
echo "2. Make sure you're logged in"
echo "3. Press F12 (Developer Tools)"
echo "4. Click 'Application' tab"
echo "5. In left sidebar: Cookies → https://x.com"
echo "6. Find these two values and copy them:"
echo ""
echo "   auth_token: [long string of letters/numbers]"
echo "   ct0: [shorter string]"
echo ""
echo "7. Paste them below:"
echo ""

# Prompt for input
read -p "Enter auth_token: " AUTH_TOKEN
read -p "Enter ct0: " CT0

if [ -n "$AUTH_TOKEN" ] && [ -n "$CT0" ]; then
    echo ""
    echo "✅ Cookies received!"
    echo ""
    echo "Add these to your shell profile (.zshrc or .bash_profile):"
    echo ""
    echo "export AUTH_TOKEN=\"$AUTH_TOKEN\""
    echo "export CT0=\"$CT0\""
    echo ""
    echo "Then run: source ~/.zshrc"
    echo ""
    echo "Or run this now to test:"
    echo "AUTH_TOKEN=\"$AUTH_TOKEN\" CT0=\"$CT0\" ./check-cheddar-v2.sh"
else
    echo "❌ Both values are required"
fi
