# GCP + GitHub Coding Agent Instructions

Files in this `gcp/github/` folder are related to Google Cloud Platform + GitHub Actions only. No code related to other clouds or CI/CD systems should be placed here.

## Variable Design

Required variables:

- `project_id` - GCP project ID
- `repository` - GitHub repository in `owner/repo` format

Optional variables:

- `roles` - List of IAM roles to grant (default: `[]`)
- `service_account_id` - Custom service account ID (auto-generated if not provided)
- `workload_identity_pool_id` - Custom pool ID (default: `github-pool`)
- `create_pool` - Whether to create the pool (default: `true`)
- `provider_id` - Custom provider ID (auto-generated if not provided)

## Design Decisions

1. **Repository-only attribute condition**: OIDC token validation checks only the repository claim (`attribute.repository == "owner/repo"`). No branch or environment filtering - keep it simple.
