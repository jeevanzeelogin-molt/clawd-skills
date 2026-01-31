# NemoBacktest Pro — Advanced Risk Analytics for Options Trading

Monte Carlo simulation, tail risk analysis, and portfolio optimization for SPX dailies and options strategies.

## Features

- **Monte Carlo Simulator**: 10,000+ simulations over customizable time periods
- **Tail Risk Calculator**: VaR, CVaR, max drawdown, skewness, kurtosis
- **Portfolio Optimizer**: Maximize MAR (Managed Account Ratio), minimize MDD
- **SPX Dailies Specialist**: Optimized for 0DTE/1DTE strategies
- **Option Omega Integration**: Import and analyze trade logs

## Installation

```bash
# Install required Python packages
pip install numpy pandas scipy matplotlib yfinance

# Or use uv (recommended)
uv pip install numpy pandas scipy matplotlib yfinance
```

## Quick Start

### Monte Carlo Simulation
```bash
./scripts/monte-carlo.py --input backtest_log.json --sims 10000 --years 10
```

### Tail Risk Analysis
```bash
./scripts/tail-risk.py --input oo_trades.csv --confidence 0.95
```

### Portfolio Optimization
```bash
./scripts/optimize-portfolio.py --target-mar 1.5 --max-mdd 0.18 --strategies "spx_dailies,iron_condor,earnings"
```

## Data Format

### Input: Trade Log (JSON)
```json
{
  "trades": [
    {
      "date": "2026-01-26",
      "ticker": "SPY",
      "strategy": "Iron Condor",
      "entry_price": 2.80,
      "exit_price": 0.65,
      "pnl": 215,
      "return_pct": 77
    }
  ]
}
```

### Output: Risk Report (JSON)
```json
{
  "monte_carlo": {
    "simulations": 10000,
    "median_cagr": 0.42,
    "worst_case": -0.35,
    "best_case": 1.25,
    "probability_of_profit": 0.85
  },
  "tail_risk": {
    "var_95": -0.12,
    "cvar_95": -0.18,
    "max_drawdown": -0.16,
    "skewness": -0.45,
    "kurtosis": 3.2
  }
}
```

## Configuration

Edit `~/.nemobacktest.json`:
```json
{
  "default_sims": 10000,
  "default_years": 10,
  "confidence_level": 0.95,
  "target_mar": 1.5,
  "max_mdd": 0.18,
  "option_omega_path": "~/Nemoblock/oo_data",
  "output_dir": "~/Nemoblock/analysis"
}
```

## Commands

| Command | Description |
|---------|-------------|
| `monte-carlo` | Run Monte Carlo simulation |
| `tail-risk` | Calculate tail risk metrics |
| `optimize` | Find optimal portfolio weights |
| `analyze-oo` | Analyze Option Omega trade logs |
| `dashboard` | Generate HTML risk dashboard |

## License

Private — for Nemoblock use only
