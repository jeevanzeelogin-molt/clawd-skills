#!/usr/bin/env python3
# /// script
# dependencies = ["yfinance", "numpy", "scipy"]
# ///

"""
Cheddar Flow + Option Omega Hybrid System
Auto-tracks alerts, detects big moves, alerts for OPRA verification
"""

import yfinance as yf
import numpy as np
from scipy.stats import norm
from datetime import datetime, timedelta
import json
import os
import sys

# Thresholds for big move detection
BIG_MOVE_THRESHOLD = 50  # Alert if P/L > 50% or < -25%
LOSS_THRESHOLD = -25
CHECK_INTERVAL_HOURS = 1

class HybridOptionTracker:
    """Hybrid tracker: Auto-model + Option Omega verification on big moves"""
    
    def __init__(self, db_path='/Users/nemotaka/clawd/logs/cheddar-hybrid-models.json',
                 alerts_path='/Users/nemotaka/clawd/logs/cheddar-big-move-alerts.json'):
        self.db_path = db_path
        self.alerts_path = alerts_path
        self.models = self.load_models()
        self.big_move_alerts = self.load_alerts()
        self.risk_free_rate = 0.045
    
    def load_models(self):
        if os.path.exists(self.db_path):
            with open(self.db_path, 'r') as f:
                return json.load(f)
        return {'models': [], 'last_check': None}
    
    def load_alerts(self):
        if os.path.exists(self.alerts_path):
            with open(self.alerts_path, 'r') as f:
                return json.load(f)
        return {'alerts': []}
    
    def save_models(self):
        with open(self.db_path, 'w') as f:
            json.dump(self.models, f, indent=2)
    
    def save_alerts(self):
        with open(self.alerts_path, 'w') as f:
            json.dump(self.big_move_alerts, f, indent=2)
    
    def black_scholes(self, S, K, T, r, sigma, option_type='CALL'):
        """Black-Scholes option pricing"""
        if T <= 0:
            # Expired - intrinsic value only
            if option_type == 'CALL':
                return max(0, S - K), (1 if S > K else 0), 0, 0, 0
            else:
                return max(0, K - S), (-1 if S < K else 0), 0, 0, 0
        
        d1 = (np.log(S / K) + (r + 0.5 * sigma ** 2) * T) / (sigma * np.sqrt(T))
        d2 = d1 - sigma * np.sqrt(T)
        
        if option_type == 'CALL':
            price = S * norm.cdf(d1) - K * np.exp(-r * T) * norm.cdf(d2)
            delta = norm.cdf(d1)
        else:
            price = K * np.exp(-r * T) * norm.cdf(-d2) - S * norm.cdf(-d1)
            delta = norm.cdf(d1) - 1
        
        gamma = norm.pdf(d1) / (S * sigma * np.sqrt(T))
        theta = (-S * norm.pdf(d1) * sigma / (2 * np.sqrt(T)) 
                 - r * K * np.exp(-r * T) * norm.cdf(d2 if option_type == 'CALL' else -d2))
        vega = S * norm.pdf(d1) * np.sqrt(T)
        
        return price, delta, gamma, theta / 365, vega / 100
    
    def get_stock_data(self, symbol):
        """Get current stock price and volatility"""
        try:
            ticker = yf.Ticker(symbol)
            hist = ticker.history(period='30d')
            
            if hist.empty:
                return None
            
            current_price = hist['Close'].iloc[-1]
            log_returns = np.log(hist['Close'] / hist['Close'].shift(1))
            volatility = log_returns.std() * np.sqrt(252)
            
            return {
                'price': current_price,
                'volatility': volatility
            }
        except Exception as e:
            print(f"Error fetching {symbol}: {e}")
            return None
    
    def create_model_from_alert(self, alert_data):
        """Create model from Cheddar Flow alert"""
        symbol = alert_data['symbol']
        direction = alert_data['direction']
        signal = alert_data.get('signal', 'Alert')
        
        stock_data = self.get_stock_data(symbol)
        if not stock_data:
            return None
        
        current_price = stock_data['price']
        volatility = stock_data['volatility']
        
        # Estimate strike (ATM if not specified)
        strike = alert_data.get('strike', current_price)
        
        # Estimate expiry (30 days default)
        days_to_expiry = alert_data.get('dte', 30)
        expiry_date = datetime.now() + timedelta(days=days_to_expiry)
        T = days_to_expiry / 365
        
        option_type = 'CALL' if direction == 'BULLISH' else 'PUT'
        
        # Calculate theoretical price
        price, delta, gamma, theta, vega = self.black_scholes(
            current_price, strike, T, self.risk_free_rate, volatility, option_type
        )
        
        model = {
            'id': f"{symbol}_{int(datetime.now().timestamp())}",
            'symbol': symbol,
            'direction': direction,
            'signal': signal,
            'strike': round(strike, 2),
            'expiry': expiry_date.strftime('%Y-%m-%d'),
            'entry_price': round(current_price, 2),
            'entry_date': datetime.now().isoformat(),
            'theoretical_entry_price': round(price, 2),
            'volatility_at_entry': round(volatility, 4),
            'option_type': option_type,
            'greeks_at_entry': {
                'delta': round(delta, 4),
                'gamma': round(gamma, 6),
                'theta': round(theta, 4),
                'vega': round(vega, 4)
            },
            'snapshots': [],
            'status': 'ACTIVE',
            'big_move_alerted': False,
            'opra_verified': False
        }
        
        self.models['models'].append(model)
        self.save_models()
        
        return model
    
    def take_hourly_snapshot(self, model_id):
        """Take snapshot and check for big moves"""
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
        option_type = model['option_type']
        
        # Calculate remaining time
        expiry = datetime.strptime(model['expiry'], '%Y-%m-%d')
        days_remaining = (expiry - datetime.now()).days
        T = max(days_remaining, 0) / 365
        
        # Calculate current option value
        price, delta, gamma, theta, vega = self.black_scholes(
            current_price, strike, T, self.risk_free_rate, volatility, option_type
        )
        
        # Calculate P/L
        entry_price = model['theoretical_entry_price']
        if entry_price > 0:
            pnl = ((price - entry_price) / entry_price) * 100
        else:
            pnl = 0
        
        snapshot = {
            'timestamp': datetime.now().isoformat(),
            'stock_price': round(current_price, 2),
            'option_price': round(price, 2),
            'pnl_percent': round(pnl, 2),
            'days_remaining': days_remaining,
            'greeks': {
                'delta': round(delta, 4),
                'gamma': round(gamma, 6),
                'theta': round(theta, 4),
                'vega': round(vega, 4)
            },
            'volatility': round(volatility, 4)
        }
        
        model['snapshots'].append(snapshot)
        
        # Check for big move
        big_move_detected = False
        alert_type = None
        
        if pnl >= BIG_MOVE_THRESHOLD and not model.get('big_move_alerted'):
            big_move_detected = True
            alert_type = 'BIG_WIN'
            model['big_move_alerted'] = True
        elif pnl <= LOSS_THRESHOLD and not model.get('big_move_alerted'):
            big_move_detected = True
            alert_type = 'BIG_LOSS'
            model['big_move_alerted'] = True
        
        if big_move_detected:
            alert = {
                'timestamp': datetime.now().isoformat(),
                'model_id': model_id,
                'symbol': symbol,
                'alert_type': alert_type,
                'pnl_percent': round(pnl, 2),
                'message': f"🚨 {alert_type}: ${symbol} showing {pnl:+.2f}%",
                'action': 'Check Option Omega for OPRA price',
                'option_omega_url': f'https://optionomega.com/dashboard/modeling/chart',
                'entry_price': model['entry_price'],
                'current_price': round(current_price, 2),
                'strike': strike
            }
            self.big_move_alerts['alerts'].append(alert)
            self.save_alerts()
        
        # Check if expired
        if days_remaining <= 0:
            model['status'] = 'EXPIRED'
            model['final_pnl'] = round(pnl, 2)
        
        self.save_models()
        
        return {
            'snapshot': snapshot,
            'big_move_detected': big_move_detected,
            'alert_type': alert_type
        }
    
    def export_to_option_omega_format(self, model_id):
        """Export model data to Option Omega compatible format"""
        for model in self.models['models']:
            if model['id'] == model_id:
                export = {
                    'symbol': model['symbol'],
                    'strategy': 'Long Call' if model['option_type'] == 'CALL' else 'Long Put',
                    'legs': [
                        {
                            'type': model['option_type'],
                            'strike': model['strike'],
                            'expiry': model['expiry'],
                            'action': 'BUY',
                            'quantity': 1
                        }
                    ],
                    'entry_stock_price': model['entry_price'],
                    'entry_date': model['entry_date'][:10],
                    'notes': f"Cheddar Flow {model['signal']} alert"
                }
                return export
        return None
    
    def run_hourly_check(self):
        """Run hourly check on all active models"""
        print("=" * 70)
        print(f"HYBRID TRACKER - Hourly Check ({datetime.now().strftime('%Y-%m-%d %H:%M')})")
        print("=" * 70)
        
        active_models = [m for m in self.models['models'] if m['status'] == 'ACTIVE']
        
        if not active_models:
            print("No active models to monitor")
            return
        
        print(f"\nMonitoring {len(active_models)} active models...\n")
        
        big_moves = []
        
        for model in active_models:
            result = self.take_hourly_snapshot(model['id'])
            if result:
                snap = result['snapshot']
                print(f"📊 {model['symbol']} @ ${snap['stock_price']} → Option: ${snap['option_price']} → P/L: {snap['pnl_percent']:+.2f}%")
                
                if result['big_move_detected']:
                    big_moves.append({
                        'symbol': model['symbol'],
                        'pnl': snap['pnl_percent'],
                        'type': result['alert_type']
                    })
        
        if big_moves:
            print("\n" + "=" * 70)
            print("🚨 BIG MOVES DETECTED - Check Option Omega!")
            print("=" * 70)
            for move in big_moves:
                emoji = "🚀" if move['type'] == 'BIG_WIN' else "📉"
                print(f"{emoji} ${move['symbol']}: {move['pnl']:+.2f}%")
            print("\n👉 Go to: https://optionomega.com/dashboard/modeling/chart")
            print("   Enter the trade details to get OPRA-verified prices")
        
        self.models['last_check'] = datetime.now().isoformat()
        self.save_models()
        
        print("\n" + "=" * 70)
        print(f"Check complete. Next check in {CHECK_INTERVAL_HOURS} hour(s)")
        print("=" * 70)

