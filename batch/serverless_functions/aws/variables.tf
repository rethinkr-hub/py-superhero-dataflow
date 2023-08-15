variable "aws_region" {
  type        = string
  description = "AWS Provider Region"
  default     = "us-east-1"
}

variable "new_service_account_name" {
  type        = string
  description = "New AWS Service Account to be created"
}

variable "contributor_user" {
  type        = string
  description = "User Name which is used for CLI Authentication"
}
