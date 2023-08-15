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