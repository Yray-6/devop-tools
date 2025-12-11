#!/bin/bash
# UI Common Functions - Shared utilities for UI components

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
BG_RED="\033[41m"
RESET="\033[0m"

# ANSI escape codes
CLEAR_LINE="\033[2K"
ESC_SEQ=$'\033'
MOVE_HOME="\033[H"
HIDE_CURSOR="\033[?25l"
SHOW_CURSOR="\033[?25h"

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

# Function to read a single character (including arrow keys)
read_key() {
  local key
  local char
  local old_stty
  local read_exit
  
  old_stty=$(stty -g)
  # Keep intr enabled so Ctrl+C sends SIGINT (not just \x03 character)
  stty -icanon -echo min 0 time 0 intr '^C' 2>/dev/null
  
  # Read character - if Ctrl+C is pressed, SIGINT will be sent and trap will handle it
  # But we also need to handle if read fails or returns \x03
  if ! IFS= read -rsn1 char 2>/dev/null; then
    # Read failed (possibly interrupted)
    stty $old_stty 2>/dev/null
    # If this was due to Ctrl+C, the trap should have handled it, but just in case:
    cleanup_and_exit
    return
  fi
  
  # Restore terminal immediately
  stty $old_stty 2>/dev/null
  
  # Check for Ctrl+C character (even though SIGINT should be sent)
  if [ "$char" = $'\x03' ]; then
    cleanup_and_exit
    return
  fi
  
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
  else
    key="$char"
  fi
  
  echo -n "$key"
}

# Function to move cursor to specific position
move_cursor() {
  local row=$1
  local col=${2:-1}
  echo -ne "\033[${row};${col}H"
}

# Function to clear line
clear_line() {
  echo -ne "${CLEAR_LINE}"
}

# Function to get terminal size
get_terminal_size() {
  local rows cols
  read -r rows cols < <(stty size)
  echo "$rows $cols"
}

