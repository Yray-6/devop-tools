#!/bin/bash

# Service: Install Certbot (Let's Encrypt)
# Usage: source this file and call install_certbot_main

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

install_certbot_main() {
    echo -e "${BLUE}🔐 Installing Certbot (Let's Encrypt)...${RESET}"
    
    # Check if Certbot is already installed
    if command -v certbot &> /dev/null; then
        if ask_reinstall "Certbot"; then
            echo -e "${YELLOW}🗑️  Removing existing Certbot installation...${RESET}"
            apt-get remove --purge certbot python3-certbot* -y 2>/dev/null || true
            apt-get autoremove -y
        else
            echo -e "${BLUE}⏭️  Skipping Certbot installation${RESET}"
            return 0
        fi
    fi
    
    # Fix broken repositories before update
    fix_broken_repositories
    
    # Update package list (ignore errors from broken repos)
    apt-get update -y 2>&1 | grep -v "cloudflare\|404\|does not have a Release file" || true
    
    # Install Certbot
    apt-get install -y certbot python3-certbot-nginx python3-certbot-apache
    
    echo -e "${GREEN}✅ Certbot installed successfully${RESET}"
    echo ""
    echo -e "${BOLD}${CYAN}💡 Usage examples:${RESET}"
    echo -e "${WHITE}  certbot --nginx${RESET}           # Get certificate for Nginx"
    echo -e "${WHITE}  certbot --apache${RESET}          # Get certificate for Apache"
    echo -e "${WHITE}  certbot renew${RESET}             # Renew certificates"
    echo -e "${WHITE}  certbot certificates${RESET}      # List certificates"
    echo ""
}

