# =============================================================================
# Variables - Environment-specific configuration
# =============================================================================
# All environment-specific values are centralized in terraform.tfvars.
# This enables easy environment portability and configuration changes.
# =============================================================================

# -----------------------------------------------------------------------------
# Core GCP Configuration
# -----------------------------------------------------------------------------
variable "project_id" {
  description = "GCP Project ID (e.g., my-vpn-project-123456)"
  type        = string
}

variable "region" {
  description = "GCP Region (e.g., asia-northeast1, us-central1)"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., prod, staging, dev)"
  type        = string
  default     = "prod"
}

# -----------------------------------------------------------------------------
# Cloud Build Configuration
# -----------------------------------------------------------------------------
variable "cloudbuild_connection_id" {
  description = "Cloud Build 2nd gen connection ID (e.g., github-johndoe)"
  type        = string
}

variable "cloudbuild_repo_id" {
  description = "Cloud Build repository ID under the connection (e.g., johndoe-custom-vpn)"
  type        = string
}

variable "default_branch" {
  description = "Default Git branch for triggers (without refs/heads/ prefix)"
  type        = string
  default     = "main"
}

# -----------------------------------------------------------------------------
# Logging Configuration
# -----------------------------------------------------------------------------
variable "log_retention_days" {
  description = "Number of days to retain logs in BigQuery before auto-deletion"
  type        = number
  default     = 7
}
