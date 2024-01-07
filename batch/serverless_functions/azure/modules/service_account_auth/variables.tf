variable "role_name" {
  type        = string
  description = "Service Account Role Name"
  default     = "superhero-datasim-role"
}

variable "roles_list" {
  type        = list(string)
  description = "List of Permitted Service Account Roles"
}

variable "security_group_name" {
  type        = string
  description = "Security Group Name"
  default     = "superhero-group"
}

variable "application_display_name" {
  type        = string
  description = "Service Account AD Application Name"
  default     = "superhero-service-account"
}

variable "client_secret_expiration" {
  type        = string
  description = "Service Account Secret Relative Expiration from Creation"
  default     = "24h"
}