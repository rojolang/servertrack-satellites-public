#!/usr/bin/env bash
set -euo pipefail

# Update ServerTrack Satellites in-place on Ubuntu 22.04/24.04

BIN_TMP="/tmp/servertrack-satellites"
RELEASE_URL="https://github.com/rojolang/servertrack-satellites-public/releases/latest/download/servertrack-satellites"
RAW_URL="https://raw.githubusercontent.com/rojolang/servertrack-satellites-public/main/servertrack-satellites"

have_curl() { command -v curl >/dev/null 2>&1; }
have_wget() { command -v wget >/dev/null 2>&1; }
fetch() {
  local url="$1" dest="$2"
  if have_curl; then
    curl -fsSL "$url" -o "$dest"
  elif have_wget; then
    wget -qO "$dest" "$url"
  else
    echo "❌ Need curl or wget to download" >&2
    exit 1
  fi
}

mkdir -p /opt/servertrack-satellites || true

echo "📥 Downloading latest binary..."
if ! fetch "$RELEASE_URL" "$BIN_TMP"; then
  echo "⚠️ Release asset not available, trying raw main..."
  fetch "$RAW_URL" "$BIN_TMP"
fi
chmod +x "$BIN_TMP"

echo "🔄 Updating installation..."
sudo "$BIN_TMP" --update

echo "✅ Update complete"
