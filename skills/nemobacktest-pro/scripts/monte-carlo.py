#!/usr/bin/env python3
"""
NemoBacktest Pro — Monte Carlo Risk Simulator
Run 10,000+ simulations over a 10-year period for options trading strategies.

Usage:
    ./monte-carlo.py --input backtest_log.json --sims 10000 --years 10 --output report.json
"""

import json
import numpy as np
import pandas as pd
import argparse
from datetime import datetime, timedelta
from pathlib import Path
import matplotlib.pyplot as plt

def load_trade_data(input_path):
    """Load trade data from JSON or CSV."""
    path = Path(input_path).expanduser()
    
    if path.suffix == '.json':
        with open(path) as f:
            data = json.load(f)
        if 'trades' in data:
            return pd.DataFrame(data['trades'])
        return pd.DataFrame(data)
    elif path.suffix == '.csv':
        return pd.read_csv(path)
    else:
        raise ValueError(f"Unsupported file format: {path.suffix}")

def calculate_trade_stats(trades_df):
    """Calculate key statistics from historical trades."""
    # Try to find returns column
    if 'return_pct' in trades_df.columns:
        returns = pd.to_numeric(trades_df['return_pct'], errors='coerce').values
    elif 'return' in trades_df.columns:
        returns = pd.to_numeric(trades_df['return'], errors='coerce').values
    elif 'pnl' in trades_df.columns:
        returns = pd.to_numeric(trades_df['pnl'], errors='coerce').values
    elif 'exit' in trades_df.columns and 'entry' in trades_df.columns:
        returns = ((pd.to_numeric(trades_df['exit'], errors='coerce') - 
                    pd.to_numeric(trades_df['entry'], errors='coerce')) / 
                   pd.to_numeric(trades_df['entry'], errors='coerce') * 100).values
    else:
        # Find first numeric column
        for col in trades_df.columns:
            if trades_df[col].dtype in ['int64', 'float64']:
                returns = trades_df[col].values
                break
        else:
            returns = pd.to_numeric(trades_df.iloc[:, -1], errors='coerce').values
    
    # Remove NaN
    returns = returns[~np.isnan(returns)]
    
    stats = {
        'mean_return': np.mean(returns),
        'std_return': np.std(returns),
        'win_rate': np.mean(returns > 0),
        'avg_win': np.mean(returns[returns > 0]) if np.any(returns > 0) else 0,
        'avg_loss': np.mean(returns[returns < 0]) if np.any(returns < 0) else 0,
        'max_win': np.max(returns),
        'max_loss': np.min(returns),
        'skewness': pd.Series(returns).skew(),
        'kurtosis': pd.Series(returns).kurtosis(),
        'trades_per_month': len(returns) / 12  # Assuming 1 year of data
    }
    return stats

