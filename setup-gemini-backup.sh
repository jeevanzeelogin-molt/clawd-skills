#!/bin/bash
# Gemini Backup Setup Script
# Run this after adding your Gemini API key

echo "🔧 Setting up Gemini as Backup Provider"
echo "========================================="
echo ""

# Load current env
export $(grep -v '^#' ~/.clawdbot/.env | xargs)

# Check if Gemini key is set
if [ -z "$GEMINI_API_KEY" ]; then
    echo "❌ GEMINI_API_KEY not found!"
    echo ""
    echo "To set up Gemini backup:"
    echo "1. Get your free API key at: https://aistudio.google.com/app/apikey"
    echo "2. Add it to ~/.clawdbot/.env:"
    echo "   export GEMINI_API_KEY='your_key_here'"
    echo ""
    exit 1
fi

echo "✅ GEMINI_API_KEY found!"
echo ""
echo "📝 Adding Gemini configuration to Clawdbot..."

# Create the config patch
clawdbot config apply << 'EOF'
{
  "models": {
    "mode": "merge",
    "providers": {
      "gemini": {
        "baseUrl": "https://generativelanguage.googleapis.com/v1beta",
        "apiKey": "${GEMINI_API_KEY}",
        "api": "gemini",
        "models": [
          {
            "id": "gemini-2.0-flash-exp",
            "name": "Gemini 2.0 Flash",
            "reasoning": false,
            "input": ["text", "image"],
            "cost": {
              "input": 0,
              "output": 0,
              "cacheRead": 0,
              "cacheWrite": 0
            },
            "contextWindow": 1000000,
            "maxTokens": 8192
          }
        ]
      }
    }
  },
  "agents": {
    "defaults": {
      "models": {
        "gemini/gemini-2.0-flash-exp": {
          "alias": "Gemini Flash"
        }
      }
    }
  },
  "auth": {
    "profiles": {
      "gemini:backup": {
        "provider": "gemini",
        "mode": "api_key"
      }
    },
    "order": {
      "gemini": [
        "gemini:backup"
      ]
    }
  }
}
EOF

echo ""
echo "✅ Gemini backup configured!"
echo ""
echo "📊 Configuration Summary:"
echo "  Primary: Kimi Code"
echo "  Backup: Gemini Flash (Free Tier)"
echo ""
echo "🚀 To switch to Gemini backup manually:"
echo "  ./switch-provider.sh gemini"
echo ""
echo "🔄 Restarting gateway..."
clawdbot gateway restart

echo ""
echo "✨ Setup complete!"
