#!/usr/bin/env python3
# /// script
# dependencies = ["yfinance", "numpy", "scipy"]
# ///

"""
Option Omega-style Trade Modeler for Cheddar Flow Alerts
Uses Black-Scholes model with real market data
"""

import yfinance as yf
import numpy as np
from scipy.stats import norm
from datetime import datetime, timedelta
import json
import os

# Black-Scholes Option Pricing Model
def black_scholes(S, K, T, r, sigma, option_type='CALL'):
    """
    S: Current stock price
    K: Strike price
    T: Time to expiration (in years)
    r: Risk-free rate (annual)
    sigma: Volatility (annual)
    option_type: 'CALL' or 'PUT'
    """
    d1 = (np.log(S / K) + (r + 0.5 * sigma ** 2) * T) / (sigma * np.sqrt(T))
    d2 = d1 - sigma * np.sqrt(T)
    
    if option_type == 'CALL':
        price = S * norm.cdf(d1) - K * np.exp(-r * T) * norm.cdf(d2)
        delta = norm.cdf(d1)
    else:  # PUT
        price = K * np.exp(-r * T) * norm.cdf(-d2) - S * norm.cdf(-d1)
        delta = norm.cdf(d1) - 1
    
    # Greeks
    gamma = norm.pdf(d1) / (S * sigma * np.sqrt(T))
    theta = (-S * norm.pdf(d1) * sigma / (2 * np.sqrt(T)) 
             - r * K * np.exp(-r * T) * norm.cdf(d2 if option_type == 'CALL' else -d2))
    vega = S * norm.pdf(d1) * np.sqrt(T)
    
    return {
        'price': price,
        'delta': delta,
        'gamma': gamma,
        'theta': theta / 365,  # Daily theta
        'vega': vega / 100  # Per 1% IV change
    }

