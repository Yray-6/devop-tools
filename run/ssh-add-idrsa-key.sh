#!/bin/bash

# Script metadata
NAME="SSH Key Manager"
DESC="Add SSH public key to remote server for passwordless login"

# Source UI components
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../src/ui/ui_common.sh"
source "$SCRIPT_DIR/../src/ui/scroll_menu.sh"

CONFIG_DIR="./storage/ssh_config"
SSH_RSA_DIR="./storage/ssh_rsa"

# Create directories if not exist
mkdir -p "$CONFIG_DIR"
mkdir -p "$SSH_RSA_DIR"

# Check and install sshpass if not available
if ! command -v sshpass &> /dev/null; then
    echo -e "${YELLOW}⚙️ sshpass not found, installing...${RESET}"
    apt-get update && apt-get install -y sshpass
fi

# Global arrays
declare -a CONFIG_FILES
declare -a CONFIG_NAMES
declare -a KEY_FILES
declare -a MENU_ITEMS

# Function to load config from file
load_config_from_file() {
    local config_file="$1"
    USER=""
    HOST=""
    PORT=""
    PASS=""
    
    if [ -f "$config_file" ]; then
        while IFS='=' read -r key value; do
            [[ -z "$key" || "$key" =~ ^[[:space:]]*# ]] && continue
            key=$(echo "$key" | xargs)
            value=$(echo "$value" | xargs)
            case "$key" in
                USER) USER="$value" ;;
                HOST) HOST="$value" ;;
                PORT) PORT="$value" ;;
                PASS) PASS="$value" ;;
            esac
        done < "$config_file"
    fi
}

# Function to display action menu for selected config
display_config_action_menu() {
    local config_file="$1"
    local selected_action=0  # 0=Add to server, 1=Edit, 2=Back, 3=Delete
    
    load_config_from_file "$config_file"
    
    local config_name=$(basename "$config_file" .conf)
    
    # Action menu loop
    while true; do
        clear
        echo -e "${BOLD}${CYAN}========================================${RESET}"
        echo -e "${BOLD}${CYAN}    Configuration: ${GREEN}$config_name${CYAN}    ${RESET}"
        echo -e "${BOLD}${CYAN}========================================${RESET}"
        echo ""
        echo -e "${BOLD}${WHITE}Connection Details:${RESET}"
        echo -e "  ${YELLOW}Username:${RESET} ${GREEN}$USER${RESET}"
        echo -e "  ${YELLOW}Host:${RESET}     ${GREEN}$HOST${RESET}"
        echo -e "  ${YELLOW}Port:${RESET}     ${GREEN}${PORT:-22}${RESET}"
        echo -e "  ${YELLOW}Password:${RESET} ${GREEN}$(echo "$PASS" | sed 's/./*/g')${RESET} (${#PASS} characters)"
        echo ""
        echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
        echo ""
        echo -e "${BOLD}${WHITE}Select an action:${RESET}"
        echo ""
        
        # Display options with highlighting
        if [ $selected_action -eq 0 ]; then
            echo -e "${BOLD}${BG_GREEN}${WHITE}▶ [1] Add to Server${RESET}"
        else
            echo -e "${GREEN}  [1] Add to Server${RESET}"
        fi
        
        if [ $selected_action -eq 1 ]; then
            echo -e "${BOLD}${BG_YELLOW}${BLUE}▶ [2] Edit${RESET}"
        else
            echo -e "${YELLOW}  [2] Edit${RESET}"
        fi
        
        if [ $selected_action -eq 2 ]; then
            echo -e "${BOLD}${BG_BLUE}${WHITE}▶ [3] Back to Menu${RESET}"
        else
            echo -e "${BLUE}  [3] Back to Menu${RESET}"
        fi
        
        if [ $selected_action -eq 3 ]; then
            echo -e "${BOLD}${BG_RED}${WHITE}▶ [4] Delete${RESET}"
        else
            echo -e "${RED}  [4] Delete${RESET}"
        fi
        
        echo ""
        echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
        echo -e "${BOLD}${WHITE}Controls: ${CYAN}↑↓${WHITE} Navigate | ${CYAN}Enter${WHITE} Select | ${CYAN}1-4${WHITE} Quick Select | ${CYAN}ESC${WHITE} Back${RESET}"
        
        # Wait for user input
        key=$(read_key)
        case "$key" in
            "UP")
                if [ $selected_action -gt 0 ]; then
                    ((selected_action--))
                else
                    selected_action=3
                fi
                ;;
            "DOWN")
                if [ $selected_action -lt 3 ]; then
                    ((selected_action++))
                else
                    selected_action=0
                fi
                ;;
            "ENTER")
                case $selected_action in
                    0) return 0 ;;  # Add to server
                    1) return 1 ;;  # Edit
                    2) return 2 ;;  # Back
                    3) return 3 ;;  # Delete
                esac
                ;;
            "1")
                return 0  # Add to server
                ;;
            "2")
                return 1  # Edit
                ;;
            "3")
                return 2  # Back
                ;;
            "4")
                return 3  # Delete
                ;;
            "ESC"|"BACKSPACE")
                return 2  # Back
                ;;
            *)
                ;;
        esac
    done
}

