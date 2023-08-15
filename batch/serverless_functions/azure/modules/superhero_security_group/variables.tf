variable "contributor_upn" {
  type        = string
  description = "User Principal Name which is used for CLI Authentication"
}

variable "security_group_name" {
  type        = string
  description = "Security Group Name"
  default     = "superhero-group"
}