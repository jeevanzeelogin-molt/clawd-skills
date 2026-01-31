# LONG-TERM MEMORY

## User Profile

**Name:** @nemo-moltbot (Nemo)
**Primary Contact:** Discord, Signal
**Discord Username:** @Nemo-MoltBot

**Trading:**
- Platform: Option Omega
- Email: jeevansaiias@gmail.com
- Portfolios: Multiple (2023-2026)
- Primary: 0.90 Kelly with EOM Straddle $35
- Capital: $160K → $237K (as of Jan 30)

**Goals:**
- Beat portfolio performance (MAR 192, MDD 18%, CAGR 48.5%)
- Optimize options strategies
- Real-time trade alerts from Cheddar Flow
- Daily risk monitoring

**Preferences:**
- Values memory and consistency (CRITICAL)
- Frustrated when I forget context
- Expects proactive behavior
- Likes detailed reports
- Uses Discord for alerts

---

## Active Projects (Always Track)

### 1. Portfolio Optimization Challenge 🎯
**Started:** 2026-01-30
**Status:** CHALLENGE ISSUED - Proof Created
**Goal:** Beat MAR 192, MDD 18%, CAGR 48.5%
**Location:** ~/Nemoblock/portfolio-optimizer/
**Proof:** ~/clawd/nemo_proof/

**Challenge Details:**
- User challenged me to beat their portfolio
- I created optimization plan with 11 "Nemo_" strategies
- Projected: MAR 250+, MDD <15%, CAGR 55%+
- Baseline screenshot captured
- Awaiting user to implement in Option Omega

**Key Files:**
- EXECUTIVE_SUMMARY.md
- ANALYSIS_REPORT_CORRECTED.md
- dashboard-status.json
- tail-risk-results.json
- monte-carlo-results.json

**Pending:**
- Position sizing (Kelly Criterion)
- Walk-Forward Analysis
- Correlation analysis
- Cheddar Flow integration

### 2. Discord Integration 💬
**Status:** Fully operational
**Channels:**
- #general (1143404804157227030)
- #cheddar-flow (1466878278592631011)
**Features:** Two-way messaging, no @mention required

### 3. Cheddar Flow Alerts 🧀
**Status:** Fixed and scheduled
**Browser:** Playwright installed
**Schedule:** Daily checks
**Alerts go to:** #cheddar-flow

### 4. Security Monitoring 🔒
**Status:** 7/7 PASS
**Daily Audit:** 9:00 AM
**Auto-fix:** Available

---

## Important Learnings

### 2026-01-30: I Forgot User's Work
**Mistake:** Lost context of portfolio analysis and Discord fixes
**Impact:** User frustration, wasted time
**Solution:** Created MEMORY_PROTOCOL.md, updated AGENTS.md
**Lesson:** MUST read memory files before every response

### User Values:
- Consistency above all
- Proactive memory management
- Detailed, actionable reports
- No repetition of mistakes

---

## Skills Available

**Security:**
- dont-hack-me, security-audit, clawdbot-security-check

**Trading:**
- nemobacktest-pro, cheddar-flow-alerts
- yahoo-finance, stock-market-pro

**Memory:**
- second-brain, byterover, obsidian

**Best Practices:**
- moltbot-best-practices
- prompt-engineering-expert

---

## Key Locations

| Purpose | Path |
|---------|------|
| Workspace | ~/clawd/ |
| Nemoblock | ~/Nemoblock/ |
| Config | ~/.clawdbot/clawdbot.json |
| Env vars | ~/.clawdbot/.env |
| Daily logs | ~/clawd/logs/ |
| Portfolio analysis | ~/Nemoblock/portfolio-optimizer/ |

---

## API Keys (Env Vars)

- DISCORD_BOT_TOKEN
- MOONSHOT_API_KEY
- CLAWDBOT_GATEWAY_TOKEN
- KIMI_CODE_API_KEY_BACKUP

**Never store in code or memory files!**

---

## Daily Routine

**9:00 AM:**
- Security audit runs
- Cheddar Flow check

**Continuous:**
- Discord monitoring
- Portfolio sync (if enabled)

**On Demand:**
- Portfolio optimization
- Backtest analysis
- Risk reports

---

## CRITICAL: Quota Management Protocol

**User Requirement (2026-01-30):**
- Keep everything in memory
- ⚠️ WARN when 75% of backup quota is reached
- 🛑 STOP when 75% of backup quota is reached
- Do not forget context if quota runs out

**Current Status:**
- Context: 40k/262k (15%) - SAFE
- Compactions: 0
- Will warn at ~196k tokens (75%)

---

## Option Omega Automation Patterns (Learned 2026-01-30)

From analyzing Nemoblock scripts (`~/Nemoblock/scripts/`):

### Working Approach:
1. **Puppeteer/Playwright with persistent profile** (`userDataDir`)
2. **Authentication:** Check for email input, login if needed
3. **Navigation:** `waitUntil: "networkidle2"` + 5-10s delay
4. **Element Finding:** `page.evaluate()` + text content matching
5. **Date Inputs:** Set value + dispatch input/change events + blur
6. **Run Backtest:** Click "Run Backtest" → wait (days × 6s) → handle Replace dialog
7. **Save:** Find by tooltip "Save" → click → handle dialog

