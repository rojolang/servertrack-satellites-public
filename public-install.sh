#!/bin/bash

# 🛰️ ServerTrack Satellites - Public Release Installer
# Downloads and installs the latest binary release from GitHub

set -e

# Beautiful colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

RELEASE_URL="https://api.github.com/repos/rojolang/servertrack-satellites-public/releases/latest"
BINARY_NAME="servertrack-satellites"
INSTALL_DIR="/usr/local/bin"
SERVICE_NAME="servertrack-satellites"

# ASCII Art Banner
show_banner() {
    echo -e "${PURPLE}${BOLD}"
    echo "  ╔═══════════════════════════════════════════════════╗"
    echo "  ║          🛰️ ServerTrack Satellites 🛰️          ║"
    echo "  ║         Production Ready Deployment               ║"
    echo "  ║                                                   ║"
    echo "  ║    🚀 Public Release Installer 🚀               ║"
    echo "  ╚═══════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "${CYAN}One-line installer for production deployment${NC}"
    echo ""
}

log() {
    echo -e "${GREEN}✨ $1${NC}"
}

step() {
    echo -e "${BLUE}🔹 $1${NC}"
}

warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}💥 $1${NC}"
    exit 1
}

success() {
    echo -e "${GREEN}${BOLD}🎉 $1${NC}"
}

show_banner

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   error "This script must be run as root (use sudo)"
fi

step "Detecting system..."
if ! command -v curl &> /dev/null; then
    step "Installing curl..."
    apt update -qq && apt install -y curl
fi

step "Fetching latest release information..."
# Get the latest release tag
LATEST_TAG=$(curl -s "$RELEASE_URL" | jq -r '.tag_name' 2>/dev/null || curl -s "$RELEASE_URL" | grep -o '"tag_name": "[^"]*' | cut -d'"' -f4)

if [ -z "$LATEST_TAG" ]; then
    error "Failed to fetch latest release tag"
fi

log "Found latest release: $LATEST_TAG"

# Construct the download URL for the binary only
LATEST_RELEASE="https://github.com/rojolang/servertrack-satellites-public/releases/download/$LATEST_TAG/$BINARY_NAME"

step "Stopping existing service if running..."
systemctl stop "$SERVICE_NAME" 2>/dev/null || true

step "Downloading latest binary..."
curl -L -o "/tmp/$BINARY_NAME" "$LATEST_RELEASE"

step "Installing binary to $INSTALL_DIR..."
mv "/tmp/$BINARY_NAME" "$INSTALL_DIR/$BINARY_NAME"
chmod +x "$INSTALL_DIR/$BINARY_NAME"

step "Creating systemd service..."
cat > "/etc/systemd/system/$SERVICE_NAME.service" << EOF
[Unit]
Description=ServerTrack Satellites - Landing Page Deployment API
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
Restart=always
RestartSec=1
User=root
Environment=PORT=8080
WorkingDirectory=/root
ExecStart=$INSTALL_DIR/$BINARY_NAME

[Install]
WantedBy=multi-user.target
EOF

step "Enabling and starting service..."
systemctl daemon-reload
systemctl enable "$SERVICE_NAME"
systemctl start "$SERVICE_NAME"

sleep 3

step "Verifying installation..."
if systemctl is-active --quiet "$SERVICE_NAME"; then
    success "ServerTrack Satellites installed successfully!"
    
    # Get server IP
    SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || echo "localhost")
    
    echo ""
    echo -e "${PURPLE}${BOLD}🌟 Installation Complete! 🌟${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${BOLD}📡 Service Status:${NC}"
    systemctl status "$SERVICE_NAME" --no-pager -l
    echo ""
    echo -e "${BOLD}🌐 API Endpoints:${NC}"
    echo -e "   🌐 ${GREEN}http://${SERVER_IP}:8080${NC}"
    echo -e "   🌐 ${GREEN}http://localhost:8080${NC}"
    echo ""
    echo -e "${BOLD}🔒 SSL Setup (Optional):${NC}"
    echo -e "   ${GREEN}curl -sSL https://raw.githubusercontent.com/rojolang/servertrack-satellites-public/master/ssl-setup.sh | bash${NC}"
    echo ""
    echo -e "${BOLD}🎯 Test Commands:${NC}"
    echo -e "   ${CYAN}curl http://localhost:8080/health${NC}"
    echo -e "   ${CYAN}curl http://localhost:8080/api/v1/provision -X POST -H 'Content-Type: application/json' -d '{\"campaign_id\":\"test\",\"landing_page_id\":\"lp1\",\"subdomain\":\"demo.yourdomain.com\",\"github_repo\":\"Hairetsucodes/lander-rojo-original\"}'${NC}"
    echo ""
    echo -e "${BOLD}📝 Management:${NC}"
    echo -e "   ${YELLOW}systemctl status $SERVICE_NAME${NC}     # Check status"
    echo -e "   ${YELLOW}journalctl -u $SERVICE_NAME -f${NC}     # View logs"
    echo -e "   ${YELLOW}systemctl restart $SERVICE_NAME${NC}    # Restart service"
    echo ""
    echo -e "${PURPLE}🛰️ Ready for production deployment with SSL support! 🛰️${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
else
    error "Installation failed. Check logs with: journalctl -u $SERVICE_NAME -f"
fi