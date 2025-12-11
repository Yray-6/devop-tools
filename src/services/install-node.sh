#!/bin/bash

# Service: Install Node.js and npm using NVM
# Usage: source this file and call install_node_main

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Check if NVM is already installed
check_nvm_installed() {
    if [ -d "$HOME/.nvm" ] && [ -f "$HOME/.nvm/nvm.sh" ]; then
        return 0  # NVM is installed
    else
        return 1  # NVM is not installed
    fi
}

# Install NVM
install_nvm() {
    echo -e "${BLUE}🔧 Installing NVM (Node Version Manager)...${RESET}"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    
    echo -e "${BLUE}📥 Loading NVM...${RESET}"
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    # Add to shell profile if not already added
    if ! grep -q "NVM_DIR" ~/.bashrc 2>/dev/null; then
        echo '' >> ~/.bashrc
        echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.bashrc
        echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ~/.bashrc
        echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> ~/.bashrc
    fi
    
    if [ -f ~/.zshrc ] && ! grep -q "NVM_DIR" ~/.zshrc 2>/dev/null; then
        echo '' >> ~/.zshrc
        echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.zshrc
        echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ~/.zshrc
        echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> ~/.zshrc
    fi
    
    echo -e "${GREEN}✅ NVM installed successfully${RESET}"
    echo ""
}

# Install Node.js
install_nodejs() {
    local version=$1
    
    # Ensure NVM is available
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    echo -e "${BLUE}📦 Installing Node.js v$version using NVM...${RESET}"
    nvm install $version
    
    echo -e "${BLUE}⚙️  Setting v$version as default...${RESET}"
    nvm alias default $version
    nvm use $version
    
    echo -e "${GREEN}✅ Node.js v$version installed and set as default${RESET}"
    echo ""
}

# Install additional packages (yarn, pm2)
install_additional_packages() {
    echo -e "${BLUE}📦 Installing additional packages (yarn, pm2)...${RESET}"
    
    # Ensure NVM is available
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    # Install yarn globally
    echo -e "${BLUE}📦 Installing Yarn...${RESET}"
    npm install -g yarn
    
    # Install pm2 globally
    echo -e "${BLUE}📦 Installing PM2...${RESET}"
    npm install -g pm2
    
    echo -e "${GREEN}✅ Additional packages installed successfully${RESET}"
    echo ""
}

install_node_main() {
    echo -e "${BLUE}📦 Installing Node.js and npm using NVM...${RESET}"
    
    # Check if NVM is already installed
    if check_nvm_installed; then
        if ask_reinstall "NVM"; then
            echo -e "${YELLOW}🗑️  Removing existing NVM installation...${RESET}"
            rm -rf "$HOME/.nvm"
            # Remove NVM from shell profiles
            sed -i '/NVM_DIR/d' ~/.bashrc 2>/dev/null || true
            sed -i '/nvm.sh/d' ~/.bashrc 2>/dev/null || true
            sed -i '/bash_completion/d' ~/.bashrc 2>/dev/null || true
            sed -i '/NVM_DIR/d' ~/.zshrc 2>/dev/null || true
            sed -i '/nvm.sh/d' ~/.zshrc 2>/dev/null || true
            sed -i '/bash_completion/d' ~/.zshrc 2>/dev/null || true
            echo -e "${GREEN}✅ Old NVM installation removed${RESET}"
            echo ""
            install_nvm
        else
            echo -e "${BLUE}⏭️  Skipping NVM installation${RESET}"
            # Ensure NVM is loaded
            export NVM_DIR="$HOME/.nvm"
            [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
            
            # Ask if user wants to install Node.js version anyway
            echo ""
            echo -e "${BOLD}${WHITE}Do you want to install or update Node.js version? (Y/N):${RESET}"
            read -p "Your choice: " install_node_choice
            if [[ ! "$install_node_choice" =~ ^[Yy]$ ]]; then
                echo -e "${BLUE}⏭️  Exiting Node.js installation${RESET}"
                echo ""
                # Show current versions if available
                if command -v node &> /dev/null; then
                    echo -e "${BOLD}${CYAN}📊 Current installed versions:${RESET}"
                    node -v 2>/dev/null || true
                    npm -v 2>/dev/null || true
                    echo ""
                fi
                return 0
            fi
        fi
    else
        install_nvm
    fi
    
    # Ensure NVM is available
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    # Check if NVM is now available
    if ! command -v nvm &> /dev/null && [ ! -s "$NVM_DIR/nvm.sh" ]; then
        echo -e "${RED}❌ Failed to load NVM. Please restart your terminal or run: source ~/.bashrc${RESET}"
        return 1
    fi
    
    # Ask for Node.js version
    echo ""
    echo -e "${BOLD}${WHITE}What version of Node.js do you want to install?${RESET}"
    echo -e "${YELLOW}(e.g. 18, 20, 22, or LTS for latest LTS version)${RESET}"
    read -p "Version [LTS]: " VERSION
    VERSION=${VERSION:-LTS}
    
    # Install Node.js
    if [ "$VERSION" = "LTS" ] || [ "$VERSION" = "lts" ]; then
        VERSION="lts/*"
    fi
    
    install_nodejs "$VERSION"
    
    # Ask if user wants to install additional packages
    echo ""
    echo -e "${BOLD}${WHITE}Do you want to install additional packages (yarn, pm2)? (Y/N):${RESET}"
    read -p "Your choice [Y]: " install_packages
    install_packages=${install_packages:-Y}
    
    if [[ "$install_packages" =~ ^[Yy]$ ]]; then
        install_additional_packages
    else
        echo -e "${BLUE}⏭️  Skipping additional packages installation${RESET}"
        echo ""
    fi
    
    # Show final status
    echo ""
    echo -e "${BOLD}${GREEN}✅ Node.js installation completed!${RESET}"
    echo ""
    echo -e "${BOLD}${CYAN}📊 Installed versions:${RESET}"
    node -v 2>/dev/null || echo -e "${RED}❌ Node.js not found${RESET}"
    npm -v 2>/dev/null || echo -e "${RED}❌ npm not found${RESET}"
    if command -v yarn &> /dev/null; then
        echo -e "${GREEN}yarn:$(yarn -v)${RESET}"
    fi
    if command -v pm2 &> /dev/null; then
        echo -e "${GREEN}pm2:$(pm2 -v)${RESET}"
    fi
    echo ""
    echo -e "${YELLOW}ℹ️  Note: You may need to restart your terminal or run 'source ~/.bashrc' to use NVM${RESET}"
    echo ""
}

