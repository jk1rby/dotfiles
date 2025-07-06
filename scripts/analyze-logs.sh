#!/bin/bash
# Log Analysis Helper Script for Cross-Platform Dotfiles

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

DOTFILES_DIR="$HOME/dotfiles"
LOG_DIR="$DOTFILES_DIR/logs"

show_usage() {
    echo "Log Analysis Helper for Cross-Platform Dotfiles"
    echo
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo
    echo "Commands:"
    echo "  list              List all installation logs"
    echo "  latest            Show the latest log"
    echo "  view <logfile>    View a specific log file"
    echo "  errors            Show all errors across logs"
    echo "  summary           Show installation summary statistics"
    echo "  follow            Follow the most recent log (if running)"
    echo "  nvidia            Show NVIDIA-related log entries"
    echo "  system            Show system information from logs"
    echo "  cleanup           Remove logs older than 30 days"
    echo
    echo "Examples:"
    echo "  $0 latest"
    echo "  $0 view install_20250105_143022.log"
    echo "  $0 errors | head -20"
}

list_logs() {
    echo -e "${CYAN}Available Installation Logs:${NC}"
    echo
    
    if [[ ! -d "$LOG_DIR" ]]; then
        echo -e "${YELLOW}No log directory found${NC}"
        return 1
    fi
    
    local logs=($(find "$LOG_DIR" -name "install_*.log" -type f | sort -r))
    
    if [[ ${#logs[@]} -eq 0 ]]; then
        echo -e "${YELLOW}No installation logs found${NC}"
        return 1
    fi
    
    printf "%-25s %-15s %-10s %s\n" "Timestamp" "Status" "Size" "File"
    echo "--------------------------------------------------------------------------------"
    
    for log in "${logs[@]}"; do
        local filename=$(basename "$log")
        local timestamp=$(echo "$filename" | sed 's/install_\([0-9]*_[0-9]*\)\.log/\1/' | sed 's/_/ /')
        local size=$(du -h "$log" | cut -f1)
        local status="UNKNOWN"
        
        if grep -q "Status: SUCCESS" "$log" 2>/dev/null; then
            status="${GREEN}SUCCESS${NC}"
        elif grep -q "Status: FAILED" "$log" 2>/dev/null; then
            status="${RED}FAILED${NC}"
        elif grep -q "FATAL" "$log" 2>/dev/null; then
            status="${RED}FATAL${NC}"
        else
            status="${YELLOW}INCOMPLETE${NC}"
        fi
        
        printf "%-25s %-24s %-10s %s\n" "$timestamp" "$status" "$size" "$filename"
    done
}

show_latest() {
    local latest=$(find "$LOG_DIR" -name "install_*.log" -type f | sort -r | head -1)
    
    if [[ -z "$latest" ]]; then
        echo -e "${YELLOW}No installation logs found${NC}"
        return 1
    fi
    
    echo -e "${CYAN}Latest Installation Log: $(basename "$latest")${NC}"
    echo
    cat "$latest"
}

view_log() {
    local logfile="$1"
    
    if [[ -z "$logfile" ]]; then
        echo -e "${RED}Error: Please specify a log file${NC}"
        show_usage
        return 1
    fi
    
    # Handle both full path and just filename
    if [[ ! -f "$logfile" ]]; then
        logfile="$LOG_DIR/$logfile"
    fi
    
    if [[ ! -f "$logfile" ]]; then
        echo -e "${RED}Error: Log file not found: $logfile${NC}"
        return 1
    fi
    
    echo -e "${CYAN}Viewing: $(basename "$logfile")${NC}"
    echo
    cat "$logfile"
}

show_errors() {
    echo -e "${CYAN}All Errors Across Installation Logs:${NC}"
    echo
    
    if [[ ! -d "$LOG_DIR" ]]; then
        echo -e "${YELLOW}No log directory found${NC}"
        return 1
    fi
    
    find "$LOG_DIR" -name "install_*.log" -type f | while read -r log; do
        local filename=$(basename "$log")
        local errors=$(grep -n "\[ERROR\]\|\[FATAL\]\|FAILED\|failed" "$log" 2>/dev/null || true)
        
        if [[ -n "$errors" ]]; then
            echo -e "${RED}=== $filename ===${NC}"
            echo "$errors"
            echo
        fi
    done
}

show_summary() {
    echo -e "${CYAN}Installation Summary Statistics:${NC}"
    echo
    
    if [[ ! -d "$LOG_DIR" ]]; then
        echo -e "${YELLOW}No log directory found${NC}"
        return 1
    fi
    
    local total_logs=$(find "$LOG_DIR" -name "install_*.log" -type f | wc -l)
    local successful=$(grep -l "Status: SUCCESS" "$LOG_DIR"/install_*.log 2>/dev/null | wc -l)
    local failed=$(grep -l "Status: FAILED" "$LOG_DIR"/install_*.log 2>/dev/null | wc -l)
    local incomplete=$((total_logs - successful - failed))
    
    echo "Total Installations: $total_logs"
    echo -e "Successful: ${GREEN}$successful${NC}"
    echo -e "Failed: ${RED}$failed${NC}"
    echo -e "Incomplete: ${YELLOW}$incomplete${NC}"
    echo
    
    # Most common errors
    echo -e "${CYAN}Most Common Error Types:${NC}"
    grep -h "\[ERROR\]" "$LOG_DIR"/install_*.log 2>/dev/null | \
        sed 's/.*\[ERROR\] //' | sort | uniq -c | sort -nr | head -5
    echo
    
    # System types
    echo -e "${CYAN}Installation by System Type:${NC}"
    grep -h "Detected:" "$LOG_DIR"/install_*.log 2>/dev/null | \
        cut -d':' -f2 | sort | uniq -c | sort -nr
}

follow_log() {
    local latest=$(find "$LOG_DIR" -name "install_*.log" -type f | sort -r | head -1)
    
    if [[ -z "$latest" ]]; then
        echo -e "${YELLOW}No installation logs found${NC}"
        return 1
    fi
    
    echo -e "${CYAN}Following: $(basename "$latest")${NC}"
    echo -e "${YELLOW}Press Ctrl+C to stop${NC}"
    echo
    tail -f "$latest"
}

show_nvidia_logs() {
    echo -e "${CYAN}NVIDIA-Related Log Entries:${NC}"
    echo
    
    find "$LOG_DIR" -name "install_*.log" -type f | while read -r log; do
        local filename=$(basename "$log")
        local nvidia_entries=$(grep -n -i "nvidia\|rtx.*4090\|cuda" "$log" 2>/dev/null || true)
        
        if [[ -n "$nvidia_entries" ]]; then
            echo -e "${GREEN}=== $filename ===${NC}"
            echo "$nvidia_entries"
            echo
        fi
    done
}

show_system_info() {
    echo -e "${CYAN}System Information from Logs:${NC}"
    echo
    
    local latest=$(find "$LOG_DIR" -name "install_*.log" -type f | sort -r | head -1)
    
    if [[ -z "$latest" ]]; then
        echo -e "${YELLOW}No installation logs found${NC}"
        return 1
    fi
    
    echo -e "${BLUE}From: $(basename "$latest")${NC}"
    echo
    
    # Extract system information section
    sed -n '/SYSTEM INFORMATION/,/===============================/p' "$latest" | \
        grep -v "==============="
}

cleanup_logs() {
    echo -e "${CYAN}Cleaning up logs older than 30 days...${NC}"
    
    if [[ ! -d "$LOG_DIR" ]]; then
        echo -e "${YELLOW}No log directory found${NC}"
        return 1
    fi
    
    local old_logs=$(find "$LOG_DIR" -name "install_*.log" -type f -mtime +30)
    
    if [[ -z "$old_logs" ]]; then
        echo -e "${GREEN}No old logs to clean up${NC}"
        return 0
    fi
    
    echo "Found logs to remove:"
    echo "$old_logs"
    echo
    
    read -p "Remove these logs? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "$old_logs" | xargs rm -f
        echo -e "${GREEN}Old logs removed${NC}"
    else
        echo -e "${YELLOW}Cleanup cancelled${NC}"
    fi
}

# Main command handling
case "${1:-list}" in
    list)
        list_logs
        ;;
    latest)
        show_latest
        ;;
    view)
        view_log "$2"
        ;;
    errors)
        show_errors
        ;;
    summary)
        show_summary
        ;;
    follow)
        follow_log
        ;;
    nvidia)
        show_nvidia_logs
        ;;
    system)
        show_system_info
        ;;
    cleanup)
        cleanup_logs
        ;;
    help|--help|-h)
        show_usage
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        echo
        show_usage
        exit 1
        ;;
esac