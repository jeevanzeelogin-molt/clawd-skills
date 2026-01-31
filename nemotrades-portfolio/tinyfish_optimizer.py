#!/usr/bin/env python3
"""
TinyFish Agent - Option Omega Portfolio Optimizer
Creates Nemo_Optimized_2026 portfolio with optimized allocations
"""

import os
import sys
from dotenv import load_dotenv

# Load API key
load_dotenv('/Users/nemotaka/.clawdbot/.env')
TINYFISH_API_KEY = os.getenv('TINYFISH_API_KEY')

if not TINYFISH_API_KEY:
    print("❌ TINYFISH_API_KEY not found in environment")
    sys.exit(1)

# Optimized allocation strategy
ALLOCATIONS = {
    'McRib Deluxe': 3.0,                      # MASSIVE INCREASE from 0.8%
    'Overnight Diagonal': 12.0,               # INCREASE from 10%
    'EOM Straddle $35 limit': 5.0,            # INCREASE from 3.1%
    '1:45 Iron Condor Without EOM': 6.0,      # INCREASE from 4%
    'BWB Gap Down - Max 3 Open': 6.0,         # Slight reduce from 6.21%
    'A New 9/23 mod2': 2.5,                   # Reduced from 3.3%
    'Dan 11/14 - mon': 2.0,                   # Slight reduce from 2.2%
    'R3. Jeevan Vix DOWN Straddle': 3.0,      # INCREASE from 2%
    'Ric Intraday swan net': 2.0,             # INCREASE from 1.2%
    'R6. MOC straddle/EOD last 12 min': 2.0,  # Slight increase from 1.89%
    'ORB Breakout BF 30/30/30': 1.0,          # Keep same
    'fri 6/7': 1.5,                           # Slight increase from 1.4%
    'monday 2/4 dc': 1.0,                     # Reduce from 1.6%
    'move down 0 dte ic - less risk': 2.0,    # Reduce from 3%
    'New JonE 42 Delta - 1 con': 1.5,         # SLASH from 4%
    'VIX UP 9:35 Iron Condor': 0.5,           # Slight reduce from 0.6%
    'put with cs': 0.5,                       # Reduce from 1.2%
    '10 day RiC - 2': 0.0,                    # ELIMINATE
    'R2. EOM 3:45pm Strangle 2.0': 0.0        # ELIMINATE
}

TINYFISH_SCRIPT = """
Goal: Create optimized portfolio "Nemo_Optimized_2026" on Option Omega

Steps:
1. Navigate to https://optionomega.com/portfolio/rZrUg05YbafekL0CYxAs
2. Click "New Portfolio" button
3. Set Starting Funds to $160,000
4. Set Start Date to 05/16/2022
5. Set End Date to 01/29/2026
6. For each strategy in the list:
   - If strategy name matches and allocation > 0: check the box and set allocation
   - If allocation = 0: skip/uncheck
7. Click "Run" button
8. Wait for backtest to complete (60-120 seconds)
9. Extract results: MAR, MDD, CAGR, P/L
10. If MAR > 209.4: save as "Nemo_Optimized_2026"

Strategies to select with allocations:
"""

# Build the strategy list for the prompt
strategy_list = "\n".join([
    f"  - {name}: {alloc}%" for name, alloc in ALLOCATIONS.items() if alloc > 0
])
strategy_list += "\n\nStrategies to ELIMINATE (0%):\n"
strategy_list += "\n".join([
    f"  - {name}" for name, alloc in ALLOCATIONS.items() if alloc == 0
])

FULL_PROMPT = TINYFISH_SCRIPT + strategy_list

print("🚀 Option Omega Portfolio Optimizer")
print("===================================")
print("Target: MAR 245-255 (up from 209.4)")
print("MDD: ≤ 18.1%")
print("")
print("Optimized Allocations:")
print(strategy_list)
print("")
print("TinyFish Prompt Ready!")
print("")
print("To execute, run:")
print("  tinyfish run --prompt-file portfolio_prompt.txt")
print("")

# Save the prompt to a file
with open('/Users/nemotaka/clawd/nemotrades-portfolio/tinyfish_prompt.txt', 'w') as f:
    f.write(FULL_PROMPT)

print("✅ Prompt saved to: tinyfish_prompt.txt")
