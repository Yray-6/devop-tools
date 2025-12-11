#!/bin/bash

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Load config
# If argument provided, use it (can be relative or absolute)
# Otherwise, default to project root config directory
if [ -n "$1" ]; then
    CONFIG_FILE="$1"
    # Convert relative path to absolute path
    # If it's relative (doesn't start with /), resolve from current directory
    if [[ "$CONFIG_FILE" != /* ]]; then
        # If relative path, resolve from current working directory
        CONFIG_FILE="$(cd "$(dirname "$CONFIG_FILE" 2>/dev/null || echo ".")" && pwd)/$(basename "$CONFIG_FILE")"
    fi
else
    # Default: use project root config directory
    CONFIG_FILE="$PROJECT_ROOT/config/project_config.conf"
fi

if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "\033[1;31mError: Configuration file $CONFIG_FILE not found! Exiting...\033[0;39m"
    exit 1
fi
source "$CONFIG_FILE"

# Set default value for PHP_PROJECT if not defined (backward compatibility)
PHP_PROJECT=${PHP_PROJECT:-"true"}

# Lưu thông tin user gốc (trước khi sudo) để sử dụng SSH keys
REAL_USER=${SUDO_USER:-$USER}
REAL_HOME=$(eval echo ~$REAL_USER)

# Định nghĩa màu sắc
NORMAL="\033[0;39m"
BLUE="\033[1;34m"
ORANGE="\033[1;33m"
RED="\033[1;31m"

# Kiểm tra và cài đặt Nginx nếu chưa có
if ! command -v nginx &> /dev/null; then
    echo -e "${ORANGE}Nginx is not installed. Installing Nginx...${NORMAL}"
    # Source install-nginx service
    if [ -f "$SCRIPT_DIR/install-nginx.sh" ]; then
        source "$SCRIPT_DIR/install-nginx.sh"
        # Call install function (non-interactive if already installed)
        if ! command -v nginx &> /dev/null; then
            install_nginx_main
        fi
    else
        echo -e "${RED}Error: install-nginx.sh not found!${NORMAL}"
        echo -e "${BLUE}Attempting to install Nginx manually...${NORMAL}"
        apt-get update -qq && apt-get install -y nginx
        if [ $? -ne 0 ]; then
            echo -e "${RED}Failed to install Nginx! Exiting...${NORMAL}"
            exit 1
        fi
    fi
    echo -e "${BLUE}Nginx installation completed.${NORMAL}"
fi

# Kiểm tra các tham số bắt buộc
if [ -z "$DOMAIN_NAME" ] || [ -z "$ROOT_DIR" ]; then
    echo -e "${RED}Missing configuration! Please check $CONFIG_FILE${NORMAL}"
    exit 1
fi

# Kiểm tra PHP_VERSION nếu dự án dùng PHP
if [ "$PHP_PROJECT" = "true" ] && [ -z "$PHP_VERSION" ]; then
    echo -e "${RED}PHP_PROJECT is enabled but PHP_VERSION is not set! Please check $CONFIG_FILE${NORMAL}"
    exit 1
fi

if [ -z "$GIT" ]; then
    echo -e "${RED}No Git repository specified in the configuration file.${NORMAL}"
fi

# Đường dẫn dự án
PROJECT_PATH="$ROOT_DIR"

# Kiểm tra nếu thư mục đã tồn tại
if [ -d "$PROJECT_PATH" ]; then
    echo -e "${ORANGE}Project directory $PROJECT_PATH already exists.${NORMAL}"
    read -p "Do you want to remove it and create a new one? [y/N]: " choice
    case "$choice" in
        y|Y)
            echo -e "${BLUE}Removing existing project directory...${NORMAL}"
            rm -rf "$PROJECT_PATH"
            if [ $? -eq 0 ]; then
                echo -e "${BLUE}Removed existing project directory successfully!${NORMAL}"
            else
                echo -e "${RED}Failed to remove existing project directory! Exiting...${NORMAL}"
                exit 1
            fi
            ;;
        *)
            echo -e "${RED}Operation aborted by user.${NORMAL}"
            exit 1
            ;;
    esac
fi

# Tạo thư mục dự án
echo -e "${BLUE}Creating project folder...${NORMAL}"
if mkdir -p "$PROJECT_PATH"; then
    mkdir -p "$PROJECT_PATH"/public_html
    chmod -R 777 "$PROJECT_PATH"
    chmod -R 777 "$PROJECT_PATH"/public_html
    echo -e "${BLUE}Project folder created: $PROJECT_PATH${NORMAL}"
else
    echo -e "${RED}Failed to create project folder! Exiting...${NORMAL}"
    exit 1
fi


# Kiểm tra xem có cần clone Git không
if [ -n "$GIT" ] && [ -n "$GIT_BRANCH" ]; then
    echo -e "${BLUE}Cloning Git repository...${NORMAL}"
    
    # Nếu đang chạy với sudo, sử dụng SSH keys của user gốc
    if [ -n "$SUDO_USER" ]; then
        echo -e "${BLUE}Running as sudo, using SSH keys from user: $REAL_USER${NORMAL}"
        # Chạy git clone với user gốc để sử dụng SSH keys của họ
        if sudo -u "$REAL_USER" git clone "$GIT" "$PROJECT_PATH"/public_html; then
            echo -e "${BLUE}Repository cloned successfully!${NORMAL}"
        else
            echo -e "${RED}Failed to clone repository! Exiting...${NORMAL}"
            exit 1
        fi
    else
        # Chạy bình thường nếu không có sudo
        if git clone "$GIT" "$PROJECT_PATH"/public_html; then
            echo -e "${BLUE}Repository cloned successfully!${NORMAL}"
        else
            echo -e "${RED}Failed to clone repository! Exiting...${NORMAL}"
            exit 1
        fi
    fi
    
    # Thêm thư mục vào danh sách safe.directory
    echo -e "${BLUE}Adding project directory to Git safe.directory...${NORMAL}"
    git config --global --add safe.directory "$PROJECT_PATH"/public_html
    if [ $? -eq 0 ]; then
        echo -e "${BLUE}Added $PROJECT_PATH/public_html to Git safe.directory successfully!${NORMAL}"
    else
        echo -e "${RED}Failed to add $PROJECT_PATH/public_html to Git safe.directory!${NORMAL}"
        exit 1
    fi

    # Chuyển sang nhánh git được chỉ định
    cd "$PROJECT_PATH"/public_html || exit 1
    
    # Kiểm tra xem branch có tồn tại không
    echo -e "${BLUE}Checking if branch '$GIT_BRANCH' exists...${NORMAL}"
    git fetch origin "$GIT_BRANCH" 2>/dev/null
    
    if git show-ref --verify --quiet refs/heads/"$GIT_BRANCH" || git show-ref --verify --quiet refs/remotes/origin/"$GIT_BRANCH"; then
        echo -e "${BLUE}Branch '$GIT_BRANCH' found. Checking out...${NORMAL}"
        if git checkout "$GIT_BRANCH"; then
            echo -e "${BLUE}Checked out to branch $GIT_BRANCH successfully!${NORMAL}"
        else
            echo -e "${ORANGE}Warning: Failed to checkout branch $GIT_BRANCH. Using default branch.${NORMAL}"
        fi
    else
        echo -e "${ORANGE}Warning: Branch '$GIT_BRANCH' does not exist. Staying on default branch.${NORMAL}"
        CURRENT_BRANCH=$(git branch --show-current)
        echo -e "${BLUE}Current branch: $CURRENT_BRANCH${NORMAL}"
    fi
else
    echo -e "${ORANGE}No Git repository or branch specified, skipping Git clone.${NORMAL}"
    # Nếu muốn có thể copy thủ công code vào $PROJECT_PATH/public_html hoặc giữ nguyên thư mục rỗng
fi

# Chạy script bổ sung nếu có
if [ -n "$SCRIPT" ]; then
    echo -e "${BLUE}Running post-clone script...${NORMAL}"
    eval "$SCRIPT"
    if [ $? -eq 0 ]; then
        echo -e "${BLUE}Script executed successfully!${NORMAL}"
    else
        echo -e "${RED}Failed to execute the script: $SCRIPT!${NORMAL}"
        exit 1
    fi
fi

# Kiểm tra và cài đặt snakeoil SSL certificate nếu chưa có
if [ ! -f "/etc/ssl/certs/ssl-cert-snakeoil.pem" ] || [ ! -f "/etc/ssl/private/ssl-cert-snakeoil.key" ]; then
    echo -e "${BLUE}Installing self-signed SSL certificate (snakeoil)...${NORMAL}"
    apt-get update -qq && apt-get install -y ssl-cert
    if [ $? -eq 0 ]; then
        echo -e "${BLUE}Snakeoil SSL certificate installed successfully!${NORMAL}"
    else
        echo -e "${RED}Failed to install snakeoil SSL certificate!${NORMAL}"
        exit 1
    fi
else
    echo -e "${BLUE}Snakeoil SSL certificate already exists.${NORMAL}"
fi

# Tạo file cấu hình Nginx
NGINX_CONF="/etc/nginx/sites-available/$DOMAIN_NAME.conf"
echo -e "${BLUE}Creating Nginx configuration...${NORMAL}"

# Kiểm tra xem có dùng PHP không
if [ "$PHP_PROJECT" = "true" ]; then
    # Cấu hình với PHP
    echo -e "${BLUE}Creating PHP-enabled Nginx config...${NORMAL}"
    cat <<EOL > $NGINX_CONF
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN_NAME;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name $DOMAIN_NAME;
    root $PROJECT_PATH/public_html$ROOT_PROJECT;
    index index.php index.html;
    ssl_certificate     /etc/ssl/certs/ssl-cert-snakeoil.pem;
    ssl_certificate_key /etc/ssl/private/ssl-cert-snakeoil.key;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php$PHP_VERSION-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
    }
    
    location ^~ /.well-known/pki-validation/ {
        allow all;
        default_type "text/plain";
    }

    location ~ /\. {
        deny all;
    }
}
EOL
else
    # Cấu hình static HTML (không dùng PHP)
    echo -e "${BLUE}Creating static HTML Nginx config...${NORMAL}"
    cat <<EOL > $NGINX_CONF
server {
    if ($http_user_agent ~* "(GPTBot|PGTBot|ChatGPT|AIbot|CCBot|Bytespider|MJ12bot|SemrushBot)") { return 444; }
    listen 80;
    listen [::]:80;
    server_name $DOMAIN_NAME;
    return 301 https://$host$request_uri;
}

server {
    if ($http_user_agent ~* "(GPTBot|PGTBot|ChatGPT|AIbot|CCBot|Bytespider|MJ12bot|SemrushBot)") { return 444; }
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name $DOMAIN_NAME;
    root $PROJECT_PATH/public_html$ROOT_PROJECT;
    index index.html index.htm;
    ssl_certificate     /etc/ssl/certs/ssl-cert-snakeoil.pem;
    ssl_certificate_key /etc/ssl/private/ssl-cert-snakeoil.key;

    location / {
        try_files \$uri \$uri/ =404;
    }
    
    location ^~ /.well-known/pki-validation/ {
        allow all;
        default_type "text/plain";
    }

    location ~ /\. {
        deny all;
    }
}
EOL
fi

if [ $? -eq 0 ]; then
    echo -e "${BLUE}Nginx configuration created: $NGINX_CONF${NORMAL}"
else
    echo -e "${RED}Failed to create Nginx configuration! Exiting...${NORMAL}"
    exit 1
fi

# Kích hoạt cấu hình Nginx
echo -e "${BLUE}Activating Nginx site...${NORMAL}"
if ln -sf "$NGINX_CONF" /etc/nginx/sites-enabled/ && systemctl restart nginx; then
    echo -e "${BLUE}Nginx restarted successfully!${NORMAL}"
else
    echo -e "${RED}Failed to restart Nginx. Check configuration and try again.${NORMAL}"
    exit 1
fi

# Thêm domain vào /etc/hosts
if ! grep -q "$DOMAIN_NAME" /etc/hosts; then
    echo "127.0.0.1       $DOMAIN_NAME" | tee -a /etc/hosts > /dev/null
    echo -e "${BLUE}Added $DOMAIN_NAME to /etc/hosts${NORMAL}"
else
    echo -e "${ORANGE}$DOMAIN_NAME already exists in /etc/hosts${NORMAL}"
fi

# Hoàn thành
echo -e "${ORANGE}Project created successfully!${NORMAL}"
echo -e "${ORANGE}Site: https://$DOMAIN_NAME${NORMAL}"
echo -e "${ORANGE}Folder: $PROJECT_PATH${NORMAL}"
