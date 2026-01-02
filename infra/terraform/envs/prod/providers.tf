# =============================================================================
# Providers - Google Cloud Platform
# =============================================================================
# Configures the Google Cloud provider with project and region defaults.
# =============================================================================

provider "google" {
  project = var.project_id
  region  = var.region
}
