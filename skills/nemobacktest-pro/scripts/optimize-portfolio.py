#!/usr/bin/env python3
"""
NemoBacktest Pro — Portfolio Optimizer
Find optimal portfolio weights for SPX dailies with MAR maximization and MDD < 18%.

Usage:
    ./optimize-portfolio.py --input strategies.json --target-mar 1.5 --max-mdd 0.18
"""

import json
import numpy as np
import pandas as pd
import argparse
from pathlib import Path
from scipy.optimize import minimize, differential_evolution
from datetime import datetime

def load_strategy_data(input_path):
    """Load strategy performance data."""
    path = Path(input_path).expanduser()
    
    with open(path) as f:
        data = json.load(f)
    
    # Expect format: {strategies: [{name, returns, max_dd, ...}, ...]}
    return data.get('strategies', data)

def calculate_portfolio_metrics(weights, strategies):
    """
    Calculate portfolio-level metrics from strategy weights.
    
    Parameters:
    -----------
    weights : array
        Portfolio weights (sum to 1)
    strategies : list
        List of strategy dictionaries with returns, cagr, max_dd
    
    Returns:
    --------
    dict : Portfolio metrics
    """
    n_strategies = len(strategies)
    
    # Extract strategy metrics
    cagrs = np.array([s.get('cagr', s.get('annual_return', 0)) for s in strategies])
    max_dds = np.array([s.get('max_drawdown', s.get('max_dd', 0)) for s in strategies])
    
    # Portfolio CAGR (weighted average)
    portfolio_cagr = np.sum(weights * cagrs)
    
    # Portfolio Max DD (conservative estimate)
    # Assume correlations can cause drawdowns to stack
    portfolio_max_dd = np.sqrt(np.sum((weights * max_dds) ** 2))
    
    # MAR Ratio
    mar = portfolio_cagr / abs(portfolio_max_dd) if portfolio_max_dd != 0 else 0
    
    # Sharpe approximation
    volatilities = np.array([s.get('volatility', 0.2) for s in strategies])
    portfolio_vol = np.sqrt(np.sum((weights * volatilities) ** 2))
    sharpe = portfolio_cagr / portfolio_vol if portfolio_vol > 0 else 0
    
    return {
        'cagr': portfolio_cagr,
        'max_drawdown': portfolio_max_dd,
        'mar': mar,
        'sharpe': sharpe,
        'volatility': portfolio_vol
    }

def objective_function(weights, strategies, target_mar=1.5, max_mdd=0.18):
    """
    Objective function to maximize (we'll minimize negative).
    
    Penalizes:
    - Low MAR
    - High drawdown
    - Concentration risk
    """
    metrics = calculate_portfolio_metrics(weights, strategies)
    
    # Penalty for MDD exceeding limit
    mdd_penalty = 0
    if metrics['max_drawdown'] < -max_mdd:
        mdd_penalty = 1000 * (abs(metrics['max_drawdown']) - max_mdd) ** 2
    
    # Penalty for MAR below target
    mar_penalty = 0
    if metrics['mar'] < target_mar:
        mar_penalty = 100 * (target_mar - metrics['mar']) ** 2
    
    # Concentration penalty (encourage diversification)
    hhi = np.sum(weights ** 2)  # Herfindahl-Hirschman Index
    concentration_penalty = 0.5 * hhi
    
    # Objective: Maximize MAR, minimize penalties
    score = metrics['mar'] - mdd_penalty - mar_penalty - concentration_penalty
    
    return -score  # Minimize negative = maximize

def optimize_portfolio(strategies, target_mar=1.5, max_mdd=0.18, method='differential_evolution'):
    """
    Find optimal portfolio allocation.
    
    Parameters:
    -----------
    strategies : list
        List of strategy dictionaries
    target_mar : float
        Target MAR ratio
    max_mdd : float
        Maximum acceptable drawdown
    method : str
        Optimization method
    
    Returns:
    --------
    dict : Optimization results
    """
    n_strategies = len(strategies)
    
    # Constraints: weights sum to 1, each weight >= 0
    constraints = {'type': 'eq', 'fun': lambda w: np.sum(w) - 1}
    bounds = [(0, 1) for _ in range(n_strategies)]
    
    if method == 'differential_evolution':
        # Global optimization
        result = differential_evolution(
            objective_function,
            bounds,
            args=(strategies, target_mar, max_mdd),
            maxiter=1000,
            tol=1e-7,
            polish=True,
            seed=42
        )
        optimal_weights = result.x
        success = result.success
    else:
        # Local optimization with multiple starting points
        best_result = None
        best_score = float('inf')
        
        for _ in range(100):
            # Random starting point
            w0 = np.random.dirichlet(np.ones(n_strategies))
            
            result = minimize(
                objective_function,
                w0,
                args=(strategies, target_mar, max_mdd),
                method='SLSQP',
                bounds=bounds,
                constraints=constraints
            )
            
            if result.fun < best_score:
                best_score = result.fun
                best_result = result
        
        optimal_weights = best_result.x
        success = best_result.success
    
    # Normalize weights (ensure sum to 1)
    optimal_weights = optimal_weights / np.sum(optimal_weights)
    
    # Calculate final metrics
    metrics = calculate_portfolio_metrics(optimal_weights, strategies)
    
    return {
        'success': success,
        'weights': optimal_weights,
        'metrics': metrics,
        'strategies': [s['name'] for s in strategies]
    }

