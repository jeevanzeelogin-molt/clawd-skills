#!/usr/bin/env python3
"""
NemoBacktest Pro — Tail Risk Calculator
Calculate VaR, CVaR, and tail risk metrics from Option Omega trade logs.

Usage:
    ./tail-risk.py --input oo_trades.csv --confidence 0.95
"""

import json
import numpy as np
import pandas as pd
import argparse
from pathlib import Path
from scipy import stats

def load_option_omega_data(input_path):
    """Load Option Omega trade logs."""
    path = Path(input_path).expanduser()
    
    if path.suffix == '.csv':
        df = pd.read_csv(path)
    elif path.suffix == '.json':
        with open(path) as f:
            data = json.load(f)
        df = pd.DataFrame(data.get('trades', data))
    else:
        raise ValueError(f"Unsupported format: {path.suffix}")
    
    # Standardize column names
    df.columns = [c.lower().replace(' ', '_') for c in df.columns]
    return df

def calculate_var(returns, confidence=0.95):
    """Calculate Value at Risk."""
    return np.percentile(returns, (1 - confidence) * 100)

def calculate_cvar(returns, confidence=0.95):
    """Calculate Conditional Value at Risk (Expected Shortfall)."""
    var = calculate_var(returns, confidence)
    return np.mean(returns[returns <= var])

def calculate_drawdowns(equity_curve):
    """Calculate drawdown series."""
    peak = np.maximum.accumulate(equity_curve)
    drawdown = (equity_curve - peak) / peak
    return drawdown

def calculate_max_drawdown(equity_curve):
    """Calculate maximum drawdown."""
    drawdowns = calculate_drawdowns(equity_curve)
    return np.min(drawdowns)

def calculate_calmar_ratio(returns, max_dd):
    """Calculate Calmar ratio (CAGR / Max DD)."""
    cagr = np.mean(returns) * 12  # Annualized (assuming monthly returns)
    return cagr / abs(max_dd) if max_dd != 0 else 0

def calculate_tail_risk_metrics(trades_df, confidence=0.95):
    """Calculate comprehensive tail risk metrics."""
    
    # Extract returns
    if 'return_pct' in trades_df.columns:
        returns = pd.to_numeric(trades_df['return_pct'], errors='coerce').values
    elif 'pnl_pct' in trades_df.columns:
        returns = pd.to_numeric(trades_df['pnl_pct'], errors='coerce').values
    elif 'pnl' in trades_df.columns and 'capital' in trades_df.columns:
        returns = (pd.to_numeric(trades_df['pnl'], errors='coerce') / 
                   pd.to_numeric(trades_df['capital'], errors='coerce')).values * 100
    elif 'return' in trades_df.columns:
        returns = pd.to_numeric(trades_df['return'], errors='coerce').values
    elif 'exit' in trades_df.columns and 'entry' in trades_df.columns:
        # Calculate returns from entry/exit prices
        returns = ((pd.to_numeric(trades_df['exit'], errors='coerce') - 
                    pd.to_numeric(trades_df['entry'], errors='coerce')) / 
                   pd.to_numeric(trades_df['entry'], errors='coerce') * 100).values
    else:
        # Try to find a numeric column for returns
        for col in trades_df.columns:
            if trades_df[col].dtype in ['int64', 'float64']:
                returns = trades_df[col].values
                break
        else:
            # Last resort: try to convert last column
            returns = pd.to_numeric(trades_df.iloc[:, -1], errors='coerce').values
    
    # Remove NaN values
    returns = returns[~np.isnan(returns)]
    
    # Build equity curve
    equity = [100000]  # Start with $100k
    for r in returns:
        equity.append(equity[-1] * (1 + r / 100))
    equity = np.array(equity)
    
    # Calculate metrics
    metrics = {
        'sample_size': len(returns),
        'confidence_level': confidence,
        
        # Return statistics
        'mean_return': np.mean(returns),
        'median_return': np.median(returns),
        'std_return': np.std(returns),
        'min_return': np.min(returns),
        'max_return': np.max(returns),
        
        # Tail risk metrics
        'var': calculate_var(returns, confidence),
        'cvar': calculate_cvar(returns, confidence),
        'skewness': stats.skew(returns),
        'kurtosis': stats.kurtosis(returns),
        
        # Drawdown metrics
        'max_drawdown': calculate_max_drawdown(equity),
        'avg_drawdown': np.mean(calculate_drawdowns(equity)),
        
        # Ratios
        'sharpe_ratio': np.mean(returns) / np.std(returns) if np.std(returns) > 0 else 0,
        'sortino_ratio': calculate_sortino_ratio(returns),
        'calmar_ratio': calculate_calmar_ratio(returns, calculate_max_drawdown(equity)),
        
        # Win/loss metrics
        'win_rate': np.mean(returns > 0),
        'profit_factor': calculate_profit_factor(returns),
        'avg_win': np.mean(returns[returns > 0]) if np.any(returns > 0) else 0,
        'avg_loss': np.mean(returns[returns < 0]) if np.any(returns < 0) else 0,
        'win_loss_ratio': calculate_win_loss_ratio(returns),
        
        # Tail events
        'tail_events_2std': np.mean(np.abs(returns - np.mean(returns)) > 2 * np.std(returns)),
        'tail_events_3std': np.mean(np.abs(returns - np.mean(returns)) > 3 * np.std(returns)),
        'consecutive_losses': max_consecutive_losses(returns),
    }
    
    return metrics, returns, equity

