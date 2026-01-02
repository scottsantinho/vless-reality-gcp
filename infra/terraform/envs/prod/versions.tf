# =============================================================================
# Versions - Terraform and Provider Constraints
# =============================================================================
# Specifies required Terraform version and provider versions.
# =============================================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}
