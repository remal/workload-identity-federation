variable "project_id" {
  description = "The GCP project ID where resources will be created"
  type        = string
}

variable "repository" {
  description = "GitHub repository in owner/repo format"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+$", var.repository))
    error_message = "Repository must be in owner/repo format."
  }
}

variable "roles" {
  description = "List of IAM roles to grant to the service account"
  type        = list(string)
  default     = []
}

variable "service_account_id" {
  description = "Custom service account ID. If not provided, auto-generated from repository name"
  type        = string
  default     = null

  validation {
    condition     = var.service_account_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.service_account_id))
    error_message = "Service account ID must be 6-30 characters, start with a letter, and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "workload_identity_pool_id" {
  description = "Workload Identity Pool ID"
  type        = string
  default     = "github-pool"
}

variable "create_pool" {
  description = "Whether to create the Workload Identity Pool. Set to false to use an existing pool"
  type        = bool
  default     = true
}

variable "provider_id" {
  description = "Custom Workload Identity Pool Provider ID. If not provided, auto-generated from repository name"
  type        = string
  default     = null

  validation {
    condition     = var.provider_id == null || can(regex("^[a-z][a-z0-9-]{2,30}[a-z0-9]$", var.provider_id))
    error_message = "Provider ID must be 4-32 characters, start with a letter, and contain only lowercase letters, numbers, and hyphens."
  }
}

