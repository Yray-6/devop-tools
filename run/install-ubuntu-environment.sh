#!/bin/bash

# Script metadata
NAME="Ubuntu Environment"
DESC="Setup Ubuntu development environment with essential tools"

# Source UI components for better menu
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/../src/ui/ui_common.sh" ]; then
    source "$SCRIPT_DIR/../src/ui/ui_common.sh"
else
    # Fallback color codes if UI common not available
    RED="\033[31m"
    GREEN="\033[32m"
    YELLOW="\033[33m"
    BLUE="\033[34m"
    CYAN="\033[36m"
    WHITE="\033[37m"
    BOLD="\033[1m"
    BG_GREEN="\033[42m"
    BG_YELLOW="\033[43m"
    BG_BLUE="\033[44m"
    RESET="\033[0m"
    
    # Simple read_key fallback
    read_key() {
        local key
        read -rsn1 key
        case "$key" in
            $'\x1b')
                read -rsn2 key
                case "$key" in
                    '[A') echo -n "UP" ;;
                    '[B') echo -n "DOWN" ;;
                    *) echo -n "ESC" ;;
                esac
                ;;
            $'\n'|$'\r') echo -n "ENTER" ;;
            *) echo -n "$key" ;;
        esac
    }
fi

# Source service files
SERVICES_DIR="$SCRIPT_DIR/../src/services"
source "$SERVICES_DIR/common.sh"
source "$SERVICES_DIR/install-nginx.sh"
source "$SERVICES_DIR/install-ufw.sh"
source "$SERVICES_DIR/install-openssh.sh"
source "$SERVICES_DIR/install-zsh.sh"
source "$SERVICES_DIR/install-essential-packages.sh"
source "$SERVICES_DIR/install-docker.sh"
source "$SERVICES_DIR/install-snakeoil-cert.sh"
source "$SERVICES_DIR/install-certbot.sh"
source "$SERVICES_DIR/install-git.sh"
source "$SERVICES_DIR/install-node.sh"

# Save terminal settings and setup Ctrl+C handling
TERM_SETTINGS=$(stty -g)

cleanup_terminal() {
    stty $TERM_SETTINGS 2>/dev/null 2>&1
    echo -ne "\033[?25h"
    echo ""
}

cleanup_and_exit() {
    cleanup_terminal
    echo -e "${BOLD}${YELLOW}⚠️  Interrupted by user${RESET}"
    exit 130
}

trap cleanup_terminal EXIT
trap cleanup_and_exit INT TERM

# Check if running on Debian/Ubuntu
check_os() {
    if [ ! -f /etc/debian_version ] && [ ! -f /etc/os-release ]; then
        echo -e "${RED}❌ This script only works on Debian/Ubuntu systems${RESET}"
  exit 1
fi

    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$ID" != "debian" && "$ID" != "ubuntu" ]]; then
            echo -e "${RED}❌ This script only works on Debian/Ubuntu systems${RESET}"
            exit 1
        fi
    fi
}

# Check root privileges
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}❌ This script requires root privileges. Please run with sudo${RESET}"
        exit 1
    fi
}

# Service functions are now sourced from src/services/*
# Wrapper functions to maintain compatibility
install_nginx() {
    install_nginx_main
}

install_ufw() {
    install_ufw_main
}

install_openssh() {
    install_openssh_main
}

install_zsh() {
    install_zsh_main
}

install_essential_packages() {
    install_essential_packages_main
}

install_docker() {
    install_docker_main
}

install_snakeoil_cert() {
    install_snakeoil_cert_main
}

install_certbot() {
    install_certbot_main
}

install_git() {
    install_git_main
}

install_node() {
    install_node_main
}

