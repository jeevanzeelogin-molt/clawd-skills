# Cheddar Flow Signal Tracker

## Monitoring Setup

### Channels Monitored
- **Cheddar Flow Server**
  - `order-flow-🌊` (ID: 935618770150518855) - Order flow alerts
  - `dark-pool-🔮` (ID: 935627450099069008) - Dark pool activity
  - `cheddar-flow-🧀` (ID: 979083772576288818) - Twitter feed

- **MAD Server (It's Great When It Works Trading Club)**
  - `oo-trade-entries-and-exits` (ID: 1420414958063190166) - Entry/exit signals
  - `general-discussion` (ID: 1418640864636309514) - General chat

### Signal Types to Track
1. **Whale Flow** - $5M+ option buys
2. **Sweep Alerts** - Large block trades
3. **Gamma Levels** - Strike price walls
4. **Earnings Plays** - Pre-earnings flow
5. **Unusual Activity** - Anomalous volume

### Keywords
- Tickers: $SPY, $QQQ, $TSLA, $AAPL, $AMZN, $META, $NVDA, $SLV, $BTC
- Terms: "sweep", "whale", "flow", "gamma", "call wall", "put hedge"
- Amounts: "$M", "million", "Billion"

## Backtesting Data

See `cheddarflow_signals_6mo.json` for historical signals and results.

## Alert Criteria
- Flow size > $5M
- Multiple whales on same ticker
- Unusual activity flagged by Cheddar
- Earnings-related flow