# Function to edit config file
edit_config_file() {
    local config_file="$1"
    
    # Check if editor is available (prefer nano, fallback to vi)
    local editor=""
    if command -v nano &> /dev/null; then
        editor="nano"
    elif command -v vi &> /dev/null; then
        editor="vi"
    else
        echo -e "${BOLD}${RED}❌ No text editor found (nano or vi)${RESET}"
        read -p "Press Enter to continue..."
        return 1
    fi
    
    clear
    echo -e "${BOLD}${CYAN}Editing configuration file...${RESET}"
    echo -e "${YELLOW}Using editor: $editor${RESET}"
    echo ""
    echo -e "${BOLD}${WHITE}Press ${CYAN}Ctrl+X${WHITE} then ${CYAN}Y${WHITE} and ${CYAN}Enter${WHITE} to save in nano${RESET}"
    echo -e "${BOLD}${WHITE}Press ${CYAN}:wq${WHITE} and ${CYAN}Enter${WHITE} to save in vi${RESET}"
    echo ""
    read -p "Press Enter to open editor..."
    
    # Open editor
    $editor "$config_file"
    local edit_exit=$?
    
    if [ $edit_exit -eq 0 ]; then
        echo ""
        echo -e "${BOLD}${GREEN}✅ Configuration saved successfully!${RESET}"
        read -p "Press Enter to continue..."
        return 0
    else
        echo ""
        echo -e "${BOLD}${YELLOW}⚠️  Configuration was not saved${RESET}"
        read -p "Press Enter to continue..."
        return 1
    fi
}

# Function to delete config file
delete_config_file() {
    local config_file="$1"
    local config_name=$(basename "$config_file" .conf)
    
    clear
    echo -e "${BOLD}${RED}========================================${RESET}"
    echo -e "${BOLD}${RED}    Delete Configuration    ${RESET}"
    echo -e "${BOLD}${RED}========================================${RESET}"
    echo ""
    echo -e "${BOLD}${YELLOW}⚠️  WARNING: This action cannot be undone!${RESET}"
    echo ""
    echo -e "${BOLD}${WHITE}Configuration to delete: ${RED}$config_name${RESET}"
    echo -e "${BOLD}${WHITE}File: ${CYAN}$config_file${RESET}"
    echo ""
    echo -e "${BOLD}${WHITE}Are you sure you want to delete this configuration?${RESET}"
    echo ""
    echo -e "${BOLD}${GREEN}[Y]${RESET} Yes, delete it"
    echo -e "${BOLD}${RED}[N]${RESET} No, cancel"
    echo ""
    
    while true; do
        key=$(read_key)
        case "$key" in
            "y"|"Y")
                if rm -f "$config_file"; then
                    echo ""
                    echo -e "${BOLD}${GREEN}✅ Configuration deleted successfully!${RESET}"
                    read -p "Press Enter to continue..."
                    return 0
                else
                    echo ""
                    echo -e "${BOLD}${RED}❌ Failed to delete configuration!${RESET}"
                    read -p "Press Enter to continue..."
                    return 1
                fi
                ;;
            "n"|"N"|"ESC"|"BACKSPACE")
                echo ""
                echo -e "${BOLD}${CYAN}Deletion cancelled.${RESET}"
                read -p "Press Enter to continue..."
                return 1
                ;;
            *)
                ;;
        esac
    done
}

