#!/bin/bash
# =============================================================================
# setup-xray.sh - Install Xray with VLESS + Reality
# =============================================================================
# Installs and configures Xray proxy server with VLESS Reality protocol.
# This script is IDEMPOTENT - safe to run multiple times.
#
# Required environment variables:
#   XRAY_PRIVATE_KEY  - Reality private key
#   XRAY_UUID         - VLESS client UUID
#   XRAY_SNI          - Server Name Indication (e.g., www.microsoft.com)
#   XRAY_PORT         - Listen port (default: 443)
# =============================================================================

set -euo pipefail

MARKER_DIR="/etc/vpn-fleet"
MARKER_FILE="${MARKER_DIR}/.xray-installed"
XRAY_DIR="/opt/xray"
XRAY_CONFIG="/opt/xray/config.json"
XRAY_LOG_DIR="/var/log/xray"
XRAY_PORT="${XRAY_PORT:-443}"

# =============================================================================
# Validate Environment
# =============================================================================
for var in XRAY_PRIVATE_KEY XRAY_UUID XRAY_SNI; do
    if [[ -z "${!var:-}" ]]; then
        echo "[ERROR] Required environment variable $var is not set"
        exit 1
    fi
done

# =============================================================================
# Skip if Already Installed (but update config and service file)
# =============================================================================
if [[ -f "$MARKER_FILE" ]]; then
    echo "[INFO] Xray already installed (marker file exists). Updating config and service..."
    
    # Update Xray config
    envsubst < /tmp/xray-config.json.tpl > "$XRAY_CONFIG"
    chmod 600 "$XRAY_CONFIG"
    chown xray:xray "$XRAY_CONFIG"
    
    # Update systemd service file (for hardening changes)
    if [[ -f /tmp/xray.service ]]; then
        if ! diff -q /tmp/xray.service /etc/systemd/system/xray.service >/dev/null 2>&1; then
            echo "[INFO] Systemd service file changed, updating..."
            cp /tmp/xray.service /etc/systemd/system/xray.service
            systemctl daemon-reload
        fi
    fi
    
    # Reload or restart to apply changes
    systemctl reload xray 2>/dev/null || systemctl restart xray
    echo "[SUCCESS] Xray config and service updated"
    exit 0
fi

# =============================================================================
# Installation
# =============================================================================
echo "[INFO] Starting Xray installation..."

# Create dedicated xray user
if ! id -u xray &>/dev/null; then
    echo "[INFO] Creating xray system user..."
    useradd --system --no-create-home --shell /usr/sbin/nologin xray
fi

mkdir -p "$MARKER_DIR" "$XRAY_DIR" "$XRAY_LOG_DIR"
chown -R xray:xray "$XRAY_DIR" "$XRAY_LOG_DIR"

# Detect architecture
ARCH=$(uname -m)
case $ARCH in
    x86_64) XRAY_ARCH="64" ;;
    aarch64) XRAY_ARCH="arm64-v8a" ;;
    *) echo "[ERROR] Unsupported architecture: $ARCH"; exit 1 ;;
esac

# Install required packages
for pkg in unzip jq curl; do
    if ! command -v $pkg &> /dev/null; then
        echo "[INFO] Installing $pkg..."
        apt-get update -qq && apt-get install -y -qq $pkg
    fi
done

# =============================================================================
# Download Xray (Pinned Version with Checksum Verification)
# =============================================================================
# Supply chain security: We pin to a known version and verify the SHA256 checksum
# to prevent MITM or compromised release attacks.
#
# To update: Get new checksum from https://github.com/XTLS/Xray-core/releases
# The checksum file is named Xray-linux-64.zip.sha256 on the release page.
# =============================================================================

# Pinned version and checksums (update together when upgrading)
XRAY_VERSION="v25.12.8"
declare -A XRAY_CHECKSUMS=(
    ["64"]="3925cb3d1c7aef2e9f441537e623011701224023dad436ef9404875dfacc2629"
    # Add arm64-v8a checksum here if needed for ARM VPS
)