def calculate_sortino_ratio(returns, risk_free_rate=0):
    """Calculate Sortino ratio (downside deviation only)."""
    downside_returns = returns[returns < 0]
    downside_std = np.std(downside_returns) if len(downside_returns) > 0 else 0
    return (np.mean(returns) - risk_free_rate) / downside_std if downside_std > 0 else 0

def calculate_profit_factor(returns):
    """Calculate profit factor (gross profit / gross loss)."""
    gross_profit = np.sum(returns[returns > 0])
    gross_loss = abs(np.sum(returns[returns < 0]))
    return gross_profit / gross_loss if gross_loss > 0 else float('inf')

def calculate_win_loss_ratio(returns):
    """Calculate win/loss ratio."""
    avg_win = np.mean(returns[returns > 0]) if np.any(returns > 0) else 0
    avg_loss = abs(np.mean(returns[returns < 0])) if np.any(returns < 0) else 1
    return avg_win / avg_loss if avg_loss > 0 else 0

def max_consecutive_losses(returns):
    """Find maximum consecutive losing trades."""
    consecutive = 0
    max_consecutive = 0
    for r in returns:
        if r < 0:
            consecutive += 1
            max_consecutive = max(max_consecutive, consecutive)
        else:
            consecutive = 0
    return max_consecutive

def stress_test_scenarios(returns):
    """Run stress test scenarios."""
    scenarios = {
        'black_monday_1987': {
            'description': 'Single day -20% drop',
            'impact': -20,
            'recovery_months': 12
        },
        'flash_crash_2010': {
            'description': 'Flash crash -9% intraday',
            'impact': -9,
            'recovery_months': 3
        },
        'covid_crash_2020': {
            'description': 'COVID crash -34%',
            'impact': -34,
            'recovery_months': 6
        },
        'volmageddon_2018': {
            'description': 'VIX spike, XIV termination',
            'impact': -15,
            'recovery_months': 4
        }
    }
    
    results = {}
    baseline_cagr = np.mean(returns) * 12
    baseline_mdd = max_drawdown_from_returns(returns)
    
    for name, scenario in scenarios.items():
        # Simulate impact
        new_returns = np.concatenate([returns, [scenario['impact']]])
        new_cagr = np.mean(new_returns) * 12
        new_mdd = max_drawdown_from_returns(new_returns)
        
        results[name] = {
            'description': scenario['description'],
            'impact_pct': scenario['impact'],
            'cagr_before': baseline_cagr,
            'cagr_after': new_cagr,
            'mdd_before': baseline_mdd,
            'mdd_after': new_mdd,
            'recovery_months': scenario['recovery_months']
        }
    
    return results

def max_drawdown_from_returns(returns):
    """Calculate max drawdown from returns series."""
    equity = [100]
    for r in returns:
        equity.append(equity[-1] * (1 + r / 100))
    equity = np.array(equity)
    peak = np.maximum.accumulate(equity)
    drawdown = (equity - peak) / peak
    return np.min(drawdown)

