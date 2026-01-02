# =============================================================================
# Terraform Variables - Production Environment
# =============================================================================
# Centralized configuration for the prod environment.
# Modify these values to customize the deployment.
# =============================================================================

# -----------------------------------------------------------------------------
# Core GCP Configuration
# -----------------------------------------------------------------------------
project_id  = "your-project-id"    # e.g., "my-vpn-project-123456"
region      = "asia-northeast1"    # GCP region (Tokyo)
environment = "prod"

# -----------------------------------------------------------------------------
# Cloud Build Configuration
# -----------------------------------------------------------------------------
cloudbuild_connection_id = "github-your-connection"    # e.g., "github-johndoe" (Cloud Build 2nd gen connection name)
cloudbuild_repo_id       = "your-username-your-repo"   # e.g., "johndoe-custom-vpn" (repository linked to connection)
default_branch           = "main"

# -----------------------------------------------------------------------------
# Logging Configuration
# -----------------------------------------------------------------------------
log_retention_days = 7
