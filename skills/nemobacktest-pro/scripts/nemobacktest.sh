#!/bin/bash
# NemoBacktest Pro — Master Control Script
# Run Monte Carlo, Tail Risk, and Portfolio Optimization

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="${SCRIPT_DIR}/../../data"
OUTPUT_DIR="${SCRIPT_DIR}/../../analysis"

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

show_help() {
    cat << EOF
NemoBacktest Pro — Advanced Risk Analytics for Options Trading

Usage: ./nemobacktest.sh [command] [options]

Commands:
  monte-carlo    Run Monte Carlo simulation
  tail-risk      Calculate tail risk metrics
  optimize       Optimize portfolio allocation
  full-analysis  Run all analyses
  dashboard      Generate HTML dashboard

Examples:
  ./nemobacktest.sh monte-carlo -i backtest.json -n 10000
  ./nemobacktest.sh tail-risk -i oo_trades.csv --stress-test
  ./nemobacktest.sh optimize -i strategies.json -m 2.0 -d 0.18
  ./nemobacktest.sh full-analysis -i backtest.json

For help on individual commands, run:
  ./nemobacktest.sh [command] --help
EOF
}

case "${1:-help}" in
    monte-carlo)
        shift
        python3 "$SCRIPT_DIR/monte-carlo.py" "$@"
        ;;
    tail-risk)
        shift
        python3 "$SCRIPT_DIR/tail-risk.py" "$@"
        ;;
    optimize)
        shift
        python3 "$SCRIPT_DIR/optimize-portfolio.py" "$@"
        ;;
    full-analysis)
        INPUT="${2:-}"
        if [ -z "$INPUT" ]; then
            echo "Usage: ./nemobacktest.sh full-analysis <input_file.json>"
            exit 1
        fi
        
        echo "🚀 Running Full NemoBacktest Analysis"
        echo "======================================"
        
        BASE_NAME=$(basename "$INPUT" | sed 's/\.[^.]*$//')
        
        echo ""
        echo "📊 Step 1: Monte Carlo Simulation"
        echo "─────────────────────────────────"
        python3 "$SCRIPT_DIR/monte-carlo.py" -i "$INPUT" -n 10000 -y 10 \
            -o "$OUTPUT_DIR/${BASE_NAME}_monte_carlo.json"
        
        echo ""
        echo "⚠️  Step 2: Tail Risk Analysis"
        echo "─────────────────────────────────"
        python3 "$SCRIPT_DIR/tail-risk.py" -i "$INPUT" -c 0.95 --stress-test \
            -o "$OUTPUT_DIR/${BASE_NAME}_tail_risk.json"
        
        echo ""
        echo "✅ Analysis complete!"
        echo "Results saved to: $OUTPUT_DIR/"
        ;;
    dashboard)
        echo "📊 Generating HTML dashboard..."
        # Placeholder for future dashboard generation
        echo "Dashboard feature coming soon!"
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
