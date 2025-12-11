#!/bin/bash

# Service: Install Git and setup configuration
# Usage: source this file and call install_git_main

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

setup_git_config() {
    echo -e "${BLUE}⚙️  Setting up Git global configuration...${RESET}"
    echo ""
    
    # Ask for username
    read -p "Enter Git username: " GIT_USERNAME
    if [ -z "$GIT_USERNAME" ]; then
        echo -e "${YELLOW}⚠️  Username is required. Skipping Git configuration.${RESET}"
        return 1
    fi
    
    # Ask for email
    read -p "Enter Git email: " GIT_EMAIL
    if [ -z "$GIT_EMAIL" ]; then
        echo -e "${YELLOW}⚠️  Email is required. Skipping Git configuration.${RESET}"
        return 1
    fi
    
    # Configure Git
    git config --global user.name "$GIT_USERNAME"
    git config --global user.email "$GIT_EMAIL"
    git config --global pull.rebase true
    
    echo ""
    echo -e "${GREEN}✅ Git configuration completed:${RESET}"
    echo -e "  ${YELLOW}Username:${RESET} ${GREEN}$GIT_USERNAME${RESET}"
    echo -e "  ${YELLOW}Email:${RESET} ${GREEN}$GIT_EMAIL${RESET}"
    echo -e "  ${YELLOW}Pull rebase:${RESET} ${GREEN}true${RESET}"
    echo ""
}

install_git_main() {
    echo -e "${BLUE}📦 Installing Git...${RESET}"
    
    # Check if Git is already installed
    if command -v git &> /dev/null; then
        if ask_reinstall "Git"; then
            echo -e "${YELLOW}🗑️  Removing existing Git installation...${RESET}"
            apt-get remove --purge git git-* -y 2>/dev/null || true
            apt-get autoremove -y
        else
            echo -e "${BLUE}⏭️  Skipping Git installation${RESET}"
            # Check if Git is already configured
            if git config --global user.name &> /dev/null && git config --global user.email &> /dev/null; then
                echo -e "${YELLOW}ℹ️  Git is already configured${RESET}"
                echo -e "  ${YELLOW}Username:${RESET} $(git config --global user.name)"
                echo -e "  ${YELLOW}Email:${RESET} $(git config --global user.email)"
                echo ""
                read -p "Do you want to reconfigure Git? (Y/N): " reconfigure
                if [[ "$reconfigure" =~ ^[Yy]$ ]]; then
                    setup_git_config
                fi
            else
                echo ""
                read -p "Git is not configured. Do you want to configure it now? (Y/N): " configure_git
                if [[ "$configure_git" =~ ^[Yy]$ ]]; then
                    setup_git_config
                fi
            fi
            return 0
        fi
    fi
    
    # Fix broken repositories before update
    fix_broken_repositories
    
    # Update package list (ignore errors from broken repos)
    apt-get update -y 2>&1 | grep -v "cloudflare\|404\|does not have a Release file" || true
    
    # Install Git
    apt-get install -y git
    
    echo -e "${GREEN}✅ Git installed successfully${RESET}"
    echo ""
    
    # Ask if user wants to configure Git
    read -p "Do you want to configure Git global settings? (Y/N): " configure_git
    if [[ "$configure_git" =~ ^[Yy]$ ]]; then
        setup_git_config
    else
        echo -e "${BLUE}⏭️  Skipping Git configuration${RESET}"
        echo -e "${YELLOW}ℹ️  You can configure Git later using:${RESET}"
        echo -e "  ${WHITE}git config --global user.name \"Your Name\"${RESET}"
        echo -e "  ${WHITE}git config --global user.email \"your.email@example.com\"${RESET}"
        echo -e "  ${WHITE}git config --global pull.rebase true${RESET}"
        echo ""
    fi
}