def main():
    tracker = HybridOptionTracker()
    
    if len(sys.argv) < 2:
        print("Cheddar Flow + Option Omega Hybrid Tracker")
        print("\nCommands:")
        print("  create <symbol> <direction> [strike] [dte]")
        print("  hourly          - Run hourly check on all models")
        print("  list            - List all active models")
        print("  export <id>     - Export model to Option Omega format")
        print("  alerts          - Show big move alerts")
        print("\nExample:")
        print("  python3 hybrid-tracker.py create SLV BEARISH 100 30")
        return
    
    cmd = sys.argv[1]
    
    if cmd == 'create':
        if len(sys.argv) < 4:
            print("Usage: create <symbol> <direction> [strike] [dte]")
            return
        
        alert_data = {
            'symbol': sys.argv[2],
            'direction': sys.argv[3],
            'strike': float(sys.argv[4]) if len(sys.argv) > 4 else None,
            'dte': int(sys.argv[5]) if len(sys.argv) > 5 else 30
        }
        
        model = tracker.create_model_from_alert(alert_data)
        if model:
            print(f"✅ Model created: {model['id']}")
            print(f"   Symbol: ${model['symbol']}")
            print(f"   Strike: ${model['strike']}")
            print(f"   Entry: ${model['entry_price']}")
            print(f"   Theo Price: ${model['theoretical_entry_price']}")
            print(f"   Delta: {model['greeks_at_entry']['delta']}")
            print(f"\n⚙️  Run 'hourly' to start monitoring")
        else:
            print("❌ Failed to create model")
    
    elif cmd == 'hourly':
        tracker.run_hourly_check()
    
    elif cmd == 'list':
        active = [m for m in tracker.models['models'] if m['status'] == 'ACTIVE']
        print(f"\nActive Models ({len(active)}):")
        for m in active:
            print(f"  {m['id']}: ${m['symbol']} {m['option_type']} @ ${m['strike']} - {m['status']}")
    
    elif cmd == 'export':
        if len(sys.argv) < 3:
            print("Usage: export <model_id>")
            return
        export = tracker.export_to_option_omega_format(sys.argv[2])
        if export:
            print(json.dumps(export, indent=2))
        else:
            print("❌ Model not found")
    
    elif cmd == 'alerts':
        alerts = tracker.big_move_alerts['alerts']
        if not alerts:
            print("No big move alerts yet")
        else:
            print(f"\nBig Move Alerts ({len(alerts)}):")
            for a in alerts[-5:]:
                print(f"  {a['timestamp'][:16]}: {a['message']}")
    
    else:
        print(f"Unknown command: {cmd}")

if __name__ == "__main__":
    main()
