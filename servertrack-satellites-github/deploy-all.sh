#!/bin/bash

# 🛰️ ServerTrack Satellites - Ultimate Self-Deploying Binary
set -e

# Colors for beautiful output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}✅ $1${NC}"; }

echo -e "${PURPLE}🛰️ ServerTrack Satellites v2.0.0${NC}"

# Check if we're on Ubuntu
if ! grep -q "Ubuntu" /etc/os-release 2>/dev/null; then
    echo -e "${RED}💥 This script requires Ubuntu 22.04 or 24.04${NC}"
    exit 1
fi

echo -e "${BLUE}🔹 Detected Ubuntu - proceeding...${NC}"

# Get the directory of this script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

echo -e "${BLUE}🔹 Running system setup...${NC}"

# Run the auto-setup script
if [ -f "$SCRIPT_DIR/auto-setup.sh" ]; then
    bash "$SCRIPT_DIR/auto-setup.sh"
else
    echo -e "${RED}💥 Auto-setup script not found${NC}"
    exit 1
fi

echo -e "${BLUE}🔹 Installing binary...${NC}"

# Copy the binary to the correct location
if [ -f "$SCRIPT_DIR/servertrack-satellites" ]; then
    cp "$SCRIPT_DIR/servertrack-satellites" /opt/servertrack-satellites/
    chmod +x /opt/servertrack-satellites/servertrack-satellites
    log "Binary installed successfully!"
else
    echo -e "${RED}💥 servertrack-satellites binary not found${NC}"
    exit 1
fi

# Kill any existing process using port 8080
if lsof -i :8080 >/dev/null 2>&1; then
    echo -e "${BLUE}🔹 Stopping existing service on port 8080...${NC}"
    pkill -f servertrack-satellites >/dev/null 2>&1 || true
    sleep 2
fi

echo -e "${BLUE}🔹 Starting service...${NC}"

# Start the service
systemctl start servertrack-satellites
systemctl enable servertrack-satellites

# Wait for service to start
sleep 3

# Check if service is running
if systemctl is-active --quiet servertrack-satellites; then
    SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
    
    echo ""
    echo -e "${PURPLE}🎉 DEPLOYMENT COMPLETE! 🎉${NC}"
    echo ""
    echo -e "${BOLD}🛰️ ServerTrack Satellites LIVE!${NC}"
    echo ""
    echo -e "${BOLD}📡 Server IP: ${GREEN}$SERVER_IP${NC}"
    echo -e "${BOLD}🌐 API: ${GREEN}http://$SERVER_IP:8080${NC}"
    echo -e "${BOLD}🔍 Health: ${GREEN}http://$SERVER_IP:8080/health${NC}"
    echo ""
    echo -e "${BOLD}🚀 Test:${NC}"
    echo -e "${CYAN}curl -X POST http://$SERVER_IP:8080/api/v1/lander \\${NC}"
    echo -e "${CYAN}  -H 'Content-Type: application/json' \\${NC}"
    echo -e "${CYAN}  -d '{\"campaign_id\":\"test-123\",\"landing_page_id\":\"lp-456\",\"subdomain\":\"demo.yourdomain.com\"}'${NC}"
    echo ""
    echo -e "${BOLD}📊 Logs:${NC} ${CYAN}sudo journalctl -u servertrack-satellites -f${NC}"
    echo -e "${BOLD}🔧 Status:${NC} ${CYAN}sudo systemctl status servertrack-satellites${NC}"
    echo ""
    echo -e "${PURPLE}✨ Ready to deploy! ✨${NC}"
else
    echo -e "${RED}💥 Service failed to start. Check logs:${NC}"
    echo -e "${CYAN}sudo journalctl -u servertrack-satellites -n 50${NC}"
    exit 1
fi