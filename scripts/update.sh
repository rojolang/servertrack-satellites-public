#!/usr/bin/env bash
set -euo pipefail

BIN_TMP="/tmp/servertrack-satellites"
RELEASE_URL="https://github.com/rojolang/servertrack-satellites-public/releases/latest/download/servertrack-satellites"
RAW_URL="https://raw.githubusercontent.com/rojolang/servertrack-satellites-public/main/servertrack-satellites"
INSTALL_PATH="/opt/servertrack-satellites/servertrack-satellites"

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

echo "📥 Downloading latest binary..."
if ! fetch "$RELEASE_URL" "$BIN_TMP"; then
  echo "⚠️ Release asset not available, trying raw main..."
  fetch "$RAW_URL" "$BIN_TMP"
fi
chmod +x "$BIN_TMP"

if [ "${EUID:-$(id -u)}" -ne 0 ]; then
  echo "🔐 Elevating to root for install/update..."
  exec sudo "$BIN_TMP" --update
fi

if [ -x "$INSTALL_PATH" ]; then
  echo "🔄 Updating existing installation..."
  "$BIN_TMP" --update
else
  echo "🆕 Installing fresh..."
  "$BIN_TMP" --install
fi

echo "✅ Done. Service status:" && systemctl status servertrack-satellites --no-pager -l || true
