#!/bin/bash
# Daily Dashboard Report
# Runs daily at 9 AM to generate a summary report

curl -s -X POST "http://127.0.0.1:18789/wake" \
  -H "Authorization: Bearer 3ae38e29e53b0e7a4dfe19ffe7466d4d7821d01b618c41ba" \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Generate the daily dashboard report showing: 1) All scheduled jobs status, 2) Cheddar Flow alerts summary from past 24h, 3) Twitter/OpenClaw mentions summary, 4) Any issues or notable events. Send a clean formatted report to Discord.",
    "target": "discord:1143404804157227030"
  }'
