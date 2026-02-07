terraform {
  required_version = "~> 1.14"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "7.18.0"
    }
  }
}

provider "google" {
  project = var.project_id
}

# Required APIs
resource "google_project_service" "iam" {
  project            = var.project_id
  service            = "iam.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "iam_credentials" {
  project            = var.project_id
  service            = "iamcredentials.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "sts" {
  project            = var.project_id
  service            = "sts.googleapis.com"
  disable_on_destroy = false
}

locals {
  # Extract owner and repo from owner/repo format and sanitize
  repo_owner      = split("/", var.repository)[0]
  repo_name       = split("/", var.repository)[1]
  owner_sanitized = replace(lower(local.repo_owner), "/[^a-z0-9-]/", "-")
  repo_sanitized  = replace(lower(local.repo_name), "/[^a-z0-9-]/", "-")

  # Auto-generated IDs and display names (no truncation - validated via preconditions)
  auto_service_account_id    = "gh-${local.owner_sanitized}-${local.repo_sanitized}"
  auto_provider_id           = "${local.owner_sanitized}-${local.repo_sanitized}"
  auto_provider_display_name = "GH Actions: ${var.repository}"

  service_account_id    = coalesce(var.service_account_id, local.auto_service_account_id)
  provider_id           = coalesce(var.provider_id, local.auto_provider_id)
  provider_display_name = coalesce(var.provider_display_name, local.auto_provider_display_name)

  # Reference pool from resource or data source
  pool_id   = var.create_pool ? google_iam_workload_identity_pool.github[0].workload_identity_pool_id : data.google_iam_workload_identity_pool.existing[0].workload_identity_pool_id
  pool_name = var.create_pool ? google_iam_workload_identity_pool.github[0].name : data.google_iam_workload_identity_pool.existing[0].name
}

# Workload Identity Pool
resource "google_iam_workload_identity_pool" "github" {
  count = var.create_pool ? 1 : 0

  project                   = var.project_id
  workload_identity_pool_id = var.workload_identity_pool_id
  display_name              = "GH Actions Pool"
  description               = "Workload Identity Pool for GitHub Actions OIDC"

  depends_on = [
    google_project_service.iam,
    google_project_service.iam_credentials,
    google_project_service.sts,
  ]
}

# Data source for existing pool when create_pool = false
data "google_iam_workload_identity_pool" "existing" {
  count = var.create_pool ? 0 : 1

  project                   = var.project_id
  workload_identity_pool_id = var.workload_identity_pool_id
}

# Workload Identity Pool Provider
resource "google_iam_workload_identity_pool_provider" "github" {
  project                            = var.project_id
  workload_identity_pool_id          = local.pool_id
  workload_identity_pool_provider_id = local.provider_id
  display_name                       = local.provider_display_name
  description                        = "OIDC provider for ${var.repository}"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
  }

  attribute_condition = "attribute.repository == \"${var.repository}\""

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }

  lifecycle {
    precondition {
      condition     = var.provider_id != null || (length(local.auto_provider_id) >= 4 && length(local.auto_provider_id) <= 32)
      error_message = "Auto-generated provider_id '${local.auto_provider_id}' is ${length(local.auto_provider_id)} characters (must be 4-32). Please provide a custom provider_id variable."
    }
    precondition {
      condition     = var.provider_display_name != null || length(local.auto_provider_display_name) <= 32
      error_message = "Auto-generated provider_display_name '${local.auto_provider_display_name}' is ${length(local.auto_provider_display_name)} characters (must be <= 32). Please provide a custom provider_display_name variable."
    }
  }
}

# Service Account for GitHub Actions
resource "google_service_account" "github" {
  project      = var.project_id
  account_id   = local.service_account_id
  display_name = "GH Actions: ${var.repository}"
  description  = "Service account for GitHub Actions Workflow Identity Federation from ${var.repository}"

  depends_on = [
    google_project_service.iam,
    google_project_service.iam_credentials,
    google_project_service.sts,
  ]

  lifecycle {
    precondition {
      condition     = var.service_account_id != null || (length(local.auto_service_account_id) >= 6 && length(local.auto_service_account_id) <= 30)
      error_message = "Auto-generated service_account_id '${local.auto_service_account_id}' is ${length(local.auto_service_account_id)} characters (must be 6-30). Please provide a custom service_account_id variable."
    }
  }
}

# Allow the GitHub repository to impersonate the service account
resource "google_service_account_iam_member" "workload_identity" {
  service_account_id = google_service_account.github.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${local.pool_name}/attribute.repository/${var.repository}"
}

# Grant IAM roles to the service account
resource "google_project_iam_member" "sa_roles" {
  for_each = toset(var.roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.github.email}"
}
