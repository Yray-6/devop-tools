#!/bin/bash

# Enhanced color codes
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
MAGENTA="\033[35m"
CYAN="\033[36m"
WHITE="\033[37m"
BOLD="\033[1m"
BG_BLUE="\033[44m"
BG_GREEN="\033[42m"
BG_YELLOW="\033[43m"
RESET="\033[0m"

# ANSI escape codes for cursor control
CURSOR_UP="\033[A"
CURSOR_DOWN="\033[B"
CURSOR_RIGHT="\033[C"
CURSOR_LEFT="\033[D"
SAVE_CURSOR="\033[s"
RESTORE_CURSOR="\033[u"
CLEAR_LINE="\033[2K"
HIDE_CURSOR="\033[?25l"
SHOW_CURSOR="\033[?25h"
MOVE_HOME="\033[H"

# Arrow key sequences
ARROW_UP=$'\033[A'
ARROW_DOWN=$'\033[B'
ARROW_RIGHT=$'\033[C'
ARROW_LEFT=$'\033[D'
ESC_SEQ=$'\033'

# Welcome banner
clear
echo -e "${BOLD}${CYAN}========================================${RESET}"
echo -e "${BOLD}${CYAN}    Welcome to Khaizinam's Script Manager    ${RESET}"
echo -e "${BOLD}${CYAN}========================================${RESET}"
echo ""

# Kiểm tra quyền root/sudo
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}❌ This script requires root privileges. Please run with sudo:${RESET}"
  echo -e "${YELLOW}   sudo bash app_ui.sh${RESET}"
  exit 1
fi

# Check and install nano if not available
if ! command -v nano &> /dev/null; then
  echo -e "${BOLD}${YELLOW}⚠️  nano not found, installing...${RESET}"
  if command -v apt-get &> /dev/null; then
    apt-get update -qq && apt-get install -y nano
  elif command -v yum &> /dev/null; then
    yum install -y nano
  elif command -v dnf &> /dev/null; then
    dnf install -y nano
  elif command -v pacman &> /dev/null; then
    pacman -S --noconfirm nano
  else
    echo -e "${RED}❌ Cannot install nano: package manager not found${RESET}"
    echo -e "${YELLOW}⚠️  Some scripts may require nano editor${RESET}"
  fi
  echo ""
fi

echo -e "${BOLD}${GREEN}🚀 Efficient system administration made easy!${RESET}"
echo -e "${BOLD}${YELLOW}📋 Choose from the available scripts below:${RESET}"
echo ""

# Save terminal settings
TERM_SETTINGS=$(stty -g)

# Function to restore terminal on exit
cleanup_terminal() {
  # Restore terminal settings
  stty $TERM_SETTINGS 2>/dev/null 2>&1
  # Show cursor
  echo -ne "${SHOW_CURSOR}"
  # Move to new line
  echo ""
}

# Enhanced cleanup with exit (for Ctrl+C)
cleanup_and_exit() {
  cleanup_terminal
  echo -e "${BOLD}${YELLOW}⚠️  Interrupted by user${RESET}"
  exit 130  # Standard exit code for Ctrl+C (128 + 2)
}

# Set up traps for clean exit
# EXIT trap will always run, INT trap handles Ctrl+C
trap cleanup_terminal EXIT
trap cleanup_and_exit INT TERM

# Function to read NAME and DESC variables from script file
read_script_metadata() {
  local script_file="$1"
  local metadata_type="$2"  # "NAME" or "DESC"
  
  if [ ! -f "$script_file" ]; then
    return 1
  fi
  
  # Extract variable value using grep and sed
  # Looks for: NAME="value" or NAME='value' or NAME=value
  local value=$(grep -m 1 "^${metadata_type}=" "$script_file" 2>/dev/null | sed "s/^${metadata_type}=//" | sed 's/^["'\'']//' | sed 's/["'\'']$//' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
  
  if [ -n "$value" ]; then
    echo "$value"
  else
    return 1
  fi
}

# Function to get script display name
get_script_name() {
  local script_file="$1"
  local name=$(read_script_metadata "$script_file" "NAME")
  
  if [ -n "$name" ]; then
    echo "$name"
  else
    # Fallback to filename without extension
    basename "$script_file" .sh
  fi
}

# Function to get script description
get_script_description() {
  local script_file="$1"
  local desc=$(read_script_metadata "$script_file" "DESC")
  
  if [ -n "$desc" ]; then
    # Return full description without truncation
    echo "$desc"
  else
    # Return empty if no DESC variable found
    echo ""
  fi
}

