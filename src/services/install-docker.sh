#!/bin/bash

# Service: Install Docker Engine and Docker Compose
# Usage: source this file and call install_docker_main

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Check if Docker is already installed
check_docker_installed() {
    if command -v docker &> /dev/null || systemctl is-active --quiet docker 2>/dev/null || [ -f /usr/bin/docker ]; then
        return 0  # Docker is installed
    else
        return 1  # Docker is not installed
    fi
}

# Remove Docker
remove_docker() {
    echo -e "${BOLD}${RED}🗑️  Removing Docker...${RESET}"
    echo ""
    
    # Stop Docker service
    if systemctl is-active --quiet docker 2>/dev/null; then
        echo -e "${BLUE}🛑 Stopping Docker service...${RESET}"
        systemctl stop docker
        systemctl stop containerd 2>/dev/null || true
    fi
    
    # Remove Docker packages
    apt remove -y docker docker-engine docker.io containerd runc docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 2>/dev/null || true
    apt purge -y docker* containerd* 2>/dev/null || true
    
    # Remove Docker binaries
    rm -f /usr/bin/docker /usr/bin/docker-containerd /usr/bin/docker-containerd-ctr /usr/bin/docker-containerd-shim /usr/bin/docker-init /usr/bin/docker-proxy /usr/bin/dockerd /usr/bin/docker-runc 2>/dev/null || true
    rm -f /usr/local/bin/docker /usr/local/bin/docker-compose 2>/dev/null || true
    rm -f /usr/local/lib/docker/cli-plugins/docker-compose 2>/dev/null || true
    
    # Remove Docker directories
    rm -rf /var/lib/docker /var/lib/containerd /etc/docker /var/run/docker.sock 2>/dev/null || true
    
    # Remove Docker group
    groupdel docker 2>/dev/null || true
    
    echo -e "${GREEN}✅ Docker removed successfully${RESET}"
    echo ""
}

install_docker_main() {
    echo -e "${BLUE}🐳 Installing Docker Engine and Docker Compose...${RESET}"
    
    # Check if Docker is already installed
    if check_docker_installed; then
        if ask_reinstall "Docker"; then
            remove_docker
        else
            echo -e "${BLUE}⏭️  Skipping Docker installation${RESET}"
            return 0
        fi
    fi
    
    # Fix broken repositories before update
    fix_broken_repositories
    
    # Update package list (ignore errors from broken repos)
    apt-get update -y 2>&1 | grep -v "cloudflare\|404\|does not have a Release file" || true
    
    # Install prerequisites
    echo -e "${BLUE}🔧 Installing prerequisites...${RESET}"
    apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release software-properties-common
    
    # Detect OS type (debian or ubuntu)
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [ "$ID" = "ubuntu" ]; then
            DOCKER_OS="ubuntu"
        else
            DOCKER_OS="debian"
        fi
        OS_CODENAME=$(lsb_release -cs 2>/dev/null || echo "${VERSION_CODENAME:-bookworm}")
    else
        DOCKER_OS="debian"
        OS_CODENAME="bookworm"
    fi
    
    # Add Docker's official GPG key
    echo -e "${BLUE}🔑 Adding Docker's official GPG key...${RESET}"
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/${DOCKER_OS}/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    
    # Add Docker repository
    echo -e "${BLUE}📁 Adding Docker repository...${RESET}"
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${DOCKER_OS} ${OS_CODENAME} stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Update package list again
    apt-get update -y 2>&1 | grep -v "cloudflare\|404\|does not have a Release file" || true
    
    # Install Docker Engine
    echo -e "${BLUE}🐳 Installing Docker Engine...${RESET}"
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Install Docker Compose (standalone)
    echo -e "${BLUE}🔗 Installing Docker Compose (standalone)...${RESET}"
    ARCH=$(uname -m)
    [ "$ARCH" = "x86_64" ] && ARCH="x86_64"
    [ "$ARCH" = "aarch64" ] && ARCH="aarch64"
    
    COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
    COMPOSE_URL="https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-linux-${ARCH}"
    
    curl -fsSL "$COMPOSE_URL" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    
    # Create symlink for 'docker compose' command
    mkdir -p /usr/local/lib/docker/cli-plugins
    ln -sf /usr/local/bin/docker-compose /usr/local/lib/docker/cli-plugins/docker-compose
    
    # Create docker group and add current user
    echo -e "${BLUE}👥 Setting up Docker group...${RESET}"
    groupadd docker 2>/dev/null || true
    
    # Add current user to docker group (if not root)
    if [ "$SUDO_USER" ]; then
        usermod -aG docker $SUDO_USER
        echo -e "${YELLOW}ℹ️  User $SUDO_USER added to docker group${RESET}"
        echo -e "${YELLOW}ℹ️  Please log out and log back in for group changes to take effect${RESET}"
    fi
    
    # Start and enable Docker service
    echo -e "${BLUE}🚀 Starting and enabling Docker service...${RESET}"
    systemctl start docker 2>/dev/null || dockerd &
    systemctl enable docker 2>/dev/null || true
    
    # Wait a bit for Docker to start
    sleep 3
    
    # Create Docker daemon configuration
    echo -e "${BLUE}⚙️  Configuring Docker daemon...${RESET}"
    mkdir -p /etc/docker
    cat > /etc/docker/daemon.json << EOF
{
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "10m",
        "max-file": "3"
    },
    "storage-driver": "overlay2",
    "live-restore": true,
    "userland-proxy": false,
    "experimental": false,
    "metrics-addr": "127.0.0.1:9323",
    "default-address-pools": [
        {
            "base": "172.17.0.0/12",
            "size": 24
        }
    ]
}
EOF
    
    # Restart Docker to apply configuration
    echo -e "${BLUE}🔄 Restarting Docker to apply configuration...${RESET}"
    systemctl restart docker 2>/dev/null || true
    
    echo -e "${GREEN}✅ Docker installed successfully${RESET}"
    echo ""
}

