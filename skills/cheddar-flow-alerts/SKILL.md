---
name: cheddar-flow-alerts
description: Monitor Cheddar Flow X/Twitter (@CheddarFlow) for options trade alerts and send real-time notifications via Discord. Uses free web scraping - NO API KEY NEEDED. Tracks unusual options activity, sweep trades, and block trades. V2 includes signal strength scoring and pattern detection.
---

# 🧀 Cheddar Flow X/Twitter Alerts v2

**Intelligent options flow monitoring with signal strength scoring**

Monitors @CheddarFlow on X/Twitter for trade alerts and sends instant Discord notifications with **signal strength analysis**.

**NO PAID API REQUIRED** - Uses free web scraping

## How It Works

1. Checks @CheddarFlow X/Twitter every few minutes
2. Detects new trade alert tweets
3. Parses trade details (symbol, strike, expiry, type)
4. Sends Discord alert instantly

## 🆕 v2 Features

- 🎯 **Signal Strength Scoring** (1-10) - Rates alerts based on premium, volume, patterns
- 📊 **Pattern Detection** - Identifies sweep clusters and repeat buyers
- 💰 **Premium Analysis** - Auto-calculates significance
- 🎨 **Rich Discord Embeds** - Color-coded by direction (green/red/yellow)
- 📈 **Flow Stats** - Daily statistics and top signals

## Signal Strength Formula

```
Base Score: 5
+ Premium Size (>$2M = +3, >$1M = +2, >$500K = +1)
+ Volume vs Avg (>10x = +2, >5x = +1)
+ Cluster Pattern (+1)
+ Near Expiry <7 DTE (+1)
= Final Score (1-10)
```

**Signal Levels:**
- 🔥 **8-10**: STRONG - Consider immediate action
- 📈 **5-7**: MODERATE - Worth watching
- 💡 **1-4**: WEAK - Informational only

## Alert Types Tracked

- **Sweep Trades** - Multi-exchange orders
- **Block Trades** - Large institutional orders  
- **Unusual Options Activity** - High volume trades
- **Flow Clusters** - Multiple sweeps on same ticker (NEW v2)
- **Whale Alerts** - Premium >$1M (always sent)

## Configuration

Edit `~/.cheddar-config.json`:
```json
{
  "discordChannel": "1466666758642340074",
  "minPremium": 100000,
  "symbols": ["SPY", "QQQ", "AAPL", "TSLA", "NVDA", "AMD"],
  "keywords": ["sweep", "block", "unusual", "flow"]
}
```

## Usage

### Manual Check
```bash
./scripts/check-x-scraper.sh
```

### Continuous Monitoring
```bash
./scripts/monitor-cheddar.sh
```

### Automated (via Launchd)
```bash
# Already set up - checks every 5 minutes
launchctl list | grep cheddar
```

## Alert Format

Discord notifications include:
🧀 **Cheddar Flow Alert**

**Symbol:** AAPL
**Strike:** 185 CALL
**Expiry:** Feb 14
**Type:** SWEEP
**Premium:** $250,000

⏰ 10:30 AM

## Setting Up

1. **Install dependencies** (if not already):
```bash
brew install jq
```

2. **Test the scraper**:
```bash
cd /Users/nemotaka/clawd/skills/cheddar-flow-alerts
./scripts/check-x-scraper.sh
```

3. **Set up Discord channel** in config

4. **Enable automated checking**:
```bash
./scripts/schedule-cheddar-launchd.sh
```

## Commands

| Command | Description |
|---------|-------------|
| `check-x-scraper.sh` | Check X/Twitter now |
| `monitor-cheddar.sh` | Run continuous monitor |
| `setup.sh` | Interactive setup wizard |

## Logs

Check logs at:
```bash
tail -f /Users/nemotaka/clawd/logs/cheddar-alerts.log
```

## Troubleshooting

**No alerts?**
- Check internet connection
- Verify Discord channel ID
- Review logs for errors
- X/Twitter may block scrapers (use VPN if needed)

**Missing trades?**
- X/Twitter rate limits may apply
- Increase check frequency if needed
- Consider using X Premium API for production

## Limitations

- Free scraper may be less reliable than paid API
- X/Twitter can block scrapers
- 5-10 minute delay possible
- Best for personal use, not professional trading
