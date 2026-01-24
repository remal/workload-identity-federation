output "service_account_email" {
  description = "Email address of the created service account"
  value       = google_service_account.github.email
}

output "workload_identity_provider" {
  description = "Full resource name of the Workload Identity Provider"
  value       = google_iam_workload_identity_pool_provider.github.name
}