# Function to read a single character (including arrow keys)
read_key() {
  local key
  local char
  local old_stty
  local read_exit
  
  # Save and modify terminal settings
  old_stty=$(stty -g)
  # Keep signal processing enabled so Ctrl+C works
  stty -icanon -echo min 0 time 0 intr '^C' 2>/dev/null
  
  # Read first character - Ctrl+C will send SIGINT which is trapped
  IFS= read -rsn1 char 2>/dev/null || {
    # If read fails (interrupted), restore and exit
    stty $old_stty 2>/dev/null
    cleanup_and_exit
    return
  }
  
  # Restore terminal immediately after read
  stty $old_stty 2>/dev/null
  
  if [ "$char" = "$ESC_SEQ" ]; then
    # Read second character for escape sequences
    old_stty=$(stty -g)
    stty -icanon -echo min 0 time 0 intr '^C' 2>/dev/null
    IFS= read -rsn1 -t 0.1 char 2>/dev/null
    stty $old_stty 2>/dev/null
    if [ "$char" = "[" ]; then
      # Read third character (arrow key)
      old_stty=$(stty -g)
      stty -icanon -echo min 0 time 0 intr '^C' 2>/dev/null
      IFS= read -rsn1 -t 0.1 char 2>/dev/null
      stty $old_stty 2>/dev/null
      
      case "$char" in
        A) key="UP" ;;
        B) key="DOWN" ;;
        C) key="RIGHT" ;;
        D) key="LEFT" ;;
        *) key="UNKNOWN" ;;
      esac
    else
      key="ESC"
    fi
  elif [ "$char" = "" ] || [ "$char" = $'\n' ] || [ "$char" = $'\r' ]; then
    key="ENTER"
  elif [ "$char" = $'\x7f' ] || [ "$char" = $'\x08' ]; then
    key="BACKSPACE"
  elif [ "$char" = $'\x03' ]; then
    # Ctrl+C detected as character
    cleanup_and_exit
    return
  else
    key="$char"
  fi
  
  echo -n "$key"
}

