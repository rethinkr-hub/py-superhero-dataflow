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

variable "new_service_account_name" {
  type        = string
  description = "New GCP Service Account to be created"
}

variable "new_service_account_description" {
  type        = string
  description = "Descripiton of new GCP Service Account to be created"
}

variable "bootstrap_project_iam_roles" {
  type        = list
  description = "List of GCP IAM Roles to bind to the new Service Account"
}