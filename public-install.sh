#!/bin/bash

# 🛰️ ServerTrack Satellites - Public Installer
# Downloads and installs ServerTrack Satellites from GitHub

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}✅ $1${NC}"; }
step() { echo -e "${BLUE}🔹 $1${NC}"; }
error() { echo -e "${RED}💥 $1${NC}"; exit 1; }

echo -e "${PURPLE}🛰️ ServerTrack Satellites - Public Installer${NC}"
echo ""

# Check Ubuntu
if ! grep -q "Ubuntu" /etc/os-release 2>/dev/null; then
    error "This script requires Ubuntu 22.04 or 24.04"
fi

# Check root
if [[ $EUID -ne 0 ]]; then
   error "This script must be run as root. Use: sudo $0"
fi

UBUNTU_VERSION=$(lsb_release -rs 2>/dev/null || grep VERSION_ID /etc/os-release | cut -d'"' -f2)
log "Ubuntu ${UBUNTU_VERSION} detected"

# Create temp directory
TMP_DIR=$(mktemp -d)
cd "$TMP_DIR"

step "Downloading ServerTrack Satellites..."

# GitHub URLs for raw files (PUBLIC REPOSITORY)
RAW_URL="https://raw.githubusercontent.com/rojolang/servertrack-satellites-public/main"

# Download installer and binary
curl -fsSL "${RAW_URL}/install.sh" -o install.sh || error "Failed to download installer"
curl -fsSL "${RAW_URL}/servertrack-satellites" -o servertrack-satellites || error "Failed to download binary"

chmod +x install.sh servertrack-satellites

log "Downloaded successfully!"

step "Running installer..."

# Run the installer
bash install.sh

# Cleanup
cd /root
rm -rf "$TMP_DIR"

# Get server IP
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')

echo ""
echo -e "${PURPLE}🎉 PUBLIC INSTALLATION COMPLETE! 🎉${NC}"
echo ""
echo -e "${GREEN}📡 Server IP: $SERVER_IP${NC}"
echo -e "${GREEN}🌐 API: http://$SERVER_IP:8080${NC}"
echo -e "${GREEN}🔍 Health: http://$SERVER_IP:8080/health${NC}"
echo ""
echo -e "${BLUE}🚀 Test deployment:${NC}"
echo -e "curl -X POST http://$SERVER_IP:8080/api/v1/lander \\"
echo -e "  -H 'Content-Type: application/json' \\"
echo -e "  -d '{\"campaign_id\":\"test\",\"landing_page_id\":\"lp1\",\"subdomain\":\"demo.puritysalt.com\"}'"
echo ""
echo -e "${GREEN}✨ ServerTrack Satellites is LIVE! ✨${NC}"