# Function to display menu with highlighted selection
# Uses cached metadata arrays to avoid re-reading files
display_menu() {
  local selected=$1
  
  # Clear screen and show header
  clear
  echo -e "${BOLD}${CYAN}========================================${RESET}"
  echo -e "${BOLD}${CYAN}    Welcome to Khaizinam's Script Manager    ${RESET}"
  echo -e "${BOLD}${CYAN}========================================${RESET}"
  echo -e "${BOLD}${GREEN}🚀 Efficient system administration made easy!${RESET}"
  echo -e "${BOLD}${YELLOW}📋 Choose from the available scripts below:${RESET}"
  echo ""
  
  local display_idx=0
  
  # Display Exit option
  if [ $selected -eq 0 ]; then
    echo -e "${BOLD}${BG_BLUE}${WHITE}  [0] Exit  ${RESET} ${CYAN}(Quit the manager)${RESET}"
  else
    echo -e "${MAGENTA}  [0] ${BOLD}Exit${RESET}  ${CYAN}(Quit the manager)${RESET}"
  fi
  
  # Display script options using cached data (no file I/O)
  for ((i=0; i<${#SCRIPT_NAMES[@]}; i++)); do
    ((display_idx++))
    local name="${SCRIPT_NAMES[$i]}"
    local desc="${SCRIPT_DESCS[$i]}"
    
    if [ $selected -eq $display_idx ]; then
      # Highlight selected option
      if (( display_idx % 2 == 0 )); then
        echo -e "${BOLD}${BG_GREEN}${WHITE}▶ [$display_idx] $name${RESET}"
        if [ -n "$desc" ]; then
          echo -e "${BOLD}${BG_GREEN}${WHITE}   └─ ${desc}${RESET}"
        fi
      else
        echo -e "${BOLD}${BG_YELLOW}${BLUE}▶ [$display_idx] $name${RESET}"
        if [ -n "$desc" ]; then
          echo -e "${BOLD}${BG_YELLOW}${BLUE}   └─ ${desc}${RESET}"
        fi
      fi
    else
      # Normal display
      if (( display_idx % 2 == 0 )); then
        echo -e "${GREEN}  [$display_idx] $name${RESET}"
        if [ -n "$desc" ]; then
          echo -e "${CYAN}     └─ ${desc}${RESET}"
        fi
      else
        echo -e "${YELLOW}  [$display_idx] $name${RESET}"
        if [ -n "$desc" ]; then
          echo -e "${CYAN}     └─ ${desc}${RESET}"
        fi
      fi
    fi
  done
  
  echo ""
  echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo -e "${BOLD}${WHITE}Controls: ${CYAN}↑↓${WHITE} Navigate | ${CYAN}Enter${WHITE} Select | ${CYAN}Type number${WHITE} Jump | ${CYAN}q${WHITE} Quit${RESET}"
  if [ -n "$INPUT_BUFFER" ]; then
    echo -e "${BOLD}${CYAN}Input: ${GREEN}$INPUT_BUFFER${RESET}"
  fi
}

# Main loop function
main_loop() {
  FILES_PATH=$(ls run/*.sh 2>/dev/null)
  if [ -z "$FILES_PATH" ]; then
    echo -e "${RED}❌ No scripts found in run/ directory!${RESET}"
    exit 1
  fi
  
  INDEX=0
  declare -a FILES
  declare -a SCRIPT_NAMES
  declare -a SCRIPT_DESCS
  
  # Populate FILES array and cache metadata (only once)
  for EACH_FILE in $FILES_PATH; do
    FILES+=("$EACH_FILE")
    SCRIPT_NAMES+=("$(get_script_name "$EACH_FILE")")
    SCRIPT_DESCS+=("$(get_script_description "$EACH_FILE")")
    ((INDEX++))
  done
  
  local selected=0
  local prev_selected=0
  local total_options=$INDEX
  local INPUT_BUFFER=""
  
  # Initial display (full render with cached data)
  display_menu $selected
  
  # Input loop
  while true; do
    local key=$(read_key)
    
    case "$key" in
      "UP")
        if [ $selected -gt 0 ]; then
          ((selected--))
        else
          selected=$total_options
        fi
        INPUT_BUFFER=""
        # Redraw menu (uses cached arrays, no file I/O)
        display_menu $selected
        ;;
      "DOWN")
        if [ $selected -lt $total_options ]; then
          ((selected++))
        else
          selected=0
        fi
        INPUT_BUFFER=""
        # Redraw menu (uses cached arrays, no file I/O)
        display_menu $selected
        ;;
      "ENTER")
        break
        ;;
      "q"|"Q")
        selected=0
        break
        ;;
      "BACKSPACE")
        if [ -n "$INPUT_BUFFER" ]; then
          INPUT_BUFFER="${INPUT_BUFFER%?}"
          # Redraw menu with updated input buffer
          display_menu $selected
        fi
        ;;
      [0-9])
        INPUT_BUFFER+="$key"
        # Update selection based on input
        if [[ "$INPUT_BUFFER" =~ ^[0-9]+$ ]]; then
          local num_input=$((10#$INPUT_BUFFER))
          if [ $num_input -le $total_options ]; then
            selected=$num_input
          fi
        fi
        # Redraw menu with updated selection (uses cached arrays, no file I/O)
        display_menu $selected
        ;;
      *)
        # Ignore other keys
        ;;
    esac
  done
  
  # Show cursor again and clear input
  echo -ne "${SHOW_CURSOR}"
  INPUT_BUFFER=""
  
  # Check if exit was selected
  if [ $selected -eq 0 ]; then
    echo -e "${BOLD}${GREEN}👋 Thank you for using Khaizinam's Script Manager!${RESET}"
    echo -e "${CYAN}Goodbye! 👋${RESET}"
    exit 0
  fi
  
  # Get selected file
  SELECTED_FILE=${FILES[$((selected-1))]}
  SELECTED_NAME=$(basename "$SELECTED_FILE")
  
  echo ""
  echo -e "${BOLD}${CYAN}========================================${RESET}"
  echo -e "${BOLD}${GREEN}🚀 Executing: $SELECTED_NAME${RESET}"
  echo -e "${BOLD}${CYAN}========================================${RESET}"
  echo ""
  
  # Run the selected script
  bash "$SELECTED_FILE"
  
  echo ""
  echo -e "${BOLD}${YELLOW}✅ Script execution completed!${RESET}"
  echo ""
  echo -e "${BOLD}${CYAN}Press Enter to return to the main menu...${RESET}"
  read -r
  
  # Clear screen and restart the loop
  clear
  echo -e "${BOLD}${CYAN}========================================${RESET}"
  echo -e "${BOLD}${CYAN}    Welcome back to Script Manager    ${RESET}"
  echo -e "${BOLD}${CYAN}========================================${RESET}"
  echo ""
}

# Start the main loop
while true; do
  main_loop
done
