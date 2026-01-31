#!/usr/bin/env node
// Add Gemini provider to config

const fs = require('fs');
const path = require('path');

const CONFIG_FILE = path.join(process.env.HOME, '.clawdbot/clawdbot.json');

let config = JSON.parse(fs.readFileSync(CONFIG_FILE, 'utf8'));

// Add Gemini provider
config.models.providers.gemini = {
  "baseUrl": "https://generativelanguage.googleapis.com/v1beta",
  "apiKey": "${GEMINI_API_KEY}",
  "api": "gemini",
  "models": [
    {
      "id": "gemini-2.0-flash-exp",
      "name": "Gemini 2.0 Flash",
      "reasoning": false,
      "input": ["text", "image"],
      "cost": { "input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0 },
      "contextWindow": 1000000,
      "maxTokens": 8192
    },
    {
      "id": "gemini-exp-1206",
      "name": "Gemini Experimental",
      "reasoning": true,
      "input": ["text", "image"],
      "cost": { "input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0 },
      "contextWindow": 1000000,
      "maxTokens": 8192
    }
  ]
};

// Add auth profile if not exists
if (!config.auth.profiles['gemini:backup']) {
  config.auth.profiles['gemini:backup'] = {
    "provider": "gemini",
    "mode": "api_key"
  };
}

// Add to auth order
if (!config.auth.order.gemini) {
  config.auth.order.gemini = ['gemini:backup'];
}

fs.writeFileSync(CONFIG_FILE, JSON.stringify(config, null, 2));
console.log('✅ Gemini provider added!');
