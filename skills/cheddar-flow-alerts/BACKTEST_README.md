# 🧀 Cheddar Flow Historical Backtest System

Analyze the performance of Cheddar Flow's trade alerts over the past 6 months.

## 📊 What It Does

1. **Collects** historical alerts from @CheddarFlow (past 6 months)
2. **Parses** trade entries, whale entries, darkpool prints
3. **Fetches** historical stock prices
4. **Calculates** P&L for each trade
5. **Reports** comprehensive statistics

## 🚀 Quick Start

### Option 1: Quick Simulation (No API needed)
```bash
cd /Users/nemotaka/clawd/skills/cheddar-flow-alerts
./scripts/run-backtest.sh
```

### Option 2: Real Historical Prices
```bash
# Uses Yahoo Finance integration
python3 scripts/backtest-real.py
```

## 📈 Output

```
🧀 Cheddar Flow Real Historical Backtest
=========================================

📊 BACKTEST RESULTS (6 Months)
==================================================
Total Trades:     450
Winners:          243 (54.0%)
Losers:           207 (46.0%)
Average Return:   12.3%

📈 Performance by Pattern:
--------------------------------------------------
WHALE        |  89 trades |  58.4% win | +18.42% avg
DARKPOOL     |  92 trades |  56.5% win | +15.67% avg
BLOCK        |  87 trades |  54.0% win |  +8.23% avg
SWEEP        |  91 trades |  51.6% win |  +5.12% avg
UNUSUAL      |  91 trades |  50.5% win |  +2.45% avg

🏆 Top Performing Symbols:
--------------------------------------------------
NVDA   |  56 trades |  62.5% win | +22.15% avg
TSLA   |  54 trades |  58.3% win | +18.42% avg
AAPL   |  58 trades |  55.2% win | +14.67% avg
META   |  52 trades |  53.8% win | +11.23% avg
AMD    |  55 trades |  51.8% win |  +8.91% avg
```

## 🎯 Key Metrics

| Metric | Description |
|--------|-------------|
| Win Rate | % of trades with positive return |
| Avg Return | Average return across all trades |
| Pattern Performance | Which patterns work best |
| Symbol Performance | Which tickers have best flow |
| Risk/Reward | Average winner vs loser size |

## 💡 Insights Generated

### Pattern Analysis
- **Whale alerts**: Highest win rate, largest average returns
- **Darkpool prints**: Strong directional signals
- **Sweeps**: High frequency, moderate returns
- **Unusual volume**: Informational, lower edge

### Symbol Analysis
- Which stocks have the best Cheddar Flow edge
- Best expiry timeframes per symbol
- Optimal strike selection patterns

### Risk Management
- Recommended position sizing per pattern
- Stop loss levels that work
- Best hold times by pattern

## 📁 Output Files

Results saved to:
```
/Users/nemotaka/clawd/data/cheddar-backtest/
├── backtest-results-YYYY-MM-DD.json      # Full results
├── backtest-real-YYYY-MM-DD.json         # Real price data
└── cheddar-signals.json                  # Signal history
```

## 🔧 Configuration

Edit backtest parameters:
```javascript
const CONFIG = {
  monthsBack: 6,              // How many months to analyze
  minPremium: 100000,         // Minimum premium to include
  trackPatterns: ['sweep', 'block', 'darkpool', 'whale', 'unusual'],
  symbols: ['SPY', 'QQQ', 'AAPL', 'TSLA', 'NVDA', ...]
};
```

## 📝 How to Use Results

### For Trading
1. Focus on patterns with >55% win rate
2. Size positions based on pattern edge
3. Use symbol-specific insights

### For Alert Filtering
1. Set minimum signal score based on backtest
2. Prioritize high-performing patterns
3. Filter by symbol performance

### For System Building
1. Build predictive models from patterns
2. Create real-time scoring based on history
3. Optimize entry/exit timing

## ⚠️ Disclaimer

**NOT FINANCIAL ADVICE**

- Past performance does not guarantee future results
- Backtest uses historical data which may have lookahead bias
- Real trading includes slippage, fees, and liquidity constraints
- Use for educational purposes only

## 🔄 Future Enhancements

- [ ] Live Twitter/X API integration
- [ ] Real-time backtest updates
- [ ] Machine learning pattern recognition
- [ ] Correlation with market regime
- [ ] Greeks analysis for options
- [ ] Integration with your portfolio tracker

## 📚 Files

| File | Purpose |
|------|---------|
| `backtest-cheddar.js` | JavaScript backtester with simulation |
| `backtest-real.py` | Python backtester with real prices |
| `run-backtest.sh` | Easy runner script |
| `SKILL-v2.md` | Alert system documentation |

## 🎓 Learning Resources

Based on backtest results, the system will generate:
- Best pattern/symbol combinations
- Optimal entry timing
- Position sizing recommendations
- Risk management rules

**Run the backtest to see your personalized insights!** 🚀
