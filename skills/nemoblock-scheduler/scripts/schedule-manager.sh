#!/bin/bash
#
# Nemoblock Schedule Manager
# Helper script for managing Launchd jobs
#

set -e

# Configuration
NEMOBLOCK_DIR="/Users/nemotaka/Nemoblock"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
LOGS_DIR="$NEMOBLOCK_DIR/logs"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

show_help() {
    cat << EOF
Nemoblock Schedule Manager

Usage: $0 <command> [options]

Commands:
    status              Show status of all nemoblock jobs
    logs [job]          Tail log files (default: all)
    run-now <job>       Run a job immediately
    enable <job>        Load a job
    disable <job>       Unload a job
    help                Show this help message

Jobs:
    sync-goal-tracker   Sync Goal Tracker with Option Omega

Examples:
    $0 status
    $0 logs
    $0 logs sync-goal-tracker
    $0 run-now sync-goal-tracker
    $0 enable sync-goal-tracker
    $0 disable sync-goal-tracker
EOF
}

# Get list of nemoblock jobs
get_jobs() {
    launchctl list 2>/dev/null | grep "com.nemoblock" | awk '{print $3}' || true
}

# Get plist file for a job
get_plist_path() {
    local job_name="$1"
    local plist_name="com.nemoblock.${job_name}.plist"
    echo "$LAUNCH_AGENTS_DIR/$plist_name"
}

# Check if job is loaded
is_job_loaded() {
    local job_name="$1"
    local full_name="com.nemoblock.${job_name}"
    launchctl list "$full_name" &>/dev/null
}

# Status command
cmd_status() {
    log_info "Checking nemoblock job status..."
    echo ""
    
    local found_jobs=0
    
    # Check sync-goal-tracker
    local job="sync-goal-tracker"
    local plist_path="$(get_plist_path "$job")"
    
    if [ -f "$plist_path" ]; then
        found_jobs=$((found_jobs + 1))
        echo "Job: $job"
        
        if is_job_loaded "$job"; then
            log_success "Status: Loaded"
            local pid=$(launchctl list "com.nemoblock.$job" 2>/dev/null | awk 'NR==2 {print $1}')
            if [ "$pid" != "-" ] && [ -n "$pid" ]; then
                log_info "PID: $pid (Running)"
            else
                log_warn "PID: - (Not currently running)"
            fi
        else
            log_warn "Status: Not loaded"
        fi
        
        # Show last run info if available
        local log_file="$LOGS_DIR/${job}.log"
        if [ -f "$log_file" ]; then
            local last_run=$(tail -50 "$log_file" 2>/dev/null | grep -E "Starting Goal Tracker sync|Goal Tracker sync complete" | tail -1)
            if [ -n "$last_run" ]; then
                echo "Last activity: $last_run"
            fi
        fi
        
        echo ""
    fi
    
    if [ $found_jobs -eq 0 ]; then
        log_warn "No nemoblock jobs found in $LAUNCH_AGENTS_DIR"
        echo ""
        log_info "Expected plist files:"
        echo "  - com.nemoblock.sync-goal-tracker.plist"
    fi
    
    # Check for failures
    local failure_log="$LOGS_DIR/sync_failures.log"
    if [ -f "$failure_log" ]; then
        local recent_failures=$(find "$failure_log" -mtime -1 2>/dev/null)
        if [ -n "$recent_failures" ]; then
            echo ""
            log_warn "Recent failures detected in the last 24 hours!"
            echo "Run '$0 logs' to see failure details."
        fi
    fi
}

# Logs command
cmd_logs() {
    local job="$1"
    
    # Ensure logs directory exists
    if [ ! -d "$LOGS_DIR" ]; then
        log_error "Logs directory not found: $LOGS_DIR"
        exit 1
    fi
    
    if [ -n "$job" ]; then
        # Tail specific job log
        local log_file="$LOGS_DIR/${job}.log"
        local error_log="$LOGS_DIR/${job}.error.log"
        
        if [ -f "$log_file" ] || [ -f "$error_log" ]; then
            log_info "Tailing logs for job: $job"
            echo "Press Ctrl+C to exit"
            echo "---"
            tail -f "$log_file" "$error_log" 2>/dev/null || tail -f "$log_file" 2>/dev/null || tail -f "$error_log" 2>/dev/null
        else
            log_error "No log files found for job: $job"
            echo "Expected: $log_file"
        fi
    else
        # Tail all nemoblock logs + failure log
        local logs_to_tail=()
        
        for log in "$LOGS_DIR"/*.log; do
            if [ -f "$log" ]; then
                logs_to_tail+=("$log")
            fi
        done
        
        if [ ${#logs_to_tail[@]} -gt 0 ]; then
            log_info "Tailing all nemoblock logs"
            echo "Press Ctrl+C to exit"
            echo "---"
            tail -f "${logs_to_tail[@]}"
        else
            log_warn "No log files found in $LOGS_DIR"
        fi
    fi
}

# Run now command
cmd_run_now() {
    local job="$1"
    
    if [ -z "$job" ]; then
        log_error "Job name required"
        echo "Usage: $0 run-now <job>"
        echo "Example: $0 run-now sync-goal-tracker"
        exit 1
    fi
    
    local full_name="com.nemoblock.${job}"
    
    if ! is_job_loaded "$job"; then
        log_warn "Job '$job' is not loaded. Attempting to load..."
        local plist_path="$(get_plist_path "$job")"
        if [ -f "$plist_path" ]; then
            launchctl load "$plist_path"
            log_success "Job loaded"
        else
            log_error "Plist file not found: $plist_path"
            exit 1
        fi
    fi
    
    log_info "Starting job: $job"
    launchctl start "$full_name"
    log_success "Job started. Check logs with: $0 logs $job"
}

# Enable command
cmd_enable() {
    local job="$1"
    
    if [ -z "$job" ]; then
        log_error "Job name required"
        echo "Usage: $0 enable <job>"
        exit 1
    fi
    
    local plist_path="$(get_plist_path "$job")"
    
    if [ ! -f "$plist_path" ]; then
        log_error "Plist file not found: $plist_path"
        exit 1
    fi
    
    if is_job_loaded "$job"; then
        log_warn "Job '$job' is already loaded"
        exit 0
    fi
    
    log_info "Loading job: $job"
    launchctl load "$plist_path"
    log_success "Job enabled: $job"
}

# Disable command
cmd_disable() {
    local job="$1"
    
    if [ -z "$job" ]; then
        log_error "Job name required"
        echo "Usage: $0 disable <job>"
        exit 1
    fi
    
    local plist_path="$(get_plist_path "$job")"
    
    if ! is_job_loaded "$job"; then
        log_warn "Job '$job' is not loaded"
        exit 0
    fi
    
    log_info "Unloading job: $job"
    launchctl unload "$plist_path"
    log_success "Job disabled: $job"
}

# Main
main() {
    local command="$1"
    shift || true
    
    case "$command" in
        status)
            cmd_status
            ;;
        logs)
            cmd_logs "$1"
            ;;
        run-now)
            cmd_run_now "$1"
            ;;
        enable)
            cmd_enable "$1"
            ;;
        disable)
            cmd_disable "$1"
            ;;
        help|--help|-h)
            show_help
            ;;
        "")
            log_error "No command specified"
            show_help
            exit 1
            ;;
        *)
            log_error "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
