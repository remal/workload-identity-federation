# Workload Identity Federation

Terraform configurations for setting up Workload Identity Federation (WIF) between cloud providers and CI/CD systems.

## Why?

When you create a new project, you typically need to:
1. Create a cloud account/project (GCP, AWS, etc.)
2. Create a CI/CD pipeline (GitHub Actions, GitLab CI, etc.)
3. Give your CI/CD pipeline access to deploy to your cloud

The traditional approach uses long-lived service account keys stored as CI/CD secrets. This is insecure:
- Keys can be leaked
- Keys don't expire (or have long expiration)
- No audit trail of which pipeline run used the key

**Workload Identity Federation** solves this by allowing your CI/CD system to authenticate using short-lived OIDC tokens. No keys to manage, rotate, or leak.

## Supported Combinations

| Cloud | CI/CD | Documentation |
|-------|-------|---------------|
| GCP | GitHub Actions | [gcp/github](gcp/github/README.md) |

## State Management

Terraform state is stored locally. The `terraform.tfstate` file is git-ignored. Each user maintains their own state for their own cloud projects.

If you need to share state or work in a team, consider using a remote backend (GCS, S3, etc.) - but that's outside the scope of this quick-start tool.

## Contributing

See [AGENTS.md](AGENTS.md) for coding guidelines and architecture decisions.

## License

MIT
