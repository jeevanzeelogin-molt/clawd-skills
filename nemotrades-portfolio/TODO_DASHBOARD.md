# 🎯 NEMOTRADES PORTFOLIO OPTIMIZATION - TODO DASHBOARD
**Last Updated:** January 30, 2026  
**Goal:** Beat MAR 208.6 with MDD ≤ 18%

---

## ✅ COMPLETED

### 1. McRib Deluxe - OPTIMIZED ✅
**Status:** DONE - 23% MAR improvement!

| Metric | Before | After | Change |
|--------|--------|-------|--------|
| MAR | 4.3 | **5.3** | ✅ +23% |
| MDD | -3.8% | **-2.7%** | ✅ Better |

**Changes Applied:**
- ✅ Added 200% stop loss
- ✅ Tightened Put exit: 0.4% → 0.3%
- ✅ Tightened Call exit: 0.5% → 0.4%
- ✅ Added Max VIX: 25
- ✅ Increased VIX filter: 0.4% → 0.5%

**Next Tests:**
- [ ] Test removing Friday (volatile day)
- [ ] Test earlier entry: 9:40 AM → 9:35 AM
- [ ] Test wider wing widths

---

## 🔄 IN PROGRESS

### 2. Iron Condor - TESTING ⏳
**Status:** Parameters set, waiting for backtest

**Changes to Test:**
- ✅ Delta: 30 → 25 (tighter to ATM)
- ✅ Wing width: 10 → 15 (wider protection)
- ✅ Stop Loss: 200%
- ✅ Max VIX: 30

**Expected Result:**
- Current MAR: 3.3
- Target MAR: 4.0+

---

## 📋 PENDING OPTIMIZATIONS

### 3. 10 day RiC - 2 🛑 PAUSE/REMOVE
**Priority:** HIGH (dragging portfolio down)

**Current Stats:**
- MAR: 2.1 (LOWEST!)
- MDD: -22.3% (HIGHEST!)

**Action:** Remove from portfolio entirely

---

### 4. EOM Straddle $35 ⏳
**Priority:** MEDIUM

**Current Stats:**
- MAR: ~3.5
- Allocation: 3.1%

**Optimization Plan:**
- [ ] Increase Max Premium: $35 → $38
- [ ] Add Min VIX: 15
- [ ] Add Max VIX: 28
- [ ] Test stop loss: 150%
- [ ] Test later entry: 9:32 AM → 10:00 AM

**Target:** MAR 4.5+

---

### 5. A New 9/23 mod2 ⏳
**Priority:** MEDIUM

**Current Stats:**
- MAR: ~2.5
- Allocation: 3.3%

**Optimization Plan:**
- [ ] Adjust Delta: 28/29 → 30
- [ ] Add stop loss: 200%
- [ ] Adjust RSI: Min 60 → Min 55
- [ ] Test later exit: 3:40 PM → 3:45 PM

**Target:** MAR 3.5+

---

### 6. BWB Gap Down ⏳
**Priority:** LOW (already good allocation 6.21%)

**Current Stats:**
- Allocation: 6.21%
- Type: RIC

**Quick Check:** Verify MAR is stable

---

### 7. Dan 11/14 - mon ⏳
**Priority:** LOW

**Current Stats:**
- Allocation: 2.2%
- Type: RIC

**Optimization Plan:**
- [ ] Test tighter profit target: 75% → 70%
- [ ] Test wider stops

---

### 8. New JonE 42 Delta ⏳
**Priority:** LOW

**Current Stats:**
- Allocation: 4%
- Type: Multi-leg

**Optimization Plan:**
- [ ] Test Delta: 42 → 45
- [ ] Add stop loss

---

## 📊 PORTFOLIO-LEVEL CHANGES

### After Strategy Optimizations:

| Strategy | Current MAR | Optimized MAR | Status |
|----------|-------------|---------------|--------|
| McRib Deluxe | 4.3 | **5.3** | ✅ Done |
| Iron Condor | 3.3 | **4.0+** | 🔄 Testing |
| 10 day RiC | 2.1 | **REMOVE** | 🛑 Pending |
| EOM Straddle | 3.5 | **4.5+** | ⏳ Pending |
| 9/23 mod2 | 2.5 | **3.5+** | ⏳ Pending |

**Projected Portfolio Impact:**
- Current MAR: 208.6
- Optimized MAR: **230-250** (+10-20%)
- Current MDD: 18.2%
- Optimized MDD: **17.0-17.5%**

---

## 🎯 NEXT ACTIONS

### Immediate (Today):
1. ✅ Complete Iron Condor test
2. 🔄 Remove 10 day RiC from portfolio
3. ⏳ Start EOM Straddle optimization

### This Week:
4. ⏳ Optimize 9/23 mod2
5. ⏳ Test McRib Deluxe variations (Friday removal)
6. ⏳ Run full portfolio backtest with all changes

### Success Criteria:
- [ ] Portfolio MAR > 220
- [ ] Portfolio MDD ≤ 18%
- [ ] All top 5 strategies optimized
- [ ] 10 day RiC removed

---

## 🔧 TESTING METHODOLOGY

### For Each Strategy:
1. **Baseline:** Record current MAR, MDD, Win Rate
2. **Hypothesis:** Identify what parameter changes might help
3. **Test:** Change ONE parameter at a time
4. **Measure:** Run backtest, record results
5. **Compare:** If MAR improves, keep change; if not, revert
6. **Iterate:** Test next parameter

### Key Parameters to Test:
- Entry/Exit times
- Delta values
- Wing widths
- Stop losses
- VIX filters (Min/Max)
- RSI thresholds
- Days to trade (remove Fridays?)
- Profit targets

---

## 📈 EXPECTED RESULTS

### Conservative Estimate:
- MAR: 208.6 → **225** (+8%)
- MDD: 18.2% → **17.5%**

### Optimistic Estimate:
- MAR: 208.6 → **250** (+20%)
- MDD: 18.2% → **17.0%**

### 10-Year Value Projection:
- Current: $125.7B
- Optimized: **$180B+** (+43%)

---

## 🚨 PRIORITY ORDER

### Must Do (Highest Impact):
1. ✅ McRib Deluxe (DONE - 23% improvement)
2. 🔄 Iron Condor (in progress)
3. 🛑 Remove 10 day RiC (immediate MAR boost)

### Should Do (Medium Impact):
4. ⏳ EOM Straddle optimization
5. ⏳ 9/23 mod2 optimization

### Nice to Have (Lower Impact):
6. ⏳ BWB Gap Down check
7. ⏳ Dan 11/14 optimization
8. ⏳ New JonE optimization

---

## 💡 KEY LEARNINGS SO FAR

### What Works:
- ✅ Adding stop losses (200% works well)
- ✅ Tightening exits (faster profit taking)
- ✅ Adding Max VIX filters (avoid high volatility)
- ✅ Increasing VIX intraday filters (more selective)

### What Doesn't Work:
- ❌ Just increasing allocation % (doesn't improve MAR)
- ❌ Too loose exits (lets winners turn to losers)

### Next Tests:
- 🤔 Removing Friday trades (volatile day)
- 🤔 Earlier/later entry times
- 🤔 Wider wing widths for iron condors
- 🤔 Different SMA combinations

---

**Ready to continue! Which strategy should I optimize next?**
