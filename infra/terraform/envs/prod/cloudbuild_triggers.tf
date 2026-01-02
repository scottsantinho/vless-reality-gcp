# =============================================================================
# Cloud Build Triggers - CI/CD Pipeline
# =============================================================================
# Defines all Cloud Build triggers for the CI/CD pipeline.
# These triggers were initially created manually in Cloud Console and are now
# managed as IaC for reproducibility and documentation.
# =============================================================================

locals {
  cloudbuild_repo = "projects/${var.project_id}/locations/${var.region}/connections/${var.cloudbuild_connection_id}/repositories/${var.cloudbuild_repo_id}"
  branch_pattern  = "^${var.default_branch}$"
  branch_ref      = "refs/heads/${var.default_branch}"
}

# -----------------------------------------------------------------------------
# Imports - Existing Triggers
# -----------------------------------------------------------------------------
# NOTE: These import blocks require the actual trigger UUIDs from your project.
# To find your trigger IDs, run:
#   gcloud builds triggers list --region=YOUR_REGION --project=YOUR_PROJECT_ID
#
# After getting the trigger IDs, update the id field below.
# Example format: projects/YOUR_PROJECT_ID/locations/YOUR_REGION/triggers/TRIGGER_UUID

import {
  to = google_cloudbuild_trigger.ci_lint
  id = "projects/${var.project_id}/locations/${var.region}/triggers/YOUR_CI_LINT_TRIGGER_UUID"
  # e.g., "projects/my-vpn-project/locations/asia-northeast1/triggers/74257014-60e4-4258-9d44-5de6d6be88f3"
}

import {
  to = google_cloudbuild_trigger.im_preview
  id = "projects/${var.project_id}/locations/${var.region}/triggers/YOUR_IM_PREVIEW_TRIGGER_UUID"
}

import {
  to = google_cloudbuild_trigger.im_apply
  id = "projects/${var.project_id}/locations/${var.region}/triggers/YOUR_IM_APPLY_TRIGGER_UUID"
}

import {
  to = google_cloudbuild_trigger.fleet_reconcile
  id = "projects/${var.project_id}/locations/${var.region}/triggers/YOUR_FLEET_RECONCILE_TRIGGER_UUID"
}

# -----------------------------------------------------------------------------
# Trigger: ci-lint
# -----------------------------------------------------------------------------
resource "google_cloudbuild_trigger" "ci_lint" {
  project  = var.project_id
  location = var.region
  name     = "ci-lint"

  repository_event_config {
    repository = local.cloudbuild_repo
    pull_request {
      branch = local.branch_pattern
    }
  }

  filename        = "cloudbuild/ci-lint.yaml"
  service_account = google_service_account.cb_ci_lint.id
}

# -----------------------------------------------------------------------------
# Trigger: im-preview
# -----------------------------------------------------------------------------
resource "google_cloudbuild_trigger" "im_preview" {
  project  = var.project_id
  location = var.region
  name     = "im-preview"

  repository_event_config {
    repository = local.cloudbuild_repo
    pull_request {
      branch = local.branch_pattern
    }
  }

  included_files = ["infra/terraform/**"]
  ignored_files  = ["**/*.md"]

  filename        = "cloudbuild/im-preview.yaml"
  service_account = google_service_account.cb_im_preview.id
}

# -----------------------------------------------------------------------------
# Trigger: im-apply
# -----------------------------------------------------------------------------
resource "google_cloudbuild_trigger" "im_apply" {
  project  = var.project_id
  location = var.region
  name     = "im-apply"

  repository_event_config {
    repository = local.cloudbuild_repo
    push {
      branch = local.branch_pattern
    }
  }

  included_files = ["infra/terraform/**"]
  ignored_files  = ["**/*.md"]

  filename        = "cloudbuild/im-apply.yaml"
  service_account = google_service_account.cb_im_apply.id
}

# -----------------------------------------------------------------------------
# Trigger: fleet-reconcile
# -----------------------------------------------------------------------------
resource "google_cloudbuild_trigger" "fleet_reconcile" {
  project  = var.project_id
  location = var.region
  name     = "fleet-reconcile"

  source_to_build {
    repository = local.cloudbuild_repo
    ref        = local.branch_ref
    repo_type  = "GITHUB"
  }

  git_file_source {
    path       = "cloudbuild/fleet-reconcile.yaml"
    repository = local.cloudbuild_repo
    revision   = local.branch_ref
    repo_type  = "GITHUB"
  }

  service_account = google_service_account.cb_fleet_reconcile.id
}
