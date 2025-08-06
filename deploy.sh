#!/bin/bash

# ✨ RojoLang API Elegant Deployment Script
# Sophisticated automation with beautiful logging

set -e

echo "✨ RojoLang API - Elegant Deployment Initiating..."
echo "🎯 Sophisticated automation, effortless results"

# Colors for beautiful output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}✅ $1${NC}"
}

warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}💥 $1${NC}"
    exit 1
}

info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if we're in the right directory
if [ ! -f "main.go" ]; then
    error "main.go not found. Run this script from the rojolang-api directory."
fi

log "Building the beautiful API..."
go mod tidy
go build -o rojolang-api main.go

log "Setting up systemd service..."
sudo cp systemd/rojolang-api.service /etc/systemd/system/
sudo systemctl daemon-reload

log "Stopping existing service (if running)..."
sudo systemctl stop rojolang-api || true

log "Starting RojoLang API service..."
sudo systemctl start rojolang-api
sudo systemctl enable rojolang-api

log "Checking service status..."
sleep 2
if sudo systemctl is-active --quiet rojolang-api; then
    log "🎉 RojoLang API is running successfully!"
    
    info "Service status:"
    sudo systemctl status rojolang-api --no-pager -l
    
    info "🌐 API is available at:"
    echo -e "   ${CYAN}http://localhost:8080${NC}"
    echo -e "   ${CYAN}http://$(curl -s ifconfig.me):8080${NC}"
    
    info "📊 Test endpoints:"
    echo -e "   ${PURPLE}GET  /${NC} - Welcome page"
    echo -e "   ${PURPLE}GET  /health${NC} - Health check"
    echo -e "   ${PURPLE}POST /api/v1/lander${NC} - Create lander"
    echo -e "   ${PURPLE}GET  /api/v1/landers${NC} - List landers"
    
    info "📝 View logs with:"
    echo -e "   ${CYAN}sudo journalctl -u rojolang-api -f${NC}"
    
else
    error "Failed to start RojoLang API service"
fi

log "✨ Elegant deployment completed successfully!"
echo "🌟 RojoLang API - Sophisticated automation ready for beautiful campaigns!"