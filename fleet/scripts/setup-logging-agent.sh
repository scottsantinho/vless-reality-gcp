#!/bin/bash
# =============================================================================
# setup-logging-agent.sh - Install Google Cloud Ops Agent
# =============================================================================
# Installs and configures the Ops Agent on VPS nodes for centralized logging.
# This script is IDEMPOTENT - safe to run multiple times.
#
# For non-GCP VMs, requires a service account key at:
#   /etc/google-cloud-ops-agent/credentials.json
# =============================================================================

set -euo pipefail

MARKER_DIR="/etc/vpn-fleet"
MARKER_FILE="${MARKER_DIR}/.ops-agent-installed"
OPS_AGENT_DIR="/etc/google-cloud-ops-agent"
CREDENTIALS_FILE="${OPS_AGENT_DIR}/credentials.json"

# =============================================================================
# Credential Setup (runs on every deployment)
# =============================================================================
if [[ -f "/tmp/ops_agent_key.json" ]]; then
    echo "[INFO] Setting up credentials for non-GCP VM..."
    chmod 600 /tmp/ops_agent_key.json
    mkdir -p "$OPS_AGENT_DIR"
    cp /tmp/ops_agent_key.json "$CREDENTIALS_FILE"
    chmod 600 "$CREDENTIALS_FILE"
    
    # Extract project ID from credentials file
    PROJECT_ID=$(grep -o '"project_id"[[:space:]]*:[[:space:]]*"[^"]*"' "$CREDENTIALS_FILE" | sed 's/.*: *"\([^"]*\)"/\1/')
    echo "[DEBUG] Extracted project ID: $PROJECT_ID"
    
    # Create systemd override for main service
    mkdir -p /etc/systemd/system/google-cloud-ops-agent.service.d
    cat > /etc/systemd/system/google-cloud-ops-agent.service.d/credentials.conf << EOF
[Service]
Environment="GOOGLE_APPLICATION_CREDENTIALS=${CREDENTIALS_FILE}"
Environment="GOOGLE_CLOUD_PROJECT=${PROJECT_ID}"
EOF
    
    # Create systemd override for fluent-bit (logging sub-agent)
    mkdir -p /etc/systemd/system/google-cloud-ops-agent-fluent-bit.service.d
    cat > /etc/systemd/system/google-cloud-ops-agent-fluent-bit.service.d/credentials.conf << EOF
[Service]
Environment="GOOGLE_SERVICE_CREDENTIALS=${CREDENTIALS_FILE}"
Environment="GOOGLE_CLOUD_PROJECT=${PROJECT_ID}"
EOF
    
    # Create systemd override for otel-collector (metrics sub-agent)
    mkdir -p /etc/systemd/system/google-cloud-ops-agent-opentelemetry-collector.service.d
    cat > /etc/systemd/system/google-cloud-ops-agent-opentelemetry-collector.service.d/credentials.conf << EOF
[Service]
Environment="GOOGLE_APPLICATION_CREDENTIALS=${CREDENTIALS_FILE}"
Environment="GOOGLE_CLOUD_PROJECT=${PROJECT_ID}"
EOF
    
    systemctl daemon-reload
    shred -u /tmp/ops_agent_key.json 2>/dev/null || rm -f /tmp/ops_agent_key.json
fi

# =============================================================================
# Skip if Already Installed
# =============================================================================
if [[ -f "$MARKER_FILE" ]]; then
    echo "[INFO] Ops Agent already installed (marker file exists). Skipping installation..."
    systemctl restart google-cloud-ops-agent || true
    exit 0
fi

# =============================================================================
# Installation
# =============================================================================
echo "[INFO] Starting Ops Agent installation..."

mkdir -p "$MARKER_DIR"
mkdir -p "$OPS_AGENT_DIR"

echo "[INFO] Downloading and running Ops Agent installer..."
curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
bash add-google-cloud-ops-agent-repo.sh --also-install
rm -f add-google-cloud-ops-agent-repo.sh

sleep 5
systemctl restart google-cloud-ops-agent

# =============================================================================
# Verification
# =============================================================================
if ! systemctl is-active --quiet google-cloud-ops-agent; then
    echo "[ERROR] Ops Agent is not running after installation"
    exit 1
fi

echo "Installed: $(date -Iseconds)" > "$MARKER_FILE"
echo "Version: $(dpkg -l google-cloud-ops-agent 2>/dev/null | grep google-cloud-ops-agent | awk '{print $3}' || echo 'unknown')" >> "$MARKER_FILE"

echo "[SUCCESS] Ops Agent installed and running"
