# =============================================================================
# Logging - Cloud Logging Sink to BigQuery
# =============================================================================
# Routes VPS logs to BigQuery for analysis and debugging (e.g., GFW blocking).
# Cost controls:
# - Configurable table expiration (auto-cleanup)
# - Log exclusion filter (drop DEBUG/INFO, only WARNING+ ingested)
# - Filtered sink (only VPS-related logs)
#
# Estimated cost: < €0.10/month for a small fleet
# =============================================================================

locals {
  # Convert days to milliseconds for BigQuery expiration
  log_retention_ms = var.log_retention_days * 24 * 60 * 60 * 1000
}

# -----------------------------------------------------------------------------
# BigQuery Dataset - VPS Logs Storage
# -----------------------------------------------------------------------------
resource "google_bigquery_dataset" "vps_logs" {
  project    = var.project_id
  dataset_id = "vps_logs"
  location   = var.region

  friendly_name = "VPS Logs"
  description   = "Logs from VPS fleet - auto-expires after ${var.log_retention_days} days"

  default_table_expiration_ms = local.log_retention_ms

  labels = {
    purpose = "vps-logging"
    env     = var.environment
  }
}

# -----------------------------------------------------------------------------
# Log Sink - Route VPS Logs to BigQuery
# -----------------------------------------------------------------------------
resource "google_logging_project_sink" "vps_to_bigquery" {
  project = var.project_id
  name    = "vps-logs-to-bigquery"

  destination = "bigquery.googleapis.com/projects/${var.project_id}/datasets/${google_bigquery_dataset.vps_logs.dataset_id}"

  # Filter: Only ingest VPS-related logs (reduces cost and noise)
  filter = <<-EOT
    resource.type = "generic_node" OR
    logName =~ "xray" OR
    logName =~ "vps-"
  EOT

  unique_writer_identity = true
}

resource "google_bigquery_dataset_iam_member" "sink_writer" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.vps_logs.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = google_logging_project_sink.vps_to_bigquery.writer_identity
}

# -----------------------------------------------------------------------------
# Log Exclusion - Drop Verbose Logs
# -----------------------------------------------------------------------------
resource "google_logging_project_exclusion" "exclude_debug_info" {
  project     = var.project_id
  name        = "exclude-vps-debug-info"
  description = "Exclude DEBUG and INFO level logs from VPS to reduce Cloud Logging costs"

  filter = <<-EOT
    resource.type = "generic_node" AND
    severity < WARNING
  EOT
}
