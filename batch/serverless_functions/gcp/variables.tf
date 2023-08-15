variable "project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "impersonate_service_account_email" {
  type        = string
  description = "GCP Service Account Email equiped with sufficient Project IAM roles to create new Service Accounts"
}

variable "impersonate_user_email" {
  type        = string
  description = "GCP Impersonation User with Service Account IAM bindings for Access Token Generation"
}