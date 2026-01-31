#!/bin/bash
# Auto-fix common security issues found by security audit
# Run with: ./scripts/security-auto-fix.sh

CONFIG_FILE="/Users/nemotaka/.clawdbot/clawdbot.json"
BACKUP_FILE="/Users/nemotaka/.clawdbot/clawdbot.json.bak.$(date +%Y%m%d-%H%M%S)"
LOG_FILE="/Users/nemotaka/clawd/logs/security-auto-fix.log"

echo "🔧 Security Auto-Fix Script"
echo "=========================="
echo ""

# Create backup
cp "$CONFIG_FILE" "$BACKUP_FILE"
echo "✅ Backup created: $BACKUP_FILE"
echo ""

# Fix 1: File permissions
echo "🔧 Checking file permissions..."
chmod 600 "$CONFIG_FILE"
echo "   Set to 600 (owner read/write only)"

# Fix 2: Check for other security issues
node /Users/nemotaka/clawd/skills/security-audit/scripts/audit.cjs --full --json > /tmp/audit-results.json 2>/dev/null

CRITICAL=$(cat /tmp/audit-results.json | grep -c '"level": "CRITICAL"' || echo 0)
HIGH=$(cat /tmp/audit-results.json | grep -c '"level": "HIGH"' || echo 0)

echo ""
echo "📊 Current Status:"
echo "   Critical: $CRITICAL"
echo "   High: $HIGH"
echo ""

if [ "$CRITICAL" -gt 0 ] || [ "$HIGH" -gt 0 ]; then
    echo "⚠️  Issues requiring manual attention:"
    cat /tmp/audit-results.json | jq -r '.findings[] | select(.level=="CRITICAL" or .level=="HIGH") | "  \(.level): \(.message)"' 2>/dev/null
    echo ""
    echo "Review and fix manually, or run:"
    echo "  node skills/security-audit/scripts/audit.cjs --fix"
fi

echo ""
echo "✅ Auto-fix complete!"
echo ""
echo "Note: API keys in config should be moved to environment variables manually."
echo "Add to your ~/.zshrc or ~/.bash_profile:"
echo "  export DISCORD_BOT_TOKEN='your-token'"
echo "  export MOONSHOT_API_KEY='your-key'"
