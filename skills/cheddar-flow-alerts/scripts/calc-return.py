#!/usr/bin/env python3
"""
Option Return Calculator for Cheddar Flow Tracker
"""

import sys

def calculate_option_return(symbol, entry, strike, current, days, option_type):
    """Calculate estimated option return"""
    
    entry = float(entry)
    strike = float(strike)
    current = float(current)
    days = int(days)
    
    # Stock movement
    stock_change = ((current - entry) / entry) * 100
    
    # Determine if ITM/OTM/ATM and delta
    if option_type == "CALL":
        moneyness = ((strike - entry) / entry) * 100
        if moneyness < -2:
            delta = 0.75  # ITM
            status = "ITM"
        elif moneyness > 2:
            delta = 0.30  # OTM
            status = "OTM"
        else:
            delta = 0.50  # ATM
            status = "ATM"
        
        # Option return
        option_return = (stock_change * delta) - (days * 2.5)
    else:  # PUT
        moneyness = ((strike - entry) / entry) * 100
        if moneyness > 2:
            delta = 0.75  # ITM
            status = "ITM"
        elif moneyness < -2:
            delta = 0.30  # OTM
            status = "OTM"
        else:
            delta = 0.50  # ATM
            status = "ATM"
        
        # Option return (inverse for puts)
        option_return = (-stock_change * delta) - (days * 2.5)
    
    print(f"📊 Option Return Calculation for ${symbol}")
    print(f"  Entry: ${entry:.2f} → Current: ${current:.2f}")
    print(f"  Stock Change: {stock_change:+.2f}%")
    print(f"  Strike: ${strike:.2f} ({status})")
    print(f"  Option Type: {option_type}")
    print(f"  Days Held: {days}")
    print(f"  Delta Used: {delta}")
    print(f"  Time Decay: -{days * 2.5:.1f}%")
    print(f"  Estimated Option Return: {option_return:+.2f}%")

if __name__ == "__main__":
    if len(sys.argv) < 5:
        print("Usage: calc-return.py <symbol> <entry> <strike> <current> [days] [CALL|PUT]")
        sys.exit(1)
    
    symbol = sys.argv[1]
    entry = sys.argv[2]
    strike = sys.argv[3]
    current = sys.argv[4]
    days = sys.argv[5] if len(sys.argv) > 5 else "5"
    option_type = sys.argv[6] if len(sys.argv) > 6 else "CALL"
    
    calculate_option_return(symbol, entry, strike, current, days, option_type)
