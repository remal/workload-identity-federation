# GCP Coding Agent Instructions

Files in this `gcp/` folder are related to Google Cloud Platform only. No code related to other clouds (AWS, Azure, etc.) should be placed here.

## Design Decisions

1. **Single repository per state**: Each Terraform apply configures Workload Identity Federation for exactly one CI/CD repository. This keeps state isolated and simple.

2. **Shared pool, separate providers**: Use one Workload Identity Pool per CI/CD system (e.g., `github-pool`, `gitlab-pool`) that can be shared across repositories. Each repository gets its own Workload Identity Pool Provider within that pool.

3. **Service account naming**: Optional variable with auto-generated default derived from repository name. Handle the 30-character SA name limit gracefully.

4. **IAM role bindings managed**: Accept a list of GCP roles as input variable and bind them to the created service account. This is convenient but requires the applying user to have IAM admin permissions.

5. **Outputs**: Raw values only - service account email and workload identity provider resource name. No workflow snippets.
