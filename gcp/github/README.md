# GCP + GitHub Actions

Workload Identity Federation setup for Google Cloud Platform with GitHub Actions.

## Prerequisites

- [tenv](https://github.com/tofuutils/tenv) - Terraform version manager (auto-installs the correct version)
- [gcloud CLI](https://cloud.google.com/sdk/gcloud) configured
- A GCP project with billing enabled
- A GitHub repository

Install tenv:
```bash
# macOS
brew install tenv

# Other platforms: see https://github.com/tofuutils/tenv#installation
```

## Setup

1. Navigate to this directory:
   ```bash
   cd gcp/github
   ```

   tenv will automatically use the Terraform version specified in `.terraform-version` at the repository root.

2. Copy the example variables file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

3. Edit `terraform.tfvars` with your values:
   ```hcl
   project_id = "my-gcp-project"
   repository = "my-org/my-repo"
   roles      = ["roles/storage.admin", "roles/run.developer"]
   ```

4. Initialize and apply:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

5. Note the outputs:
   ```
   service_account_email      = "gh-my-org-my-repo@my-gcp-project.iam.gserviceaccount.com"
   workload_identity_provider = "projects/123456789/locations/global/workloadIdentityPools/github-pool/providers/my-org-my-repo"
   ```

6. Use in your GitHub Actions workflow:
   ```yaml
   jobs:
     deploy:
       permissions:
         contents: read
         id-token: write  # Required for OIDC
       steps:
         - uses: google-github-actions/auth@v2
           with:
             workload_identity_provider: ${{ vars.WORKLOAD_IDENTITY_PROVIDER }}
             service_account: ${{ vars.SERVICE_ACCOUNT_EMAIL }}
   ```

   Store the Terraform outputs as GitHub repository variables.

## Usage Examples

### Single Repository

Basic setup for one repository:

```hcl
project_id = "my-gcp-project"
repository = "acme/api"
roles      = ["roles/storage.admin", "roles/run.developer"]
```

### Multiple Repositories with Shared Pool

A single Workload Identity Pool can be shared across multiple repositories. Each repository gets its own provider and service account.

First repository creates the pool:

```hcl
# terraform.tfvars for acme/api
project_id = "my-gcp-project"
repository = "acme/api"
roles      = ["roles/storage.admin"]
# create_pool = true (default)
```

Additional repositories reference the existing pool:

```hcl
# terraform.tfvars for acme/frontend
project_id                = "my-gcp-project"
repository                = "acme/frontend"
workload_identity_pool_id = "github-pool"  # Same pool ID
create_pool               = false          # Don't create, use existing
roles                     = ["roles/run.developer"]
```

### Long Repository Names

Service account IDs are limited to 30 characters, provider IDs and display names to 32 characters. The module auto-generates these values from the repository name.

If your repository name is too long, Terraform will fail with an error prompting you to provide custom values:

```hcl
project_id            = "my-gcp-project"
repository            = "my-organization/my-very-long-repository-name"
service_account_id    = "gh-myorg-myrepo"  # Custom short ID
provider_id           = "myorg-myrepo"     # Custom short ID
provider_display_name = "My Repo"          # Custom short display name
roles                 = []
```

## How It Works

1. **Workload Identity Pool**: A container for external identities. Created once and shared across repositories.

2. **Workload Identity Pool Provider**: Configured to trust GitHub's OIDC provider. Each repository gets its own provider with an attribute condition that only allows tokens from that specific repository.

3. **Service Account**: A GCP service account with the IAM roles needed for your CI/CD pipeline.

4. **IAM Binding**: Allows the workload identity (GitHub Actions from your repo) to impersonate the service account.

When a GitHub Actions workflow runs:
1. GitHub generates a short-lived OIDC token containing claims about the workflow (repository, branch, etc.)
2. The workflow exchanges this token with GCP's Security Token Service
3. GCP validates the token against the Workload Identity Pool Provider's configuration
4. If valid, GCP returns credentials for the bound service account
5. The workflow uses these credentials to access GCP resources

## Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `project_id` | Yes | - | GCP project ID |
| `repository` | Yes | - | GitHub repository (`owner/repo`) |
| `roles` | No | `["roles/editor"]` | List of IAM roles to grant |
| `service_account_id` | No | `gh-{owner}-{repo}` | Custom service account ID (6-30 chars) |
| `provider_id` | No | `{owner}-{repo}` | Custom provider ID (4-32 chars) |
| `provider_display_name` | No | `GH Actions - {owner/repo}` | Custom provider display name (max 32 chars) |
| `workload_identity_pool_id` | No | `github-pool` | Workload Identity Pool ID |
| `create_pool` | No | `true` | Set to `false` to use an existing pool |

## Security Notes

- The attribute condition restricts which GitHub repository can authenticate. Any workflow in that repository can assume the identity.
- Follow the principle of least privilege when specifying IAM roles.
- Never commit `terraform.tfvars` or `terraform.tfstate` files.
