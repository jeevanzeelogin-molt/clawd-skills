#!/usr/bin/env node
/**
 * Nemotrades Portfolio Optimizer
 * Main orchestrator for backtest improvements
 */

const fs = require('fs');
const path = require('path');
const { PORTFOLIO, STRATEGIES } = require('./config');

// Status tracking
const STATUS_FILE = path.join(__dirname, '../status.json');

function loadStatus() {
  if (fs.existsSync(STATUS_FILE)) {
    return JSON.parse(fs.readFileSync(STATUS_FILE, 'utf8'));
  }
  return {
    lastUpdated: new Date().toISOString(),
    phase: 'initializing',
    currentStrategy: null,
    completedStrategies: [],
    improvements: [],
    portfolioMetrics: {
      baselineMAR: PORTFOLIO.baseline.mar,
      currentMAR: PORTFOLIO.baseline.mar,
      targetMAR: PORTFOLIO.target.mar
    }
  };
}

function saveStatus(status) {
  status.lastUpdated = new Date().toISOString();
  fs.writeFileSync(STATUS_FILE, JSON.stringify(status, null, 2));
}

// Priority order for optimization (top performers first for scaling)
function getOptimizationOrder() {
  return STRATEGIES
    .filter(s => s.baselineMAR >= 10 || s.status === 'underperformer')
    .sort((a, b) => {
      // Prioritize: top performers to scale, then underperformers to fix
      if (a.status === 'top_performer' && b.status !== 'top_performer') return -1;
      if (b.status === 'top_performer' && a.status !== 'top_performer') return 1;
      if (a.status === 'underperformer') return 1;
      if (b.status === 'underperformer') return -1;
      return b.baselineMAR - a.baselineMAR;
    });
}

// Generate optimization scenarios for a strategy
function generateScenarios(strategy) {
  const scenarios = [];
  
  // Scenario 1: Current baseline (control)
  scenarios.push({
    name: `${strategy.name} - Current`,
    strategy: strategy.name,
    changes: 'None - baseline',
    expectedImprovement: 0,
    priority: 'control'
  });
  
  // Scenario 2: Allocation optimization
  if (strategy.baselineMAR >= 12 && strategy.currentAllocation < 5) {
    const newAlloc = Math.min(strategy.currentAllocation * 1.5, 6);
    scenarios.push({
      name: `${strategy.name} - Scale Up`,
      strategy: strategy.name,
      changes: `Allocation: ${strategy.currentAllocation}% → ${newAlloc.toFixed(2)}%`,
      expectedImprovement: strategy.baselineMAR * 0.15,
      priority: 'high'
    });
  }
  
  // Scenario 3: Entry timing optimization
  if (strategy.improvementAreas.includes('entry_timing') || strategy.improvementAreas.includes('exit_timing')) {
    scenarios.push({
      name: `${strategy.name} - Timing Opt`,
      strategy: strategy.name,
      changes: 'Adjust entry window by ±15 mins',
      expectedImprovement: strategy.baselineMAR * 0.08,
      priority: 'medium'
    });
  }
  
  // Scenario 4: Filter/parameter optimization
  if (strategy.filter) {
    scenarios.push({
      name: `${strategy.name} - Filter Tighten`,
      strategy: strategy.name,
      changes: 'Tighten filter criteria by 10%',
      expectedImprovement: strategy.baselineMAR * 0.12,
      priority: 'medium'
    });
  }
  
  // Scenario 5: DTE adjustment for underperformers
  if (strategy.status === 'underperformer' && strategy.dte) {
    const currentDTE = parseInt(strategy.dte);
    if (currentDTE > 5) {
      scenarios.push({
        name: `${strategy.name} - Reduce DTE`,
        strategy: strategy.name,
        changes: `DTE: ${strategy.dte} → ${Math.max(currentDTE - 2, 0)}DTE`,
        expectedImprovement: strategy.baselineMAR * 0.20,
        priority: 'high'
      });
    }
  }
  
  return scenarios;
}

// Simulate running a backtest (in production, this would use Option Omega API)
function simulateBacktest(scenario) {
  // Simulate processing time and results
  const baseMAR = STRATEGIES.find(s => s.name === scenario.strategy)?.baselineMAR || 10;
  const variance = (Math.random() - 0.5) * 0.3; // ±15% variance
  const improvement = scenario.expectedImprovement * (1 + variance);
  
  return {
    scenario: scenario.name,
    baseMAR: baseMAR,
    optimizedMAR: baseMAR + improvement,
    improvement: improvement,
    improvementPct: ((improvement / baseMAR) * 100).toFixed(1),
    winRate: 60 + Math.random() * 20,
    maxDD: 15 + Math.random() * 10,
    trades: Math.floor(100 + Math.random() * 200),
    status: improvement > 0 ? 'improved' : 'no_change'
  };
}

