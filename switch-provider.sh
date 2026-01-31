#!/bin/bash
# Provider Switcher - Switch between AI providers
# Usage: ./switch-provider.sh [kimi|gemini|auto]

PROVIDER=${1:-kimi}

show_help() {
    echo "Provider Switcher for Clawdbot"
    echo ""
    echo "Usage:"
    echo "  ./switch-provider.sh kimi    # Use Kimi (primary)"
    echo "  ./switch-provider.sh gemini  # Use Gemini (backup)"
    echo "  ./switch-provider.sh auto    # Auto-switch based on availability"
    echo "  ./switch-provider.sh status  # Check current provider"
    echo ""
}

if [ "$PROVIDER" == "help" ] || [ "$PROVIDER" == "--help" ] || [ "$PROVIDER" == "-h" ]; then
    show_help
    exit 0
fi

check_kimi() {
    # Check if Kimi API key is set and valid
    if [ -z "$KIMI_CODE_API_KEY_BACKUP" ] && [ -z "$MOONSHOT_API_KEY" ]; then
        return 1
    fi
    return 0
}

check_gemini() {
    # Check if Gemini API key is set
    if [ -z "$GEMINI_API_KEY" ]; then
        return 1
    fi
    return 0
}

get_current_provider() {
    # Extract from clawdbot config
    grep -o '"primary": "[^"]*"' ~/.clawdbot/clawdbot.json 2>/dev/null | head -1 | cut -d'"' -f4
}

switch_to_kimi() {
    echo "🚀 Switching to Kimi (Primary)..."
    clawdbot config patch --file ~/.clawdbot/clawdbot.json << 'EOF'
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "kimi-code/kimi-for-coding"
      }
    }
  }
}
EOF
    echo "✅ Switched to Kimi Code"
}

switch_to_gemini() {
    echo "🔄 Switching to Gemini (Backup)..."
    
    # Check if Gemini key exists
    if [ -z "$GEMINI_API_KEY" ]; then
        echo "⚠️  GEMINI_API_KEY not set!"
        echo "Please add your Gemini API key to ~/.clawdbot/.env"
        echo "Get one at: https://aistudio.google.com/app/apikey"
        exit 1
    fi
    
    clawdbot config patch --file ~/.clawdbot/clawdbot.json << 'EOF'
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "gemini/gemini-2.0-flash-exp"
      }
    }
  }
}
EOF
    echo "✅ Switched to Gemini Flash (Backup)"
}

case "$PROVIDER" in
    kimi|kimi-code|primary|main)
        switch_to_kimi
        ;;
    gemini|backup|google)
        switch_to_gemini
        ;;
    status)
        CURRENT=$(get_current_provider)
        echo "Current provider: $CURRENT"
        
        echo ""
        echo "Provider Status:"
        if check_kimi; then
            echo "  ✅ Kimi: Available"
        else
            echo "  ❌ Kimi: No API key"
        fi
        
        if check_gemini; then
            echo "  ✅ Gemini: Available"
        else
            echo "  ❌ Gemini: No API key"
        fi
        ;;
    auto)
        echo "🤖 Auto-detecting best provider..."
        if check_kimi; then
            switch_to_kimi
        elif check_gemini; then
            switch_to_gemini
        else
            echo "❌ No providers available!"
            echo "Please set KIMI_CODE_API_KEY_BACKUP or GEMINI_API_KEY"
            exit 1
        fi
        ;;
    *)
        echo "❌ Unknown provider: $PROVIDER"
        show_help
        exit 1
        ;;
esac

# Restart gateway to apply changes
echo ""
echo "🔄 Restarting gateway..."
clawdbot gateway restart

echo ""
echo "✨ Done! Provider switched successfully."
