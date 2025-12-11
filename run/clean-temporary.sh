#!/bin/bash

# Script metadata
NAME="Clean Temporary"
DESC="Clear temporary files and system logs to free up disk space"

# Source UI components and services
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICES_DIR="$SCRIPT_DIR/../src/services"

if [ -f "$SCRIPT_DIR/../src/ui/ui_common.sh" ]; then
    source "$SCRIPT_DIR/../src/ui/ui_common.sh"
else
    # Fallback color codes
    RED="\033[31m"
    GREEN="\033[32m"
    YELLOW="\033[33m"
    BLUE="\033[34m"
    CYAN="\033[36m"
    WHITE="\033[37m"
    BOLD="\033[1m"
    RESET="\033[0m"
fi

# Source service files
source "$SERVICES_DIR/common.sh"
source "$SERVICES_DIR/clean-tmp.sh"
source "$SERVICES_DIR/clean-log.sh"

clear
echo -e "${BOLD}${CYAN}========================================${RESET}"
echo -e "${BOLD}${CYAN}    Clean Temporary Files & Logs    ${RESET}"
echo -e "${BOLD}${CYAN}========================================${RESET}"
echo ""

# Clear temporary files
echo -e "${BOLD}${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
clean_tmp_main

# Clear log files
echo -e "${BOLD}${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
clean_log_main

echo -e "${BOLD}${GREEN}✅ Cleanup completed!${RESET}"
echo ""