def monte_carlo_simulation(stats, initial_capital=100000, years=10, n_sims=10000):
    """
    Run Monte Carlo simulation for options trading strategy.
    
    Parameters:
    -----------
    stats : dict
        Trade statistics (mean, std, win_rate, etc.)
    initial_capital : float
        Starting capital
    years : int
        Simulation period in years
    n_sims : int
        Number of simulations
    
    Returns:
    --------
    dict : Simulation results
    """
    months = years * 12
    trades_per_month = max(1, int(stats['trades_per_month']))
    
    # Store equity curves for all simulations
    equity_curves = np.zeros((n_sims, months + 1))
    equity_curves[:, 0] = initial_capital
    
    max_drawdowns = np.zeros(n_sims)
    final_returns = np.zeros(n_sims)
    cagrs = np.zeros(n_sims)
    
    for sim in range(n_sims):
        capital = initial_capital
        peak = capital
        max_dd = 0
        
        for month in range(months):
            # Simulate trades for this month
            monthly_pnl = 0
            for _ in range(trades_per_month):
                # Determine if win or loss
                is_win = np.random.random() < stats['win_rate']
                
                if is_win:
                    # Sample from winning distribution
                    return_pct = np.random.normal(stats['avg_win'], stats['std_return'] * 0.5)
                else:
                    # Sample from losing distribution
                    return_pct = np.random.normal(stats['avg_loss'], stats['std_return'] * 0.5)
                
                # Apply return to capital
                trade_pnl = capital * (return_pct / 100)
                monthly_pnl += trade_pnl
                capital += trade_pnl
            
            equity_curves[sim, month + 1] = capital
            
            # Track peak and drawdown
            if capital > peak:
                peak = capital
            drawdown = (peak - capital) / peak
            if drawdown > max_dd:
                max_dd = drawdown
        
        max_drawdowns[sim] = max_dd
        final_returns[sim] = (capital - initial_capital) / initial_capital
        cagrs[sim] = (capital / initial_capital) ** (1 / years) - 1
    
    # Calculate percentiles
    results = {
        'simulations': n_sims,
        'years': years,
        'initial_capital': initial_capital,
        'final_capital': {
            'median': np.median(equity_curves[:, -1]),
            'mean': np.mean(equity_curves[:, -1]),
            'percentile_5': np.percentile(equity_curves[:, -1], 5),
            'percentile_25': np.percentile(equity_curves[:, -1], 25),
            'percentile_75': np.percentile(equity_curves[:, -1], 75),
            'percentile_95': np.percentile(equity_curves[:, -1], 95),
        },
        'cagr': {
            'median': np.median(cagrs),
            'mean': np.mean(cagrs),
            'percentile_5': np.percentile(cagrs, 5),
            'percentile_25': np.percentile(cagrs, 25),
            'percentile_75': np.percentile(cagrs, 75),
            'percentile_95': np.percentile(cagrs, 95),
        },
        'max_drawdown': {
            'median': np.median(max_drawdowns),
            'mean': np.mean(max_drawdowns),
            'worst': np.max(max_drawdowns),
            'percentile_95': np.percentile(max_drawdowns, 95),
        },
        'probability_of_profit': np.mean(final_returns > 0),
        'probability_of_target': np.mean(cagrs > 0.20),  # 20% annual target
        'probability_mdd_under_18': np.mean(max_drawdowns < 0.18),
        'risk_of_ruin': np.mean(equity_curves[:, -1] < initial_capital * 0.5),
    }
    
    return results, equity_curves

def generate_report(results, stats, output_path=None):
    """Generate formatted report."""
    report = f"""
╔════════════════════════════════════════════════════════════════╗
║     🎲 MONTE CARLO SIMULATION RESULTS ({results['simulations']:,} sims)     ║
╚════════════════════════════════════════════════════════════════╝

📊 SIMULATION PARAMETERS
─────────────────────────────────────────────────────────────────
Initial Capital:    ${results['initial_capital']:,.0f}
Simulation Period:  {results['years']} years
Trades/Month:       {stats['trades_per_month']:.1f}

📈 HISTORICAL TRADE STATISTICS
─────────────────────────────────────────────────────────────────
Win Rate:           {stats['win_rate']:.1%}
Avg Return:         {stats['mean_return']:.2f}%
Std Deviation:      {stats['std_return']:.2f}%
Avg Win:            {stats['avg_win']:.2f}%
Avg Loss:           {stats['avg_loss']:.2f}%
Skewness:           {stats['skewness']:.3f}
Kurtosis:           {stats['kurtosis']:.3f}

🎯 CAGR (Compound Annual Growth Rate)
─────────────────────────────────────────────────────────────────
Median:             {results['cagr']['median']:.1%}
Mean:               {results['cagr']['mean']:.1%}
5th Percentile:     {results['cagr']['percentile_5']:.1%} (Worst case)
25th Percentile:    {results['cagr']['percentile_25']:.1%}
75th Percentile:    {results['cagr']['percentile_75']:.1%}
95th Percentile:    {results['cagr']['percentile_95']:.1%} (Best case)

💰 FINAL CAPITAL (Starting: ${results['initial_capital']:,.0f})
─────────────────────────────────────────────────────────────────
Median:             ${results['final_capital']['median']:,.0f}
Mean:               ${results['final_capital']['mean']:,.0f}
5th Percentile:     ${results['final_capital']['percentile_5']:,.0f}
95th Percentile:    ${results['final_capital']['percentile_95']:,.0f}

📉 MAX DRAWDOWN
─────────────────────────────────────────────────────────────────
Median:             {results['max_drawdown']['median']:.1%}
Mean:               {results['max_drawdown']['mean']:.1%}
Worst Case:         {results['max_drawdown']['worst']:.1%}
95th Percentile:    {results['max_drawdown']['percentile_95']:.1%}

🎲 PROBABILITIES
─────────────────────────────────────────────────────────────────
Probability of Profit:              {results['probability_of_profit']:.1%}
Probability of 20%+ CAGR:           {results['probability_of_target']:.1%}
Probability MDD < 18%:              {results['probability_mdd_under_18']:.1%}
Risk of Ruin (>50% loss):           {results['risk_of_ruin']:.1%}

✅ MAR RATIO (CAGR / Max DD)
─────────────────────────────────────────────────────────────────
Median MAR:         {results['cagr']['median'] / results['max_drawdown']['median']:.2f}
"""
    
    print(report)
    
    if output_path:
        with open(output_path, 'w') as f:
            json.dump({
                'parameters': {
                    'simulations': results['simulations'],
                    'years': results['years'],
                    'initial_capital': results['initial_capital']
                },
                'historical_stats': stats,
                'results': results
            }, f, indent=2, default=str)
        print(f"\n📁 Report saved to: {output_path}")
    
    return report

