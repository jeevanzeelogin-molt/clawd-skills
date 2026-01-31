#!/bin/bash
# Clawdbot Operations Dashboard
# Run this anytime to see the status of all automated jobs

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║           🤖 CLAWDBOT OPERATIONS DASHBOARD                     ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Check launchd jobs
echo "📋 SCHEDULED JOBS"
echo "─────────────────────────────────────────────────────────────────"
echo ""

for job in com.clawd.cheddar-alerts com.clawd.twitter-monitor com.clawd.daily-dashboard; do
    status=$(launchctl list | grep "$job" | awk '{print $2}')
    if [ -n "$status" ]; then
        if [ "$status" -eq 0 ]; then
            echo "  ✅ $job - Running (PID: $(launchctl list | grep "$job" | awk '{print $1}'))"
        else
            echo "  ⚠️  $job - Exit code: $status"
        fi
    else
        echo "  ⏸️  $job - Not loaded"
    fi
done

echo ""
echo "📊 JOB DETAILS"
echo "─────────────────────────────────────────────────────────────────"
echo ""
echo "  🧀 Cheddar Flow Alerts    - Every 5 minutes"
echo "     └─ Checks @CheddarFlow X/Twitter for options trades"
echo ""
echo "  🐦 Twitter/OpenClaw Monitor - Every 6 hours (00:00, 06:00, 12:00, 18:00)"
echo "     └─ Searches for OpenClaw mentions and community projects"
echo ""
echo "  📈 Daily Dashboard Report   - Every day at 9:00 AM"
echo "     └─ Summary of all jobs, alerts, and community activity"
echo ""

# Check recent logs
echo "📜 RECENT LOG ACTIVITY"
echo "─────────────────────────────────────────────────────────────────"
echo ""

if [ -f /tmp/cheddar-alerts.log ]; then
    echo "  🧀 Cheddar Flow (last 5 lines):"
    tail -5 /tmp/cheddar-alerts.log | sed 's/^/     /'
    echo ""
else
    echo "  🧀 Cheddar Flow: No logs yet"
    echo ""
fi

if [ -f /tmp/twitter-monitor.log ]; then
    echo "  🐦 Twitter Monitor (last 5 lines):"
    tail -5 /tmp/twitter-monitor.log | sed 's/^/     /'
    echo ""
else
    echo "  🐦 Twitter Monitor: No logs yet"
    echo ""
fi

echo ""
echo "🔧 QUICK ACTIONS"
echo "─────────────────────────────────────────────────────────────────"
echo ""
echo "  Run Cheddar Flow check now:"
echo "    cd /Users/nemotaka/clawd/skills/cheddar-flow-alerts && ./scripts/check-x-scraper.sh"
echo ""
echo "  Run Twitter monitor now:"
echo "    /Users/nemotaka/clawd/skills/cheddar-flow-alerts/twitter-monitor.sh"
echo ""
echo "  View full logs:"
echo "    tail -f /tmp/cheddar-alerts.log"
echo "    tail -f /tmp/twitter-monitor.log"
echo "    tail -f /tmp/daily-dashboard.log"
echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  Dashboard updated: $(date '+%Y-%m-%d %H:%M:%S')                          ║"
echo "╚════════════════════════════════════════════════════════════════╝"