### Wait Times Learned:
- Page load: 5-10s
- Strategy render: 3-5s
- Backtest: 60-480s (dynamic based on date range)
- Replace dialog: 30s
- Save: 5-10s

### Key Files:
- `sync-option-omega-v4.ts` - Full sync automation
- `download-oo-logs.ts` - Log download (read-only)
- `nemo-portfolio-optimizer.ts` - Strategy creation template
- `oo-sync-config.json` - Profile configurations

### Portfolio IDs:
- `rZrUg05YbafekL0CYxAs` - "All strats Rebal 70 kelly - v4" (baseline)
- `vVWYQComYNNnycRVvT1S` - 0.85 Kelly
- `fUl7ecw3u7zYrxdEcall` - 0.90 Kelly
- `JQ0lnTBrfVAiisZCv875` - Rebal 70 Kelly v3
- `DADlgd32w6XJHjWfxGa0` - Goal Tracker 2026

---

## Option Omega Optimization - CORRECTED WORKFLOW (2026-01-30)

**User Corrections:**

### 1. Workflow Fix
- ❌ DON'T go to Model page to save
- ✅ Stay on Test page, click New Backtest → Run → Save
- ✅ Rename IN THE SAVE DIALOG before clicking Save
- ✅ Always "Create New Backtest" - NEVER replace existing

### 2. Strategy Optimization (NOT allocation!)
- ❌ DON'T just change allocation %
- ✅ DO optimize entry/exit criteria, filters, parameters
- ✅ Use SAME starting capital for all strategies (apples to apples)
- ✅ Allocation % only matters for PORTFOLIO-level optimization
- ✅ After optimizing all 19 strategies, THEN figure out best portfolio allocation

### 3. Save Naming Convention
- Always prefix with "Nemo_"
- Include strategy name
- Include attempt number or key change (e.g., "Nemo_McRib_Delta40")

**Correct Approach:**
1. On Test page, click "New Backtest"
2. Change parameters (entry/exit/filters/delta/DTE)
3. Set dates: 05/16/2022 → 01/29/2026
4. Click Run
5. Wait for backtest (check every 10-15 sec)
6. When complete, click Save icon
7. Select "Create New Backtest"
8. RENAME to "Nemo_[Strategy]_[Change]"
9. Click Save
10. Move to next strategy

**Key Learning:**
- Strategy-level optimization = entry/exit/filter parameters
- Portfolio-level optimization = allocation percentages
- Never confuse the two!
- My "optimizations" on McRib made it WORSE - original was better tuned

---

## CHALLENGE FINAL CLARIFICATION (2026-01-30 22:26 PST)

**User Message:** "Use same 19 strats, same starting capital, come up with better allocations to increase MAR with MDD ≤ 18.2%. It's not about beating P/L - MAR, MDD, tail risk are important."

**FINAL UNDERSTANDING:**
- ✅ Use EXACT SAME 19 strategies (NO parameter changes!)
- ✅ Use SAME $160,000 starting capital
- ✅ Only optimize: ALLOCATION PERCENTAGES across the 19 strategies
- ✅ Goal: Higher portfolio MAR, MDD ≤ 18.2%
- ✅ Tail risk matters

**What I Was Wrong About:**
- ❌ Individual strategy optimization (waste of time)
- ❌ Changing deltas, exits, filters
- ✅ Should have been: Portfolio-level allocation optimization only

**Correct Path Forward:**
1. Create new portfolio "Nemo_Optimized_2026"
2. Add same 19 strategies from his portfolio
3. Adjust allocation % based on my analysis
4. Run backtest
5. Compare MAR to baseline 208.6

**My Analysis from Earlier:**
- McRib Deluxe: Increase 0.8% → 3% (highest MAR)
- Overnight Diagonal: Increase 10% → 12%
- EOM Straddle: Increase 3.1% → 5%
- New JonE: Decrease 4% → 1.5% (underperformer)
- etc.

---

## Active Challenge: Portfolio Optimization (2026-01-30)

**Status:** In Progress - Continue Tomorrow

**Goal:** Beat MAR 209.4 with optimized allocations across 19 strategies

**Progress:**
- ✅ Extracted all 19 strategies with metrics
- ✅ Created optimization formula (target MAR 245-255)
- ⚠️ Blocked: Browser automation timeouts during portfolio creation

**Key Moves:**
- McRib Deluxe: 0.8% → 3% (+2.2%)
- Overnight Diagonal: 10% → 12% (+2%)
- EOM Straddle: 3.1% → 5% (+1.9%)
- New JonE 42D: 4% → 1.5% (-2.5%) [slash drag]
- Eliminate: 10 day RiC, R2 EOM Strangle

**Full Details:** `memory/2026-01-30-portfolio-challenge.md`

---

**Last Updated:** 2026-01-30 23:10 PST
**Next Review:** Continue tomorrow 2026-01-31
