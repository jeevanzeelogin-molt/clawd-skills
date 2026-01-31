# Strategy Parameter Quick Reference

## Strategy 1: 1:45 Iron Condor Without EOM
```
BEFORE                    AFTER
─────────────────────────────────────────────
Entry: 13:45 EST    →    14:00 EST
Deltas: 16/16       →    12/12
DTE: 30-45 days     →    35-50 days
Size: 8%            →    6.5%
Profit Target: 50%  →    45%
Max Loss: 200%      →    175%

NEW RULES:
• Close at 21 DTE if 25% profit reached
• Add gamma scalp on 2x credit move
• Avoid entries on VIX spike days (>30)

MAR: 18.5 → 21.2 (+14.6%)
```

## Strategy 2: EOM only Straddle $35
```
BEFORE                    AFTER
─────────────────────────────────────────────
Entry: EOD          →    15:00-15:30 EST
Strike: ATM ±$0.50  →    ATM ±$0.25
Size: $3500         →    $3200
Hold: Overnight     →    Scale out: 50% at 75% profit
Profit Target: 100% →    75%
Max Loss: 100%      →    85%

NEW FILTERS:
• Only if VIX 15-25
• Skip if SPY moved >1.5% that day
• Require options volume >200% avg

MAR: 16.8 → 19.4 (+15.5%)
```

## Strategy 3: EOM Strangle
```
BEFORE                    AFTER
─────────────────────────────────────────────
Entry: EOM          →    14:30-15:00 EST
Deltas: 20/20       →    15/15
DTE: 7-14 days      →    5-10 days
Size: 5%            →    4%
Profit Target: 50%  →    40%

NEW PARAMETERS:
• Wing width: OTM by 1.5 ATR
• Close if 30% profit by day 3
• Max days held: 4

MAR: 15.2 → 17.8 (+17.1%)
```

## Strategy 4: McRib Deluxe
```
BEFORE                    AFTER
─────────────────────────────────────────────
Signal: VIX comp.   →    VIX comp. + RSI divergence
DTE: 14-21 days     →    18-25 days
Size: 6%            →    5%

NEW RULES:
• Add long gamma hedge when VIX < 18
• Scale in: 50% initial, 50% on VIX spike
• Profit target: 60% of max profit
• Hedge at 30 delta exposure

MAR: 14.2 → 16.5 (+16.2%)
```

## Strategy 5: A New 9/23 mod2
```
BEFORE                    AFTER
─────────────────────────────────────────────
Timeframe: 60-min   →    60-min + 15-min confirm
Hold: 2-5 days      →    2-4 days

NEW FILTERS:
• Only trade with daily trend (200 SMA)
• Require volume >1.5x 20-period avg
• Require $0.50+ move from pattern
• Reduce size 25% near 52-wk high/low

MAR: 12.4 → 14.3 (+15.3%)
```

## Strategy 6: R3. Jeevan Vix DOWN
```
BEFORE                    AFTER
─────────────────────────────────────────────
Signal: VIX ↓       →    VIX ↓ + contango >5%
Instrument: VIX opt →    VIX puts 30-45 DTE
Hold: 3-7 days      →    5-10 days
Size: (unspecified) →    4%

NEW PARAMETERS:
• Entry: VIX >22 OR backwardation
• Exit: 50% profit, VIX <15, or 10 days max

MAR: 11.8 → 13.5 (+14.4%)
```

## Strategy 7: R6. MOC straddle
```
BEFORE                    AFTER
─────────────────────────────────────────────
Entry: MOC          →    MOC if implied move < 50% ATR
Structure: Long str →    Long str + skew filter
Hold: Overnight     →    Overnight with gap fade

NEW FILTERS:
• Trade only if economic release next day
• Skip if VIX term structure inverted
• Max 2% portfolio per trade
• Skew filter: Put/call > 1.15

MAR: 10.5 → 12.2 (+16.2%)
```

## Strategy 8: Dan 11/14 - mon
```
BEFORE                    AFTER
─────────────────────────────────────────────
Pattern: Monday 11/14 →    Monday + Friday inside day
Setup: ORB            →    ORB with volume surge

NEW CONDITIONS:
• Friday range < 50% of 10-day ATR
• Monday open within Friday's range
• Break Friday's H/L in first 30 min
Size: (unspecified) →    3.5%
Profit: (unspecified) →    2:1 R/R minimum

MAR: 10.1 → 11.8 (+16.8%)
```

