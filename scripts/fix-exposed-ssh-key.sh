#!/bin/bash

# Script to help regenerate SSH keys after exposure
# This should be run to create a new SSH key pair

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SSH_DIR="$PROJECT_ROOT/storage/.ssh"

# Colors
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
CYAN="\033[36m"
BOLD="\033[1m"
RESET="\033[0m"

echo -e "${BOLD}${CYAN}========================================${RESET}"
echo -e "${BOLD}${CYAN}    SSH Key Regeneration Helper    ${RESET}"
echo -e "${BOLD}${CYAN}========================================${RESET}"
echo ""

echo -e "${YELLOW}⚠️  Your SSH private key was exposed in a public repository.${RESET}"
echo -e "${YELLOW}This script will help you create a new SSH key pair.${RESET}"
echo ""

# Backup old key
if [ -f "$SSH_DIR/id_rsa" ]; then
    echo -e "${BLUE}📦 Creating backup of old key...${RESET}"
    mkdir -p "$SSH_DIR/backup_$(date +%Y%m%d_%H%M%S)"
    cp "$SSH_DIR/id_rsa" "$SSH_DIR/backup_$(date +%Y%m%d_%H%M%S)/id_rsa.backup" 2>/dev/null || true
    cp "$SSH_DIR/id_rsa.pub" "$SSH_DIR/backup_$(date +%Y%m%d_%H%M%S)/id_rsa.pub.backup" 2>/dev/null || true
    echo -e "${GREEN}✅ Backup created${RESET}"
    echo ""
fi

# Get email for key
read -p "Enter your email for the new SSH key (or press Enter for default): " USER_EMAIL
if [ -z "$USER_EMAIL" ]; then
    USER_EMAIL="$(whoami)@$(hostname)"
fi

# Generate new key
echo ""
echo -e "${BLUE}🔑 Generating new SSH key pair...${RESET}"
echo -e "${CYAN}Note: You can press Enter for no passphrase, or enter a secure passphrase${RESET}"
echo ""

# Create SSH directory if it doesn't exist
mkdir -p "$SSH_DIR"

# Generate new key
ssh-keygen -t rsa -b 4096 -C "$USER_EMAIL" -f "$SSH_DIR/id_rsa" -N ""

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ New SSH key pair created successfully!${RESET}"
    echo ""
    echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""
    echo -e "${BOLD}📋 Next Steps:${RESET}"
    echo ""
    echo -e "1. ${BOLD}Revoke old key on GitHub:${RESET}"
    echo -e "   Visit: ${CYAN}https://github.com/settings/keys/125981112${RESET}"
    echo -e "   Click 'Delete' or 'Revoke'"
    echo ""
    echo -e "2. ${BOLD}Add new public key to GitHub:${RESET}"
    echo -e "   Visit: ${CYAN}https://github.com/settings/keys/new${RESET}"
    echo -e "   Copy the content below and paste it:"
    echo ""
    echo -e "${BOLD}${GREEN}Your new public key:${RESET}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    cat "$SSH_DIR/id_rsa.pub"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""
    echo -e "3. ${BOLD}Test the connection:${RESET}"
    echo -e "   Run: ${CYAN}ssh -T git@github.com${RESET}"
    echo ""
    echo -e "4. ${BOLD}Update your SSH agent (if needed):${RESET}"
    echo -e "   Run: ${CYAN}bash run/ssh-setting-wsl.sh${RESET}"
    echo ""
else
    echo -e "${RED}❌ Failed to generate SSH key${RESET}"
    exit 1
fi

