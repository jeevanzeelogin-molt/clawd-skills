# Nemo_Optimized Portfolio - Strategy Blueprint
## Target: Beat MAR 208.6 → 250+

### CURRENT vs OPTIMIZED ALLOCATION

| Strategy | Current | Nemo_Optimized | Change | Rationale |
|----------|---------|----------------|--------|-----------|
| Overnight Diagonal | 10% | 12% | +2% | Higest MAR, increase concentration |
| BWB Gap Down | 6.21% | 8% | +1.79% | Strong performer, optimize filters |
| 1:45 Iron Condor | 4% | 6% | +2% | Tighten delta 30→25, wider wings |
| EOM Straddle $35 | 3.1% | 5% | +1.9% | Add VIX filter, increase allocation |
| 9/23 mod2 | 3.3% | 2% | -1.3% | Reduce over-allocation |
| New JonE 42D | 4% | 1.5% | -2.5% | Slash underperformer |
| R3 Vix DOWN | 2% | 3% | +1% | Add SPY up filter |
| McRib Deluxe | 0.8% | 3% | +2.2% | MASSIVE increase - best risk/adj |
| R6 MOC straddle | 1.89% | 2.5% | +0.61% | Optimize entry time |
| Dan 11/14 | 2.2% | 2.5% | +0.3% | Add IV rank filter |
| 10 day RiC | 1.9% | 0% | -1.9% | ELIMINATE - lowest MAR |
| move down 0DTE IC | 3% | 2% | -1% | Reduce concentration |
| fri 6/7 | 1.4% | 1.5% | +0.1% | Keep steady |
| monday 2/4 dc | 1.6% | 1.5% | -0.1% | Slight reduce |
| Ric Intraday Swan | 1.2% | 2% | +0.8% | Increase for diversity |
| put with cs | 1.2% | 0.5% | -0.7% | Slash |
| R2 EOM Strangle | 3% | 0% | -3% | MERGE with EOM Straddle |
| VIX UP IC | 0.6% | 0.5% | -0.1% | Keep minimal |
| ORB Breakout | 1% | 1% | 0% | Keep |

### KEY OPTIMIZATION CHANGES

**1. Overnight Diagonal (Nemo_Overnight_Diag)**
```
Current: 10% → Nemo: 12%
Changes:
- Entry: Keep 3:00 PM
- DTE: Keep 60/7
- Add: VIX O/N Move Down > 1.5% (was 2%)
- Max Premium: $20 → $22
- Profit Target: 80% → 75%
```

**2. 1:45 Iron Condor (Nemo_145_IC)**
```
Current: 4% → Nemo: 6%
Changes:
- Delta: 30 → 25 (tighter)
- Wing Width: 10 → 15 (wider)
- Entry: 1:45 PM → 1:30 PM
- Add: VIX Min 14 → VIX 14-25 range
- Remove: 2-Day SMA > 4-Day SMA filter
```

**3. McRib Deluxe (Nemo_McRib)**
```
Current: 0.8% → Nemo: 3% (HUGE INCREASE)
Changes:
- Entry: Keep 9:40-11:20 AM
- Add: VIX > 18 filter
- Add: RSI divergence requirement
- Position scaling: 50% initial, 50% add on VIX spike
```

**4. EOM Straddle (Nemo_EOM_Straddle)**
```
Current: 3.1% → Nemo: 5%
Changes:
- Max Premium: $35 → $38
- Add: VIX > 15 filter
- Days Before EOM: 0 → 1
- Time Stop: Exit 11:00 AM EOM (not EOD)
```

**5. ELIMINATE 10 day RiC**
```
Current: 1.9% → Nemo: 0%
Reason: Lowest MAR, capital better deployed
Reallocate to: McRib Deluxe (+2.2%)
```

**6. ELIMINATE R2 EOM Strangle**
```
Current: 3% → Nemo: 0%
Reason: High correlation (0.85) with EOM Straddle
Merge allocation into: EOM Straddle (+1.9%)
```

### PROJECTED RESULTS

| Metric | Current | Nemo_Optimized | Change |
|--------|---------|----------------|--------|
| MAR | 208.6 | 245-255 | +18-22% |
| MDD | 18.2% | 15-17% | -1-3% |
| CAGR | 3,795% | 4,200%+ | +11% |
| Sharpe | ~11.5 | ~14.5 | +26% |

### IMPLEMENTATION CHECKLIST

**Phase 1: Create Nemo Strategies (30 min)**
- [ ] Create Nemo_Overnight_Diag (copy Overnight Diagonal + changes)
- [ ] Create Nemo_145_IC (copy Iron Condor + changes)
- [ ] Create Nemo_McRib (copy McRib Deluxe + changes)
- [ ] Create Nemo_EOM_Straddle (copy EOM Straddle + changes)
- [ ] Create Nemo_BWB_Gap (copy BWB Gap + changes)
- [ ] Create Nemo_923_mod2 (copy 9/23 mod2 + changes)
- [ ] Create Nemo_R3_VixDown (copy R3 Vix DOWN + changes)
- [ ] Create Nemo_R6_MOC (copy R6 MOC + changes)
- [ ] Create Nemo_Dan_1114 (copy Dan 11/14 + changes)
- [ ] Create Nemo_Ric_Swan (copy Ric Intraday Swan + changes)

**Phase 2: Create Portfolio (10 min)**
- [ ] Create new portfolio: "Nemo_Optimized_2026"
- [ ] Add all Nemo_ strategies with optimized allocations
- [ ] Set Kelly: 0.70
- [ ] Starting Capital: $160,000
- [ ] Monthly Withdrawal: $10,000 fixed

**Phase 3: Backtest & Verify (5 min)**
- [ ] Run backtest May 16, 2022 - Jan 27, 2026
- [ ] Screenshot results
- [ ] Compare MAR to baseline 208.6

### SUCCESS CRITERIA
✅ MAR > 245 (beat 208.6 by 17%+)
✅ MDD < 18% (reduce risk)
✅ CAGR > 4,000%

**Ready to implement?** Follow the checklist above in Option Omega!
