#!/usr/bin/env node
/**
 * Live Dashboard - Nemotrades Portfolio Optimizer
 * Real-time updates on backtest improvements
 */

const fs = require('fs');
const path = require('path');
const { PORTFOLIO, STRATEGIES } = require('./config');

const STATUS_FILE = path.join(__dirname, '../status.json');

function loadStatus() {
  if (!fs.existsSync(STATUS_FILE)) {
    return {
      phase: 'idle',
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
  return JSON.parse(fs.readFileSync(STATUS_FILE, 'utf8'));
}

function displayDashboard() {
  const status = loadStatus();
  
  console.clear();
  console.log('╔══════════════════════════════════════════════════════════════════╗');
  console.log('║        🚀 NEMOTRADES PORTFOLIO OPTIMIZER - LIVE DASHBOARD       ║');
  console.log('╚══════════════════════════════════════════════════════════════════╝');
  console.log('');
  
  // Portfolio Overview
  console.log('📈 PORTFOLIO OVERVIEW');
  console.log('────────────────────────────────────────────────────────────────────');
  console.log(`Portfolio ID: ${PORTFOLIO.id}`);
  console.log(`Baseline MAR: ${PORTFOLIO.baseline.mar} (excellent)`);
  console.log(`Current MAR:  ${status.portfolioMetrics.currentMAR.toFixed(1)}`);
  console.log(`Target MAR:   ${PORTFOLIO.target.mar}`);
  
  const progress = ((status.portfolioMetrics.currentMAR - PORTFOLIO.baseline.mar) / 
    (PORTFOLIO.target.mar - PORTFOLIO.baseline.mar) * 100);
  console.log(`Progress:     ${Math.max(0, Math.min(100, progress)).toFixed(1)}% to target`);
  console.log('');
  
  // Status
  console.log('🔄 CURRENT STATUS');
  console.log('────────────────────────────────────────────────────────────────────');
  console.log(`Phase: ${status.phase.toUpperCase()}`);
  
  if (status.currentStrategy) {
    console.log(`Optimizing: ${status.currentStrategy}`);
  }
  
  console.log(`Strategies Completed: ${status.completedStrategies.length} / ${STRATEGIES.length}`);
  console.log(`Improvements Found: ${status.improvements.length}`);
  console.log(`Last Updated: ${new Date(status.lastUpdated).toLocaleString()}`);
  console.log('');
  
  // Improvements
  if (status.improvements.length > 0) {
    console.log('✅ RECENT IMPROVEMENTS');
    console.log('────────────────────────────────────────────────────────────────────');
    
    status.improvements
      .sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp))
      .slice(0, 5)
      .forEach((imp, i) => {
        const improvement = imp.improvement > 0 ? '+' + imp.improvement.toFixed(1) : imp.improvement.toFixed(1);
        console.log(`${i + 1}. ${imp.strategy}`);
        console.log(`   MAR: ${imp.originalMAR.toFixed(1)} → ${imp.optimizedMAR.toFixed(1)} (${improvement})`);
        console.log(`   Change: ${imp.changes}`);
        console.log('');
      });
  }
  
  // Strategy Queue
  console.log('📋 NEXT UP');
  console.log('────────────────────────────────────────────────────────────────────');
  
  const remaining = STRATEGIES
    .filter(s => !status.completedStrategies.includes(s.name))
    .sort((a, b) => b.baselineMAR - a.baselineMAR)
    .slice(0, 3);
  
  if (remaining.length === 0) {
    console.log('✅ All strategies optimized!');
  } else {
    remaining.forEach((s, i) => {
      const emoji = s.status === 'top_performer' ? '🌟' : 
                    s.status === 'star_performer' ? '⭐' : '📊';
      console.log(`${i + 1}. ${emoji} ${s.name} (MAR: ${s.baselineMAR})`);
    });
  }
  
  console.log('');
  console.log('═══════════════════════════════════════════════════════════════════');
  console.log('Commands: optimize | dashboard | status | reset');
  console.log('═══════════════════════════════════════════════════════════════════');
}

// Watch mode - auto refresh
function watchMode() {
  displayDashboard();
  
  // Refresh every 5 seconds
  setInterval(() => {
    displayDashboard();
  }, 5000);
  
  console.log('\n👀 Watching for updates... (Press Ctrl+C to exit)');
}

// Command handling
const command = process.argv[2];

switch (command) {
  case 'watch':
    watchMode();
    break;
  case 'status':
    displayDashboard();
    break;
  default:
    displayDashboard();
}

module.exports = { displayDashboard };
