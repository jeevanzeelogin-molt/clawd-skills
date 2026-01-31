#!/bin/bash
# Cheddar Flow Historical Backtest Runner
# Analyzes past 6 months of alerts and simulates performance

echo "🧀 Cheddar Flow Historical Backtest"
echo "===================================="
echo ""
echo "This will:"
echo "  1. Collect historical alerts from @CheddarFlow (past 6 months)"
echo "  2. Parse trade entries, whale entries, darkpool prints"
echo "  3. Fetch historical stock prices"
echo "  4. Calculate P&L for each trade"
echo "  5. Generate comprehensive backtest report"
echo ""

# Check dependencies
if ! command -v node &> /dev/null; then
    echo "❌ Node.js not found. Please install Node.js."
    exit 1
fi

cd /Users/nemotaka/clawd/skills/cheddar-flow-alerts

# Create data directory
mkdir -p /Users/nemotaka/clawd/data/cheddar-backtest

# Run the backtest
echo "📊 Starting backtest simulation..."
echo ""

node scripts/backtest-cheddar.js

echo ""
echo "✅ Backtest complete!"
echo ""
echo "📁 Output files:"
echo "  • /Users/nemotaka/clawd/data/cheddar-backtest/backtest-results-*.json"
echo ""
echo "📈 To view detailed results:"
echo "  cat /Users/nemotaka/clawd/data/cheddar-backtest/backtest-results-*.json | jq '.summary'"
echo ""
echo "💡 Note: This uses simulated data for demonstration."
echo "   For real backtesting with actual historical prices,"
echo "   integrate with your yahoo-finance skill."
