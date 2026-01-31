# TinyFish Setup Guide - Option Omega Portfolio Optimizer

## Prerequisites

1. **TinyFish API Key** ✅ (You have this!)
2. **Node.js 18+** or **Python 3.9+**
3. **Option Omega Account** with access to portfolio

## Installation

### Option A: Node.js/JavaScript

```bash
# Install TinyFish SDK
npm install -g @tinyfish/agent

# Or local install
npm install @tinyfish/agent
```

### Option B: Python

```bash
# Install TinyFish SDK
pip install tinyfish

# Or with requirements
pip install -r requirements.txt
```

## Configuration

1. **Set API Key in environment:**
```bash
export TINYFISH_API_KEY="your_api_key_here"
```

Or add to `~/.clawdbot/.env`:
```
TINYFISH_API_KEY=your_api_key_here
```

2. **Verify installation:**
```bash
# Node.js
tinyfish --version

# Python
python -c "import tinyfish; print(tinyfish.__version__)"
```

## Running the Optimizer

### Method 1: Using the prompt file (Simplest)
```bash
# Read the prompt
cat /Users/nemotaka/clawd/nemotrades-portfolio/tinyfish_prompt.txt

# Copy and paste into TinyFish web interface
# OR use CLI if available
tinyfish run --prompt-file tinyfish_prompt.txt
```

### Method 2: Using the Node.js script
```bash
cd /Users/nemotaka/clawd/nemotrades-portfolio
node tinyfish-optimizer.js
```

### Method 3: Using the Python script
```bash
cd /Users/nemotaka/clawd/nemotrades-portfolio
python3 tinyfish_optimizer.py

# This generates the prompt, then you can:
tinyfish run --prompt "$(cat tinyfish_prompt.txt)"
```

## Expected Output

```
🚀 Option Omega Portfolio Optimization
===============================================
Target: MAR 245-255 (up from 209.4)
MDD: ≤ 18.1%

✅ Portfolio creation completed!
Results: {
  "mar": 248.7,
  "mdd": "-17.8%",
  "cagr": "4,523%",
  "pl": "$145.2B"
}

🎉 CHALLENGE COMPLETE!
MAR improved: 209.4 → 248.7
MDD: -17.8%
```

## Troubleshooting

### Issue: API key not found
**Solution:**
```bash
export TINYFISH_API_KEY="your_key"
# Or add to ~/.bashrc or ~/.zshrc
```

### Issue: Timeout during backtest
**Solution:** Increase wait time in script:
```javascript
{ action: 'wait', timeMs: 120000 }  // 2 minutes
```

### Issue: Element not found
**Solution:** TinyFish uses natural language - describe element differently:
```javascript
// Instead of:
element: '#run-button'

// Use:
element: 'button with text "Run"'
```

## Files Created

1. `tinyfish-optimizer.js` - Node.js automation script
2. `tinyfish_optimizer.py` - Python automation script
3. `tinyfish_prompt.txt` - Natural language prompt
4. `TINYFISH_SETUP.md` - This guide

## Next Steps

1. ✅ Install TinyFish SDK
2. ✅ Set API key
3. 🎯 Run optimizer
4. 📊 Verify MAR > 209.4
5. 🎉 Save as "Nemo_Optimized_2026"

## Resources

- TinyFish Docs: https://docs.mino.ai/
- TinyFish Cookbook: https://github.com/tinyfish-io/tinyfish-cookbook
- Option Omega Docs: https://docs.optionomega.com/

---
**Ready to execute!** 🚀
