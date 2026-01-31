#!/bin/bash
# Twitter OpenClaw Monitor
# Runs every 6 hours to check for OpenClaw mentions and projects

curl -s -X POST "http://127.0.0.1:18789/wake" \
  -H "Authorization: Bearer 3ae38e29e53b0e7a4dfe19ffe7466d4d7821d01b618c41ba" \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Search Twitter/X for OpenClaw mentions, new projects, and community activity. Look for: 1) Tweets mentioning OpenClaw or Clawdbot, 2) New GitHub repos related to Clawdbot, 3) Community projects and integrations. Report findings to Discord #general with links and summaries.",
    "target": "discord:1143404804157227030"
  }'