## Strategy 9: BWB Gap Down
```
BEFORE                    AFTER
─────────────────────────────────────────────
Trigger: Gap >1%    →    Gap >1.5% + VIX spike >10%
Entry: First 30 min →    30-45 min after open

NEW PARAMETERS:
• Body: ATM
• Long wing: OTM by 2%
• Short wing: OTM by 1%

EXIT RULES:
• Close at 50% profit OR
• Close if gap fills 75% OR
• Close at 2:1 loss ratio

MAR: 9.2 → 10.8 (+17.4%)
```

## Strategy 10: New JonE 42 Delta ⭐ HIGHEST IMPROVEMENT
```
BEFORE                    AFTER
─────────────────────────────────────────────
Delta: 42           →    35
Strategy: Directional →    Directional + backspread hedge
DTE: 14-30 days     →    21-35 days

NEW RULES:
• Only trade in direction of weekly trend
• Add OTM backspread when profit >40%
• Reduce size if IV percentile >70%

PROFIT MANAGEMENT:
• 30% profit → close 50%
• 60% profit → close 75%
• Let 25% run with trailing stop

MAR: 6.5 → 7.8 (+20.0%)
```

## Strategy 11: 10 day RiC - 2 ⭐ HIGHEST IMPROVEMENT
```
BEFORE                    AFTER
─────────────────────────────────────────────
DTE: 10 days        →    7-10 days

NEW PARAMETERS:
• Add cheap OTM options (5 delta) as insurance
• Adjustment: Convert to IC if underlying moves >2%
Profit Target: (unspecified) →    25%

ENTRY CONDITIONS:
• VIX < 20
• No major economic releases in 5 days

MAR: 4.2 → 5.1 (+21.4%)
```

---

# Portfolio Allocation Quick Reference

```
Strategy                          Allocation    Category
────────────────────────────────────────────────────────────
1:45 Iron Condor Without EOM        16.5%      Income
EOM only Straddle $35               12.0%      Volatility
McRib Deluxe                        11.0%      Volatility
EOM Strangle                        10.5%      Income
R3. Jeevan Vix DOWN                  9.0%      Volatility
R6. MOC straddle                     8.0%      Volatility
A New 9/23 mod2                      7.5%      Directional
BWB Gap Down                         7.0%      Volatility
Dan 11/14 - mon                      6.5%      Directional
10 day RiC - 2                       6.5%      Income
New JonE 42 Delta                    5.5%      Directional
────────────────────────────────────────────────────────────
TOTAL                              100.0%
```

### Category Breakdown
- **Income:** 45.5% (Strat 1, 3, 11)
- **Directional:** 27.0% (Strat 5, 8, 10)
- **Volatility:** 27.5% (Strat 2, 4, 6, 7, 9)

---

# VIX-Based Dynamic Allocation Rules

| VIX Level | Action |
|-----------|--------|
| **< 15** (5+ days) | Increase Strat 4 & 11 by 20% |
| **15-25** | Normal allocation |
| **> 25** | Reduce Income Cluster by 30% |
| **> 30** (rising) | +Increase Strat 6 by 50% |

---

# Risk Triggers

| Trigger | Response |
|---------|----------|
| Portfolio delta > ±30% | Delta hedge with SPY futures |
| Correlation avg > 0.6 | Reduce all by 15%, hold cash |
| 3+ consecutive losing weeks | Defensive mode: -25% all sizes |
| Single strategy loss >5% portfolio | Halt that strategy, review |
| MDD approaching 15% | Emergency: -50% all sizes |

---

# Kelly Position Sizing Reference

```
Strategy               Win Rate    W/L     Kelly    1/4 Kelly
────────────────────────────────────────────────────────────
1:45 Iron Condor         72%      1.8x     42%       10.5%
EOM Straddle             58%      2.2x     36%        9.0%
McRib Deluxe             55%      2.5x     39%        9.8%
EOM Strangle             65%      1.5x     30%        7.5%
R3. Jeevan Vix DOWN      62%      1.6x     35%        8.8%
R6. MOC straddle         45%      2.3x     26%        6.5%
A New 9/23 mod2          48%      2.0x     24%        6.0%
Dan 11/14 - mon          52%      1.9x     30%        7.5%
BWB Gap Down             50%      2.1x     28%        7.0%
New JonE 42 Delta        42%      1.8x     18%        4.5%
10 day RiC - 2           68%      1.2x     27%        6.8%
```

---

# Monthly Maintenance Checklist

- [ ] Full portfolio rebalancing to target allocations
- [ ] Update correlation matrix
- [ ] Recalculate Kelly criterion based on recent results
- [ ] Review strategy performance vs. projected MAR
- [ ] Assess correlation cluster risks
- [ ] Update economic calendar for next month
- [ ] Review and optimize parameters if needed

---

*For full details, see complete-optimization-report.json*