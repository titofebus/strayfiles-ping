#!/bin/bash
# Strayfiles Ping installer
# Downloads and verifies the strayfiles-ping binary for your platform

set -eu

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
    if [ -t 0 ]; then
      # Interactive terminal — prompt user
      printf "Continue without verification? (y/N) "
      read -r REPLY
      if [ "$REPLY" != "y" ] && [ "$REPLY" != "Y" ]; then
        echo "Installation cancelled"
        exit 1
      fi
    else
      # Non-interactive (piped) — proceed with warning
      echo "   Proceeding without verification (non-interactive mode)"
    fi
  fi
else
  echo "⚠️  Signature file not found (development build?)"
  echo "   Skipping verification..."
fi

# Install binary
mv "${TEMP_DIR}/strayfiles-ping" "${INSTALL_DIR}/strayfiles-ping"
chmod +x "${INSTALL_DIR}/strayfiles-ping"

# Remove quarantine on macOS (blocks unsigned binaries)
if [ "$OS" = "darwin" ]; then
  xattr -rd com.apple.quarantine "${INSTALL_DIR}/strayfiles-ping" 2>/dev/null || true
fi

# Download native dialog binary (macOS only)
if [ "$OS" = "darwin" ]; then
  DIALOG_URL="${DOWNLOAD_URL/strayfiles-ping-/strayfiles-dialog-}"
  echo ""
  echo "Downloading native dialog binary..."
  if curl -fsSL "$DIALOG_URL" -o "${TEMP_DIR}/strayfiles-dialog" 2>/dev/null; then
    # Download and verify dialog signature
    DIALOG_SIG_URL="${DIALOG_URL}.minisig"
    DIALOG_VERIFIED=false

    if curl -fsSL "$DIALOG_SIG_URL" -o "${TEMP_DIR}/strayfiles-dialog.minisig" 2>/dev/null; then
      if command -v minisign >/dev/null 2>&1; then
        echo "$PUBLIC_KEY" > "${TEMP_DIR}/pubkey"
        if minisign -Vm "${TEMP_DIR}/strayfiles-dialog" -p "${TEMP_DIR}/pubkey" 2>/dev/null; then
          echo "Signature verified"
          DIALOG_VERIFIED=true
        else
          echo "WARNING: Dialog signature verification failed - skipping dialog install"
          echo "Native dialogs will not be available. Re-run the install script to retry."
        fi
      else
        # No minisign - install anyway (already warned above for main binary)
        DIALOG_VERIFIED=true
      fi
    else
      # No signature file - development build
      DIALOG_VERIFIED=true
    fi

    if [ "$DIALOG_VERIFIED" = true ]; then
      mv "${TEMP_DIR}/strayfiles-dialog" "${INSTALL_DIR}/strayfiles-dialog"
      chmod +x "${INSTALL_DIR}/strayfiles-dialog"
      xattr -rd com.apple.quarantine "${INSTALL_DIR}/strayfiles-dialog" 2>/dev/null || true
      echo "Installed strayfiles-dialog to ${INSTALL_DIR}/strayfiles-dialog"
    fi
  else
    echo "Dialog binary not available for this release - native dialogs will not work"
    echo "Remote push notifications still available with Pro subscription"
  fi
fi

# Check if install dir is in PATH
if [[ ":$PATH:" != *":${INSTALL_DIR}:"* ]]; then
  echo ""
  echo "Add this to your shell profile (.bashrc, .zshrc, etc.):"
  echo "  export PATH=\"\$PATH:${INSTALL_DIR}\""
  echo ""
fi

echo ""
echo "Installed strayfiles-ping to ${INSTALL_DIR}/strayfiles-ping"
echo ""
echo "Next steps:"
echo "  1. Say 'ping me when done' to Claude (works immediately - no account needed!)"
echo "  2. Optional: Run 'strayfiles-ping auth' to unlock remote push notifications (Pro)"
