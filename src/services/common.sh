#!/bin/bash

# Common functions for Ubuntu environment setup services
# This file should be sourced by service scripts

# Get script directory for relative paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source UI common if available
if [ -f "$PROJECT_ROOT/src/ui/ui_common.sh" ]; then
    source "$PROJECT_ROOT/src/ui/ui_common.sh"
else
    # Fallback color codes
    RED="\033[31m"
    GREEN="\033[32m"
    YELLOW="\033[33m"
    BLUE="\033[34m"
    CYAN="\033[36m"
    WHITE="\033[37m"
    BOLD="\033[1m"
    BG_GREEN="\033[42m"
    BG_YELLOW="\033[43m"
    BG_BLUE="\033[44m"
    RESET="\033[0m"
fi

# Function to fix broken repositories
fix_broken_repositories() {
    # Check for common broken repositories and remove them
    if [ -f /etc/apt/sources.list.d/cloudflare-main.list ]; then
        if ! apt-get update -y 2>&1 | grep -q "cloudflare.*404"; then
            : # Repository is fine, do nothing
        else
            echo -e "${YELLOW}⚠️  Removing broken Cloudflare repository...${RESET}"
            rm -f /etc/apt/sources.list.d/cloudflare-main.list
            rm -f /etc/apt/sources.list.d/cloudflare-main.list.save
        fi
    fi
}

# Function to ask for reinstall confirmation
ask_reinstall() {
    local package_name="$1"
    if [ -z "$package_name" ]; then
        package_name="this package"
    fi
    
    echo -e "${YELLOW}⚠️  $package_name is already installed${RESET}"
    echo -e "${BOLD}${WHITE}Do you want to remove and reinstall? (Y/N):${RESET}"
    while true; do
        read -p "Your choice: " choice
        case "$choice" in
            [Yy]|[Yy][Ee][Ss])
                return 0  # Yes, reinstall
                ;;
            [Nn]|[Nn][Oo])
                return 1  # No, skip
                ;;
            *)
                echo -e "${RED}❌ Please enter Y or N${RESET}"
                ;;
        esac
    done
}

