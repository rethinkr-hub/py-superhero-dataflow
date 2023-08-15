variable "new_service_account_name" {
  type        = string
  description = "New AWS Service Account to be created"
}

variable "new_service_account_path" {
  type        = string
  description = "New AWS Service Account Path"
  default     = "datasim-superhero"
}

variable "policy_prefix" {
  type        = string
  description = "Policy Prefix"
  default     = "DatasimSuperheroIAM"
}

variable "bootstrap_iam_roles" {
  type        = list
  description = "List of AWS IAM Roles to bind to the new Service Account"
}