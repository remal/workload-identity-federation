# GCP + GitHub Coding Agent Instructions

Files in this `gcp/github/` folder are related to Google Cloud Platform + GitHub Actions only. No code related to other clouds or CI/CD systems should be placed here.

## Design Decisions

1. **Repository-only attribute condition**: OIDC token validation checks only the repository claim (`attribute.repository == "owner/repo"`). No branch or environment filtering - keep it simple.
