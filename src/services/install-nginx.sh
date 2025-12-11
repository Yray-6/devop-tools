#!/bin/bash

# Service: Install Nginx and remove Apache2
# Usage: source this file and call install_nginx_main

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

install_nginx_main() {
    echo -e "${BLUE}🟢 Installing Nginx...${RESET}"
    
    # Check if Apache2 is installed
    if command -v apache2 &> /dev/null || dpkg -l | grep -q apache2; then
        echo -e "${YELLOW}🔥 Apache2 detected. Removing Apache2...${RESET}"
        apt-get remove --purge apache2* -y
        apt-get autoremove -y
        apt-get autoclean
    fi
    
    # Check if Nginx is already installed
    if command -v nginx &> /dev/null; then
        if ask_reinstall "Nginx"; then
            apt-get remove --purge nginx* -y
            apt-get autoremove -y
        else
            echo -e "${BLUE}⏭️  Skipping Nginx installation${RESET}"
            return 0
        fi
    fi
    
    # Fix broken repositories before update
    fix_broken_repositories
    
    # Update package list (ignore errors from broken repos)
    apt-get update -y 2>&1 | grep -v "cloudflare\|404\|does not have a Release file" || true
    
    apt-get install -y nginx
    echo -e "${GREEN}✅ Nginx installed successfully${RESET}"
    echo ""
}

