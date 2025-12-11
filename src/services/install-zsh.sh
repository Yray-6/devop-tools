#!/bin/bash

# Service: Install Zsh and Oh My Zsh
# Usage: source this file and call install_zsh_main

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

install_zsh_main() {
    echo -e "${BLUE}🎨 Installing Zsh and Oh My Zsh...${RESET}"
    
    # Check if Zsh is already installed
    if command -v zsh &> /dev/null; then
        if ! ask_reinstall "Zsh"; then
            echo -e "${BLUE}⏭️  Skipping Zsh installation${RESET}"
            # Check if Oh My Zsh is installed
            if [ -d "$HOME/.oh-my-zsh" ]; then
                echo -e "${YELLOW}ℹ️  Oh My Zsh is already installed${RESET}"
                return 0
            fi
        else
            # Remove Zsh and Oh My Zsh if reinstall
            apt-get remove --purge zsh -y 2>/dev/null || true
            rm -rf "$HOME/.oh-my-zsh" "$HOME/.zshrc" 2>/dev/null || true
        fi
    fi
    
    # Fix broken repositories before update
    fix_broken_repositories
    
    # Update package list (ignore errors from broken repos)
    apt-get update -y 2>&1 | grep -v "cloudflare\|404\|does not have a Release file" || true
    
    # Install Zsh
    apt-get install -y zsh
    
    # Install Oh My Zsh if not exists
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        echo -e "${BLUE}📥 Installing Oh My Zsh...${RESET}"
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        
        # Set theme to bira
        if [ -f "$HOME/.zshrc" ]; then
            sed -i 's/ZSH_THEME=".*"/ZSH_THEME="bira"/' "$HOME/.zshrc"
            echo -e "${GREEN}✅ Zsh theme set to 'bira'${RESET}"
        fi
    fi
    
    echo -e "${GREEN}✅ Zsh and Oh My Zsh installed successfully${RESET}"
    echo ""
}