class OptionOmegaModeler:
    """Models option trades like Option Omega"""
    
    def __init__(self, db_path='/Users/nemotaka/clawd/logs/cheddar-omega-models.json'):
        self.db_path = db_path
        self.models = self.load_models()
        self.risk_free_rate = 0.045  # 4.5% annual
    
    def load_models(self):
        if os.path.exists(self.db_path):
            with open(self.db_path, 'r') as f:
                return json.load(f)
        return {'models': []}
    
    def save_models(self):
        with open(self.db_path, 'w') as f:
            json.dump(self.models, f, indent=2)
    
    def get_stock_data(self, symbol):
        """Get current stock price and volatility"""
        try:
            ticker = yf.Ticker(symbol)
            hist = ticker.history(period='30d')
            
            if hist.empty:
                return None
            
            current_price = hist['Close'].iloc[-1]
            
            # Calculate historical volatility (annualized)
            log_returns = np.log(hist['Close'] / hist['Close'].shift(1))
            volatility = log_returns.std() * np.sqrt(252)  # Annualized
            
            return {
                'price': current_price,
                'volatility': volatility,
                'history': hist
            }
        except Exception as e:
            print(f"Error fetching {symbol}: {e}")
            return None
    
    def create_model(self, alert_id, symbol, direction, signal, strike, expiry, 
                     premium=None, alert_date=None):
        """Create a new option model from Cheddar Flow alert"""
        
        stock_data = self.get_stock_data(symbol)
        if not stock_data:
            return None
        
        current_price = stock_data['price']
        volatility = stock_data['volatility']
        
        # Calculate days to expiration
        if not alert_date:
            alert_date = datetime.now()
        else:
            alert_date = datetime.strptime(alert_date, '%Y-%m-%d')
        
        expiry_date = datetime.strptime(expiry, '%Y-%m-%d')
        days_to_expiry = (expiry_date - alert_date).days
        T = days_to_expiry / 365  # In years
        
        # Determine option type from direction
        option_type = 'CALL' if direction == 'BULLISH' else 'PUT'
        
        # Calculate theoretical option price
        bs = black_scholes(current_price, strike, T, self.risk_free_rate, 
                          volatility, option_type)
        
        model = {
            'id': f"{symbol}_{alert_id}_{int(datetime.now().timestamp())}",
            'alert_id': alert_id,
            'symbol': symbol,
            'direction': direction,
            'signal': signal,
            'strike': strike,
            'expiry': expiry,
            'entry_price': current_price,
            'entry_date': alert_date.isoformat(),
            'expiry_date': expiry_date.isoformat(),
            'days_to_expiry': days_to_expiry,
            'option_type': option_type,
            'volatility_at_entry': round(volatility, 4),
            'theoretical_price': round(bs['price'], 2),
            'premium_paid': premium,
            'greeks_at_entry': {
                'delta': round(bs['delta'], 4),
                'gamma': round(bs['gamma'], 6),
                'theta': round(bs['theta'], 4),
                'vega': round(bs['vega'], 4)
            },
            'snapshots': [],
            'status': 'ACTIVE',
            'created_at': datetime.now().isoformat()
        }
        
        self.models['models'].append(model)
        self.save_models()
        
        return model
    
    def take_snapshot(self, model_id):
        """Take hourly snapshot of model performance"""
        model = None
        for m in self.models['models']:
            if m['id'] == model_id:
                model = m
                break
        
        if not model or model['status'] != 'ACTIVE':
            return None
        
        symbol = model['symbol']
        stock_data = self.get_stock_data(symbol)
        
        if not stock_data:
            return None
        
        current_price = stock_data['price']
        volatility = stock_data['volatility']
        strike = model['strike']
        
        # Calculate remaining time
        expiry_date = datetime.fromisoformat(model['expiry_date'])
        days_remaining = (expiry_date - datetime.now()).days
        T = max(days_remaining, 0) / 365
        
        # Calculate current option value
        bs = black_scholes(current_price, strike, T, self.risk_free_rate,
                          volatility, model['option_type'])
        
        # Calculate P/L
        entry_price = model['theoretical_price']
        current_option_price = bs['price']
        pnl = ((current_option_price - entry_price) / entry_price) * 100 if entry_price > 0 else 0
        
        snapshot = {
            'timestamp': datetime.now().isoformat(),
            'stock_price': round(current_price, 2),
            'option_price': round(current_option_price, 2),
            'days_remaining': days_remaining,
            'pnl_percent': round(pnl, 2),
            'greeks': {
                'delta': round(bs['delta'], 4),
                'gamma': round(bs['gamma'], 6),
                'theta': round(bs['theta'], 4),
                'vega': round(bs['vega'], 4)
            },
            'volatility': round(volatility, 4)
        }
        
        model['snapshots'].append(snapshot)
        
        # Check if expired
        if days_remaining <= 0:
            model['status'] = 'EXPIRED'
            model['final_pnl'] = round(pnl, 2)
        
        self.save_models()
        
        return snapshot
    
    def get_model_status(self, model_id):
        """Get current status of a model"""
        for model in self.models['models']:
            if model['id'] == model_id:
                return model
        return None
    
    def list_active_models(self):
        """List all active models"""
        return [m for m in self.models['models'] if m['status'] == 'ACTIVE']
    
    def close_model(self, model_id, final_pnl=None):
        """Close a model with final result"""
        for model in self.models['models']:
            if model['id'] == model_id:
                model['status'] = 'CLOSED'
                if final_pnl:
                    model['final_pnl'] = final_pnl
                model['closed_at'] = datetime.now().isoformat()
                self.save_models()
                return True
        return False
    
    def generate_report(self, model_id):
        """Generate detailed report for a model"""
        model = self.get_model_status(model_id)
        if not model:
            return None
        
        report = f"""
# Option Omega Style Model Report
## {model['symbol']} {model['option_type']} - Strike ${model['strike']}

**Model ID:** {model['id']}  
**Status:** {model['status']}  
**Alert Signal:** {model['signal']}

### Entry Details
- **Stock Price:** ${model['entry_price']}
- **Option Price:** ${model['theoretical_price']}
- **Date:** {model['entry_date'][:10]}
- **Expiry:** {model['expiry']}
- **DTE:** {model['days_to_expiry']}

### Greeks at Entry
- **Delta:** {model['greeks_at_entry']['delta']}
- **Gamma:** {model['greeks_at_entry']['gamma']}
- **Theta:** ${model['greeks_at_entry']['theta']}/day
- **Vega:** ${model['greeks_at_entry']['vega']} per 1% IV

### Snapshots ({len(model['snapshots'])})
"""
        
        for snap in model['snapshots'][-5:]:  # Last 5 snapshots
            report += f"""
**{snap['timestamp'][:16]}**
- Stock: ${snap['stock_price']} | Option: ${snap['option_price']}
- P/L: {snap['pnl_percent']:+.2f}% | DTE: {snap['days_remaining']}
- Δ: {snap['greeks']['delta']} | θ: {snap['greeks']['theta']}
"""
        
        if model.get('final_pnl'):
            report += f"\n### Final Result\n**P/L: {model['final_pnl']:+.2f}%**\n"
        
        return report

