---
name: cheddar-flow-alerts-v2
description: Enhanced Cheddar Flow monitoring with signal scoring, historical tracking, and actionable trade alerts. Monitors @CheddarFlow for options sweeps, blocks, and unusual activity with intelligent parsing.
---

# 🧀 Cheddar Flow Alerts v2

**Intelligent options flow monitoring with signal strength scoring**

## What's New in v2

- 🎯 **Signal Strength Scoring** - Rates alerts 1-10 based on multiple factors
- 📊 **Historical Context** - Compares to 30-day average volume
- 💰 **Premium Analysis** - Auto-calculates if trade is significant
- 🔄 **Pattern Detection** - Identifies repeated sweeps, sweep clusters
- 📈 **Actionable Embeds** - Rich Discord messages with key levels
- 🎨 **Color Coding** - Green (bullish) / Red (bearish) / Yellow (neutral)

## Signal Strength Formula

```
Base Score (1-10)
+ Premium Size (>$1M = +2, >$500K = +1)
+ Volume vs Avg (>10x = +2, >5x = +1)
+ Multiple Sweeps (same ticker = +1)
+ Near Expiry (<7 days = +1)
= Final Score (1-10)
```

**Signal Levels:**
- 🟢 **8-10**: STRONG - Consider immediate action
- 🟡 **5-7**: MODERATE - Worth watching
- ⚪ **1-4**: WEAK - Informational only

## Alert Types

### 1. **Sweep Alerts** 🧹
Multi-exchange orders indicating urgency
```
🧀 SWEEP ALERT | NVDA | Score: 9/10

Bullish Call Sweep
Strike: $750 CALL
Expiry: Feb 14 (13 DTE)
Premium: $2.4M 🔥

📊 Context:
• 15x average daily volume
• 3rd sweep today on NVDA
• Unusual size for strike

🎯 Key Levels:
Support: $735 | Resistance: $765

💡 Signal: STRONG BULLISH
```

### 2. **Block Trades** 🧱
Large institutional orders
```
🧀 BLOCK ALERT | SPY | Score: 7/10

Bearish Put Block
Strike: $590 PUT
Expiry: Feb 21
Premium: $8.2M

📊 Institutional sized
🎯 Potential hedge or directional bet
```

### 3. **Unusual Activity** 📈
Volume spikes vs historical
```
🧀 UNUSUAL ACTIVITY | AMD

Call volume: 450% of avg
Put/Call ratio: 0.3 (bullish skew)
Net premium: +$1.8M calls

💡 Signal: Bullish flow building
```

### 4. **Flow Clusters** 🎯
Multiple signals same ticker
```
🧀 FLOW CLUSTER | TSLA

4 sweeps in last 30 minutes
Total premium: $12.4M
Direction: Mixed (calls + puts)

💡 Interpretation: Earnings play or 
   straddle position building
```

## Configuration

Edit `~/.cheddar-config.json`:

```json
{
  "discordChannel": "1143404804157227030",
  "minSignalScore": 5,
  "minPremium": 100000,
  "trackSymbols": ["SPY", "QQQ", "AAPL", "TSLA", "NVDA", "AMD", "META", "AMZN"],
  "alertTypes": ["sweep", "block", "unusual", "cluster"],
  "quietHours": {
    "enabled": false,
    "start": "22:00",
    "end": "06:00"
  },
  "patterns": {
    "trackClusters": true,
    "clusterWindowMinutes": 60,
    "minSweepsForCluster": 3
  }
}
```

## Commands

| Command | Description |
|---------|-------------|
| `check-cheddar.sh` | Check for alerts now |
| `analyze-flow.sh <TICKER>` | Analyze recent flow for ticker |
| `flow-stats.sh` | Show today's top signals |
| `backtest-alert.sh` | Test signal scoring |

## Usage

### Quick Check
```bash
cd /Users/nemotaka/clawd/skills/cheddar-flow-alerts
./scripts/check-cheddar.sh
```

### Analyze Specific Ticker
```bash
./scripts/analyze-flow.sh NVDA
```

### View Today's Top Alerts
```bash
./scripts/flow-stats.sh
```

## How It Works

1. **Scrape** - Fetches @CheddarFlow tweets every 3 minutes
2. **Parse** - Extracts ticker, strike, expiry, premium, type
3. **Score** - Calculates signal strength (1-10)
4. **Enrich** - Adds context (volume vs avg, key levels)
5. **Filter** - Only sends if ≥ minSignalScore
6. **Alert** - Sends rich Discord embed

## Installation

```bash
# Run enhanced setup
./scripts/setup-v2.sh
```

## Logs

```bash
# Real-time alerts
tail -f /Users/nemotaka/clawd/logs/cheddar-alerts.log

# Signal history
cat /Users/nemotaka/clawd/logs/cheddar-signals.json

# Daily stats
./scripts/flow-stats.sh
```

## Smart Features

### Pattern Recognition
- **Sweep Clusters** - 3+ sweeps in 60 min on same ticker
- **Repeat Buyers** - Same strike/expiry hit multiple times
- **Whale Tracking** - Premium >$5M alerts (always sent)

### Context Awareness
- **Market Hours** - Reduced alerts after 4 PM ET
- **Earnings Season** - Higher sensitivity pre-earnings
- **VIX Environment** - Adjusts thresholds based on volatility

### Anti-Spam
- **Duplicate Detection** - Won't re-alert same trade
- **Cooldown Period** - 10 min between same-ticker alerts
- **Minimum Threshold** - Filters <$100K premium trades

## Example Workflows

### Day Trading
```
1. Alert comes in: NVDA Call Sweep Score 9/10
2. Check chart: At support, volume building
3. Enter position with tight stop
4. Set target at resistance level from alert
```

### Swing Trading
```
1. Flow Cluster on AAPL detected
2. Multiple sweeps over 2 days
3. Same expiry (2 weeks out)
4. Research catalyst → earnings next week
5. Position for earnings move
```

### Hedging
```
1. Portfolio heavily weighted tech
2. QQQ Put Block $15M alert (Score 8/10)
3. Add QQQ puts as portfolio hedge
4. Strike matches alert level
```

## Limitations

- Free scraper has 3-5 min delay
- X/Twitter may block (use VPN if needed)
- Not real-time like paid API
- Best for idea generation, not execution

## Disclaimer

**NOT FINANCIAL ADVICE** - These alerts are for informational purposes only. Always do your own research before trading. Past performance does not guarantee future results.