def generate_tail_risk_report(metrics, stress_tests, output_path=None):
    """Generate formatted tail risk report."""
    
    conf_pct = int(metrics['confidence_level'] * 100)
    
    report = f"""
╔════════════════════════════════════════════════════════════════╗
║        ⚠️  TAIL RISK ANALYSIS REPORT ({conf_pct}% Confidence)              ║
╚════════════════════════════════════════════════════════════════╝

📊 SAMPLE STATISTICS
─────────────────────────────────────────────────────────────────
Sample Size:        {metrics['sample_size']:,} trades
Mean Return:        {metrics['mean_return']:.2f}%
Median Return:      {metrics['median_return']:.2f}%
Std Deviation:      {metrics['std_return']:.2f}%
Min Return:         {metrics['min_return']:.2f}%
Max Return:         {metrics['max_return']:.2f}%

🎯 RISK METRICS
─────────────────────────────────────────────────────────────────
VaR ({conf_pct}%):           {metrics['var']:.2f}%
CVaR ({conf_pct}%):          {metrics['cvar']:.2f}%
Max Drawdown:       {metrics['max_drawdown']:.2%}
Avg Drawdown:       {metrics['avg_drawdown']:.2%}

📈 DISTRIBUTION SHAPE
─────────────────────────────────────────────────────────────────
Skewness:           {metrics['skewness']:.3f} {'(Left tail)' if metrics['skewness'] < 0 else '(Right tail)'}
Kurtosis:           {metrics['kurtosis']:.3f} {'(Fat tails)' if metrics['kurtosis'] > 3 else '(Normal tails)'}
Tail Events (2σ):   {metrics['tail_events_2std']:.1%}
Tail Events (3σ):   {metrics['tail_events_3std']:.1%}

🏆 PERFORMANCE RATIOS
─────────────────────────────────────────────────────────────────
Sharpe Ratio:       {metrics['sharpe_ratio']:.2f}
Sortino Ratio:      {metrics['sortino_ratio']:.2f}
Calmar Ratio:       {metrics['calmar_ratio']:.2f}

💰 WIN/LOSS ANALYSIS
─────────────────────────────────────────────────────────────────
Win Rate:           {metrics['win_rate']:.1%}
Profit Factor:      {metrics['profit_factor']:.2f}
Avg Win:            {metrics['avg_win']:.2f}%
Avg Loss:           {metrics['avg_loss']:.2f}%
Win/Loss Ratio:     {metrics['win_loss_ratio']:.2f}
Max Consecutive Losses: {metrics['consecutive_losses']}

🔥 STRESS TEST SCENARIOS
─────────────────────────────────────────────────────────────────
"""
    
    for name, scenario in stress_tests.items():
        report += f"""
{scenario['description']}:
  Impact: {scenario['impact_pct']:.0f}%
  CAGR Before: {scenario['cagr_before']:.1%} → After: {scenario['cagr_after']:.1%}
  MDD Before: {scenario['mdd_before']:.1%} → After: {scenario['mdd_after']:.1%}
  Est. Recovery: {scenario['recovery_months']} months
"""
    
    report += """
⚠️  TAIL RISK WARNINGS
─────────────────────────────────────────────────────────────────
"""
    
    # Generate warnings
    warnings = []
    if metrics['skewness'] < -0.5:
        warnings.append("⚠️  High negative skewness — large losses more likely than large gains")
    if metrics['kurtosis'] > 3:
        warnings.append("⚠️  Fat tails detected — extreme events more likely than normal distribution")
    if metrics['max_drawdown'] < -0.20:
        warnings.append(f"⚠️  Max drawdown {metrics['max_drawdown']:.1%} exceeds 20% threshold")
    if metrics['consecutive_losses'] > 5:
        warnings.append(f"⚠️  {metrics['consecutive_losses']} consecutive losses — check for streak risk")
    if metrics['var'] < -10:
        warnings.append(f"⚠️  VaR is {metrics['var']:.1f}% — large single-trade losses possible")
    
    if warnings:
        report += '\n'.join(warnings)
    else:
        report += "✅ No major tail risk warnings"
    
    report += "\n"
    
    print(report)
    
    if output_path:
        with open(output_path, 'w') as f:
            json.dump({
                'metrics': metrics,
                'stress_tests': stress_tests
            }, f, indent=2, default=str)
        print(f"📁 Report saved to: {output_path}")
    
    return report

def main():
    parser = argparse.ArgumentParser(description='Tail Risk Calculator for Options Trading')
    parser.add_argument('--input', '-i', required=True, help='Input trade log (CSV or JSON)')
    parser.add_argument('--confidence', '-c', type=float, default=0.95, help='Confidence level (0-1)')
    parser.add_argument('--output', '-o', help='Output JSON file')
    parser.add_argument('--stress-test', '-s', action='store_true', help='Run stress tests')
    
    args = parser.parse_args()
    
    print("⚠️  NemoBacktest Pro — Tail Risk Calculator")
    print(f"   Loading trade data from: {args.input}")
    
    # Load data
    trades_df = load_option_omega_data(args.input)
    print(f"   Loaded {len(trades_df)} trades")
    
    # Calculate metrics
    print(f"   Calculating tail risk metrics ({args.confidence:.0%} confidence)...")
    metrics, returns, equity = calculate_tail_risk_metrics(trades_df, args.confidence)
    
    # Stress tests
    stress_tests = {}
    if args.stress_test:
        print("   Running stress test scenarios...")
        stress_tests = stress_test_scenarios(returns)
    
    # Generate report
    generate_tail_risk_report(metrics, stress_tests, args.output)

if __name__ == '__main__':
    main()
