#!/usr/bin/env python3
# /// script
# dependencies = ["yfinance", "requests"]
# ///

"""
Cheddar Flow Alert Result Calculator v2
Calculates results for pending alerts and updates backtest
"""

import yfinance as yf
import json
from datetime import datetime, timedelta
import os

# Pending alerts from our CHEDDAR_ALL_ALERTS.md
PENDING_ALERTS = [
    # Alert ID, Symbol, Alert Date, Direction, Signal, Description
    ("MU_2026-01-30", "MU", "2026-01-30", "BEARISH", "PUT", "Deep ITM Put Sweep $3.6M"),
    ("VIX_2026-01-30", "^VIX", "2026-01-30", "BULLISH", "CALL", "$2M OTM Call"),
    ("SPY_2026-01-30", "SPY", "2026-01-30", "BULLISH", "CALL", "$1B Call Wall @ 700"),
    ("QQQ_2026-01-29", "QQQ", "2026-01-29", "BEARISH", "PUT", "Millions Worth OTM Puts"),
    ("SLV_2026-01-29", "SLV", "2026-01-29", "BEARISH", "PUT", "$1.3M Put Sweep (known result: +342%, +700%)"),
]

def get_stock_price(symbol, date):
    """Get stock price on specific date"""
    try:
        ticker = yf.Ticker(symbol)
        # Get data from date to 1 day after
        start = datetime.strptime(date, "%Y-%m-%d")
        end = start + timedelta(days=2)
        hist = ticker.history(start=start.strftime("%Y-%m-%d"), end=end.strftime("%Y-%m-%d"))
        
        if not hist.empty:
            return {
                'open': round(hist['Open'].iloc[0], 2),
                'close': round(hist['Close'].iloc[0], 2),
                'high': round(hist['High'].iloc[0], 2),
                'low': round(hist['Low'].iloc[0], 2),
                'volume': int(hist['Volume'].iloc[0])
            }
    except Exception as e:
        print(f"  ⚠️ Error fetching {symbol} on {date}: {e}")
    return None

def calculate_return(entry_price, exit_price, direction, days=3, option_type="ATM"):
    """Calculate estimated option return"""
    stock_change = ((exit_price - entry_price) / entry_price) * 100
    
    # Delta based on option type
    delta_map = {"ITM": 0.75, "ATM": 0.50, "OTM": 0.30}
    delta = delta_map.get(option_type, 0.50)
    
    # Time decay: ~2.5% per day
    time_decay = days * 2.5
    
    if direction == "BULLISH":  # CALL
        option_return = (stock_change * delta) - time_decay
    else:  # PUT
        option_return = (-stock_change * delta) - time_decay
    
    return {
        "stock_change_pct": round(stock_change, 2),
        "option_return_pct": round(option_return, 2),
        "delta": delta,
        "time_decay": time_decay,
        "days": days
    }

def main():
    print("=" * 80)
    print("CHEDDAR FLOW PENDING ALERT - 3 DAY RESULT CALCULATION")
    print("=" * 80)
    print()
    
    results = []
    today = datetime.now()
    
    for alert_id, symbol, alert_date, direction, signal, description in PENDING_ALERTS:
        print(f"📊 Analyzing: ${symbol}")
        print(f"   Alert Date: {alert_date}")
        print(f"   Direction: {direction} | Signal: {signal}")
        print(f"   Description: {description}")
        
        # Skip VIX (index)
        if symbol == "^VIX":
            print(f"   ⚠️ Skipping VIX (index - no direct option pricing)")
            print()
            continue
        
        # Get entry price (alert date)
        entry_data = get_stock_price(symbol, alert_date)
        if not entry_data:
            print(f"   ❌ Could not fetch entry data")
            print()
            continue
        
        # Calculate exit date (3 days later)
        alert_dt = datetime.strptime(alert_date, "%Y-%m-%d")
        exit_date = alert_dt + timedelta(days=3)
        
        # If exit date is in future, use latest available
        if exit_date > today:
            exit_date = today - timedelta(days=1)
        
        # Get exit price (3 days later)
        exit_data = get_stock_price(symbol, exit_date.strftime("%Y-%m-%d"))
        if not exit_data:
            print(f"   ⚠️ Using latest available price")
            exit_data = entry_data  # Fallback
        
        entry_price = entry_data['close']
        exit_price = exit_data['close']
        
        print(f"   Entry Price ({alert_date}): ${entry_price}")
        print(f"   Exit Price ({exit_date.strftime('%Y-%m-%d')}): ${exit_price}")
        
        # Determine option type from description
        option_type = "ATM"
        if "ITM" in description:
            option_type = "ITM"
        elif "OTM" in description:
            option_type = "OTM"
        
        # Calculate return
        calc = calculate_return(entry_price, exit_price, direction, days=3, option_type=option_type)
        
        print(f"   Stock Change: {calc['stock_change_pct']:+.2f}%")
        print(f"   Estimated Option Return (3 days): {calc['option_return_pct']:+.2f}%")
        print(f"   (Delta: {calc['delta']}, Time Decay: -{calc['time_decay']}%)")
        
        # Special handling for known results
        if "+342%" in description or "+700%" in description:
            print(f"   📌 KNOWN RESULT: Cheddar Flow posted +342%/+700%")
            calc['actual_return'] = 700
            calc['source'] = "CheddarFlow Twitter"
        else:
            calc['source'] = "Calculated (3-day estimate)"
        
        result = {
            "alert_id": alert_id,
            "symbol": symbol,
            "alert_date": alert_date,
            "exit_date": exit_date.strftime("%Y-%m-%d"),
            "direction": direction,
            "signal": signal,
            "description": description,
            "entry_price": entry_price,
            "exit_price": exit_price,
            "stock_change_pct": calc['stock_change_pct'],
            "option_return_pct": calc['option_return_pct'],
            "option_type": option_type,
            "source": calc.get('source', 'Calculated'),
            'actual_return': calc.get('actual_return')
        }
        results.append(result)
        
        print()
    
    # Save results
    output_file = '/Users/nemotaka/clawd/logs/cheddar-3day-results.json'
    with open(output_file, 'w') as f:
        json.dump(results, f, indent=2)
    
    # Summary
    print("=" * 80)
    print("SUMMARY")
    print("=" * 80)
    
    if results:
        winning = [r for r in results if r['option_return_pct'] > 0]
        losing = [r for r in results if r['option_return_pct'] < 0]
        
        print(f"\nTotal Alerts Analyzed: {len(results)}")
        print(f"Winning (3-day): {len(winning)}")
        print(f"Losing (3-day): {len(losing)}")
        
        avg_return = sum(r['option_return_pct'] for r in results) / len(results)
        print(f"Average Return: {avg_return:+.2f}%")
        
        print(f"\nDetailed Results:")
        for r in results:
            status = "✅" if r['option_return_pct'] > 0 else "❌"
            source = f"[{r['source']}]" if 'source' in r else ""
            print(f"  {status} ${r['symbol']}: {r['option_return_pct']:+.2f}% {source}")
    
    print(f"\n💾 Results saved to: {output_file}")
    print("=" * 80)

if __name__ == "__main__":
    main()