def generate_efficient_frontier(strategies, n_points=50):
    """Generate efficient frontier by varying MDD constraints."""
    frontier = []
    
    for max_mdd in np.linspace(0.10, 0.30, n_points):
        result = optimize_portfolio(strategies, target_mar=0.5, max_mdd=max_mdd)
        if result['success']:
            frontier.append({
                'max_mdd': max_mdd,
                'cagr': result['metrics']['cagr'],
                'mar': result['metrics']['mar'],
                'weights': result['weights'].tolist()
            })
    
    return frontier

def generate_optimization_report(result, strategies, target_mar, max_mdd, output_path=None):
    """Generate formatted optimization report."""
    
    weights = result['weights']
    metrics = result['metrics']
    
    report = f"""
╔════════════════════════════════════════════════════════════════╗
║          🎯 PORTFOLIO OPTIMIZATION RESULTS                     ║
╚════════════════════════════════════════════════════════════════╝

📋 CONSTRAINTS
─────────────────────────────────────────────────────────────────
Target MAR:         {target_mar:.2f}
Max Drawdown:       {max_mdd:.1%}

✅ OPTIMAL ALLOCATION
─────────────────────────────────────────────────────────────────
"""
    
    for i, (strategy, weight) in enumerate(zip(strategies, weights)):
        if weight > 0.001:  # Only show non-zero allocations
            bar = '█' * int(weight * 50)
            report += f"  {strategy['name']:20s} {weight*100:5.1f}% {bar}\n"
    
    report += f"""
📊 PORTFOLIO METRICS
─────────────────────────────────────────────────────────────────
Expected CAGR:      {metrics['cagr']:.1%}
Expected Max DD:    {metrics['max_drawdown']:.1%}
MAR Ratio:          {metrics['mar']:.2f}
Sharpe Ratio:       {metrics['sharpe']:.2f}
Volatility:         {metrics['volatility']:.1%}

✅ CONSTRAINT CHECK
─────────────────────────────────────────────────────────────────
MAR Target Met:     {'✅ Yes' if metrics['mar'] >= target_mar else '❌ No'} ({metrics['mar']:.2f} vs {target_mar:.2f})
MDD Limit Met:      {'✅ Yes' if abs(metrics['max_drawdown']) <= max_mdd else '❌ No'} ({abs(metrics['max_drawdown']):.1%} vs {max_mdd:.1%})
"""
    
    # Strategy breakdown
    report += """
📈 STRATEGY DETAILS
─────────────────────────────────────────────────────────────────
"""
    for i, strategy in enumerate(strategies):
        report += f"""
{strategy['name']}:
  Allocation:       {weights[i]*100:.1f}%
  Historical CAGR:  {strategy.get('cagr', strategy.get('annual_return', 0)):.1%}
  Historical MDD:   {strategy.get('max_drawdown', strategy.get('max_dd', 0)):.1%}
  MAR:              {strategy.get('mar', strategy.get('cagr', 0) / abs(strategy.get('max_drawdown', 1))):.2f}
"""
    
    print(report)
    
    if output_path:
        output_data = {
            'optimization_params': {
                'target_mar': target_mar,
                'max_mdd': max_mdd,
                'timestamp': datetime.now().isoformat()
            },
            'optimal_weights': {
                strategy['name']: float(weights[i]) 
                for i, strategy in enumerate(strategies)
            },
            'portfolio_metrics': {
                k: float(v) if isinstance(v, (int, float, np.number)) else v
                for k, v in metrics.items()
            },
            'strategies': strategies
        }
        
        with open(output_path, 'w') as f:
            json.dump(output_data, f, indent=2)
        print(f"📁 Report saved to: {output_path}")
    
    return report

def main():
    parser = argparse.ArgumentParser(description='Portfolio Optimizer for SPX Dailies')
    parser.add_argument('--input', '-i', required=True, help='Strategy performance JSON')
    parser.add_argument('--target-mar', '-m', type=float, default=1.5, help='Target MAR ratio')
    parser.add_argument('--max-mdd', '-d', type=float, default=0.18, help='Maximum drawdown')
    parser.add_argument('--output', '-o', help='Output JSON file')
    parser.add_argument('--frontier', '-f', action='store_true', help='Generate efficient frontier')
    
    args = parser.parse_args()
    
    print("🎯 NemoBacktest Pro — Portfolio Optimizer")
    print(f"   Loading strategy data from: {args.input}")
    
    # Load strategies
    strategies = load_strategy_data(args.input)
    print(f"   Loaded {len(strategies)} strategies")
    
    # Optimize
    print(f"   Optimizing for MAR >= {args.target_mar}, MDD <= {args.max_mdd:.1%}...")
    result = optimize_portfolio(strategies, args.target_mar, args.max_mdd)
    
    # Generate report
    generate_optimization_report(result, strategies, args.target_mar, args.max_mdd, args.output)
    
    # Efficient frontier
    if args.frontier:
        print("\n📈 Generating efficient frontier...")
        frontier = generate_efficient_frontier(strategies)
        
        frontier_path = args.output.replace('.json', '_frontier.json') if args.output else 'efficient_frontier.json'
        with open(frontier_path, 'w') as f:
            json.dump(frontier, f, indent=2)
        print(f"📁 Efficient frontier saved to: {frontier_path}")

if __name__ == '__main__':
    main()
