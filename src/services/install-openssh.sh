#!/bin/bash

# Service: Install OpenSSH server
# Usage: source this file and call install_openssh_main

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

install_openssh_main() {
    echo -e "${BLUE}🔐 Installing OpenSSH server...${RESET}"
    
    # Check if OpenSSH is already installed
    if command -v sshd &> /dev/null || systemctl is-active --quiet ssh 2>/dev/null; then
        if ! ask_reinstall "OpenSSH"; then
            echo -e "${BLUE}⏭️  Skipping OpenSSH installation${RESET}"
            return 0
        fi
    fi
    
    # Fix broken repositories before update
    fix_broken_repositories
    
    # Update package list (ignore errors from broken repos)
    apt-get update -y 2>&1 | grep -v "cloudflare\|404\|does not have a Release file" || true
    
    apt-get install -y openssh-server
    systemctl enable ssh
    systemctl start ssh
    echo -e "${GREEN}✅ OpenSSH installed and started successfully${RESET}"
    echo ""
}

