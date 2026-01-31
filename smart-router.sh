#!/bin/bash
# Smart Model Router - Wrapper Script
# Usage: ./smart-router.sh "your request" [tier]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REQUEST="$1"
TIER="$2"

if [ -z "$REQUEST" ]; then
    echo "🤖 Smart Model Router"
    echo "===================="
    echo ""
    echo "Routes your requests to the most cost-effective AI model."
    echo ""
    echo "Usage:"
    echo "  ./smart-router.sh \"your request here\""
    echo "  ./smart-router.sh \"your request\" [tier]"
    echo ""
    echo "Tiers:"
    echo "  bulk      - FREE Gemini (CSV, extraction, formatting)"
    echo "  standard  - Kimi Code (analysis, summaries, coding)"
    echo "  complex   - Kimi K2 (multi-step, strategy, architecture)"
    echo "  critical  - Claude (debugging, deep reasoning)"
    echo ""
    echo "Examples:"
    echo '  ./smart-router.sh "summarize this CSV"'
    echo '  ./smart-router.sh "extract all tickers" bulk'
    echo '  ./smart-router.sh "debug this complex error" critical'
    echo ""
    echo "Stats:"
    node "$SCRIPT_DIR/smart-router.js" 2>/dev/null | head -5 || echo "  No stats yet"
    exit 0
fi

# Run the router
node "$SCRIPT_DIR/smart-router.js" "$REQUEST" "$TIER"
