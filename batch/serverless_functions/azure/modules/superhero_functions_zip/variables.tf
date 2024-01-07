variable "function_bucket_name" {
  type        = string
  description = "Azure Functions Storage Account Name for Function Zip"
}

variable "function_container_name" {
  type        = string
  description = "Azure Functions Storage Account Container for Function Zip"
}

variable "function_bucket_connection" {
  type        = string
  description = "Azure Functions Storage Account Connection String"
}

variable "function_sas_token_expiry" {
  type        = string
  description = "Function ZIP SAS Token Relative Expiry Time"
  default     = "24h"
}