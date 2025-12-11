#!/bin/bash

# Service: Clean system log files older than 7 days
# Usage: source this file and call clean_log_main

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

clean_log_main() {
    LOG_DIR="/var/log"
    DAYS_OLD=7
    
    echo -e "${BLUE}📋 Cleaning system logs from ${CYAN}$LOG_DIR${RESET}"
    echo -e "${YELLOW}Removing files older than ${CYAN}$DAYS_OLD${YELLOW} days${RESET}"
    
    # Show total space occupied
    if [ -d "$LOG_DIR" ]; then
        total_space=$(du -sh "$LOG_DIR" 2>/dev/null | cut -f1)
        echo -e "${YELLOW}Total space occupied by $LOG_DIR: ${CYAN}$total_space${RESET}"
        echo ""
        
        # Find and delete log files older than specified days
        logs=$(find "$LOG_DIR" -type f -mtime +$DAYS_OLD 2>/dev/null)
        total_size=0
        deleted_count=0
        
        if [ -z "$logs" ]; then
            echo -e "${GREEN}✅ No log files older than $DAYS_OLD days found${RESET}"
            echo ""
            return 0
        fi
        
        echo -e "${YELLOW}Log files found:${RESET}"
        while IFS= read -r file; do
            if [ -f "$file" ]; then
                size=$(du -k "$file" 2>/dev/null | cut -f1)
                size_mb=$(echo $size | awk '{printf "%.2f MB", $1/1024}')
                echo -e "  ${CYAN}$file${RESET} - ${YELLOW}$size_mb${RESET}"
                
                # Delete the file
                if rm -f "$file" 2>/dev/null; then
                    total_size=$((total_size + size))
                    ((deleted_count++))
                fi
            fi
        done <<< "$logs"
        
        # Convert total_size from KB to MB
        if [ $total_size -gt 0 ]; then
            total_size_mb=$(echo $total_size | awk '{printf "%.2f MB", $1/1024}')
            echo ""
            echo -e "${GREEN}✅ Deleted ${CYAN}$deleted_count${GREEN} log files${RESET}"
            echo -e "${GREEN}✅ Total space recovered: ${CYAN}$total_size_mb${RESET}"
        else
            echo -e "${YELLOW}⚠️  No files were deleted${RESET}"
        fi
    else
        echo -e "${RED}❌ Directory $LOG_DIR does not exist${RESET}"
        return 1
    fi
    
    echo ""
}

