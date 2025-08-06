#!/bin/bash

# 🛰️ ServerTrack Satellites - One-Command Installer
# Run this script on any Ubuntu 22/24 server to install everything automatically

set -e

echo "🛰️ ServerTrack Satellites - One-Command Installer"
echo "This will install and configure everything needed..."

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Check if we have the necessary files
if [ ! -f "$SCRIPT_DIR/servertrack-satellites" ]; then
    echo "💥 servertrack-satellites binary not found!"
    echo "Make sure you have all files in the same directory:"
    echo "- servertrack-satellites (binary)"
    echo "- auto-setup.sh"
    echo "- install.sh (this script)"
    exit 1
fi

# Run the deployment
echo "🚀 Starting full deployment..."
bash "$SCRIPT_DIR/deploy-all.sh"

echo "✅ Installation complete!"
