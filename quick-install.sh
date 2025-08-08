#!/bin/bash

# 🛰️ ServerTrack Satellites - Quick Release Installer
# Downloads latest release assets and runs epic installation
# Updated: 2025-08-08 - Uses GitHub releases for reliability

set -e

# Epic Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'  
PURPLE='\033[0;35m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log() { echo -e "${GREEN}✅ $1${NC}"; }
step() { echo -e "${BLUE}🔹 $1${NC}"; }
error() { echo -e "${RED}💥 $1${NC}"; exit 1; }
epic() { echo -e "${PURPLE}${BOLD}🛰️ $1${NC}"; }

echo ""
epic "ServerTrack Satellites - Quick Release Installer"
echo -e "${CYAN}Downloading latest release assets from GitHub...${NC}"
echo ""

# Pre-flight checks
if ! grep -q "Ubuntu" /etc/os-release 2>/dev/null; then
    error "This script requires Ubuntu 22.04 or 24.04"
fi

if [[ $EUID -ne 0 ]]; then
   error "This script must be run as root. Use: sudo $0"
fi

UBUNTU_VERSION=$(lsb_release -rs 2>/dev/null || grep VERSION_ID /etc/os-release | cut -d'"' -f2)
log "Ubuntu ${UBUNTU_VERSION} detected and supported"

# Create temp directory  
TMP_DIR=$(mktemp -d)
cd "$TMP_DIR"

step "Downloading latest release assets..."

# GitHub release URLs for direct asset downloads
RELEASE_BASE="https://github.com/rojolang/servertrack-satellites-public/releases/latest/download"

# Download the epic installer and binary from release assets
step "Downloading epic installer..."
curl -fsSL "${RELEASE_BASE}/install.sh" -o install.sh || error "Failed to download epic installer"

step "Downloading ServerTrack Satellites binary..."
curl -fsSL "${RELEASE_BASE}/servertrack-satellites" -o servertrack-satellites || error "Failed to download binary"

# Make executable
chmod +x install.sh servertrack-satellites

log "All release assets downloaded successfully!"
echo ""

step "Launching epic installation..."
echo ""

# Run the epic installer (which will self-destruct)
bash install.sh

# Cleanup temp directory (installer already self-destructed)
cd /root
rm -rf "$TMP_DIR"

# Get server IP for final message
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')

echo ""
echo -e "${PURPLE}${BOLD}🎉 QUICK INSTALLATION COMPLETE! 🎉${NC}"
echo ""
echo -e "${GREEN}📡 Server IP: $SERVER_IP${NC}"
echo -e "${GREEN}🌐 API: http://$SERVER_IP:8080${NC}" 
echo -e "${GREEN}🔍 Health: http://$SERVER_IP:8080/health${NC}"
echo ""
echo -e "${BLUE}🚀 Test deployment:${NC}"
echo -e "${CYAN}curl -X POST http://$SERVER_IP:8080/api/v1/lander \\${NC}"
echo -e "${CYAN}  -H 'Content-Type: application/json' \\${NC}"
echo -e "${CYAN}  -d '{\"campaign_id\":\"test\",\"landing_page_id\":\"lp1\",\"subdomain\":\"demo.puritysalt.com\"}'${NC}"
echo ""
echo -e "${GREEN}✨ ServerTrack Satellites is LIVE with MAXIMUM EPIC! ✨${NC}"

# Self-destruct this quick installer too
echo ""
echo -e "${YELLOW}🔥 Self-destructing quick installer for security...${NC}"
sleep 1
SCRIPT_PATH="$0"
if [ -f "$SCRIPT_PATH" ] && [ "$SCRIPT_PATH" != "/dev/stdin" ]; then
    rm -f "$SCRIPT_PATH"
    echo -e "${GREEN}✅ Quick installer removed successfully${NC}"
else
    echo -e "${CYAN}ℹ️  Quick installer was run from curl - no cleanup needed${NC}"
fi