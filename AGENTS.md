# Coding Agent Instructions

## Project Overview

This repository contains Terraform configurations for setting up Workload Identity Federation between cloud providers and CI/CD systems. The primary goal is to eliminate long-lived service account keys by allowing CI/CD pipelines to authenticate using OIDC tokens.

## Architecture

### Folder Structure

```
/
├── .terraform-version            # Terraform version for tenv (repository root)
└── <cloud>/<cicd>/
    ├── README.md                 # Module documentation
    ├── main.tf                   # Provider configuration, version constraints, and main resources
    ├── variables.tf              # Input variables
    ├── outputs.tf                # Output values
    └── terraform.tfvars.example  # Example variable values
```

- `<cloud>`: lowercase cloud provider name (`gcp`, `aws`, `azure`)
- `<cicd>`: lowercase CI/CD system name (`github`, `gitlab`)

Each `<cloud>/<cicd>` combination is a standalone Terraform root module with its own state.

### Current Implementations

- `gcp/github` - Google Cloud Platform + GitHub Actions

## Coding Standards

### Terraform

- **Version constraint**: Defined in `main.tf` (terraform and provider blocks) and `.terraform-version`
- **No separate versions.tf**: Keep `terraform` and `provider` blocks in `main.tf`, do not create a separate `versions.tf` file
- For Terraform file changes, run from the repository root:
  1. `./validate <cloud> <cicd>` to validate
  2. If validation succeeds, run `terraform fmt -recursive <cloud>/<cicd>` to format files
- Variables must have descriptions
- Use `validation` blocks for input validation where appropriate
- Prefer explicit resource references over `depends_on` when possible
- Use `locals` for computed values and to reduce repetition

### Naming Conventions

- Resource names in Terraform: `snake_case`
- Variables: `snake_case`
- Keep resource names short but descriptive
- Avoid the abbreviation "WIF" — always use the full term "Workload Identity Federation"

### Variable Design

Required variables should be minimal. Use sensible defaults where possible. See cloud-specific AGENTS.md files for variable details.

## Local Development

### Prerequisites

- [tenv](https://github.com/tofuutils/tenv) for Terraform version management
- Cloud CLI configured with appropriate credentials (see cloud-specific AGENTS.md for details)

### Terraform Version Management

This project uses [tenv](https://github.com/tofuutils/tenv) to manage Terraform versions. A single `.terraform-version` file in the repository root specifies the required version for all modules.

tenv automatically detects the `.terraform-version` file and uses the specified version. If the version isn't installed, tenv will install it automatically.

```bash
# Install tenv (macOS)
brew install tenv

# tenv automatically uses .terraform-version when you run terraform commands
terraform version  # Uses version from .terraform-version
```

The `.terraform-version` file contains the version number.

### Workflow

1. Navigate to the appropriate directory (e.g., `cd gcp/github`)
2. Copy `terraform.tfvars.example` to `terraform.tfvars`
3. Fill in required variables
4. Run `terraform init`
5. Run `terraform plan` to preview changes
6. Run `terraform apply` to create resources

### State Management

Terraform state is stored locally in `terraform.tfstate`. This file is git-ignored. Each user maintains their own local state for their own cloud projects.

## Testing

When adding new cloud/CI-CD combinations:

1. Test with a real cloud account and CI/CD repository
2. Verify the full flow: apply Terraform, then run a CI/CD pipeline that authenticates using Workload Identity Federation
3. Test `terraform destroy` cleans up all created resources

## Adding New Combinations

When adding support for a new cloud or CI/CD system:

1. Create the directory structure: `<cloud>/<cicd>/`
2. Implement all required files (`main.tf`, `variables.tf`, `outputs.tf`)
3. Add `terraform.tfvars.example` with documented examples
4. Update the README.md to document the new combination
5. Follow existing patterns from `gcp/github` for consistency

## Documentation Maintenance

When making code changes, review and update relevant documentation files to keep them in sync. These files may exist at the repository root or within specific folders:

- **README.md** - Update if changes affect usage instructions, examples, or feature descriptions
- **AGENTS.md** - Update if changes affect coding patterns, architecture, or development workflows

Check for these files both at the root level and in any affected subdirectories. Always ensure documentation accurately reflects the current state of the code.

## Security Considerations

- Never commit `terraform.tfvars` files containing real values
- Never commit `terraform.tfstate` files
- Use the principle of least privilege when specifying IAM roles
- The attribute condition should be as restrictive as practical for your use case