# Display main menu
show_main_menu() {
    local selected_option=0
    
    while true; do
        clear
        echo -e "${BOLD}${CYAN}========================================${RESET}"
        echo -e "${BOLD}${CYAN}    Ubuntu Environment Setup    ${RESET}"
        echo -e "${BOLD}${CYAN}========================================${RESET}"
        echo ""
        echo -e "${BOLD}${WHITE}Select installation option:${RESET}"
        echo ""
        
        # Display options with highlighting
        if [ $selected_option -eq 0 ]; then
            echo -e "${BOLD}${BG_GREEN}${WHITE}▶ [1] Install All${RESET}"
        else
            echo -e "${GREEN}  [1] Install All${RESET}"
        fi
        
        if [ $selected_option -eq 1 ]; then
            echo -e "${BOLD}${BG_YELLOW}${BLUE}▶ [2] Install Nginx (Remove Apache2)${RESET}"
        else
            echo -e "${YELLOW}  [2] Install Nginx (Remove Apache2)${RESET}"
        fi
        
        if [ $selected_option -eq 2 ]; then
            echo -e "${BOLD}${BG_YELLOW}${BLUE}▶ [3] Install and Configure UFW${RESET}"
        else
            echo -e "${YELLOW}  [3] Install and Configure UFW${RESET}"
        fi
        
        if [ $selected_option -eq 3 ]; then
            echo -e "${BOLD}${BG_YELLOW}${BLUE}▶ [4] Install OpenSSH${RESET}"
        else
            echo -e "${YELLOW}  [4] Install OpenSSH${RESET}"
        fi
        
        if [ $selected_option -eq 4 ]; then
            echo -e "${BOLD}${BG_YELLOW}${BLUE}▶ [5] Install Zsh and Oh My Zsh${RESET}"
        else
            echo -e "${YELLOW}  [5] Install Zsh and Oh My Zsh${RESET}"
        fi
        
        if [ $selected_option -eq 5 ]; then
            echo -e "${BOLD}${BG_YELLOW}${BLUE}▶ [6] Install Essential Packages${RESET}"
        else
            echo -e "${YELLOW}  [6] Install Essential Packages (curl, wget, nano)${RESET}"
        fi
        
        if [ $selected_option -eq 6 ]; then
            echo -e "${BOLD}${BG_YELLOW}${BLUE}▶ [7] Install Docker${RESET}"
        else
            echo -e "${YELLOW}  [7] Install Docker${RESET}"
        fi
        
        if [ $selected_option -eq 7 ]; then
            echo -e "${BOLD}${BG_YELLOW}${BLUE}▶ [8] Install Snakeoil SSL Certificate${RESET}"
        else
            echo -e "${YELLOW}  [8] Install Snakeoil SSL Certificate${RESET}"
        fi
        
        if [ $selected_option -eq 8 ]; then
            echo -e "${BOLD}${BG_YELLOW}${BLUE}▶ [9] Install Certbot (Let's Encrypt)${RESET}"
        else
            echo -e "${YELLOW}  [9] Install Certbot (Let's Encrypt)${RESET}"
        fi
        
        if [ $selected_option -eq 9 ]; then
            echo -e "${BOLD}${BG_YELLOW}${BLUE}▶ [10] Install Git${RESET}"
        else
            echo -e "${YELLOW}  [10] Install Git${RESET}"
        fi
        
        if [ $selected_option -eq 10 ]; then
            echo -e "${BOLD}${BG_YELLOW}${BLUE}▶ [11] Install Node.js (NVM)${RESET}"
        else
            echo -e "${YELLOW}  [11] Install Node.js (NVM)${RESET}"
        fi
        
        if [ $selected_option -eq 11 ]; then
            echo -e "${BOLD}${BG_BLUE}${WHITE}▶ [12] Exit${RESET}"
        else
            echo -e "${BLUE}  [12] Exit${RESET}"
        fi
        
        echo ""
        echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
        echo -e "${BOLD}${WHITE}Controls: ${CYAN}↑↓${WHITE} Navigate | ${CYAN}Enter${WHITE} Select | ${CYAN}1-12${WHITE} Quick Select${RESET}"
        
        # Read input using read_key
        key=$(read_key)
        case "$key" in
            "UP")
                if [ $selected_option -gt 0 ]; then
                    ((selected_option--))
                else
                    selected_option=11
                fi
                ;;
            "DOWN")
                if [ $selected_option -lt 11 ]; then
                    ((selected_option++))
                else
                    selected_option=0
                fi
                ;;
            "ENTER")
                return $selected_option
                ;;
            "1"|"2"|"3"|"4"|"5"|"6"|"7"|"8"|"9"|"10"|"11"|"12")
                return $((${key} - 1))
                ;;
            "ESC"|"q"|"Q")
                return 11  # Exit
                ;;
        esac
    done
}

# Main execution
clear

# Check OS and root
check_os
check_root

echo -e "${BOLD}${CYAN}========================================${RESET}"
echo -e "${BOLD}${CYAN}    Ubuntu Environment Setup    ${RESET}"
echo -e "${BOLD}${CYAN}========================================${RESET}"
echo ""

# Main menu loop
while true; do
    show_main_menu
    menu_choice=$?
    
    case $menu_choice in
        0)
            # Install All
            clear
            echo -e "${BOLD}${GREEN}🚀 Installing all packages...${RESET}"
            echo ""
            install_nginx
            install_ufw
            install_openssh
            install_zsh
            install_essential_packages
            install_docker
            install_snakeoil_cert
            install_certbot
            install_git
            install_node
            echo -e "${BOLD}${GREEN}✅ All installations completed!${RESET}"
            echo ""
            read -p "Press Enter to continue..."
            ;;
        1)
            # Install Nginx
            clear
            install_nginx
            read -p "Press Enter to continue..."
            ;;
        2)
            # Install UFW
            clear
            install_ufw
            read -p "Press Enter to continue..."
            ;;
        3)
            # Install OpenSSH
            clear
            install_openssh
            read -p "Press Enter to continue..."
            ;;
        4)
            # Install Zsh
            clear
            install_zsh
            read -p "Press Enter to continue..."
            ;;
        5)
            # Install Essential Packages
            clear
            install_essential_packages
            read -p "Press Enter to continue..."
            ;;
        6)
            # Install Docker
            clear
            install_docker
            read -p "Press Enter to continue..."
            ;;
        7)
            # Install Snakeoil SSL Certificate
            clear
            install_snakeoil_cert
            read -p "Press Enter to continue..."
            ;;
        8)
            # Install Certbot
            clear
            install_certbot
            read -p "Press Enter to continue..."
            ;;
        9)
            # Install Git
            clear
            install_git
            read -p "Press Enter to continue..."
            ;;
        10)
            # Install Node.js (NVM)
            clear
            install_node
            read -p "Press Enter to continue..."
            ;;
        11)
            # Exit
            clear
            echo -e "${BOLD}${CYAN}👋 Exiting...${RESET}"
            exit 0
            ;;
    esac
done