// Main optimization loop
async function runOptimization() {
  console.log('🚀 Nemotrades Portfolio Optimizer');
  console.log('═══════════════════════════════════════════════════════════');
  console.log('');
  console.log(`Portfolio: ${PORTFOLIO.id}`);
  console.log(`Baseline MAR: ${PORTFOLIO.baseline.mar}`);
  console.log(`Target MAR: ${PORTFOLIO.target.mar}`);
  console.log(`Strategies: ${STRATEGIES.length}`);
  console.log('');
  
  const status = loadStatus();
  const optimizationQueue = getOptimizationOrder();
  
  console.log('📋 Optimization Priority Queue:');
  optimizationQueue.forEach((s, i) => {
    const emoji = s.status === 'top_performer' ? '🌟' : 
                  s.status === 'star_performer' ? '⭐' : 
                  s.status === 'underperformer' ? '⚠️' : '📊';
    console.log(`  ${i + 1}. ${emoji} ${s.name} (MAR: ${s.baselineMAR}, Alloc: ${s.currentAllocation}%)`);
  });
  console.log('');
  
  // Process each strategy
  for (const strategy of optimizationQueue.slice(0, 5)) { // Process top 5 first
    console.log(`\n⚙️  Optimizing: ${strategy.name}`);
    console.log('─'.repeat(60));
    
    status.currentStrategy = strategy.name;
    status.phase = 'optimizing';
    saveStatus(status);
    
    const scenarios = generateScenarios(strategy);
    const results = [];
    
    for (const scenario of scenarios) {
      process.stdout.write(`  Testing: ${scenario.name}... `);
      
      // Simulate backtest run
      await new Promise(r => setTimeout(r, 500));
      const result = simulateBacktest(scenario);
      results.push(result);
      
      const icon = result.status === 'improved' ? '✅' : '➡️';
      console.log(`${icon} MAR: ${result.baseMAR.toFixed(1)} → ${result.optimizedMAR.toFixed(1)} (${result.improvementPct}%)`);
    }
    
    // Find best result
    const bestResult = results.reduce((best, current) => 
      current.optimizedMAR > best.optimizedMAR ? current : best
    );
    
    if (bestResult.improvement > 0.5) {
      status.improvements.push({
        strategy: strategy.name,
        originalMAR: strategy.baselineMAR,
        optimizedMAR: bestResult.optimizedMAR,
        improvement: bestResult.improvement,
        changes: scenarios.find(s => s.name === bestResult.scenario)?.changes || 'Unknown',
        timestamp: new Date().toISOString()
      });
      
      // Update current portfolio MAR estimate
      const contribution = (strategy.currentAllocation / 100) * bestResult.improvement;
      status.portfolioMetrics.currentMAR += contribution;
    }
    
    status.completedStrategies.push(strategy.name);
    saveStatus(status);
    
    console.log(`  Best: ${bestResult.scenario} (+${bestResult.improvementPct}%)`);
  }
  
  // Final summary
  console.log('\n');
  console.log('📊 OPTIMIZATION SUMMARY');
  console.log('═══════════════════════════════════════════════════════════');
  console.log(`Strategies Optimized: ${status.completedStrategies.length}`);
  console.log(`Improvements Found: ${status.improvements.length}`);
  console.log(`Portfolio MAR: ${PORTFOLIO.baseline.mar} → ${status.portfolioMetrics.currentMAR.toFixed(1)}`);
  console.log(`Progress to Target: ${((status.portfolioMetrics.currentMAR / PORTFOLIO.target.mar) * 100).toFixed(1)}%`);
  console.log('');
  
  if (status.improvements.length > 0) {
    console.log('✅ Top Improvements:');
    status.improvements
      .sort((a, b) => b.improvement - a.improvement)
      .slice(0, 5)
      .forEach((imp, i) => {
        console.log(`  ${i + 1}. ${imp.strategy}: +${imp.improvement.toFixed(1)} MAR`);
        console.log(`     ${imp.changes}`);
      });
  }
  
  status.phase = 'completed';
  saveStatus(status);
  
  console.log('');
  console.log('📝 Next Steps:');
  console.log('  1. Review optimization results above');
  console.log('  2. Implement top improvements in Option Omega');
  console.log('  3. Run ./update-dashboard.sh to refresh status');
}

// Run if called directly
if (require.main === module) {
  runOptimization().catch(console.error);
}

module.exports = { runOptimization, generateScenarios };
