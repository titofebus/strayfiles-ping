#!/bin/sh
# Strayfiles Ping installer
# Downloads the strayfiles-ping MCP server and strayfiles-dialog native UI binary
# Usage: curl -fsSL https://strayfiles.com/ping-install.sh | sh

set -e

DOWNLOAD_URL="https://strayfiles.com/releases/latest"
INSTALL_DIR="${HOME}/.local/bin"

# Minimum expected binary size (1 MB) to catch error pages
MIN_SIZE=1000000

# Detect platform
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

case "$ARCH" in
  x86_64) ARCH="x64" ;;
  aarch64|arm64) ARCH="arm64" ;;
  *) echo "Unsupported architecture: $ARCH" >&2; exit 1 ;;
esac

case "$OS" in
  darwin) PLATFORM="macos-${ARCH}" ;;
  linux) PLATFORM="linux-${ARCH}" ;;
  *) echo "Unsupported OS: $OS" >&2; exit 1 ;;
esac

CHECKSUMS_URL="${DOWNLOAD_URL}/checksums.sha256"

# Create install directory
mkdir -p "$INSTALL_DIR"

# Temp file tracking for cleanup
TMP_FILES=""
cleanup() {
  for f in $TMP_FILES; do
    rm -f "$f"
  done
}
trap cleanup EXIT INT TERM

# Download helper — supports curl and wget
download() {
  _url="$1"
  _dest="$2"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$_url" -o "$_dest"
  elif command -v wget >/dev/null 2>&1; then
    wget -q "$_url" -O "$_dest"
  else
    echo "Error: curl or wget is required" >&2
    exit 1
  fi
}

# Fetch checksums for verification
CHECKSUMS=""
if command -v curl >/dev/null 2>&1; then
  CHECKSUMS=$(curl -fsSL "$CHECKSUMS_URL" 2>/dev/null) || true
elif command -v wget >/dev/null 2>&1; then
  CHECKSUMS=$(wget -qO- "$CHECKSUMS_URL" 2>/dev/null) || true
fi

verify_checksum() {
  _file="$1"
  _binary_name="$2"

  if [ -z "$CHECKSUMS" ]; then
    echo "Warning: checksum file not available, skipping verification." >&2
    return 0
  fi

  # Exact match: grep for " binary_name" at end of line to avoid substring matches
  _expected=$(echo "$CHECKSUMS" | grep " ${_binary_name}\$" | awk '{print $1}')
  if [ -z "$_expected" ]; then
    echo "Warning: no checksum found for $_binary_name, skipping verification." >&2
    return 0
  fi

  _actual=""
  if command -v shasum >/dev/null 2>&1; then
    _actual=$(shasum -a 256 "$_file" | awk '{print $1}')
  elif command -v sha256sum >/dev/null 2>&1; then
    _actual=$(sha256sum "$_file" | awk '{print $1}')
  else
    echo "Warning: no SHA-256 tool found, skipping checksum verification." >&2
    return 0
  fi

  if [ "$_actual" != "$_expected" ]; then
    echo "Error: Checksum mismatch for $_binary_name!" >&2
    echo "  Expected: $_expected" >&2
    echo "  Got:      $_actual" >&2
    echo "The download may be corrupted or tampered with." >&2
    return 1
  fi

  echo "Checksum verified."
  return 0
}

# Download and install strayfiles-ping
PING_BINARY="strayfiles-ping-${PLATFORM}"
PING_URL="${DOWNLOAD_URL}/${PING_BINARY}"
TMP_FILE="${INSTALL_DIR}/strayfiles-ping.tmp.$$"
TMP_FILES="$TMP_FILE"

echo "Installing strayfiles-ping for ${PLATFORM}..."
echo "Downloading from ${PING_URL}..."
download "$PING_URL" "$TMP_FILE"

# Validate binary size
FILE_SIZE=$(wc -c < "$TMP_FILE" | tr -d ' ')
if [ "$FILE_SIZE" -lt "$MIN_SIZE" ]; then
  echo "Error: Downloaded file is too small (${FILE_SIZE} bytes)." >&2
  echo "The download server may be misconfigured or the binary is not yet available." >&2
  exit 1
fi

verify_checksum "$TMP_FILE" "$PING_BINARY"
mv "$TMP_FILE" "${INSTALL_DIR}/strayfiles-ping"
chmod +x "${INSTALL_DIR}/strayfiles-ping"

# Remove macOS quarantine attribute
if [ "$OS" = "darwin" ]; then
  xattr -d com.apple.quarantine "${INSTALL_DIR}/strayfiles-ping" 2>/dev/null || true
fi

echo "Installed strayfiles-ping to ${INSTALL_DIR}/strayfiles-ping"

# Download strayfiles-dialog binary (macOS only — native dialog UI)
if [ "$OS" = "darwin" ]; then
  DIALOG_BINARY="strayfiles-dialog-${PLATFORM}"
  DIALOG_URL="${DOWNLOAD_URL}/${DIALOG_BINARY}"
  TMP_FILE="${INSTALL_DIR}/strayfiles-dialog.tmp.$$"
  TMP_FILES="$TMP_FILES $TMP_FILE"

  echo ""
  echo "Installing strayfiles-dialog (native dialog UI)..."
  echo "Downloading from ${DIALOG_URL}..."
  if download "$DIALOG_URL" "$TMP_FILE" 2>/dev/null; then
    # Validate binary size
    DIALOG_SIZE=$(wc -c < "$TMP_FILE" | tr -d ' ')
    if [ "$DIALOG_SIZE" -lt "$MIN_SIZE" ]; then
      rm -f "$TMP_FILE"
      echo "Note: strayfiles-dialog download was too small (possible error). Skipping."
      echo "Ping will use TUI notifications instead."
    else
      verify_checksum "$TMP_FILE" "$DIALOG_BINARY"
      mv "$TMP_FILE" "${INSTALL_DIR}/strayfiles-dialog"
      chmod +x "${INSTALL_DIR}/strayfiles-dialog"
      xattr -d com.apple.quarantine "${INSTALL_DIR}/strayfiles-dialog" 2>/dev/null || true
      echo "Installed strayfiles-dialog to ${INSTALL_DIR}/strayfiles-dialog"
    fi
  else
    rm -f "$TMP_FILE"
    echo "Note: strayfiles-dialog not available yet. Ping will use TUI notifications instead."
    echo "You can re-run this script later to pick it up when available."
  fi
fi

# Check if install dir is in PATH (POSIX-compatible check)
case ":${PATH}:" in
  *":${INSTALL_DIR}:"*) ;;
  *)
    echo ""
    echo "Add this to your shell profile (.bashrc, .zshrc, etc.):"
    echo "  export PATH=\"\$PATH:${INSTALL_DIR}\""
    echo ""
    ;;
esac

echo ""
echo "Setup complete! Next steps:"
echo ""
echo "  1. Add the MCP server to your agent:"
echo ""
echo "     Claude Code:  claude mcp add --transport stdio strayfiles-ping -- strayfiles-ping"
echo "     Codex:        codex mcp add strayfiles-ping -- strayfiles-ping"
echo ""
echo "     For Cursor, Windsurf, VS Code, and others, add to your MCP config:"
echo "     {\"mcpServers\":{\"strayfiles-ping\":{\"command\":\"strayfiles-ping\"}}}"
echo ""
echo "  2. (Optional) Sign in for cross-device sync:"
echo "     strayfiles-ping auth"
echo ""
echo "  3. Say 'ping me when done' to your agent"
