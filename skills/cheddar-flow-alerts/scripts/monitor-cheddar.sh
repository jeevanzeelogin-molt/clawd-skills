#!/bin/bash
# Continuous monitoring for Cheddar Flow

echo "🧀 Starting Cheddar Flow Monitor..."
echo "Press Ctrl+C to stop"
echo ""

while true; do
    /Users/nemotaka/clawd/skills/cheddar-flow-alerts/scripts/check-cheddar.sh
    echo "Sleeping for 5 minutes..."
    sleep 300
done
