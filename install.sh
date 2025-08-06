#!/bin/bash

# 🛰️ ServerTrack Satellites - Ultimate One-Liner Ubuntu Installer
# Elegant satellite deployment script for Ubuntu 24.04 LTS

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

# ASCII Art Banner
show_banner() {
    echo -e "${PURPLE}${BOLD}"
    echo "  ╔═══════════════════════════════════════════════════╗"
    echo "  ║          🛰️ ServerTrack Satellites 🛰️          ║"
    echo "  ║         Elegant Campaign Automation               ║"
    echo "  ║                                                   ║"
    echo "  ║    🚀 One-Liner Ubuntu Installer 🚀             ║"
    echo "  ╚═══════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "${CYAN}Sophisticated automation, effortless deployment${NC}"
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

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   warn "This script should not be run as root for security. Run as sudo when needed."
fi

show_banner

step "Detecting Ubuntu version..."
if ! grep -q "Ubuntu" /etc/os-release; then
    error "This installer is designed for Ubuntu. Detected: $(lsb_release -d)"
fi

UBUNTU_VERSION=$(lsb_release -rs)
log "Detected Ubuntu ${UBUNTU_VERSION} - Perfect for ServerTrack Satellites!"

step "Updating package repositories..."
sudo apt update -qq

step "Installing essential dependencies..."
sudo apt install -y curl wget nginx certbot python3-certbot-nginx jq git unzip

step "Installing Go 1.21.5..."
if ! command -v go &> /dev/null; then
    log "Downloading Go 1.21.5 for elegant performance..."
    wget -q https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
    sudo tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
    export PATH=$PATH:/usr/local/go/bin
    rm go1.21.5.linux-amd64.tar.gz
    success "Go installed beautifully!"
else
    log "Go already installed: $(go version)"
fi

step "Cloning RojoLang API repository..."
if [ -d "rojolang-api" ]; then
    warn "Directory rojolang-api exists, updating..."
    cd rojolang-api
    git pull
else
    git clone https://github.com/rojolang/rojolang-api.git
    cd rojolang-api
fi

step "Building the elegant API..."
export PATH=$PATH:/usr/local/go/bin
go mod tidy
go build -o rojolang-api main.go

step "Setting up production systemd service..."
sudo cp systemd/rojolang-api.service /etc/systemd/system/
sudo systemctl daemon-reload

step "Deploying with elegant automation..."
sudo systemctl stop rojolang-api 2>/dev/null || true
sudo systemctl start rojolang-api
sudo systemctl enable rojolang-api

sleep 3

step "Verifying deployment..."
if sudo systemctl is-active --quiet rojolang-api; then
    success "RojoLang API deployed successfully!"
    
    # Get server IP
    SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || echo "localhost")
    
    echo ""
    echo -e "${PURPLE}${BOLD}🌟 Deployment Complete! 🌟${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${BOLD}📡 API Endpoints:${NC}"
    echo -e "   🌐 ${GREEN}http://${SERVER_IP}:8080${NC}"
    echo -e "   🌐 ${GREEN}http://localhost:8080${NC}"
    echo ""
    echo -e "${BOLD}🎯 Test Commands:${NC}"
    echo -e "   ${CYAN}curl http://localhost:8080/health${NC}"
    echo -e "   ${CYAN}curl http://localhost:8080/${NC}"
    echo ""
    echo -e "${BOLD}📊 Create a Lander:${NC}"
    echo -e '   curl -X POST http://localhost:8080/api/v1/lander \'
    echo -e '     -H "Content-Type: application/json" \'
    echo -e '     -d '"'"'{"campaign_id":"test-123","landing_page_id":"lp-456","subdomain":"demo"}'"'"
    echo ""
    echo -e "${BOLD}📝 Management:${NC}"
    echo -e "   ${YELLOW}sudo systemctl status rojolang-api${NC}   # Check status"
    echo -e "   ${YELLOW}sudo journalctl -u rojolang-api -f${NC}   # View logs"
    echo -e "   ${YELLOW}sudo systemctl restart rojolang-api${NC}  # Restart service"
    echo ""
    echo -e "${PURPLE}✨ Elegant automation, beautiful results ✨${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
else
    error "Deployment failed. Check logs with: sudo journalctl -u rojolang-api -f"
fi