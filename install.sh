#!/bin/bash
# Strayfiles Ping installer
# Downloads and verifies the strayfiles-ping binary for your platform

set -e

REPO="titofebus/strayfiles-ping"
INSTALL_DIR="${HOME}/.local/bin"

# Minisign public key for signature verification
# This key is used to verify all release binaries
PUBLIC_KEY="RWQf6LRCGA9i5UxATuRCuQV8PuJBLAZ4r7r7qQ9f3RcqH0L4fK0NqBYk"

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

# Create install directory and temp dir
mkdir -p "$INSTALL_DIR"
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

# Download binary
echo "Downloading binary from ${DOWNLOAD_URL}..."
curl -fsSL "$DOWNLOAD_URL" -o "${TEMP_DIR}/strayfiles-ping"

# Download signature
SIGNATURE_URL="${DOWNLOAD_URL}.minisig"
echo "Downloading signature..."
if curl -fsSL "$SIGNATURE_URL" -o "${TEMP_DIR}/strayfiles-ping.minisig" 2>/dev/null; then
  # Verify signature if minisign is available
  if command -v minisign >/dev/null 2>&1; then
    echo "Verifying signature..."
    echo "$PUBLIC_KEY" > "${TEMP_DIR}/pubkey"

    if minisign -Vm "${TEMP_DIR}/strayfiles-ping" -p "${TEMP_DIR}/pubkey" 2>/dev/null; then
      echo "✓ Signature verified"
    else
      echo "❌ Signature verification failed!"
      echo "The binary may have been tampered with."
      echo "Refusing to install for your security."
      exit 1
    fi
  else
    echo "⚠️  minisign not found - skipping signature verification"
    echo "   Install minisign for secure verification:"
    echo "   - macOS: brew install minisign"
    echo "   - Linux: apt-get install minisign"
    echo ""
    read -p "Continue without verification? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo "Installation cancelled"
      exit 1
    fi
  fi
else
  echo "⚠️  Signature file not found (development build?)"
  echo "   Skipping verification..."
fi

# Install binary
mv "${TEMP_DIR}/strayfiles-ping" "${INSTALL_DIR}/strayfiles-ping"
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
