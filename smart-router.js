#!/usr/bin/env node
/**
 * Smart Model Router
 * Routes tasks to the most cost-effective AI model based on complexity
 */

const fs = require('fs');
const path = require('path');

const CONFIG_FILE = path.join(process.env.HOME, '.clawdbot/smart-router-config.json');
const STATS_FILE = path.join(process.env.HOME, '.clawdbot/routing-stats.json');

// Default configuration
const DEFAULT_CONFIG = {
  defaultTier: 'standard',
  fallbackOrder: ['gemini', 'kimi', 'claude'],
  costLimits: {
    dailyMax: 5.00,
    warningAt: 3.00
  },
  models: {
    gemini: {
      name: 'Gemini Flash',
      costPer1M: 0,
      contextWindow: 1000000,
      bestFor: ['bulk', 'extraction', 'formatting']
    },
    kimi: {
      name: 'Kimi Code',
      costPer1M: 0.5,
      contextWindow: 256000,
      bestFor: ['standard', 'analysis', 'coding']
    },
    kimiK2: {
      name: 'Kimi K2',
      costPer1M: 1.0,
      contextWindow: 256000,
      bestFor: ['complex', 'reasoning', 'synthesis']
    },
    claude: {
      name: 'Claude Sonnet',
      costPer1M: 15.0,
      contextWindow: 200000,
      bestFor: ['critical', 'debugging', 'architecture']
    }
  }
};

// Keywords for complexity detection
const COMPLEXITY_KEYWORDS = {
  bulk: [
    'summarize csv', 'extract all', 'format list', 'convert to json',
    'find highest', 'find lowest', 'count', 'list all', 'parse',
    'bulk', 'extract tickers', 'get symbols'
  ],
  standard: [
    'why is', 'compare', 'explain', 'what is', 'how to',
    'write python', 'plot', 'chart', 'analyze', 'summary'
  ],
  complex: [
    'multi-leg', 'strategy', 'build skill', 'scrape', 'portfolio',
    'hedging', 'synthesize', 'architecture', 'design'
  ],
  critical: [
    'debug', 'fix error', 'complex error', 'deep analysis',
    'probability', 'architect', 'system design'
  ]
};

function loadConfig() {
  try {
    return JSON.parse(fs.readFileSync(CONFIG_FILE, 'utf8'));
  } catch {
    return DEFAULT_CONFIG;
  }
}

function loadStats() {
  try {
    return JSON.parse(fs.readFileSync(STATS_FILE, 'utf8'));
  } catch {
    return { 
      totalRequests: 0, 
      byTier: { bulk: 0, standard: 0, complex: 0, critical: 0 },
      estimatedCost: 0,
      dailyStats: {}
    };
  }
}

function saveStats(stats) {
  fs.writeFileSync(STATS_FILE, JSON.stringify(stats, null, 2));
}

function detectComplexity(request) {
  const lowerRequest = request.toLowerCase();
  
  // Check for critical keywords first
  for (const keyword of COMPLEXITY_KEYWORDS.critical) {
    if (lowerRequest.includes(keyword)) return 'critical';
  }
  
  // Check for complex keywords
  for (const keyword of COMPLEXITY_KEYWORDS.complex) {
    if (lowerRequest.includes(keyword)) return 'complex';
  }
  
  // Check for bulk keywords
  for (const keyword of COMPLEXITY_KEYWORDS.bulk) {
    if (lowerRequest.includes(keyword)) return 'bulk';
  }
  
  // Check for standard keywords
  for (const keyword of COMPLEXITY_KEYWORDS.standard) {
    if (lowerRequest.includes(keyword)) return 'standard';
  }
  
  // Check request length - longer = more complex
  if (lowerRequest.length > 500) return 'complex';
  if (lowerRequest.length > 200) return 'standard';
  
  // Default
  return 'standard';
}

function routeToModel(tier, config) {
  const tierToModel = {
    bulk: 'gemini',
    standard: 'kimi',
    complex: 'kimiK2',
    critical: 'claude'
  };
  
  const modelKey = tierToModel[tier] || 'kimi';
  return config.models[modelKey];
}

function calculateCost(model, inputTokens = 2000, outputTokens = 500) {
  const inputCost = (inputTokens / 1000000) * model.costPer1M;
  const outputCost = (outputTokens / 1000000) * (model.costPer1M * 5); // Output usually 5x
  return inputCost + outputCost;
}

function main() {
  const args = process.argv.slice(2);
  const request = args[0] || '';
  const forcedTier = args[1];
  
  if (!request) {
    console.log('Smart Model Router');
    console.log('Usage: smart-router "your request here" [tier]');
    console.log('Tiers: bulk, standard, complex, critical');
    console.log('');
    console.log('Examples:');
    console.log('  smart-router "summarize this CSV"');
    console.log('  smart-router "debug this error" critical');
    process.exit(0);
  }
  
  const config = loadConfig();
  const stats = loadStats();
  
  // Detect or use forced tier
  const tier = forcedTier || detectComplexity(request);
  const model = routeToModel(tier, config);
  const estimatedCost = calculateCost(model);
  
  // Update stats
  const today = new Date().toISOString().split('T')[0];
  if (!stats.dailyStats[today]) {
    stats.dailyStats[today] = { requests: 0, cost: 0 };
  }
  
  stats.totalRequests++;
  stats.byTier[tier]++;
  stats.estimatedCost += estimatedCost;
  stats.dailyStats[today].requests++;
  stats.dailyStats[today].cost += estimatedCost;
  
  saveStats(stats);
  
  // Output routing decision
  const result = {
    request: request.substring(0, 100) + (request.length > 100 ? '...' : ''),
    detectedTier: tier,
    selectedModel: model.name,
    modelKey: Object.keys(config.models).find(k => config.models[k] === model),
    estimatedCost: `$${estimatedCost.toFixed(4)}`,
    reason: forcedTier ? 'User forced tier' : 'Auto-detected complexity',
    savings: tier === 'bulk' ? 'Using FREE Gemini!' : null
  };
  
  console.log(JSON.stringify(result, null, 2));
  
  // Budget warning
  const dailyCost = stats.dailyStats[today].cost;
  if (dailyCost > config.costLimits.warningAt) {
    console.log(`\n⚠️  BUDGET WARNING: $${dailyCost.toFixed(2)} spent today (Limit: $${config.costLimits.dailyMax})`);
    console.log('   Consider using "bulk" tier for simple tasks to save money.');
  }
}

main();
