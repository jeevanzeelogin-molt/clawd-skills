#!/bin/bash
# Daily Security Audit Runner for Clawdbot
# Runs at 9 AM daily via launchd

LOG_FILE="/Users/nemotaka/clawd/logs/security-audit-daily.log"
REPORT_FILE="/Users/nemotaka/clawd/logs/security-audit-latest.json"
ALERT_SENT_FILE="/Users/nemotaka/clawd/logs/security-alerts-sent.log"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Timestamp
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
echo "[$TIMESTAMP] Starting daily security audit..." >> "$LOG_FILE"

# Run the audit
cd /Users/nemotaka/clawd
AUDIT_OUTPUT=$(node skills/security-audit/scripts/audit.cjs --full --json 2>&1)
AUDIT_STATUS=$?

# Save full report
echo "$AUDIT_OUTPUT" > "$REPORT_FILE"

if [ $AUDIT_STATUS -ne 0 ]; then
    echo "[$TIMESTAMP] ❌ Audit failed to run" >> "$LOG_FILE"
    exit 1
fi

# Parse results
echo "$AUDIT_OUTPUT" | grep -q '"CRITICAL"'
HAS_CRITICAL=$?

echo "$AUDIT_OUTPUT" | grep -q '"HIGH"'
HAS_HIGH=$?

CRITICAL_COUNT=$(echo "$AUDIT_OUTPUT" | grep -c '"level": "CRITICAL"' || echo 0)
HIGH_COUNT=$(echo "$AUDIT_OUTPUT" | grep -c '"level": "HIGH"' || echo 0)

# Log summary
echo "[$TIMESTAMP] Audit complete. Critical: $CRITICAL_COUNT, High: $HIGH_COUNT" >> "$LOG_FILE"

# Check if we already sent an alert for this issue today
ALERT_ID="$(date +%Y%m%d)-$CRITICAL_COUNT-$HIGH_COUNT"
if [ -f "$ALERT_SENT_FILE" ] && grep -q "$ALERT_ID" "$ALERT_SENT_FILE"; then
    echo "[$TIMESTAMP] Alert already sent today for this issue" >> "$LOG_FILE"
    exit 0
fi

# If critical or high issues found, send Discord alert
if [ $HAS_CRITICAL -eq 0 ] || [ $HAS_HIGH -eq 0 ]; then
    echo "[$TIMESTAMP] 🚨 Issues found! Sending Discord alert..." >> "$LOG_FILE"
    
    # Build alert message
    ALERT_MSG="🚨 **DAILY SECURITY AUDIT ALERT** 🚨

"
    
    if [ $HAS_CRITICAL -eq 0 ]; then
        ALERT_MSG+="🔴 **$CRITICAL_COUNT CRITICAL** issue(s) found!

"
    fi
    
    if [ $HAS_HIGH -eq 0 ]; then
        ALERT_MSG+="🟠 **$HIGH_COUNT HIGH** severity issue(s) found!

"
    fi
    
    ALERT_MSG+="📊 Run: \`node skills/security-audit/scripts/audit.cjs --full\` for details.

"
    ALERT_MSG+="🔧 Want me to fix these? Reply with 'fix security issues'"
    
    # Send via Discord
    /Users/nemotaka/clawd/skills/cheddar-flow-alerts/scripts/send-dm.sh "$ALERT_MSG" 2>&1 >> "$LOG_FILE"
    
    # Mark alert as sent
    echo "$ALERT_ID" >> "$ALERT_SENT_FILE"
    
    echo "[$TIMESTAMP] ✅ Discord alert sent" >> "$LOG_FILE"
else
    echo "[$TIMESTAMP] ✅ No issues found. All clear!" >> "$LOG_FILE"
fi

exit 0
