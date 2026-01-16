#!/bin/bash

# Squid Proxy One-Key Installation Script
# Author: Auto-generated
# Description: Automatically download, install, configure and start Squid proxy server

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Detect OS and package manager
detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    elif type lsb_release >/dev/null 2>&1; then
        OS=$(lsb_release -si)
        VER=$(lsb_release -sr)
    elif [[ -f /etc/redhat-release ]]; then
        OS="Red Hat Enterprise Linux"
        VER=$(cat /etc/redhat-release | sed 's/.*release //' | sed 's/ .*//')
    else
        print_error "Cannot detect operating system"
        exit 1
    fi
    
    print_status "Detected OS: $OS $VER"
}

# Install Squid based on OS
install_squid() {
    # Set config path first (needed even if already installed)
    SQUID_CONFIG="/etc/squid/squid.conf"
    SQUID_SERVICE="squid"
    
    # Check if Squid is already installed
    if command -v squid &> /dev/null; then
        print_success "Squid is already installed, skipping installation"
        return 0
    fi
    
    print_status "Installing Squid proxy server..."
    
    if [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
        sudo apt-get update
        sudo apt-get install -y squid
    elif [[ "$OS" == *"CentOS"* ]] || [[ "$OS" == *"Red Hat"* ]] || [[ "$OS" == *"Rocky"* ]] || [[ "$OS" == *"AlmaLinux"* ]]; then
        if command -v dnf &> /dev/null; then
            dnf install -y squid
        else
            yum install -y squid
        fi
    elif [[ "$OS" == *"Fedora"* ]]; then
        dnf install -y squid
    elif [[ "$OS" == *"SUSE"* ]] || [[ "$OS" == *"openSUSE"* ]]; then
        zypper install -y squid
    elif [[ "$OS" == *"Arch"* ]]; then
        pacman -Sy --noconfirm squid
    elif [[ "$OS" == *"Alpine"* ]]; then
        apk update
        apk add squid
    else
        print_error "Unsupported operating system: $OS"
        print_warning "Please install Squid manually and run this script again"
        exit 1
    fi
    
    print_success "Squid installed successfully"
}

# Backup original configuration
backup_config() {
    if [[ -f "$SQUID_CONFIG" ]]; then
        print_status "Backing up original configuration..."
        cp "$SQUID_CONFIG" "${SQUID_CONFIG}.backup.$(date +%Y%m%d_%H%M%S)"
        print_success "Original configuration backed up"
    fi
}

# Configure Squid
configure_squid() {
    print_status "Configuring Squid with custom settings..."
    
    cat > "$SQUID_CONFIG" << 'EOF'
# 监听端口
http_port 5566

# 基本ACL（可选，但推荐）
acl SSL_ports port 443
acl Safe_ports port 80 443 8080
acl CONNECT method CONNECT

# 基本安全规则
http_access deny !Safe_ports
http_access deny CONNECT !SSL_ports

# 隐私保护设置
forwarded_for off
via off
httpd_suppress_version_string on

# 删除可能暴露信息的头
request_header_access X-Forwarded-For deny all
request_header_access Via deny all
request_header_access Cache-Control deny all
request_header_access X-Cache deny all
request_header_access X-Cache-Lookup deny all

# 用户认证配置
auth_param basic program /usr/lib/squid/basic_ncsa_auth /etc/squid/passwd
auth_param basic children 5
auth_param basic realm Squid Proxy Authentication
auth_param basic credentialsttl 2 hours

# 定义需要认证的ACL
acl authenticated proxy_auth REQUIRED

# 只允许认证用户访问（拒绝开放代理）
http_access allow authenticated
http_access deny all

# 缓存目录（如果目录不存在会自动创建）
cache_dir ufs /var/spool/squid 100 16 256
EOF
    
    print_success "Squid configuration updated"
}

# Setup authentication - create password file
setup_auth() {
    print_status "Setting up proxy authentication..."
    
    # Install htpasswd tool if not available
    if ! command -v htpasswd &> /dev/null; then
        print_status "Installing htpasswd tool..."
        if [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
            apt-get install -y apache2-utils
        elif [[ "$OS" == *"CentOS"* ]] || [[ "$OS" == *"Red Hat"* ]] || [[ "$OS" == *"Rocky"* ]] || [[ "$OS" == *"AlmaLinux"* ]] || [[ "$OS" == *"Fedora"* ]]; then
            if command -v dnf &> /dev/null; then
                dnf install -y httpd-tools
            else
                yum install -y httpd-tools
            fi
        elif [[ "$OS" == *"SUSE"* ]] || [[ "$OS" == *"openSUSE"* ]]; then
            zypper install -y apache2-utils
        elif [[ "$OS" == *"Arch"* ]]; then
            pacman -Sy --noconfirm apache
        elif [[ "$OS" == *"Alpine"* ]]; then
            apk add apache2-utils
        fi
    fi
    
    # Find the correct path for basic_ncsa_auth
    AUTH_PROGRAM=""
    for path in /usr/lib/squid/basic_ncsa_auth /usr/lib64/squid/basic_ncsa_auth /usr/libexec/squid/basic_ncsa_auth /usr/lib/squid3/basic_ncsa_auth; do
        if [[ -f "$path" ]]; then
            AUTH_PROGRAM="$path"
            break
        fi
    done
    
    if [[ -z "$AUTH_PROGRAM" ]]; then
        print_error "Cannot find basic_ncsa_auth program"
        print_warning "Authentication may not work properly"
    else
        # Update config with correct auth program path
        sed -i "s|/usr/lib/squid/basic_ncsa_auth|$AUTH_PROGRAM|g" "$SQUID_CONFIG"
        print_status "Using auth program: $AUTH_PROGRAM"
    fi
    
    # Generate random password if not provided
    PROXY_USER="${PROXY_USER:-proxyuser}"
    PROXY_PASS="${PROXY_PASS:-$(openssl rand -base64 12)}"
    
    # Create password file
    htpasswd -cb /etc/squid/passwd "$PROXY_USER" "$PROXY_PASS"
    chmod 640 /etc/squid/passwd
    
    # Set proper ownership
    if id "squid" &>/dev/null; then
        chown root:squid /etc/squid/passwd
    elif id "proxy" &>/dev/null; then
        chown root:proxy /etc/squid/passwd
    fi
    
    print_success "Authentication setup completed"
    print_status "Proxy Username: $PROXY_USER"
    print_status "Proxy Password: $PROXY_PASS"
    
    # Save credentials to file for reference
    echo "Proxy Credentials (created on $(date))" > /etc/squid/proxy_credentials.txt
    echo "Username: $PROXY_USER" >> /etc/squid/proxy_credentials.txt
    echo "Password: $PROXY_PASS" >> /etc/squid/proxy_credentials.txt
    chmod 600 /etc/squid/proxy_credentials.txt
    print_status "Credentials saved to /etc/squid/proxy_credentials.txt"
}

# Create cache directory and set permissions
setup_cache() {
    print_status "Setting up cache directory..."
    
    # Create cache directory if it doesn't exist
    mkdir -p /var/spool/squid
    
    # Set proper ownership and permissions
    if id "squid" &>/dev/null; then
        chown -R squid:squid /var/spool/squid
    elif id "proxy" &>/dev/null; then
        chown -R proxy:proxy /var/spool/squid
    fi
    
    chmod -R 755 /var/spool/squid
    
    # Initialize cache directory
    squid -z 2>/dev/null || true
    
    print_success "Cache directory setup completed"
}

# Configure firewall
configure_firewall() {
    print_status "Configuring firewall..."
    
    # Try different firewall management tools
    if command -v ufw &> /dev/null; then
        ufw allow 5566/tcp
        print_success "UFW firewall rule added for port 5566"
    elif command -v firewall-cmd &> /dev/null; then
        firewall-cmd --permanent --add-port=5566/tcp
        firewall-cmd --reload
        print_success "Firewalld rule added for port 5566"
    elif command -v iptables &> /dev/null; then
        iptables -I INPUT -p tcp --dport 5566 -j ACCEPT
        # Try to save iptables rules
        if command -v iptables-save &> /dev/null; then
            iptables-save > /etc/iptables/rules.v4 2>/dev/null || true
        fi
        print_success "Iptables rule added for port 5566"
    else
        print_warning "No firewall management tool found. Please manually open port 5566"
    fi
}

# Start and enable Squid service
start_squid() {
    print_status "Starting Squid service..."
    
    # Enable and start the service
    # systemctl enable "$SQUID_SERVICE"
    sudo systemctl restart "$SQUID_SERVICE"
    
    # Wait a moment for service to start
    sleep 3
    
    # Check if service is running
    if systemctl is-active --quiet "$SQUID_SERVICE"; then
        print_success "Squid service started successfully"
    else
        print_error "Failed to start Squid service"
        print_status "Checking service status..."
        systemctl status "$SQUID_SERVICE" --no-pager
        exit 1
    fi
}

# Test Squid configuration
test_squid() {
    print_status "Testing Squid configuration..."
    
    # Test configuration syntax
    if squid -k parse; then
        print_success "Squid configuration syntax is valid"
    else
        print_error "Squid configuration has syntax errors"
        exit 1
    fi
    
    # Test if port is listening
    sleep 2
    if netstat -tlnp 2>/dev/null | grep -q ":5566 " || ss -tlnp 2>/dev/null | grep -q ":5566 "; then
        print_success "Squid is listening on port 5566"
    else
        print_warning "Port 5566 may not be listening yet. Please check manually."
    fi
}

# Display final information
show_info() {
    local SERVER_IP=$(hostname -I | awk '{print $1}')
    
    echo
    echo "=============================================="
    print_success "Squid Proxy Installation Completed!"
    echo "=============================================="
    echo
    echo "Proxy Server Details:"
    echo "  - Listen Port: 5566"
    echo "  - Configuration: $SQUID_CONFIG"
    echo "  - Cache Directory: /var/spool/squid"
    echo
    print_warning "AUTHENTICATION ENABLED (Proxy is NOT open)"
    echo "  - Username: $PROXY_USER"
    echo "  - Password: $PROXY_PASS"
    echo "  - Credentials file: /etc/squid/proxy_credentials.txt"
    echo
    echo "Usage Examples:"
    echo "  - HTTP Proxy: http://$PROXY_USER:$PROXY_PASS@$SERVER_IP:5566"
    echo "  - Test with curl:"
    echo "    curl -x http://$PROXY_USER:$PROXY_PASS@$SERVER_IP:5566 http://httpbin.org/ip"
    echo "    curl --proxy-user $PROXY_USER:$PROXY_PASS -x http://$SERVER_IP:5566 http://httpbin.org/ip"
    echo
    echo "Add more users:"
    echo "  htpasswd /etc/squid/passwd newusername"
    echo
    echo "Service Management:"
    echo "  - Start:   systemctl start $SQUID_SERVICE"
    echo "  - Stop:    systemctl stop $SQUID_SERVICE"
    echo "  - Restart: systemctl restart $SQUID_SERVICE"
    echo "  - Status:  systemctl status $SQUID_SERVICE"
    echo
    echo "Configuration file: $SQUID_CONFIG"
    echo "Log files: /var/log/squid/"
    echo
    print_warning "Remember to configure your client applications with the proxy credentials!"
    echo
}

# Main execution
main() {
    echo "=============================================="
    echo "    Squid Proxy One-Key Installation Script"
    echo "=============================================="
    echo
    
    check_root
    detect_os
    install_squid
    backup_config
    configure_squid
    setup_auth
    setup_cache
    configure_firewall
    start_squid
    test_squid
    show_info
}

# Run main function
main "$@"