#!/bin/bash
# Tailscale Setup Helper for Clawdbot
# Run this to authenticate Tailscale

echo "====================================="
echo "Tailscale Setup for Clawdbot"
echo "====================================="
echo ""

# Check if Tailscale is installed
if ! command -v tailscale &> /dev/null; then
    echo "❌ Tailscale not found. Installing..."
    brew install tailscale
fi

# Check current status
echo "📊 Current Tailscale status:"
tailscale status 2>&1 || echo "   Not authenticated yet"
echo ""

echo "🔐 Authentication Options:"
echo ""
echo "Option 1: Browser Authentication (Recommended)"
echo "  Run: sudo tailscale up"
echo "  Then complete login in your browser"
echo ""
echo "Option 2: Auth Key (Headless)"
echo "  1. Get auth key from: https://login.tailscale.com/admin/settings/keys"
echo "  2. Run: sudo tailscale up --auth-key=tskey-auth-XXXXXX"
echo ""
echo "Option 3: Connect to existing tailnet"
echo "  Run: sudo tailscale up --operator=$USER"
echo ""

echo "After authentication, Clawdbot can:"
echo "  ✅ Use secure tailnet IPs (100.x.x.x)"
echo "  ✅ Send files via Taildrop"
echo "  ✅ SSH to tailnet devices"
echo "  ✅ Use exit nodes"
echo ""

# Check if already authenticated
if tailscale status &>/dev/null; then
    echo "✅ Tailscale is already authenticated!"
    echo ""
    echo "Your tailnet IP: $(tailscale ip -4 2>/dev/null || echo 'N/A')"
    echo ""
    echo "Online devices:"
    tailscale status | grep -v "^#" | head -10
fi
