# GCP Coding Agent Instructions

Files in this `gcp/` folder are related to Google Cloud Platform only. No code related to other clouds (AWS, Azure, etc.) should be placed here.

## Coding Standards

### Terraform Provider

- **Google provider**: Pin to a specific stable version in `main.tf`

### Naming Conventions

- GCP resource IDs: `kebab-case`

### Prerequisites

- `gcloud` CLI configured with appropriate credentials
- Sufficient IAM permissions in target GCP project:
  - `iam.workloadIdentityPools.create`
  - `iam.workloadIdentityPoolProviders.create`
  - `iam.serviceAccounts.create`
  - `resourcemanager.projects.setIamPolicy` (if binding roles)

## Design Decisions

1. **Single repository per state**: Each Terraform apply configures Workload Identity Federation for exactly one CI/CD repository. This keeps state isolated and simple.

2. **Shared pool, separate providers**: Use one Workload Identity Pool per CI/CD system (e.g., `github-pool`, `gitlab-pool`) that can be shared across repositories. Each repository gets its own Workload Identity Pool Provider within that pool.

3. **Service account naming**: Optional variable with auto-generated default derived from repository name. Handle the 30-character SA name limit gracefully.

4. **IAM role bindings managed**: Accept a list of GCP roles as input variable and bind them to the created service account. This is convenient but requires the applying user to have IAM admin permissions.

5. **Outputs**: Raw values only - service account email and workload identity provider resource name. No workflow snippets.

## Common Patterns

### Resource Naming with Length Limits

GCP service account IDs have a 30-character limit, provider IDs have a 32-character limit. Use preconditions to fail with a clear error when auto-generated IDs exceed limits:

```hcl
locals {
  # Auto-generated IDs from repository name (no truncation)
  owner_sanitized = replace(lower(local.repo_owner), "/[^a-z0-9-]/", "-")
  repo_sanitized  = replace(lower(local.repo_name), "/[^a-z0-9-]/", "-")
  auto_service_account_id = "gh-${local.owner_sanitized}-${local.repo_sanitized}"
  service_account_id = coalesce(var.service_account_id, local.auto_service_account_id)
}

resource "google_service_account" "example" {
  account_id = local.service_account_id

  lifecycle {
    precondition {
      condition     = var.service_account_id != null || length(local.auto_service_account_id) <= 30
      error_message = "Auto-generated service_account_id is too long. Please provide a custom service_account_id variable."
    }
  }
}
```

### Conditional Resource Creation

If a resource might optionally be created:

```hcl
resource "google_project_iam_member" "sa_roles" {
  for_each = toset(var.roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.github.email}"
}
```