def main():
    parser = argparse.ArgumentParser(description='Monte Carlo Risk Simulator for Options Trading')
    parser.add_argument('--input', '-i', required=True, help='Input trade log (JSON or CSV)')
    parser.add_argument('--sims', '-n', type=int, default=10000, help='Number of simulations')
    parser.add_argument('--years', '-y', type=int, default=10, help='Simulation years')
    parser.add_argument('--capital', '-c', type=float, default=100000, help='Initial capital')
    parser.add_argument('--output', '-o', help='Output JSON file')
    parser.add_argument('--plot', '-p', action='store_true', help='Generate equity curve plot')
    
    args = parser.parse_args()
    
    print("🎲 NemoBacktest Pro — Monte Carlo Simulator")
    print(f"   Loading trade data from: {args.input}")
    
    # Load data
    trades_df = load_trade_data(args.input)
    print(f"   Loaded {len(trades_df)} trades")
    
    # Calculate statistics
    print("   Calculating trade statistics...")
    stats = calculate_trade_stats(trades_df)
    
    # Run simulation
    print(f"   Running {args.sims:,} simulations over {args.years} years...")
    print("   (This may take a moment)")
    
    results, equity_curves = monte_carlo_simulation(
        stats, 
        initial_capital=args.capital,
        years=args.years,
        n_sims=args.sims
    )
    
    # Generate report
    generate_report(results, stats, args.output)
    
    # Optional plot
    if args.plot:
        plt.figure(figsize=(12, 6))
        
        # Plot percentiles
        months = np.arange(args.years * 12 + 1)
        p5 = np.percentile(equity_curves, 5, axis=0)
        p25 = np.percentile(equity_curves, 25, axis=0)
        p50 = np.percentile(equity_curves, 50, axis=0)
        p75 = np.percentile(equity_curves, 75, axis=0)
        p95 = np.percentile(equity_curves, 95, axis=0)
        
        plt.fill_between(months, p5, p95, alpha=0.2, label='5th-95th percentile')
        plt.fill_between(months, p25, p75, alpha=0.3, label='25th-75th percentile')
        plt.plot(months, p50, 'b-', linewidth=2, label='Median')
        plt.axhline(y=args.capital, color='r', linestyle='--', label='Initial Capital')
        
        plt.xlabel('Months')
        plt.ylabel('Portfolio Value ($)')
        plt.title(f'Monte Carlo Simulation ({args.sims:,} runs, {args.years} years)')
        plt.legend()
        plt.grid(True, alpha=0.3)
        
        plot_path = args.output.replace('.json', '.png') if args.output else 'monte_carlo_equity.png'
        plt.savefig(plot_path, dpi=150, bbox_inches='tight')
        print(f"📊 Plot saved to: {plot_path}")

if __name__ == '__main__':
    main()
