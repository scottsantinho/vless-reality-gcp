# =============================================================================
# Storage - Infrastructure Manager Staging Bucket IAM
# =============================================================================
# Infra Manager uses a GCS staging bucket created outside Terraform.
# Grant read access to the trigger service accounts that run IM preview/apply.
# =============================================================================

locals {
  infra_manager_staging_bucket = "${var.project_id}_infra_manager_staging"
}

# -----------------------------------------------------------------------------
# Bucket IAM - Preview Access
# -----------------------------------------------------------------------------
resource "google_storage_bucket_iam_member" "im_preview_can_read_staging_bucket" {
  bucket = local.infra_manager_staging_bucket
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.cb_im_preview.email}"
}

# -----------------------------------------------------------------------------
# Bucket IAM - Apply Access
# -----------------------------------------------------------------------------
resource "google_storage_bucket_iam_member" "im_apply_can_read_staging_bucket" {
  bucket = local.infra_manager_staging_bucket
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.cb_im_apply.email}"
}

resource "google_storage_bucket_iam_member" "im_apply_can_manage_staging_objects" {
  bucket = local.infra_manager_staging_bucket
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.cb_im_apply.email}"
}

# -----------------------------------------------------------------------------
# Bucket IAM - Executor Access
# -----------------------------------------------------------------------------
resource "google_storage_bucket_iam_member" "im_executor_can_admin_staging_bucket" {
  bucket = local.infra_manager_staging_bucket
  role   = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.im_executor.email}"
}
