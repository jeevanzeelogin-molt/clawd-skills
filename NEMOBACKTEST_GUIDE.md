# NemoBacktest Pro — Integration Guide

## 🎯 What Was Built

### 1. **NemoBacktest Pro Skill** (`/Users/nemotaka/clawd/skills/nemobacktest-pro/`)
Advanced risk analytics toolkit for options trading:

#### Scripts:
- **`monte-carlo.py`** — Run 10,000+ simulations over 10-year periods
- **`tail-risk.py`** — Calculate VaR, CVaR, skewness, kurtosis, stress tests
- **`optimize-portfolio.py`** — Find optimal allocations (max MAR, MDD < 18%)
- **`nemobacktest.sh`** — Master control script

### 2. **Option Omega Log Downloader** (`/Users/nemotaka/Nemoblock/scripts/download-oo-logs.ts`)
Read-only script to safely download trade logs from Option Omega.

---

## 🚀 Quick Start

### Step 1: Download Option Omega Logs
```bash
cd /Users/nemotaka/Nemoblock

# Download logs (headless mode)
npx tsx scripts/download-oo-logs.ts --profile kelly-090

# Or with visible browser (for debugging)
npx tsx scripts/download-oo-logs.ts --visible
```

Files will be saved to: `~/Nemoblock/oo_analysis_logs/`

### Step 2: Run Tail Risk Analysis
```bash
cd /Users/nemotaka/clawd
python3 skills/nemobacktest-pro/scripts/tail-risk.py \
  -i ~/Nemoblock/oo_analysis_logs/trade_log.csv \
  -c 0.95 \
  --stress-test
```

### Step 3: Run Monte Carlo Simulation
```bash
python3 skills/nemobacktest-pro/scripts/monte-carlo.py \
  -i ~/Nemoblock/oo_analysis_logs/trade_log.csv \
  -n 10000 \
  -y 10 \
  -c 100000
```

### Step 4: Optimize Portfolio
```bash
python3 skills/nemobacktest-pro/scripts/optimize-portfolio.py \
  -i skills/nemobacktest-pro/sample_strategies.json \
  -m 2.0 \
  -d 0.18
```

---

## 📊 Sample Output

### Tail Risk Report
```
⚠️  TAIL RISK ANALYSIS REPORT (95% Confidence)
─────────────────────────────────────────────────
VaR (95%):           -12.5%
CVaR (95%):          -18.3%
Max Drawdown:        -15.2%
Skewness:            -0.85 (Left tail)
Kurtosis:            4.2 (Fat tails)
Sharpe Ratio:        1.45
Sortino Ratio:       2.1
```

### Monte Carlo Results
```
🎲 MONTE CARLO SIMULATION (10,000 sims, 10 years)
─────────────────────────────────────────────────
Median CAGR:         42%
5th Percentile:      18% (Worst case)
95th Percentile:     68% (Best case)
Probability MDD<18%: 85%
Risk of Ruin:        2%
```

### Portfolio Optimization
```
🎯 OPTIMAL ALLOCATION
─────────────────────────────────────────────────
SPX_Iron_Condor       23.6% ███████████
SPX_Butterflies       44.2% ██████████████████████
SPX_Credit_Spreads    13.7% ██████
VIX_Calendar          10.1% █████
Earnings_Straddles     8.4% ████

Portfolio MAR:       7.14
Portfolio MDD:       5.8%
```

---

## 🔧 What You Have Access To

### On Your Mac:
1. **Full user access** (nemotaka, admin group)
2. **Nemoblock project** at `~/Nemoblock/`:
   - Next.js 15 analytics workspace
   - Option Omega integration scripts
   - Portfolio sync automation
   - Live dashboard

3. **Option Omega Credentials** (in `.env.local`):
   - Email: jeevansaiias@gmail.com
   - Multiple portfolio IDs (2023-2026)

4. **Clawdbot workspace** at `~/clawd/`:
   - Cheddar Flow alerts (running every 5 min)
   - NemoBacktest Pro (new)
   - Skills directory

---

## 🛡️ Safety Rules (As Requested)

✅ **ALLOWED:**
- Read/download Option Omega logs
- Analyze trade data
- Run simulations
- Generate reports
- Create new skills

❌ **NEVER:**
- Delete trades in Option Omega
- Modify Option Omega data
- Close positions via API (unless explicitly enabled)
- Delete any files in Nemoblock without confirmation

---

## 📈 Next Steps

### Immediate:
1. Download Option Omega logs using the new script
2. Run tail risk analysis on your actual trade data
3. Run Monte Carlo simulation with 10,000 iterations

### Short-term:
1. Create strategy JSON from your Option Omega data
2. Run portfolio optimization
3. Build automated daily risk reports

### Long-term:
1. Integrate with Cheddar Flow alerts for real-time risk monitoring
2. Build custom dashboard combining all data sources
3. Develop ML-based trade filtering based on risk metrics

---

## 🆘 Troubleshooting

### Option Omega Login Issues:
```bash
# Refresh session (run visible mode once)
npx tsx scripts/download-oo-logs.ts --visible
# Log in manually, then close
```

### Missing Python Packages:
```bash
python3 -m pip install pandas numpy scipy matplotlib --break-system-packages
```

### Permission Errors:
All scripts are read-only and safe to run. They only download/analyze data.

---

## 📁 File Locations

| Component | Path |
|-----------|------|
| NemoBacktest Pro | `~/clawd/skills/nemobacktest-pro/` |
| Nemoblock Project | `~/Nemoblock/` |
| Option Omega Logs | `~/Nemoblock/oo_analysis_logs/` |
| Cheddar Flow Skill | `~/clawd/skills/cheddar-flow-alerts/` |
| Analysis Output | `~/Nemoblock/analysis/` |

---

*Built for Nemoblock | Read-Only Safe | No Data Modification*
