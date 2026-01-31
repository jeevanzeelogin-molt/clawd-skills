#!/bin/bash
# Kimi Code CLI Setup Script

echo "🚀 Setting up Kimi Code CLI..."

# Check if already installed
if ! command -v kimi &> /dev/null; then
    echo "📦 Installing kimi-code..."
    npm install -g kimi-code
fi

if ! command -v claude &> /dev/null; then
    echo "📦 Installing claude-code..."
    npm install -g @anthropic-ai/claude-code
fi

# Load API key from .env
export $(grep -v '^#' ~/.clawdbot/.env | xargs)

if [ -z "$MOONSHOT_API_KEY" ]; then
    echo "❌ MOONSHOT_API_KEY not found in ~/.clawdbot/.env"
    echo "Please add your Moonshot API key to the .env file"
    exit 1
fi

echo "🔐 Configuring Kimi Code with Moonshot API..."
kimi -k "$MOONSHOT_API_KEY" --base-url "https://api.moonshot.ai/v1" \
    --reasoning-model "kimi-k2-0905-preview" \
    --completion-model "kimi-k2-0905-preview"
