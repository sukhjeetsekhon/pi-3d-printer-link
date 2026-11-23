#!/usr/bin/env bash
# ==============================================================================
# install.sh - One-step installer for pi-link on Raspberry Pi (Bookworm/Trixie)
# ==============================================================================
set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_BIN="/usr/local/bin/pi-link"

echo "=== Installing pi-link ==="

# Ensure scripts are executable
chmod +x "$REPO_DIR/bin/pi-link"
chmod +x "$REPO_DIR/install.sh"
chmod +x "$REPO_DIR/firmware/esp32c5/flash_esp32c5.py"

# Symlink to /usr/local/bin
if [[ -L "$TARGET_BIN" || -f "$TARGET_BIN" ]]; then
    rm -f "$TARGET_BIN"
fi

ln -s "$REPO_DIR/bin/pi-link" "$TARGET_BIN"

echo "pi-link successfully installed to $TARGET_BIN"
echo "You can now run:"
echo "  sudo pi-link setup"
echo "  sudo pi-link status"
