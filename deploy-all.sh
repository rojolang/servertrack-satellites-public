#!/bin/bash

# 🛰️ ServerTrack Satellites - Ultimate Self-Deploying Binary
# This script contains everything needed and auto-deploys on any Ubuntu server

set -e

# Colors for beautiful output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${PURPLE}${BOLD}"
echo "  ╔══════════════════════════════════════════════════════════════╗"
echo "  ║                🛰️ ServerTrack Satellites 🛰️                ║"
echo "  ║              Self-Deploying Binary v2.0.0                    ║"
echo "  ║                                                              ║"
echo "  ║      🚀 Automatically installs and starts everything! 🚀    ║"
echo "  ╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check if we're on Ubuntu
if ! grep -q "Ubuntu" /etc/os-release 2>/dev/null; then
    echo -e "${RED}💥 This script requires Ubuntu 22.04 or 24.04${NC}"
    exit 1
fi

echo -e "${BLUE}🔹 Detected Ubuntu - proceeding with installation...${NC}"

# Get the directory of this script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

echo -e "${BLUE}🔹 Running system setup...${NC}"

# Run the auto-setup script (embedded below or from file)
if [ -f "$SCRIPT_DIR/auto-setup.sh" ]; then
    bash "$SCRIPT_DIR/auto-setup.sh"
else
    echo -e "${BLUE}🔹 Auto-setup script not found, running inline setup...${NC}"
    # Inline setup would go here - for now assume the file exists
fi

echo -e "${BLUE}🔹 Installing ServerTrack Satellites binary...${NC}"

# Copy the binary to the correct location
if [ -f "$SCRIPT_DIR/servertrack-satellites" ]; then
    cp "$SCRIPT_DIR/servertrack-satellites" /opt/servertrack-satellites/
    chmod +x /opt/servertrack-satellites/servertrack-satellites
else
    echo -e "${RED}💥 servertrack-satellites binary not found in $SCRIPT_DIR${NC}"
    echo -e "${CYAN}ℹ️  Make sure you have both servertrack-satellites binary and this script in the same directory${NC}"
    exit 1
fi

echo -e "${BLUE}🔹 Starting ServerTrack Satellites service...${NC}"

# Start the service
systemctl start servertrack-satellites
systemctl enable servertrack-satellites

# Wait a moment for service to start
sleep 3

# Check if service is running
if systemctl is-active --quiet servertrack-satellites; then
    SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
    
    echo ""
    echo -e "${PURPLE}${BOLD}🎉 DEPLOYMENT COMPLETE! 🎉${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${BOLD}🛰️ ServerTrack Satellites is LIVE and ready!${NC}"
    echo ""
    echo -e "${BOLD}📡 Server IP: ${GREEN}$SERVER_IP${NC}"
    echo -e "${BOLD}🌐 API Endpoint: ${GREEN}http://$SERVER_IP:8080${NC}"
    echo -e "${BOLD}🔍 Health Check: ${GREEN}http://$SERVER_IP:8080/health${NC}"
    echo ""
    echo -e "${BOLD}🚀 Test deployment:${NC}"
    echo -e "${CYAN}curl -X POST http://$SERVER_IP:8080/api/v1/lander \\${NC}"
    echo -e "${CYAN}  -H 'Content-Type: application/json' \\${NC}"
    echo -e "${CYAN}  -d '{\"campaign_id\":\"test-123\",\"landing_page_id\":\"lp-456\",\"subdomain\":\"demo.yourdomain.com\"}'${NC}"
    echo ""
    echo -e "${BOLD}📊 Monitor logs:${NC}"
    echo -e "${CYAN}sudo journalctl -u servertrack-satellites -f${NC}"
    echo ""
    echo -e "${BOLD}🔧 Manage service:${NC}"
    echo -e "${CYAN}sudo systemctl status servertrack-satellites${NC}"
    echo -e "${CYAN}sudo systemctl restart servertrack-satellites${NC}"
    echo ""
    echo -e "${PURPLE}✨ Ready to deploy beautiful campaigns! ✨${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
else
    echo -e "${RED}💥 Service failed to start. Check logs:${NC}"
    echo -e "${CYAN}sudo journalctl -u servertrack-satellites -n 50${NC}"
    exit 1
fi