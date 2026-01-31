#!/usr/bin/env python3
# /// script
# dependencies = ["yfinance", "pandas", "numpy"]
# ///

"""
Cheddar Flow Alert Result Calculator
Estimates returns for pending alerts using Yahoo Finance data
"""

import yfinance as yf
import pandas as pd
import json
from datetime import datetime, timedelta
import time

# Pending alerts from our analysis
PENDING_ALERTS = [
    {"symbol": "MU", "date": "2026-01-30", "direction": "BEARISH", "signal": "PUT", "premium": "$3.6M", "description": "Deep ITM Put Sweep"},
    {"symbol": "VIX", "date": "2026-01-30", "direction": "BULLISH", "signal": "CALL", "premium": "$2M", "description": "OTM Call"},
    {"symbol": "SPY", "date": "2026-01-30", "direction": "BULLISH", "signal": "CALL", "premium": "$1B", "description": "Call Wall @ 700"},
    {"symbol": "QQQ", "date": "2026-01-29", "direction": "BEARISH", "signal": "PUT", "premium": "Millions", "description": "OTM Puts"},
    {"symbol": "SLV", "date": "2026-01-29", "direction": "BEARISH", "signal": "PUT", "premium": "$1.3M", "description": "Put Sweep (resulted in +342%, +700%)"},
]

def get_stock_data(symbol, start_date, end_date):
    """Fetch historical stock data"""
    try:
        ticker = yf.Ticker(symbol)
        hist = ticker.history(start=start_date, end=end_date)
        return hist
    except Exception as e:
        print(f"❌ Error fetching {symbol}: {e}")
        return None

def calculate_option_return(entry_price, exit_price, direction, days_held=5, option_type="ATM"):
    """
    Estimate option return based on stock price movement
    
    Rough estimates:
    - ATM options: ~50 delta, so option moves ~50% of stock move
    - ITM options: ~70 delta
    - OTM options: ~30 delta
    - Time decay: ~2-5% per day
    """
    stock_change_pct = ((exit_price - entry_price) / entry_price) * 100
    
    # Delta estimate based on option type
    delta_map = {"ITM": 0.7, "ATM": 0.5, "OTM": 0.3}
    delta = delta_map.get(option_type, 0.5)
    
    # Time decay (theta) - roughly 3% per day
    time_decay = days_held * 3
    
    # Calculate option return
    if direction == "BULLISH":  # Calls
        option_return = (stock_change_pct * delta) - time_decay
    else:  # Puts
        option_return = (-stock_change_pct * delta) - time_decay
    
    return {
        "stock_change_pct": round(stock_change_pct, 2),
        "option_return_pct": round(option_return, 2),
        "delta_used": delta,
        "time_decay_pct": time_decay
    }

def main():
    print("=" * 70)
    print("CHEDDAR FLOW ALERT RESULT CALCULATOR")
    print("Estimating returns for pending alerts using Yahoo Finance")
    print("=" * 70)
    print()
    
    results = []
    
    for alert in PENDING_ALERTS:
        symbol = alert["symbol"]
        alert_date = alert["date"]
        direction = alert["direction"]
        
        print(f"📊 Analyzing: {symbol}")
        print(f"   Alert Date: {alert_date}")
        print(f"   Direction: {direction}")
        print(f"   Signal: {alert['signal']} | {alert['description']}")
        
        # Calculate dates for historical data
        start = datetime.strptime(alert_date, "%Y-%m-%d")
        end = start + timedelta(days=7)  # Check 1 week after alert
        
        # Fetch data
        hist = get_stock_data(symbol, start.strftime("%Y-%m-%d"), end.strftime("%Y-%m-%d"))
        
        if hist is None or hist.empty:
            print(f"   ⚠️ No data available")
            print()
            continue
        
        # Get entry price (alert date)
        try:
            entry_price = hist.iloc[0]['Close']
            exit_price = hist.iloc[-1]['Close']  # 1 week later
            
            print(f"   Entry Price: ${entry_price:.2f}")
            print(f"   Exit Price (1W later): ${exit_price:.2f}")
            
            # Determine option type based on signal
            option_type = "ATM"
            if "ITM" in alert['description']:
                option_type = "ITM"
            elif "OTM" in alert['description']:
                option_type = "OTM"
            
            # Calculate return
            calc = calculate_option_return(entry_price, exit_price, direction, days_held=5, option_type=option_type)
            
            print(f"   Stock Change: {calc['stock_change_pct']:+.2f}%")
            print(f"   Estimated Option Return: {calc['option_return_pct']:+.2f}%")
            print(f"   (Delta: {calc['delta_used']}, Time Decay: {calc['time_decay_pct']}%)")
            
            result = {
                "symbol": symbol,
                "alert_date": alert_date,
                "direction": direction,
                "signal": alert['signal'],
                "premium": alert['premium'],
                "description": alert['description'],
                "entry_price": round(entry_price, 2),
                "exit_price": round(exit_price, 2),
                "stock_change_pct": calc['stock_change_pct'],
                "option_return_pct": calc['option_return_pct'],
                "option_type": option_type
            }
            results.append(result)
            
        except Exception as e:
            print(f"   ⚠️ Error calculating: {e}")
        
        print()
        time.sleep(1)  # Rate limiting
    
    # Summary
    print("=" * 70)
    print("SUMMARY")
    print("=" * 70)
    
    if results:
        winning_trades = [r for r in results if r['option_return_pct'] > 0]
        losing_trades = [r for r in results if r['option_return_pct'] < 0]
        
        total_return = sum(r['option_return_pct'] for r in results)
        avg_return = total_return / len(results)
        
        print(f"\nTotal Alerts Analyzed: {len(results)}")
        print(f"Winning Trades: {len(winning_trades)}")
        print(f"Losing Trades: {len(losing_trades)}")
        print(f"Win Rate: {len(winning_trades)/len(results)*100:.1f}%")
        print(f"Average Return: {avg_return:+.2f}%")
        print(f"Total Return: {total_return:+.2f}%")
        
        print(f"\nDetailed Results:")
        for r in results:
            status = "✅" if r['option_return_pct'] > 0 else "❌"
            print(f"  {status} ${r['symbol']}: {r['option_return_pct']:+.2f}% (${r['entry_price']:.2f} → ${r['exit_price']:.2f})")
        
        # Save results
        with open('/Users/nemotaka/clawd/logs/cheddar-calculated-results.json', 'w') as f:
            json.dump(results, f, indent=2)
        print(f"\n💾 Results saved to: ~/clawd/logs/cheddar-calculated-results.json")
    
    print("\n" + "=" * 70)
    print("NOTE: These are ESTIMATED returns based on stock price movement")
    print("Actual option returns may vary due to:")
    print("  - Exact strike price and expiration")
    print("  - Implied volatility changes")
    print("  - Time decay (theta)")
    print("  - Bid-ask spreads")
    print("=" * 70)

if __name__ == "__main__":
    main()
