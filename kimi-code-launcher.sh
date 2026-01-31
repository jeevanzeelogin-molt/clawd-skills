#!/bin/bash
# Quick launcher for Kimi Code CLI

export $(grep -v '^#' ~/.clawdbot/.env | xargs)

PORT=${KIMI_PORT:-3001}

echo "🚀 Starting Kimi Code CLI on port $PORT..."
echo "   Base URL: https://api.moonshot.ai/v1"
echo "   Model: kimi-k2-0905-preview"
echo ""

kimi -p "$PORT" \
    --base-url "https://api.moonshot.ai/v1" \
    --reasoning-model "kimi-k2-0905-preview" \
    --completion-model "kimi-k2-0905-preview"
