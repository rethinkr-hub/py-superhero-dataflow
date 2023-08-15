variable "subscription_id" {
  type = string
  description = "Existing Azure Subscription ID"
}

variable "tenant_id" {
  type = string
  description = "Azure Tenant ID"
}

variable "contributor_upn" {
  type        = string
  description = "User Principal Name which is used for CLI Authentication"
}