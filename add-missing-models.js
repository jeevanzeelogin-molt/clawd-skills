#!/usr/bin/env node
/**
 * Add Missing Models to Clawdbot Config
 * Directly modifies ~/.clawdbot/clawdbot.json
 */

const fs = require('fs');
const path = require('path');

const CONFIG_FILE = path.join(process.env.HOME, '.clawdbot/clawdbot.json');

// Read current config
let config;
try {
  config = JSON.parse(fs.readFileSync(CONFIG_FILE, 'utf8'));
} catch (error) {
  console.error('❌ Failed to read config:', error.message);
  process.exit(1);
}

// Ensure models structure
if (!config.models) config.models = { mode: 'merge', providers: {} };
if (!config.models.providers) config.models.providers = {};

// Add Gemini provider
config.models.providers.gemini = {
  baseUrl: "https://generativelanguage.googleapis.com/v1beta",
  apiKey: "${GEMINI_API_KEY}",
  api: "gemini",
  models: [
    {
      id: "gemini-2.0-flash-exp",
      name: "Gemini 2.0 Flash",
      reasoning: false,
      input: ["text", "image"],
      cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
      contextWindow: 1000000,
      maxTokens: 8192
    },
    {
      id: "gemini-exp-1206",
      name: "Gemini Experimental",
      reasoning: true,
      input: ["text", "image"],
      cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
      contextWindow: 1000000,
      maxTokens: 8192
    }
  ]
};

// Add Anthropic provider (Claude)
config.models.providers.anthropic = {
  baseUrl: "https://api.anthropic.com/v1",
  apiKey: "${ANTHROPIC_API_KEY}",
  api: "anthropic-messages",
  models: [
    {
      id: "claude-3-5-haiku-20241022",
      name: "Claude 3.5 Haiku",
      reasoning: false,
      input: ["text", "image"],
      cost: { input: 0.8, output: 4.0, cacheRead: 0.08, cacheWrite: 1.0 },
      contextWindow: 200000,
      maxTokens: 8192
    },
    {
      id: "claude-3-5-sonnet-20241022",
      name: "Claude 3.5 Sonnet",
      reasoning: true,
      input: ["text", "image"],
      cost: { input: 3.0, output: 15.0, cacheRead: 0.3, cacheWrite: 3.75 },
      contextWindow: 200000,
      maxTokens: 8192
    }
  ]
};

// Add model aliases
if (!config.agents) config.agents = {};
if (!config.agents.defaults) config.agents.defaults = {};
if (!config.agents.defaults.models) config.agents.defaults.models = {};

config.agents.defaults.models["gemini/gemini-2.0-flash-exp"] = { alias: "Gemini Flash" };
config.agents.defaults.models["gemini/gemini-exp-1206"] = { alias: "Gemini Exp" };
config.agents.defaults.models["anthropic/claude-3-5-haiku-20241022"] = { alias: "Claude Haiku" };
config.agents.defaults.models["anthropic/claude-3-5-sonnet-20241022"] = { alias: "Claude Sonnet" };

// Add auth profiles
if (!config.auth) config.auth = {};
if (!config.auth.profiles) config.auth.profiles = {};

config.auth.profiles["gemini:backup"] = { provider: "gemini", mode: "api_key" };
config.auth.profiles["anthropic:default"] = { provider: "anthropic", mode: "api_key" };

if (!config.auth.order) config.auth.order = {};
config.auth.order["gemini"] = ["gemini:backup"];
config.auth.order["anthropic"] = ["anthropic:default"];

// Write updated config
fs.writeFileSync(CONFIG_FILE, JSON.stringify(config, null, 2));

console.log('✅ Models added successfully!');
console.log('');
console.log('📊 Available Models:');
console.log('  🟣 Kimi Code (Primary)');
console.log('  🟣 Kimi K2 (Smart)');
console.log('  🔵 Gemini Flash (FREE)');
console.log('  🔵 Gemini Exp (FREE)');
console.log('  🟡 Claude Haiku (Fast)');
console.log('  🟡 Claude Sonnet (Deep)');
console.log('');
console.log('🔄 Restart gateway to apply changes:');
console.log('  clawdbot gateway restart');
