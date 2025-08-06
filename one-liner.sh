#!/bin/bash
# 🛰️ ServerTrack Satellites - Ultimate One-Liner Installer
# 
# Usage: curl -fsSL https://raw.githubusercontent.com/rojolang/servertrack-satellites/main/one-liner.sh | sudo bash
#
# This single command will:
# 1. Turn any Ubuntu server into a ServerTrack Satellite
# 2. Install all dependencies and configure everything
# 3. Download and install the ServerTrack Satellites API
# 4. Start the service and make it ready to receive campaign deployments

set -e

echo "🛰️ ServerTrack Satellites - One-Liner Installation Starting..."

# Download and run the bootstrap script
curl -fsSL https://raw.githubusercontent.com/rojolang/servertrack-satellites/main/satellite-bootstrap.sh | bash

# Download and install the complete ServerTrack Satellites package
echo "📦 Installing ServerTrack Satellites API..."
cd /tmp
curl -fsSL https://github.com/rojolang/servertrack-satellites/releases/latest/download/servertrack-satellites-deploy.tar.gz -o servertrack-satellites-deploy.tar.gz
tar xzf servertrack-satellites-deploy.tar.gz
cd servertrack-satellites-deploy

# Run the installer
bash install.sh

echo ""
echo "🎉 ONE-LINER INSTALLATION COMPLETE!"
echo ""
echo "🛰️ This server is now a fully configured ServerTrack Satellite!"
echo "📡 API running on port 8080"
echo "🚀 Ready to receive campaign deployment commands!"
echo ""
echo "Test with:"
echo "curl http://$(curl -s ifconfig.me):8080/health"