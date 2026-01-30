---
name: cheddar-flow-alerts
description: Monitor Cheddar Flow for options trade entries and send real-time alerts via Discord, Signal, or other channels. Use when user wants to track unusual options activity, sweep trades, or block trades from Cheddar Flow.
---

# Cheddar Flow Trade Alerts

Monitors Cheddar Flow for new trade entries and sends instant alerts.

## Supported Alert Types

- **Unusual Options Activity** - High volume trades
- **Sweep Trades** - Multi-exchange orders
- **Block Trades** - Large institutional orders
- **Premium Threshold** - Trades above $X amount
- **Symbol Watchlist** - Specific tickers you care about

## Configuration

Create `~/.cheddar-config.json`:
```json
{
  "apiKey": "your_cheddar_api_key",
  "discordChannel": "your_discord_channel_id",
  "alertThresholds": {
    "minPremium": 100000,
    "symbols": ["SPY", "QQQ", "AAPL", "TSLA"],
    "tradeTypes": ["sweep", "block"]
  }
}
```

## Usage

### Check for new trades (manual)
```bash
./scripts/check-cheddar.sh
```

### Start monitoring (continuous)
```bash
./scripts/monitor-cheddar.sh
```

### Set up automated alerts
```bash
# Add to crontab for every 5 minutes
*/5 * * * * cd /Users/nemotaka/clawd/skills/cheddar-flow-alerts && ./scripts/check-cheddar.sh
```

## Alert Format

Discord alerts include:
- Ticker symbol
- Strike price & expiration
- Call/Put type
- Premium amount
- Trade type (sweep/block)
- Timestamp

## Commands

| Command | Description |
|---------|-------------|
| `check-now` | Check for new trades immediately |
| `set-threshold <amount>` | Set minimum premium alert |
| `add-symbol <symbol>` | Add ticker to watchlist |
| `remove-symbol <symbol>` | Remove ticker from watchlist |
| `status` | Show current configuration |

## Getting Cheddar Flow Access

1. Subscribe at https://cheddarflow.com
2. Get API key from dashboard
3. Add to config file

## Troubleshooting

**No alerts coming through?**
- Check API key is valid
- Verify Discord channel ID
- Check alert thresholds aren't too high
- Review logs in `logs/cheddar-alerts.log`
