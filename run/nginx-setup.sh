#!/bin/bash

# Script metadata
NAME="Nginx Setup"
DESC="Configure and setup Nginx web server with PHP support"

# DEFAULT VARIABLES
PHP_VERSION="8.2"
APP_TYPE="laravel"
ROOT_DIR="/var/www"
GIT=""
GIT_BRANCH="main"
DOMAIN_NAME=""
CONFIG_DIR="./storage/config"
ROOT_PROJECT=""
PHP_PROJECT="true"

# Tạo thư mục config nếu chưa tồn tại
mkdir -p $CONFIG_DIR

# FUNCTION: Tạo file cấu hình
create_project_config() {
  CONFIG_FILE="$CONFIG_DIR/$DOMAIN_NAME.conf"

  echo "Tạo file cấu hình tại: $CONFIG_FILE"
  cat <<EOL >$CONFIG_FILE
PHP_PROJECT="$PHP_PROJECT"
PHP_VERSION="$PHP_VERSION"
APP_TYPE="$APP_TYPE"
ROOT_DIR="$ROOT_DIR/$DOMAIN_NAME"
ROOT_PROJECT="$ROOT_PROJECT"
GIT="$GIT"
GIT_BRANCH="$GIT_BRANCH"
SCRIPT=""
DOMAIN_NAME="$DOMAIN_NAME"
EOL
  echo "Đã tạo file cấu hình thành công!"
  echo "$CONFIG_FILE"
}

# Menu chính
echo "Chọn chức năng:"
echo "[1] Tạo mới dự án"
echo "[2] Danh sách dự án"
echo "[3] Tạo lại dự án từ config"
echo "[4] Xoá dự án"
read -p "Nhập lựa chọn của bạn: " FUNCTION_CHOICE

case $FUNCTION_CHOICE in
1)
  echo "Bạn đã chọn: Tạo mới dự án"

  # Hỏi có dùng PHP không
  read -p "Bạn có muốn sử dụng PHP không? [Y/n]: " USE_PHP
  if [[ "$USE_PHP" =~ ^[nN]$ ]]; then
    PHP_PROJECT="false"
    PHP_VERSION=""
    echo "Chế độ: Static HTML (không dùng PHP)"
  else
    PHP_PROJECT="true"
    read -p "Nhập phiên bản PHP (default: $PHP_VERSION): " INPUT_PHP_VERSION
    PHP_VERSION=${INPUT_PHP_VERSION:-$PHP_VERSION}
    echo "Chế độ: PHP $PHP_VERSION"
  fi

  read -p "Nhập tên miền: " DOMAIN_NAME

  read -p "Nhập root index (default: trống = /public_html, hoặc /public nếu dùng Laravel): " INPUT_ROOT_PROJECT
  ROOT_PROJECT=${INPUT_ROOT_PROJECT:-$ROOT_PROJECT}

  # Hỏi có dùng Git không
  read -p "Bạn có muốn sử dụng Git để clone dự án không? [y/N]: " USE_GIT
  if [[ "$USE_GIT" =~ ^[yY]$ ]]; then
    read -p "Nhập đường dẫn Git repo: " GIT
    read -p "Nhập nhánh Git (mặc định: $GIT_BRANCH): " INPUT_GIT_BRANCH
    GIT_BRANCH=${INPUT_GIT_BRANCH:-$GIT_BRANCH}
  else
    GIT=""
    GIT_BRANCH=""
  fi

  echo "Đang tạo dự án với thông tin:"
  echo "PHP Version: $PHP_VERSION"
  echo "Git Branch: $GIT_BRANCH"
  echo "Domain Name: $DOMAIN_NAME"
  echo "Git Repo: $GIT"

  # Tạo file cấu hình
  create_project_config

  # Hỏi người dùng xác nhận khởi tạo
  read -p "Bạn có muốn khởi tạo dự án với các option trên? [y/N]: " CONFIRM
  if [[ "$CONFIRM" =~ ^[yY]$ ]]; then
    bash src/services/init-nginx.sh "$CONFIG_FILE"
  else
    echo "Khởi tạo dự án đã bị hủy."
  fi
  ;;
2)
  echo "Bạn đã chọn: Danh sách dự án"
  # Kiểm tra xem thư mục config có file nào không
  if [ -z "$(ls -A $CONFIG_DIR)" ]; then
    echo "Thư mục config hiện không có file nào."
  else
    echo "Danh sách file cấu hình trong thư mục config:"
    ls -1 $CONFIG_DIR
  fi
  ;;
3)
  echo "Bạn đã chọn: Tạo lại dự án từ config"

  # Hỏi người dùng nhập tên config muốn chạy
  read -p "Nhập tên config muốn chạy (ví dụ: khaizinam.test.conf): " PATHNAME

  # Kiểm tra file cấu hình có tồn tại không
  CONFIG_FILE="./storage/config/$PATHNAME"
  if [ -f "$CONFIG_FILE" ]; then
    # Chạy script init-nginx.sh với file cấu hình
    bash src/services/init-nginx.sh "$CONFIG_FILE"
  else
    echo "File cấu hình $PATHNAME không tồn tại."
  fi
  ;;
4)
  echo "Bạn đã chọn: Xoá dự án"

  # Hỏi người dùng nhập tên config muốn xoá
  read -p "Nhập tên domain muốn xoá (ví dụ: khaizinam.test): " PATHNAME

  # Xoá thư mục dự án nếu tồn tại
  PROJECT_PATH="$ROOT_DIR/$PATHNAME"
  if [ -d "$PROJECT_PATH" ]; then
    echo "Đang xoá thư mục dự án: $PROJECT_PATH"
    rm -rf "$PROJECT_PATH"
    if [ $? -eq 0 ]; then
      echo "Đã xoá thư mục dự án thành công!"
    else
      echo "Lỗi khi xoá thư mục dự án!"
    fi
  else
    echo "Thư mục dự án $PROJECT_PATH không tồn tại."
  fi
  #xoa nginx config
  NGINX_CONFIG="/etc/nginx/sites-available/$PATHNAME.conf"
  if [ -f "$NGINX_CONFIG" ]; then
    echo "Đang xoá cấu hình Nginx: $NGINX_CONFIG"
    rm -f "$NGINX_CONFIG"
    if [ $? -eq 0 ]; then
      echo "Đã xoá cấu hình Nginx thành công!"
    else
      echo "Lỗi khi xoá cấu hình Nginx!"
    fi
  else
    echo "Cấu hình Nginx $NGINX_CONFIG không tồn tại."
  fi
  # Tái khởi động Nginx
  echo "Đang tái khởi động Nginx..."
  systemctl restart nginx
  if [ $? -eq 0 ]; then
    echo "Nginx đã được tái khởi động thành công!"
  else
    echo "Lỗi khi tái khởi động Nginx!"
  fi
  echo "Đã xoá dự án thành công!"
  ;;
*)
  echo "Lựa chọn không hợp lệ. Vui lòng thử lại."
  ;;
esac
