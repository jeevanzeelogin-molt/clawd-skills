# Cheddar Flow Alert System - Context & Memory

**Created:** January 31, 2026  
**Purpose:** Monitor @CheddarFlow Twitter for options trade alerts and track results

---

## System Overview

### What It Does
1. **Monitors** @CheddarFlow Twitter every 5 minutes for trade alerts
2. **Sends Discord alerts** with full details (date, time, symbol, premium, tweet link)
3. **Tracks results** - waits for Cheddar Flow to post follow-up results
4. **Calculates 3-day results** automatically if no result posted
5. **Maintains backtest** document with all trades

### Key Files
- `check-cheddar-v3.sh` - Main monitor (uses bird CLI)
- `cheddar-tracker.sh` - Manual strike entry tracker
- `calculate-3day-results.py` - Auto 3-day result calculator
- `CHEDDAR_ALL_ALERTS.md` - All 128 alerts documented
- `CHEDDAR_BACKTEST_DETAILED.md` - Full backtest with trade analysis
- `logs/cheddar-alerts.log` - Alert history
- `logs/cheddar-backtest.log` - Backtest summary
- `logs/cheddar-tracker-db.json` - Active trades database

---

## Backtest Results (3 Months)

### Performance
- **Total Alerts:** 133
- **With Results:** 7 confirmed + 4 calculated
- **Win Rate:** 100% (confirmed), 25% (calculated 3-day)
- **Average Return:** +206.9% (confirmed), -3.84% (calculated)
- **Portfolio Simulation:** $10K → $13,193 (+31.94%)

### Top Trades
1. **SLV Put Sweep** - +700% (Silver whale, 1 day)
2. **SLV Put Sweep** - +342% (Same position)
3. **QQQ Power Alert** - +236%
4. **AAPL Whale** - +55% (10 minutes!)

### Pending Alerts (Calculated 3-Day)
- **MU** - $3.6M Deep ITM Put → -7.50% (3-day calc)
- **SPY** - $1B Call Wall @ 700 → -7.50% (3-day calc)
- **QQQ** - OTM Puts → -7.14% (3-day calc)

---

## Important Notes

### Why Calculated Results Differ from Actual
- **SLV Example:** Calculated +6.77% vs Actual +700%
- **Reason:** Options can have gamma acceleration, IV expansion
- **Lesson:** Cheddar Flow's actual results are more accurate than calculations

### Tracking Strategy
1. **Primary:** Wait for Cheddar Flow to post result tweet
2. **Backup:** Calculate 3-day result if no post after 3 days
3. **Manual:** Use tracker.sh to enter strikes and calculate

### Data Sources
- **Twitter:** @CheddarFlow (via bird CLI)
- **Prices:** Yahoo Finance (yfinance)
- **Storage:** GitHub repo + local JSON files

---

## Daily Operations

### Automatic (Every 5 min)
- Check @CheddarFlow for new alerts
- Send Discord notifications
- Log to files

### Automatic (Daily @ 9 AM)
- Check for 3-day old alerts
- Calculate results if needed
- Update backtest document

### Manual Commands
```bash
# Add new alert manually
cheddar-tracker add SPY CALL SWEEP "$2M"

# Enter strike price
cheddar-tracker strike <id> 450 2026-02-14

# Calculate return
cheddar-tracker calc SPY 450 455 460 5 CALL

# Record result
cheddar-tracker result SPY +75
```

---

## Future Improvements

1. **Auto-strike detection** - Parse strike from tweet images (OCR)
2. **Real-time P&L** - Track position value intraday
3. **Backtest refresh** - Weekly re-run with new data
4. **Alert correlation** - Compare with market events
5. **Win rate by signal** - SWEEP vs BLOCK vs WHALE analysis

---

## GitHub Repository
- **URL:** https://github.com/jeevanzeelogin-molt/clawd-skills
- **Key Files:**
  - `CHEDDAR_ALL_ALERTS.md` (128 alerts)
  - `CHEDDAR_BACKTEST_DETAILED.md` (full analysis)
  - `skills/cheddar-flow-alerts/` (monitoring system)
  - `logs/cheddar-*` (data files)

---

*Last Updated: January 31, 2026*  
*Maintained by: Cheddar Flow Alert System*