# Global variable to store selected SSH key content
SELECTED_SSH_KEY_CONTENT=""

# Function to select SSH key
select_ssh_key() {
    SELECTED_SSH_KEY_CONTENT=""
    
    # Load SSH keys
    KEY_FILES=()
    mapfile -t KEY_FILES < <(ls "$SSH_RSA_DIR"/*.pub 2>/dev/null)
    
    for i in "${!KEY_FILES[@]}"; do
        KEY_FILES[$i]=$(basename "${KEY_FILES[$i]}")
    done
    
    if [ ${#KEY_FILES[@]} -eq 0 ]; then
        # No keys, ask to create new
        clear
        echo -e "${BOLD}${YELLOW}⚠️  No SSH public keys found${RESET}"
        echo ""
        read -p "Enter name for new SSH key (without .pub): " NEW_NAME
        read -p "Paste SSH public key content (ssh-rsa ...): " SSH_KEY_CONTENT
        TARGET_FILE="$SSH_RSA_DIR/${NEW_NAME}.pub"
        echo "$SSH_KEY_CONTENT" > "$TARGET_FILE"
        echo -e "${BOLD}${GREEN}✅ Saved SSH key: $(basename "$TARGET_FILE")${RESET}"
        SELECTED_SSH_KEY_CONTENT="$SSH_KEY_CONTENT"
        return 0
    fi
    
    # Build menu items
    local menu_items=("${KEY_FILES[@]}")
    menu_items+=("Create New Key")
    menu_items+=("Back")
    
    # Initialize scroll menu
    scroll_menu_init "${menu_items[@]}"
    
    # Run scroll menu
    scroll_menu_run "Select SSH Public Key"
    local selected=$SCROLL_MENU_RESULT
    local cancelled="${SCROLL_MENU_CANCELLED:-0}"
    
    # Always clear and restore terminal after menu
    clear
    echo -ne "\033[?25h"  # Show cursor
    stty echo 2>/dev/null || true  # Restore echo
    
    # Check if user cancelled
    if [ "$cancelled" -eq 1 ] || [ $selected -eq -1 ]; then
        return 1
    fi
    
    local key_count=${#KEY_FILES[@]}
    local new_key_idx=$key_count
    local back_idx=$(($key_count + 1))
    
    if [ $selected -eq $back_idx ]; then
        return 1
    elif [ $selected -eq $new_key_idx ]; then
        # Create new key
        echo -e "${BOLD}${CYAN}Creating new SSH key...${RESET}"
        echo ""
        read -p "Enter name for new SSH key (without .pub): " NEW_NAME
        read -p "Paste SSH public key content (ssh-rsa ...): " SSH_KEY_CONTENT
        TARGET_FILE="$SSH_RSA_DIR/${NEW_NAME}.pub"
        echo "$SSH_KEY_CONTENT" > "$TARGET_FILE"
        echo -e "${BOLD}${GREEN}✅ Saved SSH key: $(basename "$TARGET_FILE")${RESET}"
        SELECTED_SSH_KEY_CONTENT="$SSH_KEY_CONTENT"
        return 0
    else
        # Selected existing key
        local key_file="${KEY_FILES[$selected]}"
        local target_file="$SSH_RSA_DIR/$key_file"
        if [ -f "$target_file" ]; then
            SELECTED_SSH_KEY_CONTENT=$(cat "$target_file")
            return 0
        else
            echo -e "${BOLD}${RED}❌ Key file not found!${RESET}"
            return 1
        fi
    fi
}

# Function to add SSH key to server
add_key_to_server() {
    local config_file="$1"
    
    load_config_from_file "$config_file"
    
    # Validate config
    if [ -z "$USER" ] || [ -z "$HOST" ] || [ -z "$PORT" ] || [ -z "$PASS" ]; then
        echo -e "${BOLD}${RED}❌ Invalid configuration! Missing required fields.${RESET}"
        read -p "Press Enter to continue..."
        return 1
    fi
    
    # Select SSH key
    if ! select_ssh_key; then
        clear
        return 1
    fi
    
    SSH_KEY_CONTENT="$SELECTED_SSH_KEY_CONTENT"
    
    if [ -z "$SSH_KEY_CONTENT" ]; then
        clear
        echo -e "${BOLD}${RED}❌ No SSH key selected${RESET}"
        read -p "Press Enter to continue..."
        return 1
    fi
    
    # Clear screen and show selected key info
    clear
    echo -e "${BOLD}${CYAN}========================================${RESET}"
    echo -e "${BOLD}${CYAN}    Add SSH Key to Server    ${RESET}"
    echo -e "${BOLD}${CYAN}========================================${RESET}"
    echo ""
    echo -e "${BOLD}${WHITE}Configuration:${RESET}"
    echo -e "  ${YELLOW}Server:${RESET} ${GREEN}$USER@$HOST:$PORT${RESET}"
    echo ""
    echo -e "${BOLD}${WHITE}Selected SSH Key:${RESET}"
    echo -e "${CYAN}$(echo "$SSH_KEY_CONTENT" | head -c 80)...${RESET}"
    echo ""
    
    # Test connection
    echo -e "${BOLD}${CYAN}🔍 Testing connection to ${GREEN}$USER@$HOST:$PORT${CYAN}...${RESET}"
    echo ""
    TEST_OUTPUT=$(sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -p "$PORT" "$USER@$HOST" "echo 'Connection OK'" 2>&1)
    TEST_EXIT=$?
    
    if [ $TEST_EXIT -ne 0 ]; then
        echo -e "${BOLD}${RED}❌ Cannot connect to server!${RESET}"
        echo ""
        echo -e "${YELLOW}Please check:${RESET}"
        echo -e "  ${CYAN}Hostname/IP:${RESET} $HOST"
        echo -e "  ${CYAN}Port:${RESET} $PORT"
        echo -e "  ${CYAN}Username:${RESET} $USER"
        echo ""
        echo -e "${YELLOW}Error details:${RESET}"
        echo "$TEST_OUTPUT"
        echo ""
        read -p "Press Enter to continue..."
        return 1
    fi
    
    echo -e "${BOLD}${GREEN}✅ Connection OK${RESET}"
    echo ""
    
    # Get fingerprint of key
    KEY_FINGERPRINT=$(echo "$SSH_KEY_CONTENT" | awk '{print $2}')
    
    # Create command to add key
    SSH_COMMAND="mkdir -p ~/.ssh && chmod 700 ~/.ssh && grep -qF '$KEY_FINGERPRINT' ~/.ssh/authorized_keys 2>/dev/null && echo 'KEY_EXISTS' || (echo '$SSH_KEY_CONTENT' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && echo 'KEY_ADDED')"
    
    # Upload key
    echo -e "${BOLD}${BLUE}📤 Uploading SSH key...${RESET}"
    echo ""
    RESULT=$(sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no -p "$PORT" "$USER@$HOST" "$SSH_COMMAND" 2>&1)
    EXIT_CODE=$?
    
    if [ $EXIT_CODE -eq 0 ]; then
        if echo "$RESULT" | grep -q "KEY_EXISTS"; then
            echo -e "${BOLD}${YELLOW}⚠️  SSH key already exists on server $USER@$HOST${RESET}"
            echo -e "${BOLD}${GREEN}✅ You can SSH to the server without password: ${CYAN}ssh -p $PORT $USER@$HOST${RESET}"
        elif echo "$RESULT" | grep -q "KEY_ADDED"; then
            echo -e "${BOLD}${GREEN}✅ SSH key uploaded successfully to $USER@$HOST${RESET}"
            echo -e "${BOLD}${GREEN}✅ You can SSH to the server without password: ${CYAN}ssh -p $PORT $USER@$HOST${RESET}"
        else
            echo -e "${BOLD}${GREEN}✅ SSH key processed on $USER@$HOST${RESET}"
        fi
    else
        echo -e "${BOLD}${RED}❌ Upload failed (Exit code: $EXIT_CODE)${RESET}"
        echo -e "${YELLOW}Error output:${RESET}"
        echo "$RESULT"
    fi
    
    echo ""
    read -p "Press Enter to continue..."
}

# Function to handle configuration action
handle_config_action() {
    local selected_file="$1"
    
    # Validate that file exists
    if [ ! -f "$selected_file" ]; then
        echo -e "${BOLD}${RED}❌ Error: Configuration file not found!${RESET}"
        read -p "Press Enter to continue..."
        return 1
    fi
    
    # Show action menu
    display_config_action_menu "$selected_file"
    local action=$?
    
    case $action in
        0)
            # Add to server selected
            add_key_to_server "$selected_file"
            ;;
        1)
            # Edit selected
            if edit_config_file "$selected_file"; then
                return 0
            fi
            ;;
        2)
            # Back selected - do nothing, just return
            return 0
            ;;
        3)
            # Delete selected
            if delete_config_file "$selected_file"; then
                # Config was deleted, return to reload menu
                return 0
            fi
            ;;
    esac
    
    return 0
}

# Function to create new configuration
handle_new_configuration() {
    clear
    echo -e "${BOLD}${CYAN}Creating new configuration...${RESET}"
    echo ""
    read -p "User: " USER
    read -p "Host (IP or domain): " HOST
    read -p "Port [22]: " PORT
    PORT=${PORT:-22}
    read -sp "Password: " PASS
    echo ""
    
    read -p "Config filename (without .conf, default: ${USER}-${HOST}): " CONFIG_NAME
    CONFIG_NAME=${CONFIG_NAME:-"${USER}-${HOST}"}
    
    CONFIG_FILE="$CONFIG_DIR/${CONFIG_NAME}.conf"
    cat > "$CONFIG_FILE" <<EOF
USER=$USER
HOST=$HOST
PORT=$PORT
PASS=$PASS
EOF
    echo -e "${BOLD}${GREEN}✅ Saved new config to $(basename "$CONFIG_FILE")${RESET}"
    echo ""
    read -p "Press Enter to continue..."
}

# Function to load menu items
load_menu_items() {
    # Load configurations
    mapfile -t CONFIG_FILES < <(ls "$CONFIG_DIR"/*.conf 2>/dev/null)
    
    # Clear arrays before building
    CONFIG_NAMES=()
    MENU_ITEMS=()
    
    # Build menu items array
    for file in "${CONFIG_FILES[@]}"; do
        fname=$(basename "$file")
        CONFIG_NAMES+=("${fname%.conf}")
        MENU_ITEMS+=("${fname%.conf}")
    done
    
    # Add special options
    MENU_ITEMS+=("New Configuration")
    MENU_ITEMS+=("Quit (Return to Main Menu)")
}

# Function to handle quit action
handle_quit() {
    clear
    echo -e "${BOLD}${GREEN}👋 Returning to main menu...${RESET}"
    exit 0
}

# Function to handle configuration selection
handle_config_selection() {
    local selected=$1
    local config_count=$2
    
    if [ $selected -ge 0 ] && [ $selected -lt $config_count ]; then
        local selected_file="${CONFIG_FILES[$selected]}"
        handle_config_action "$selected_file"
        return 0
    else
        # Invalid selection
        echo -e "${BOLD}${RED}❌ Invalid selection: $selected${RESET}"
        echo -e "${YELLOW}Please try again.${RESET}"
        read -p "Press Enter to continue..."
        return 1
    fi
}

# Function to run main menu
run_main_menu() {
    # Load and build menu items
    load_menu_items
    
    # Initialize scroll menu
    scroll_menu_init "${MENU_ITEMS[@]}"
    
    # Run scroll menu
    scroll_menu_run "SSH Key Manager"
    local selected=$SCROLL_MENU_RESULT
    
    # Check if user cancelled
    if [ "${SCROLL_MENU_CANCELLED:-0}" -eq 1 ] || [ $selected -eq -1 ]; then
        handle_quit
    fi
    
    # Calculate indices
    local config_count=${#CONFIG_NAMES[@]}
    local new_idx=$config_count
    local quit_idx=$(($config_count + 1))
    
    # Handle selection
    if [ $selected -eq $quit_idx ]; then
        # Quit selected
        handle_quit
    elif [ $selected -eq $new_idx ]; then
        # New configuration selected
        handle_new_configuration
    else
        # Configuration selected
        handle_config_selection $selected $config_count
    fi
}

# Main menu loop
while true; do
    run_main_menu
done
