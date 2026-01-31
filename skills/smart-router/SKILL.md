---
name: smart_router
description: Automatically routes tasks to the most cost-effective AI model based on complexity. Uses Kimi/Gemini for bulk tasks, Kimi Code for standard analysis, and reserves expensive models for complex reasoning only.
---

# 🤖 Smart Model Router

Intelligently routes your requests to the most cost-effective AI model based on task complexity.

## 💰 Cost-Optimized Routing

| Task Type | Model | Cost | Use For |
|-----------|-------|------|---------|
| **Bulk/Data** | Gemini Flash | **FREE** | CSV parsing, ticker extraction, formatting |
| **Standard** | Kimi Code | Low | Daily analysis, summaries, coding |
| **Complex** | Kimi K2 | Medium | Multi-step reasoning, strategy |
| **Critical** | Claude/Sonnet | High | Deep analysis, debugging, architecture |

## 🎯 Routing Logic

```
User Request
     │
     ▼
┌─────────────────┐
│  Complexity     │
│   Analysis      │
└────────┬────────┘
         │
    ┌────┴────┬────────┬────────┐
    ▼         ▼        ▼        ▼
  BULK     STANDARD  COMPLEX  CRITICAL
    │         │        │        │
    ▼         ▼        ▼        ▼
 Gemini    Kimi    Kimi K2   Claude
 (Free)    Code    (Smart)   (Deep)
```

## 📝 Usage

Add this to your agent configuration or use the helper functions.

### Route Triggers

**BULK_TASK** → Gemini Flash (Free)
- "Summarize this CSV"
- "Extract all tickers from this text"
- "Format this list into JSON"
- "Find the highest volume"

**STANDARD_TASK** → Kimi Code (Default)
- "Why is NVDA flow bearish?"
- "Compare these two trades"
- "Write Python to plot this"
- "Explain this strategy"

**COMPLEX_TASK** → Kimi K2 (Smart)
- "Analyze multi-leg option strategy"
- "Build a skill for scraping"
- "Review portfolio hedging"
- "Complex data synthesis"

**CRITICAL_TASK** → Expensive Model (Manual)
- "Debug this complex error"
- "Architect a new system"
- "Deep probability analysis"

## 🔧 Implementation

### Option 1: Use the Router Script

```bash
# Route a request automatically
/Users/nemotaka/clawd/smart-router.sh "summarize this CSV" bulk

# Force specific tier
/Users/nemotaka/clawd/smart-router.sh "analyze NVDA" standard
/Users/nemotaka/clawd/smart-router.sh "debug this" complex
```

### Option 2: Python Integration

```python
from smart_router import route_task

# Auto-detect and route
result = route_task("Summarize this flow data")

# Force specific tier
result = route_task("Debug my code", tier="critical")
```

### Option 3: Clawdbot Native

The router is automatically applied to all requests. Check the routing decision in the response metadata.

## 📊 Cost Tracking

Monitor your spending:

```bash
# View cost report
clawdbot cost-report

# Check routing statistics
cat ~/.clawdbot/routing-stats.json
```

## 🎛️ Configuration

Edit `/Users/nemotaka/clawd/smart-router-config.json`:

```json
{
  "default_tier": "standard",
  "fallback_order": ["kimi", "gemini", "claude"],
  "cost_limits": {
    "daily_max": 5.00,
    "warning_at": 3.00
  }
}
```

## 🚀 Auto-Fallback Integration

The Smart Router works with your existing auto-fallback:

1. **Normal operation**: Routes to cheapest capable model
2. **Kimi quota exceeded**: Falls back to Gemini (free)
3. **Complex task**: Upgrades to stronger model automatically
4. **Budget warning**: Forces cheaper models

## 💡 Example Scenarios

| Request | Routed To | Why |
|---------|-----------|-----|
| "Extract tickers from this list" | Gemini | Bulk pattern matching |
| "Is this put spread bullish?" | Kimi Code | Standard analysis |
| "Build a new trading skill" | Kimi K2 | Complex architecture |
| "Debug this 500-line error" | Claude | Deep reasoning needed |

## 🔒 Safety Features

- **Budget guardrails**: Auto-switch to free tier when approaching limit
- **Complexity detection**: Analyzes request before routing
- **Fallback chains**: Multiple backup options
- **Manual override**: Force any tier when needed