echo "[INFO] Installing Xray version: $XRAY_VERSION (pinned)"

# Verify we have a checksum for this architecture
if [[ -z "${XRAY_CHECKSUMS[$XRAY_ARCH]:-}" ]]; then
    echo "[ERROR] No pinned checksum for architecture: $XRAY_ARCH"
    echo "[ERROR] Please add the SHA256 checksum to this script before deploying to this architecture"
    exit 1
fi

EXPECTED_SHA256="${XRAY_CHECKSUMS[$XRAY_ARCH]}"
XRAY_URL="https://github.com/XTLS/Xray-core/releases/download/${XRAY_VERSION}/Xray-linux-${XRAY_ARCH}.zip"
echo "[DEBUG] Download URL: $XRAY_URL"
echo "[DEBUG] Expected SHA256: $EXPECTED_SHA256"

for attempt in 1 2 3; do
    echo "[INFO] Download attempt $attempt..."
    curl -L --fail -o /tmp/xray.zip "$XRAY_URL" && break
    echo "[WARN] Download failed, retrying in 5s..."
    sleep 5
done

if [[ ! -f /tmp/xray.zip ]]; then
    echo "[ERROR] Failed to download Xray after 3 attempts"
    exit 1
fi

# Verify checksum (supply chain security)
echo "[INFO] Verifying SHA256 checksum..."
ACTUAL_SHA256=$(sha256sum /tmp/xray.zip | cut -d' ' -f1)

if [[ "$ACTUAL_SHA256" != "$EXPECTED_SHA256" ]]; then
    echo "[ERROR] Checksum verification FAILED!"
    echo "[ERROR] Expected: $EXPECTED_SHA256"
    echo "[ERROR] Actual:   $ACTUAL_SHA256"
    echo "[ERROR] This could indicate a compromised download or version mismatch"
    rm -f /tmp/xray.zip
    exit 1
fi

echo "[SUCCESS] Checksum verified"

FILE_SIZE=$(stat -c%s /tmp/xray.zip 2>/dev/null || stat -f%z /tmp/xray.zip)
echo "[INFO] Downloaded ${FILE_SIZE} bytes"
unzip -o /tmp/xray.zip -d "$XRAY_DIR"
chmod +x "$XRAY_DIR/xray"
rm -f /tmp/xray.zip

ln -sf "$XRAY_DIR/xray" /usr/local/bin/xray

# =============================================================================
# Configuration
# =============================================================================
if [[ -f /tmp/xray-config.json.tpl ]]; then
    echo "[INFO] Generating Xray config from template..."
    envsubst < /tmp/xray-config.json.tpl > "$XRAY_CONFIG"
    chmod 600 "$XRAY_CONFIG"
    chown xray:xray "$XRAY_CONFIG"
else
    echo "[ERROR] Config template not found at /tmp/xray-config.json.tpl"
    exit 1
fi

# =============================================================================
# Systemd Service
# =============================================================================
if [[ -f /tmp/xray.service ]]; then
    echo "[INFO] Installing systemd service..."
    cp /tmp/xray.service /etc/systemd/system/xray.service
    systemctl daemon-reload
    systemctl enable xray
    systemctl start xray
else
    echo "[ERROR] Systemd service file not found at /tmp/xray.service"
    exit 1
fi

# =============================================================================
# Verification
# =============================================================================
sleep 3
if ! systemctl is-active --quiet xray; then
    echo "[ERROR] Xray is not running after installation"
    journalctl -u xray --no-pager -n 20
    exit 1
fi

echo "Installed: $(date -Iseconds)" > "$MARKER_FILE"
echo "Version: ${XRAY_VERSION}" >> "$MARKER_FILE"

echo "[SUCCESS] Xray installed and running on port ${XRAY_PORT}"
