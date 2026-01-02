# =============================================================================
# Service Accounts - Infrastructure Manager & Cloud Build
# =============================================================================
# These service accounts were initially created manually to bootstrap the
# project. Now documented here as IaC for reproducibility and documentation.
# Import blocks below allow Terraform to adopt existing resources into state.
# =============================================================================

locals {
  # Bootstrap roles (consider removing after initial setup)
  im_executor_bootstrap_roles = [
    "roles/iam.serviceAccountAdmin",
    "roles/secretmanager.admin",
    "roles/serviceusage.serviceUsageAdmin",
  ]

  # Steady-state roles (required for ongoing operations)
  im_executor_steady_roles = [
    "roles/config.agent",
    "roles/cloudbuild.builds.editor",
  ]

  im_executor_roles = concat(local.im_executor_bootstrap_roles, local.im_executor_steady_roles)

  cb_ci_lint_roles = [
    "roles/logging.logWriter",
  ]

  cb_im_preview_roles = [
    "roles/config.admin",
    "roles/logging.logWriter",
  ]

  cb_im_apply_roles = [
    "roles/config.admin",
    "roles/logging.logWriter",
    "roles/cloudbuild.builds.editor",
  ]

  cb_fleet_reconcile_roles = [
    "roles/logging.logWriter",
  ]

  vps_logging_agent_roles = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
  ]

  im_executor_logging_roles = [
    "roles/bigquery.admin",
    "roles/logging.configWriter",
  ]
}

# -----------------------------------------------------------------------------
# Imports - Existing Service Accounts
# -----------------------------------------------------------------------------
# NOTE: Update the project ID in each import block to match your project.
# Example format: projects/YOUR_PROJECT_ID/serviceAccounts/SA_NAME@YOUR_PROJECT_ID.iam.gserviceaccount.com

import {
  to = google_service_account.im_executor
  id = "projects/${var.project_id}/serviceAccounts/im-executor@${var.project_id}.iam.gserviceaccount.com"
  # e.g., "projects/my-vpn-project-123456/serviceAccounts/im-executor@my-vpn-project-123456.iam.gserviceaccount.com"
}

import {
  to = google_service_account.cb_ci_lint
  id = "projects/${var.project_id}/serviceAccounts/cb-ci-lint@${var.project_id}.iam.gserviceaccount.com"
}

import {
  to = google_service_account.cb_im_preview
  id = "projects/${var.project_id}/serviceAccounts/cb-im-preview@${var.project_id}.iam.gserviceaccount.com"
}

import {
  to = google_service_account.cb_im_apply
  id = "projects/${var.project_id}/serviceAccounts/cb-im-apply@${var.project_id}.iam.gserviceaccount.com"
}

import {
  to = google_service_account.cb_fleet_reconcile
  id = "projects/${var.project_id}/serviceAccounts/cb-fleet-reconcile@${var.project_id}.iam.gserviceaccount.com"
}

# -----------------------------------------------------------------------------
# Service Account: im-executor
# -----------------------------------------------------------------------------
resource "google_service_account" "im_executor" {
  project      = var.project_id
  account_id   = "im-executor"
  display_name = "im-executor"
  description  = "Execution identity for Infrastructure Manager (Terraform runner)"
}

resource "google_project_iam_member" "im_executor_roles" {
  for_each = toset(local.im_executor_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.im_executor.email}"
}

resource "google_project_iam_member" "im_executor_logging_roles" {
  for_each = toset(local.im_executor_logging_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.im_executor.email}"
}

# -----------------------------------------------------------------------------
# Service Account: cb-ci-lint
# -----------------------------------------------------------------------------
resource "google_service_account" "cb_ci_lint" {
  project      = var.project_id
  account_id   = "cb-ci-lint"
  display_name = "cb-ci-lint"
  description  = "Service account used by ci-lint trigger"
}

resource "google_project_iam_member" "cb_ci_lint_roles" {
  for_each = toset(local.cb_ci_lint_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.cb_ci_lint.email}"
}

# -----------------------------------------------------------------------------
# Service Account: cb-im-preview
# -----------------------------------------------------------------------------
resource "google_service_account" "cb_im_preview" {
  project      = var.project_id
  account_id   = "cb-im-preview"
  display_name = "cb-im-preview"
  description  = "Service account used by im-preview trigger"
}

resource "google_project_iam_member" "cb_im_preview_roles" {
  for_each = toset(local.cb_im_preview_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.cb_im_preview.email}"
}

# -----------------------------------------------------------------------------
# Service Account: cb-im-apply
# -----------------------------------------------------------------------------
resource "google_service_account" "cb_im_apply" {
  project      = var.project_id
  account_id   = "cb-im-apply"
  display_name = "cb-im-apply"
  description  = "Service account used by im-apply trigger"
}

resource "google_project_iam_member" "cb_im_apply_roles" {
  for_each = toset(local.cb_im_apply_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.cb_im_apply.email}"
}

# -----------------------------------------------------------------------------
# Service Account: cb-fleet-reconcile
# -----------------------------------------------------------------------------
resource "google_service_account" "cb_fleet_reconcile" {
  project      = var.project_id
  account_id   = "cb-fleet-reconcile"
  display_name = "cb-fleet-reconcile"
  description  = "Service account used by fleet-reconcile trigger"
}

resource "google_project_iam_member" "cb_fleet_reconcile_roles" {
  for_each = toset(local.cb_fleet_reconcile_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.cb_fleet_reconcile.email}"
}

# -----------------------------------------------------------------------------
# Service Account: vps-logging-agent
# -----------------------------------------------------------------------------
resource "google_service_account" "vps_logging_agent" {
  project      = var.project_id
  account_id   = "vps-logging-agent"
  display_name = "VPS Logging Agent"
  description  = "Identity for Google Cloud Ops Agent on VPS nodes to send logs/metrics"
}

resource "google_project_iam_member" "vps_logging_agent_roles" {
  for_each = toset(local.vps_logging_agent_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.vps_logging_agent.email}"
}

# -----------------------------------------------------------------------------
# Cross-Account IAM - Impersonation Bindings
# -----------------------------------------------------------------------------
# cb-im-preview can impersonate im-executor
resource "google_service_account_iam_member" "cb_im_preview_can_use_im_executor" {
  service_account_id = google_service_account.im_executor.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.cb_im_preview.email}"
}

# cb-im-apply can impersonate im-executor
resource "google_service_account_iam_member" "cb_im_apply_can_use_im_executor" {
  service_account_id = google_service_account.im_executor.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.cb_im_apply.email}"
}

# cb-im-apply can impersonate cb-fleet-reconcile
resource "google_service_account_iam_member" "cb_im_apply_can_use_cb_fleet_reconcile" {
  service_account_id = google_service_account.cb_fleet_reconcile.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.cb_im_apply.email}"
}

# im-executor can impersonate all trigger SAs (for Terraform actAs)
resource "google_service_account_iam_member" "im_executor_can_use_cb_ci_lint" {
  service_account_id = google_service_account.cb_ci_lint.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.im_executor.email}"
}

resource "google_service_account_iam_member" "im_executor_can_use_cb_im_preview" {
  service_account_id = google_service_account.cb_im_preview.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.im_executor.email}"
}

resource "google_service_account_iam_member" "im_executor_can_use_cb_im_apply" {
  service_account_id = google_service_account.cb_im_apply.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.im_executor.email}"
}

resource "google_service_account_iam_member" "im_executor_can_use_cb_fleet_reconcile" {
  service_account_id = google_service_account.cb_fleet_reconcile.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.im_executor.email}"
}
