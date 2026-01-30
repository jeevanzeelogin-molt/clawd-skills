# Nemoblock Scheduler Skill

Manage Launchd jobs for Nemoblock automated tasks.

## Overview

This skill helps manage scheduled jobs for Nemoblock, including the Goal Tracker sync script. Jobs are managed via macOS `launchd` (not cron).

## Quick Reference

### Job Files Location

- **User LaunchAgents**: `~/Library/LaunchAgents/`
- **Nemoblock jobs**: `~/Library/LaunchAgents/com.nemoblock.*.plist`

### Common Commands

| Action | Command |
|--------|---------|
| List all nemoblock jobs | `launchctl list | grep com.nemoblock` |
| Check if a job is loaded | `launchctl list com.nemoblock.sync-goal-tracker` |
| Load a job | `launchctl load ~/Library/LaunchAgents/com.nemoblock.<job>.plist` |
| Unload a job | `launchctl unload ~/Library/LaunchAgents/com.nemoblock.<job>.plist` |
| Start a job now | `launchctl start com.nemoblock.<job>` |
| Stop a running job | `launchctl stop com.nemoblock.<job>` |
| View job logs | `tail -f ~/Nemoblock/logs/<job>.log` |
| View failure logs | `cat ~/Nemoblock/logs/sync_failures.log` |

## Using the Helper Script

The `schedule-manager.sh` script provides a convenient interface:

```bash
# From the Nemoblock directory
./scripts/schedule-manager.sh status
./scripts/schedule-manager.sh logs
./scripts/schedule-manager.sh run-now sync-goal-tracker
./scripts/schedule-manager.sh enable sync-goal-tracker
./scripts/schedule-manager.sh disable sync-goal-tracker
```

## Available Jobs

### sync-goal-tracker

Syncs data from Option Omega to Goal Tracker daily at 9 AM EST.

- **Plist**: `~/Library/LaunchAgents/com.nemoblock.sync-goal-tracker.plist`
- **Log**: `~/Nemoblock/logs/sync-goal-tracker.log`
- **Failure Log**: `~/Nemoblock/logs/sync_failures.log`

## Troubleshooting

### Job not running?

1. Check if loaded: `launchctl list | grep nemoblock`
2. Check for errors: `cat ~/Nemoblock/logs/sync_failures.log`
3. Try running manually: `npx tsx scripts/sync-goal-tracker.ts`

### Permission issues?

Jobs run as the user who loaded them. Ensure the plist `UserName` matches your account.

### Environment variables not available?

Launchd jobs don't inherit shell env vars. Set them in the plist `EnvironmentVariables` section or in `.env.local`.

### Headless mode issues?

By default, the sync runs headless. To debug with a visible browser:
```bash
SYNC_HEADLESS=false npx tsx scripts/sync-goal-tracker.ts
```

## Creating a New Job

1. Create a plist file in `~/Library/LaunchAgents/com.nemoblock.<name>.plist`
2. Use the template below
3. Load with `launchctl load ~/Library/LaunchAgents/com.nemoblock.<name>.plist`

### Plist Template

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.nemoblock.JOB_NAME</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/env</string>
        <string>npx</string>
        <string>tsx</string>
        <string>/Users/nemotaka/Nemoblock/scripts/SCRIPT.ts</string>
    </array>
    <key>WorkingDirectory</key>
    <string>/Users/nemotaka/Nemoblock</string>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>9</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
    <key>StandardOutPath</key>
    <string>/Users/nemotaka/Nemoblock/logs/JOB_NAME.log</string>
    <key>StandardErrorPath</key>
    <string>/Users/nemotaka/Nemoblock/logs/JOB_NAME.error.log</string>
    <key>RunAtLoad</key>
    <false/>
</dict>
</plist>
```

## Monitoring

### Set up log rotation (optional)

```bash
# Add to crontab or create a launchd job
0 0 * * * mv ~/Nemoblock/logs/sync-goal-tracker.log ~/Nemoblock/logs/sync-goal-tracker.log.$(date +\%Y\%m\%d)
```

### Alert on failure

The sync script writes to `~/Nemoblock/logs/sync_failures.log` on failure. Monitor this file:

```bash
# Check for recent failures
find ~/Nemoblock/logs -name "sync_failures.log" -mtime -1 -exec cat {} \;
```
