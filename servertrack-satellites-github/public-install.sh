#!/bin/bash

# 🛰️ ServerTrack Satellites - Public Installer
# This script downloads and installs ServerTrack Satellites on Ubuntu servers

set -e

# Colors for beautiful output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}✅ $1${NC}"; }
step() { echo -e "${BLUE}🔹 $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
error() { echo -e "${RED}💥 $1${NC}"; exit 1; }

echo -e "${PURPLE}${BOLD}🛰️ ServerTrack Satellites - Public Installer${NC}"
echo ""

# Check if we're on Ubuntu
if ! grep -q "Ubuntu" /etc/os-release 2>/dev/null; then
    error "This script requires Ubuntu 22.04 or 24.04"
fi

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   error "This script must be run as root. Use: sudo bash $0"
fi

UBUNTU_VERSION=$(lsb_release -rs 2>/dev/null || grep VERSION_ID /etc/os-release | cut -d'"' -f2)
log "Ubuntu ${UBUNTU_VERSION} detected - perfect!"

# Create temporary directory
TMP_DIR=$(mktemp -d)
cd "$TMP_DIR"

step "Downloading ServerTrack Satellites deployment package..."

# TODO: Replace with actual download URL when repo is set up
# For now, assuming files are available at a public URL
DOWNLOAD_URL="https://raw.githubusercontent.com/rojolang/servertrack-satellites/main"

# Download all required files
curl -fsSL "${DOWNLOAD_URL}/install.sh" -o install.sh || error "Failed to download install.sh"
curl -fsSL "${DOWNLOAD_URL}/auto-setup.sh" -o auto-setup.sh || error "Failed to download auto-setup.sh" 
curl -fsSL "${DOWNLOAD_URL}/deploy-all.sh" -o deploy-all.sh || error "Failed to download deploy-all.sh"
curl -fsSL "${DOWNLOAD_URL}/servertrack-satellites" -o servertrack-satellites || error "Failed to download binary"

# Make scripts executable
chmod +x install.sh auto-setup.sh deploy-all.sh servertrack-satellites

log "All files downloaded successfully!"

step "Starting installation..."

# Run the installer
bash install.sh

# Cleanup
cd /root
rm -rf "$TMP_DIR"

# Get server IP for final message
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')

echo ""
echo -e "${PURPLE}${BOLD}🎉 INSTALLATION COMPLETE! 🎉${NC}"
echo ""
echo -e "${BOLD}🛰️ ServerTrack Satellites is now LIVE!${NC}"
echo ""
echo -e "${BOLD}📡 Server IP: ${GREEN}$SERVER_IP${NC}"
echo -e "${BOLD}🌐 API: ${GREEN}http://$SERVER_IP:8080${NC}"
echo -e "${BOLD}🔍 Health: ${GREEN}http://$SERVER_IP:8080/health${NC}"
echo ""
echo -e "${BOLD}🚀 Test deployment:${NC}"
echo -e "${CYAN}curl -X POST http://$SERVER_IP:8080/api/v1/lander \\${NC}"
echo -e "${CYAN}  -H 'Content-Type: application/json' \\${NC}"
echo -e "${CYAN}  -d '{\"campaign_id\":\"test-123\",\"landing_page_id\":\"lp-456\",\"subdomain\":\"demo.puritysalt.com\"}'${NC}"
echo ""
echo -e "${BOLD}📊 Monitor:${NC} ${CYAN}sudo journalctl -u servertrack-satellites -f${NC}"
echo -e "${BOLD}🔧 Manage:${NC} ${CYAN}sudo systemctl status servertrack-satellites${NC}"
echo ""
echo -e "${PURPLE}✨ Ready to deploy beautiful campaigns! ✨${NC}"