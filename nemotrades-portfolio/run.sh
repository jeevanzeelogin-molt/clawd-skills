#!/bin/bash
# Nemotrades Portfolio Optimizer - Runner

cd "$(dirname "$0")"

echo "🚀 Nemotrades Portfolio Optimizer"
echo "═══════════════════════════════════════════════════════════════"
echo ""

case "$1" in
  dashboard)
    echo "📊 Opening Strategy Heatmap..."
    open heatmap.html
    ;;
  optimize)
    echo "⚙️  Running Strategy Optimization..."
    node src/optimizer.js
    ;;
  status)
    echo "📈 Displaying Live Dashboard..."
    node src/dashboard.js
    ;;
  watch)
    echo "👀 Starting Watch Mode..."
    node src/dashboard.js watch
    ;;
  *)
    echo "Usage: ./run.sh [command]"
    echo ""
    echo "Commands:"
    echo "  dashboard  - Open strategy heatmap"
    echo "  optimize   - Run backtest optimization"
    echo "  status     - Show live dashboard"
    echo "  watch      - Watch mode (auto-refresh)"
    echo ""
    echo "Quick Start:"
    echo "  ./run.sh dashboard    # View heatmap"
    echo "  ./run.sh optimize     # Run optimizations"
    echo "  ./run.sh status       # Check progress"
    ;;
esac
