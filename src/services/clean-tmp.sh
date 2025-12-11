#!/bin/bash

# Service: Clean temporary files from /tmp
# Usage: source this file and call clean_tmp_main

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

clean_tmp_main() {
    TMP_DIR="/tmp"
    
    echo -e "${BLUE}📁 Cleaning temporary files from ${CYAN}$TMP_DIR${RESET}"
    
    # Count files before cleanup
    if [ -d "$TMP_DIR" ]; then
        files_before=$(ls -1 "$TMP_DIR" 2>/dev/null | wc -l)
        echo -e "${YELLOW}Found ${CYAN}$files_before${YELLOW} files/directories in $TMP_DIR${RESET}"
        
        if [ "$files_before" -eq 0 ]; then
            echo -e "${GREEN}✅ $TMP_DIR is already clean${RESET}"
            echo ""
            return 0
        fi
        
        # Remove all files
        rm -rf "$TMP_DIR"/*
        
        if [ $? -eq 0 ]; then
            # Count files after cleanup
            files_after=$(ls -1 "$TMP_DIR" 2>/dev/null | wc -l)
            echo -e "${GREEN}✅ All temporary files successfully deleted${RESET}"
            echo -e "${YELLOW}Remaining files/directories: ${CYAN}$files_after${RESET}"
        else
            echo -e "${RED}❌ Failed to delete temporary files${RESET}"
            return 1
        fi
    else
        echo -e "${RED}❌ Directory $TMP_DIR does not exist${RESET}"
        return 1
    fi
    
    echo ""
}

