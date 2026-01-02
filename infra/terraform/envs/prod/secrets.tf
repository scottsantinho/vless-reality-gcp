# =============================================================================
# Secrets - Secret Manager Resources
# =============================================================================
# These secrets were created manually via gcloud/Console. Importing them into
# Terraform for documentation, IaC completeness, and enabling references from
# other Terraform resources.
#
# Note: Secret VALUES are NOT stored in Terraform - only the secret containers.
# =============================================================================

locals {
  cb_im_triggers_secret_ids = [
    "vps-ssh-private-key",
    "vps-ssh-host-keys",
    "xray-reality-private-key",
    "xray-uuid",
    "vps-logging-agent-key",
  ]
}

# -----------------------------------------------------------------------------
# Imports - Existing Secrets
# -----------------------------------------------------------------------------
# NOTE: Update the project ID in each import block to match your project.
# Example format: projects/YOUR_PROJECT_ID/secrets/SECRET_NAME

import {
  to = google_secret_manager_secret.vps_ssh_private_key
  id = "projects/${var.project_id}/secrets/vps-ssh-private-key"  # e.g., "projects/my-vpn-project-123456/secrets/vps-ssh-private-key"
}

import {
  to = google_secret_manager_secret.xray_reality_private_key
  id = "projects/${var.project_id}/secrets/xray-reality-private-key"
}

import {
  to = google_secret_manager_secret.xray_uuid
  id = "projects/${var.project_id}/secrets/xray-uuid"
}

import {
  to = google_secret_manager_secret.vps_ssh_host_keys
  id = "projects/${var.project_id}/secrets/vps-ssh-host-keys"
}

# -----------------------------------------------------------------------------
# Secret: vps-ssh-private-key
# -----------------------------------------------------------------------------
resource "google_secret_manager_secret" "vps_ssh_private_key" {
  project   = var.project_id
  secret_id = "vps-ssh-private-key"

  labels = {
    purpose = "vps-access"
    type    = "ssh-key"
  }

  replication {
    auto {}
  }
}

# -----------------------------------------------------------------------------
# Secret: xray-reality-private-key
# -----------------------------------------------------------------------------
resource "google_secret_manager_secret" "xray_reality_private_key" {
  project   = var.project_id
  secret_id = "xray-reality-private-key"

  labels = {
    purpose = "xray-config"
    type    = "reality-key"
  }

  replication {
    auto {}
  }
}

# -----------------------------------------------------------------------------
# Secret: xray-uuid
# -----------------------------------------------------------------------------
resource "google_secret_manager_secret" "xray_uuid" {
  project   = var.project_id
  secret_id = "xray-uuid"

  labels = {
    purpose = "xray-config"
    type    = "client-uuid"
  }

  replication {
    auto {}
  }
}

# -----------------------------------------------------------------------------
# Secret: vps-logging-agent-key
# -----------------------------------------------------------------------------
# Manual step required after creation:
# 1. gcloud iam service-accounts keys create /tmp/key.json \
#      --iam-account=vps-logging-agent@${PROJECT_ID}.iam.gserviceaccount.com
# 2. gcloud secrets versions add vps-logging-agent-key --data-file=/tmp/key.json
# 3. rm /tmp/key.json
# -----------------------------------------------------------------------------
resource "google_secret_manager_secret" "vps_logging_agent_key" {
  project   = var.project_id
  secret_id = "vps-logging-agent-key"

  labels = {
    purpose = "ops-agent"
    type    = "sa-key"
  }

  replication {
    auto {}
  }
}

# -----------------------------------------------------------------------------
# Secret: vps-ssh-host-keys
# -----------------------------------------------------------------------------
resource "google_secret_manager_secret" "vps_ssh_host_keys" {
  project   = var.project_id
  secret_id = "vps-ssh-host-keys"

  labels = {
    purpose = "ssh-security"
    type    = "known-hosts"
  }

  replication {
    auto {}
  }
}

# -----------------------------------------------------------------------------
# Secret IAM - cb-fleet-reconcile Access
# -----------------------------------------------------------------------------
resource "google_secret_manager_secret_iam_member" "cb_fleet_reconcile_secret_access" {
  for_each = toset(local.cb_im_triggers_secret_ids)

  secret_id = "projects/${var.project_id}/secrets/${each.value}"
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:cb-fleet-reconcile@${var.project_id}.iam.gserviceaccount.com"
}
