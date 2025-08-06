#!/bin/bash

# 🛰️ ServerTrack Satellites - Slim Installer
set -e

echo "🛰️ ServerTrack Satellites - Slim Install"

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

if [ ! -f "$SCRIPT_DIR/servertrack-satellites" ]; then
    echo "💥 servertrack-satellites binary not found!"
    exit 1
fi

bash "$SCRIPT_DIR/auto-setup.sh"
bash "$SCRIPT_DIR/deploy-all.sh"

echo "✅ Ready!"
