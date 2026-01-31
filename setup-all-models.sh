#!/bin/bash
# Setup Missing AI Models
# Adds Gemini and Claude to your Clawdbot configuration

echo "🤖 Setting up missing AI models..."
echo "=================================="
echo ""

# Load env
export $(grep -v '^#' ~/.clawdbot/.env | xargs)

# Check which models are missing
MISSING=""

if [ -z "$GEMINI_API_KEY" ] || [ "$GEMINI_API_KEY" = "" ]; then
    echo "❌ Gemini API key not found"
    MISSING="$MISSING gemini"
else
    echo "✅ Gemini API key found"
fi

if [ -z "$ANTHROPIC_API_KEY" ]; then
    echo "❌ Anthropic (Claude) API key not found"
    MISSING="$MISSING claude"
else
    echo "✅ Anthropic API key found"
fi

echo ""

# Function to add Gemini
add_gemini() {
    echo "📝 Adding Gemini provider..."
    
    # Create temporary config file
    cat > /tmp/gemini-config.json << 'EOF'
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
      }
    }
  },
  "agents": {
    "defaults": {
      "models": {
        "gemini/gemini-2.0-flash-exp": { "alias": "Gemini Flash" },
        "gemini/gemini-exp-1206": { "alias": "Gemini Exp" }
      }
    }
  },
  "auth": {
    "profiles": {
      "gemini:backup": { "provider": "gemini", "mode": "api_key" }
    }
  }
}
EOF
    
    clawdbot config patch --file /tmp/gemini-config.json
    echo "✅ Gemini added!"
}

# Function to add Claude
add_claude() {
    echo "📝 Adding Claude provider..."
    
    cat > /tmp/claude-config.json << 'EOF'
{
  "models": {
    "mode": "merge",
    "providers": {
      "anthropic": {
        "baseUrl": "https://api.anthropic.com/v1",
        "apiKey": "${ANTHROPIC_API_KEY}",
        "api": "anthropic-messages",
        "models": [
          {
            "id": "claude-3-5-haiku-20241022",
            "name": "Claude 3.5 Haiku",
            "reasoning": false,
            "input": ["text", "image"],
            "cost": { "input": 0.8, "output": 4.0, "cacheRead": 0.08, "cacheWrite": 1.0 },
            "contextWindow": 200000,
            "maxTokens": 8192
          },
          {
            "id": "claude-3-5-sonnet-20241022",
            "name": "Claude 3.5 Sonnet",
            "reasoning": true,
            "input": ["text", "image"],
            "cost": { "input": 3.0, "output": 15.0, "cacheRead": 0.3, "cacheWrite": 3.75 },
            "contextWindow": 200000,
            "maxTokens": 8192
          }
        ]
      }
    }
  },
  "agents": {
    "defaults": {
      "models": {
        "anthropic/claude-3-5-haiku-20241022": { "alias": "Claude Haiku" },
        "anthropic/claude-3-5-sonnet-20241022": { "alias": "Claude Sonnet" }
      }
    }
  },
  "auth": {
    "profiles": {
      "anthropic:default": { "provider": "anthropic", "mode": "api_key" }
    }
  }
}
EOF
    
    clawdbot config patch --file /tmp/claude-config.json
    echo "✅ Claude added!"
}

# Main setup
if [ -n "$GEMINI_API_KEY" ] && [ "$GEMINI_API_KEY" != "" ]; then
    add_gemini
fi

if [ -n "$ANTHROPIC_API_KEY" ]; then
    add_claude
fi

echo ""
echo "🔄 Restarting gateway to apply changes..."
clawdbot gateway restart

echo ""
echo "📊 Available Models:"
echo "  🟣 Kimi Code (Primary)"
echo "  🟣 Kimi K2 (Smart)"
if [ -n "$GEMINI_API_KEY" ] && [ "$GEMINI_API_KEY" != "" ]; then
    echo "  🔵 Gemini Flash (Backup - FREE)"
fi
if [ -n "$ANTHROPIC_API_KEY" ]; then
    echo "  🟡 Claude Haiku (Fast)"
    echo "  🟡 Claude Sonnet (Deep)"
fi

echo ""
echo "💡 To add missing API keys:"
if [ -z "$ANTHROPIC_API_KEY" ]; then
    echo "  • Claude: Get key at https://console.anthropic.com/"
    echo "    Add to ~/.clawdbot/.env: export ANTHROPIC_API_KEY='your_key'"
fi

echo ""
echo "✨ Setup complete!"