# CLI Interface
def main():
    import sys
    
    modeler = OptionOmegaModeler()
    
    if len(sys.argv) < 2:
        print("Option Omega Style Modeler for Cheddar Flow")
        print("\nCommands:")
        print("  create <symbol> <direction> <strike> <expiry> [signal] [premium]")
        print("  snapshot <model_id>")
        print("  status <model_id>")
        print("  list")
        print("  close <model_id> [pnl]")
        print("  report <model_id>")
        print("\nExample:")
        print("  python3 omega-modeler.py create SLV BEARISH 100 2026-02-21 'Put Sweep' 1300000")
        return
    
    cmd = sys.argv[1]
    
    if cmd == 'create':
        if len(sys.argv) < 5:
            print("Usage: create <symbol> <direction> <strike> <expiry> [signal] [premium]")
            return
        
        symbol = sys.argv[2]
        direction = sys.argv[3]
        strike = float(sys.argv[4])
        expiry = sys.argv[5]
        signal = sys.argv[6] if len(sys.argv) > 6 else 'Alert'
        premium = sys.argv[7] if len(sys.argv) > 7 else None
        
        model = modeler.create_model(
            alert_id=f"manual_{int(datetime.now().timestamp())}",
            symbol=symbol,
            direction=direction,
            signal=signal,
            strike=strike,
            expiry=expiry,
            premium=premium
        )
        
        if model:
            print(f"✅ Model created: {model['id']}")
            print(f"   Symbol: ${symbol}")
            print(f"   Strike: ${strike}")
            print(f"   Expiry: {expiry}")
            print(f"   Theoretical Price: ${model['theoretical_price']}")
            print(f"   Delta: {model['greeks_at_entry']['delta']}")
        else:
            print("❌ Failed to create model")
    
    elif cmd == 'snapshot':
        if len(sys.argv) < 3:
            print("Usage: snapshot <model_id>")
            return
        
        snap = modeler.take_snapshot(sys.argv[2])
        if snap:
            print(f"📸 Snapshot taken:")
            print(f"   Stock: ${snap['stock_price']}")
            print(f"   Option: ${snap['option_price']}")
            print(f"   P/L: {snap['pnl_percent']:+.2f}%")
            print(f"   DTE: {snap['days_remaining']}")
        else:
            print("❌ Failed to take snapshot")
    
    elif cmd == 'list':
        models = modeler.list_active_models()
        print(f"📊 Active Models ({len(models)}):")
        for m in models:
            print(f"   {m['id']}: ${m['symbol']} {m['option_type']} @ ${m['strike']} - {m['status']}")
    
    elif cmd == 'report':
        if len(sys.argv) < 3:
            print("Usage: report <model_id>")
            return
        
        report = modeler.generate_report(sys.argv[2])
        if report:
            print(report)
        else:
            print("❌ Model not found")
    
    else:
        print(f"Unknown command: {cmd}")

if __name__ == "__main__":
    main()
