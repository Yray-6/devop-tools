#!/bin/bash

# Service: Install snakeoil SSL certificate
# Usage: source this file and call install_snakeoil_cert_main

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

install_snakeoil_cert_main() {
    echo -e "${BLUE}🔒 Installing snakeoil SSL certificate...${RESET}"
    
    # Check if snakeoil certificate already exists
    if [ -f "/etc/ssl/certs/ssl-cert-snakeoil.pem" ] && [ -f "/etc/ssl/private/ssl-cert-snakeoil.key" ]; then
        if ask_reinstall "Snakeoil SSL certificate"; then
            echo -e "${YELLOW}🗑️  Removing existing snakeoil certificate...${RESET}"
            rm -f /etc/ssl/certs/ssl-cert-snakeoil.pem /etc/ssl/private/ssl-cert-snakeoil.key 2>/dev/null || true
        else
            echo -e "${BLUE}⏭️  Skipping snakeoil certificate installation${RESET}"
            return 0
        fi
    fi
    
    # Fix broken repositories before update
    fix_broken_repositories
    
    # Update package list (ignore errors from broken repos)
    apt-get update -y 2>&1 | grep -v "cloudflare\|404\|does not have a Release file" || true
    
    apt-get install -y ssl-cert
    
    echo -e "${GREEN}✅ Snakeoil SSL certificate installed successfully${RESET}"
    echo ""
}

