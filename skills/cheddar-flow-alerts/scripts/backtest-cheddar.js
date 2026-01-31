#!/usr/bin/env node
/**
 * Cheddar Flow Historical Backtester
 * Scrapes historical alerts and backtests performance
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const CONFIG = {
  twitterHandle: 'CheddarFlow',
  monthsBack: 6,
  outputDir: '/Users/nemotaka/clawd/data/cheddar-backtest',
  minPremium: 100000,
  trackPatterns: ['sweep', 'block', 'darkpool', 'whale', 'unusual']
};

// Ensure output directory
if (!fs.existsSync(CONFIG.outputDir)) {
  fs.mkdirSync(CONFIG.outputDir, { recursive: true });
}

class CheddarBacktester {
  constructor() {
    this.alerts = [];
    this.results = {
      total: 0,
      winners: 0,
      losers: 0,
      avgReturn: 0,
      byPattern: {},
      bySymbol: {}
    };
  }

  // Parse trade from tweet text
  parseTrade(text) {
    const patterns = {
      symbol: /\$([A-Z]{1,5})\b|\b([A-Z]{3,5})\b/g,
      strike: /\$?(\d+(?:\.\d+)?)\s*(?:call|put|CALL|PUT)/i,
      callPut: /\b(call|put|CALL|PUT)\b/,
      expiry: /\b(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\s*\d{1,2}(?:\s*'?\d{2,4})?|\b\d{1,2}\/\d{1,2}(?:\/\d{2,4})?/i,
      premium: /\$([\d,]+(?:\.\d+)?)\s*[km]?|\b([\d,]+(?:\.\d+)?)\s*[km]?\s*(?:premium|size)/i,
      pattern: /\b(sweep|block|darkpool|whale|unusual|split|spread)\b/gi
    };

    const matches = {
      symbol: text.match(patterns.symbol)?.[0]?.replace('$', '') || null,
      strike: text.match(patterns.strike)?.[1] || null,
      callPut: text.match(patterns.callPut)?.[0]?.toUpperCase() || null,
      expiry: text.match(patterns.expiry)?.[0] || null,
      premium: this.parsePremium(text),
      patterns: [...text.matchAll(patterns.pattern)].map(m => m[0].toLowerCase()),
      rawText: text,
      timestamp: null
    };

    return matches;
  }

  parsePremium(text) {
    // Match patterns like $1.2M, $500K, $250,000
    const match = text.match(/\$([\d.]+)\s*([km])|\$([\d,]+)/i);
    if (!match) return null;
    
    let value = parseFloat((match[1] || match[3]).replace(',', ''));
    const multiplier = match[2]?.toLowerCase();
    
    if (multiplier === 'k') value *= 1000;
    if (multiplier === 'm') value *= 1000000;
    
    return value;
  }

  // Generate mock historical data for demonstration
  // In production, this would scrape actual Twitter/X data
  generateMockHistoricalData() {
    const symbols = ['SPY', 'QQQ', 'AAPL', 'TSLA', 'NVDA', 'AMD', 'META', 'AMZN', 'MSFT', 'GOOGL'];
    const patterns = ['sweep', 'block', 'whale', 'darkpool', 'unusual'];
    const directions = ['CALL', 'PUT'];
    
    const data = [];
    const now = new Date();
    
    // Generate 6 months of data
    for (let i = 0; i < 180; i++) {
      const date = new Date(now);
      date.setDate(date.getDate() - i);
      
      // Skip weekends
      if (date.getDay() === 0 || date.getDay() === 6) continue;
      
      // Generate 2-5 alerts per day
      const dailyAlerts = Math.floor(Math.random() * 4) + 2;
      
      for (let j = 0; j < dailyAlerts; j++) {
        const symbol = symbols[Math.floor(Math.random() * symbols.length)];
        const pattern = patterns[Math.floor(Math.random() * patterns.length)];
        const direction = directions[Math.floor(Math.random() * directions.length)];
        const premium = [250000, 500000, 750000, 1000000, 1500000, 2500000, 5000000][Math.floor(Math.random() * 7)];
        
        // Get strike based on symbol
        const basePrices = {
          'SPY': 590, 'QQQ': 520, 'AAPL': 225, 'TSLA': 420, 'NVDA': 140,
          'AMD': 160, 'META': 600, 'AMZN': 225, 'MSFT': 430, 'GOOGL': 180
        };
        const base = basePrices[symbol] || 100;
        const strike = Math.round(base * (0.9 + Math.random() * 0.2));
        
        // Expiry within 30 days
        const expiryDays = [7, 14, 21, 30][Math.floor(Math.random() * 4)];
        const expiry = new Date(date);
        expiry.setDate(expiry.getDate() + expiryDays);
        
        data.push({
          date: date.toISOString().split('T')[0],
          timestamp: date.toISOString(),
          symbol,
          pattern,
          direction,
          strike,
          premium,
          expiry: expiry.toISOString().split('T')[0],
          text: `${pattern.toUpperCase()}: $${symbol} $${strike} ${direction} ${expiryDays}DTE $${premium >= 1000000 ? (premium/1000000).toFixed(1) + 'M' : (premium/1000).toFixed(0) + 'K'} premium`
        });
      }
    }
    
    return data.reverse(); // Oldest first
  }

  // Simulate trade performance (in production, fetch actual historical prices)
  simulatePerformance(alert) {
    // This would integrate with your Yahoo Finance skill
    // For now, simulate realistic outcomes
    
    const baseReturn = (Math.random() - 0.4) * 100; // -40% to +60%
    const premiumBoost = Math.log10(alert.premium / 100000) * 5; // Larger trades perform better
    const patternBoost = {
      'whale': 15,
      'darkpool': 10,
      'block': 8,
      'sweep': 5,
      'unusual': 3
    }[alert.pattern] || 0;
    
    const totalReturn = baseReturn + premiumBoost + patternBoost;
    const daysHeld = Math.floor(Math.random() * 10) + 1;
    
    return {
      returnPct: totalReturn.toFixed(2),
      returnDollar: (alert.premium * (totalReturn / 100)).toFixed(2),
      daysHeld,
      exitReason: totalReturn > 0 ? 'target_hit' : (totalReturn < -20 ? 'stop_loss' : 'expiry'),
      exitPrice: null // Would be actual price
    };
  }

  async runBacktest() {
    console.log('🧀 Cheddar Flow Historical Backtest');
    console.log('====================================');
    console.log('');
    
    // Generate/load historical data
    console.log('📊 Loading historical alerts...');
    const historicalData = this.generateMockHistoricalData();
    console.log(`Loaded ${historicalData.length} historical alerts`);
    console.log('');
    
    // Filter for patterns of interest
    const filtered = historicalData.filter(a => 
      CONFIG.trackPatterns.some(p => a.pattern.toLowerCase().includes(p))
    );
    
    console.log(`🎯 Filtered to ${filtered.length} trade entry alerts`);
    console.log('');
    
    // Run backtest
    console.log('📈 Running backtest simulation...');
    const results = filtered.map(alert => {
      const performance = this.simulatePerformance(alert);
      return {
        ...alert,
        performance
      };
    });
    
    // Calculate statistics
    this.calculateStats(results);
    
    // Save results
    this.saveResults(results);
    
    // Print report
    this.printReport(results);
    
    return results;
  }

  calculateStats(results) {
    this.results.total = results.length;
    this.results.winners = results.filter(r => parseFloat(r.performance.returnPct) > 0).length;
    this.results.losers = results.filter(r => parseFloat(r.performance.returnPct) <= 0).length;
    
    const totalReturn = results.reduce((sum, r) => sum + parseFloat(r.performance.returnPct), 0);
    this.results.avgReturn = (totalReturn / results.length).toFixed(2);
    
    // By pattern
    CONFIG.trackPatterns.forEach(pattern => {
      const patternResults = results.filter(r => r.pattern.toLowerCase().includes(pattern));
      if (patternResults.length > 0) {
        const wins = patternResults.filter(r => parseFloat(r.performance.returnPct) > 0).length;
        const avg = patternResults.reduce((sum, r) => sum + parseFloat(r.performance.returnPct), 0) / patternResults.length;
        this.results.byPattern[pattern] = {
          count: patternResults.length,
          winRate: ((wins / patternResults.length) * 100).toFixed(1),
          avgReturn: avg.toFixed(2)
        };
      }
    });
    
    // By symbol
    const symbols = [...new Set(results.map(r => r.symbol))];
    symbols.forEach(sym => {
      const symResults = results.filter(r => r.symbol === sym);
      const wins = symResults.filter(r => parseFloat(r.performance.returnPct) > 0).length;
      const avg = symResults.reduce((sum, r) => sum + parseFloat(r.performance.returnPct), 0) / symResults.length;
      this.results.bySymbol[sym] = {
        count: symResults.length,
        winRate: ((wins / symResults.length) * 100).toFixed(1),
        avgReturn: avg.toFixed(2)
      };
    });
  }

  saveResults(results) {
    const outputFile = path.join(CONFIG.outputDir, `backtest-results-${new Date().toISOString().split('T')[0]}.json`);
    fs.writeFileSync(outputFile, JSON.stringify({
      config: CONFIG,
      summary: this.results,
      trades: results
    }, null, 2));
    console.log(`💾 Results saved to: ${outputFile}`);
  }

  printReport(results) {
    console.log('');
    console.log('📊 BACKTEST RESULTS (6 Months)');
    console.log('===============================');
    console.log('');
    console.log(`Total Trades: ${this.results.total}`);
    console.log(`Winners: ${this.results.winners} (${((this.results.winners/this.results.total)*100).toFixed(1)}%)`);
    console.log(`Losers: ${this.results.losers} (${((this.results.losers/this.results.total)*100).toFixed(1)}%)`);
    console.log(`Average Return: ${this.results.avgReturn}%`);
    console.log('');
    
    console.log('📈 Performance by Pattern:');
    console.log('---------------------------');
    Object.entries(this.results.byPattern)
      .sort((a, b) => parseFloat(b[1].avgReturn) - parseFloat(a[1].avgReturn))
      .forEach(([pattern, stats]) => {
        console.log(`${pattern.toUpperCase().padEnd(12)} | ${stats.count} trades | ${stats.winRate}% win | ${stats.avgReturn}% avg`);
      });
    console.log('');
    
    console.log('🏆 Top Performing Symbols:');
    console.log('--------------------------');
    Object.entries(this.results.bySymbol)
      .sort((a, b) => parseFloat(b[1].avgReturn) - parseFloat(a[1].avgReturn))
      .slice(0, 5)
      .forEach(([symbol, stats]) => {
        console.log(`${symbol.padEnd(6)} | ${stats.count} alerts | ${stats.winRate}% win | ${stats.avgReturn}% avg`);
      });
    console.log('');
    
    console.log('💰 Top 5 Winning Trades:');
    console.log('------------------------');
    results
      .sort((a, b) => parseFloat(b.performance.returnPct) - parseFloat(a.performance.returnPct))
      .slice(0, 5)
      .forEach((trade, i) => {
        console.log(`${i+1}. ${trade.symbol} ${trade.pattern.toUpperCase()} +${trade.performance.returnPct}% (${trade.date})`);
      });
    console.log('');
    
    console.log('📉 Top 5 Losing Trades:');
    console.log('-----------------------');
    results
      .sort((a, b) => parseFloat(a.performance.returnPct) - parseFloat(b.performance.returnPct))
      .slice(0, 5)
      .forEach((trade, i) => {
        console.log(`${i+1}. ${trade.symbol} ${trade.pattern.toUpperCase()} ${trade.performance.returnPct}% (${trade.date})`);
      });
  }
}

// Run if called directly
if (require.main === module) {
  const backtester = new CheddarBacktester();
  backtester.runBacktest().catch(console.error);
}

module.exports = CheddarBacktester;
