#!/bin/bash
# Flow Stats Viewer - Shows today's top signals and patterns

SIGNAL_HISTORY="/Users/nemotaka/clawd/logs/cheddar-signals.json"

if [ ! -f "$SIGNAL_HISTORY" ]; then
    echo "No signal history found. Run check-cheddar-v2.sh first."
    exit 1
fi

echo "🧀 Cheddar Flow Stats - $(date '+%Y-%m-%d')"
echo "=========================================="
echo ""

# Today's signals
echo "📊 Today's Signals:"
jq -r --arg today "$(date +%Y-%m-%d)" '
    [.[] | select(.datetime | startswith($today))] |
    group_by(.symbol) |
    map({
        symbol: .[0].symbol,
        count: length,
        total_premium: map(.premium) | add,
        avg_score: (map(.score) | add / length),
        top_score: (map(.score) | max)
    }) |
    sort_by(.total_premium) | reverse |
    .[0:10] |
    .[] |
    "  \(.symbol): \(.count) alerts | Premium: $\(.total_premium | tostring | split("") | reverse | join("") | gsub("(\\d{3})(?=\\d)"; "\\1,") | split("") | reverse | join("")) | Avg Score: \(.avg_score | floor)/10 | Top: \(.top_score)/10"
' "$SIGNAL_HISTORY" 2>/dev/null || echo "  No data yet"

echo ""
echo "🔥 Top Score Alerts Today:"
jq -r --arg today "$(date +%Y-%m-%d)" '
    [.[] | select(.datetime | startswith($today))] |
    sort_by(.score) | reverse |
    .[0:5] |
    .[] |
    "  [\(.score)/10] \(.symbol) \(.strike)\(.callPut) \(.type) - $\(.premium)"
' "$SIGNAL_HISTORY" 2>/dev/null || echo "  No data yet"

echo ""
echo "📈 Pattern Detection:"

# Check for clusters
clusters=$(jq -r --arg today "$(date +%Y-%m-%d)" '
    [.[] | select(.datetime | startswith($today) and .type == "cluster")] |
    group_by(.symbol) |
    map({symbol: .[0].symbol, count: length}) |
    sort_by(.count) | reverse |
    .[] |
    "  \(.symbol): \(.count) cluster events"
' "$SIGNAL_HISTORY" 2>/dev/null)

if [ -n "$clusters" ]; then
    echo "  Cluster Activity:"
    echo "$clusters"
else
    echo "  No cluster patterns detected yet"
fi

echo ""
echo "💰 Total Premium Tracked Today:"
total=$(jq -r --arg today "$(date +%Y-%m-%d)" '
    [.[] | select(.datetime | startswith($today))] |
    map(.premium) | add // 0
' "$SIGNAL_HISTORY" 2>/dev/null)

if [ -n "$total" ] && [ "$total" != "null" ]; then
    echo "  $\$(echo "scale=1; $total/1000000" | bc)M"
else
    echo "  $0"
fi
