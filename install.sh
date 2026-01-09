#!/bin/bash
# Strayfiles Ping installer
# Downloads the strayfiles-ping binary for your platform

set -e

REPO="titofebus/strayfiles-ping"
INSTALL_DIR="${HOME}/.local/bin"

# Detect platform
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

case "$ARCH" in
  x86_64) ARCH="x64" ;;
  aarch64|arm64) ARCH="arm64" ;;
  *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

case "$OS" in
  darwin) PLATFORM="macos-${ARCH}" ;;
  linux) PLATFORM="linux-${ARCH}" ;;
  *) echo "Unsupported OS: $OS"; exit 1 ;;
esac

# Get latest release
LATEST=$(curl -s "https://api.github.com/repos/${REPO}/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

if [ -z "$LATEST" ]; then
  echo "Failed to get latest release. Trying direct download..."
  DOWNLOAD_URL="https://strayfiles.com/releases/strayfiles-ping-${PLATFORM}"
else
  DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${LATEST}/strayfiles-ping-${PLATFORM}"
fi

echo "Installing strayfiles-ping for ${PLATFORM}..."

# Create install directory
mkdir -p "$INSTALL_DIR"

# Download binary
echo "Downloading from ${DOWNLOAD_URL}..."
curl -fsSL "$DOWNLOAD_URL" -o "${INSTALL_DIR}/strayfiles-ping"
chmod +x "${INSTALL_DIR}/strayfiles-ping"

# Check if install dir is in PATH
if [[ ":$PATH:" != *":${INSTALL_DIR}:"* ]]; then
  echo ""
  echo "Add this to your shell profile (.bashrc, .zshrc, etc.):"
  echo "  export PATH=\"\$PATH:${INSTALL_DIR}\""
  echo ""
fi

echo "Installed strayfiles-ping to ${INSTALL_DIR}/strayfiles-ping"
echo ""
echo "Next steps:"
echo "  1. Run: strayfiles-ping auth"
echo "  2. Say 'ping me when done' to Claude"
