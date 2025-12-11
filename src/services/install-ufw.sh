#!/bin/bash

# Service: Install and configure UFW
# Usage: source this file and call install_ufw_main

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

install_ufw_main() {
    echo -e "${BLUE}🛡️  Installing and configuring UFW...${RESET}"
    
    # Check if UFW is already installed
    if command -v ufw &> /dev/null; then
        if ! ask_reinstall "UFW"; then
            echo -e "${BLUE}⏭️  Skipping UFW installation${RESET}"
        fi
    fi
    
    # Fix broken repositories before update
    fix_broken_repositories
    
    # Update package list (ignore errors from broken repos)
    apt-get update -y 2>&1 | grep -v "cloudflare\|404\|does not have a Release file" || true
    
    apt-get install -y ufw
    
    # Allow default ports
    echo -e "${BLUE}🔓 Opening default ports...${RESET}"
    ufw allow OpenSSH  # Port 22
    ufw allow 80/tcp   # HTTP
    ufw allow 443/tcp  # HTTPS
    
    # Ask for additional ports
    echo -e "${BOLD}${WHITE}Do you want to open additional ports? (Y/N):${RESET}"
    read -p "Your choice: " open_more
    
    if [[ "$open_more" =~ ^[Yy]$ ]]; then
        while true; do
            echo -e "${BOLD}${CYAN}Enter port number to open (or 'done' to finish):${RESET}"
            read -p "Port: " port
            if [ "$port" = "done" ] || [ -z "$port" ]; then
                break
            fi
            if [[ "$port" =~ ^[0-9]+$ ]]; then
                ufw allow $port/tcp
                echo -e "${GREEN}✅ Port $port opened${RESET}"
            else
                echo -e "${RED}❌ Invalid port number${RESET}"
            fi
        done
    fi
    
    # Enable UFW
    echo -e "${BLUE}🔄 Enabling UFW...${RESET}"
    ufw --force enable
    echo -e "${GREEN}✅ UFW installed and configured successfully${RESET}"
    echo ""
}

