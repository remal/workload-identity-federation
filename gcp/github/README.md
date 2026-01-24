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
   service_account_email = "gh-my-repo@my-gcp-project.iam.gserviceaccount.com"
   workload_identity_provider = "projects/123456789/locations/global/workloadIdentityPools/github-pool/providers/my-repo"
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
             workload_identity_provider: 'projects/123456789/locations/global/workloadIdentityPools/github-pool/providers/my-repo'
             service_account: 'gh-my-repo@my-gcp-project.iam.gserviceaccount.com'
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
| `roles` | Yes | - | List of IAM roles to grant |
| `service_account_id` | No | Auto-generated | Custom service account ID |
| `workload_identity_pool_id` | No | `github-pool` | Custom pool ID |

## Security Notes

- The attribute condition restricts which GitHub repository can authenticate. Any workflow in that repository can assume the identity.
- Follow the principle of least privilege when specifying IAM roles.
- Never commit `terraform.tfvars` or `terraform.tfstate` files.
