#!/bin/bash

# Service: Install essential packages (curl, wget, nano)
# Usage: source this file and call install_essential_packages_main

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

install_essential_packages_main() {
    echo -e "${BLUE}📦 Installing essential packages (curl, wget, nano)...${RESET}"
    
    # Fix broken repositories before update
    fix_broken_repositories
    
    # Update package list (ignore errors from broken repos)
    apt-get update -y 2>&1 | grep -v "cloudflare\|404\|does not have a Release file" || true
    
    apt-get install -y curl wget nano
    
    echo -e "${GREEN}✅ Essential packages installed successfully${RESET}"
    echo ""
}

