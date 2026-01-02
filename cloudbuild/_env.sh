#!/usr/bin/env bash
# =============================================================================
# Cloud Build Environment - Shared Configuration
# =============================================================================
# Non-secret configuration values for all Cloud Build pipelines.
# Source this file at the start of each build step.
# =============================================================================

export PROJECT_ID="your-project-id"           # e.g., my-vpn-project-123456
export LOCATION="asia-northeast1"             # GCP region for Cloud Build
export DEPLOYMENT_ID="custom-vpn-prod"        # Infrastructure Manager deployment name
export DEPLOYMENT_DIR="infra/terraform/envs/prod"
export REPO_URI="https://github.com/your-username/your-repo.git"  # e.g., https://github.com/johndoe/custom-vpn.git
export FLEET_TRIGGER="fleet-reconcile"
