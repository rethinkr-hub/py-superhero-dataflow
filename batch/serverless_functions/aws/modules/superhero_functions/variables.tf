variable "function_name" {
  type        = string
  description = "AWS Lambda Function Sourcec File Name"
  default     = "superhero-function-standard-etl"
}

variable "bucket_arns" {
  type        = list(string)
  description = "AWS Storage Bucket ARNs for Data"
}

variable "layer_arns" {
  type        = list(string)
  description = "AWS Lambda Function Layer ARNs for Function Dependencies"
}

variable "function_source" {
  type        = string
  description = "AWS Lambda Function Source Code File Name"
  default     = "lambda_function"
}

variable "function_handler" {
  type        = string
  description = "AWS Lambda Function Source Handler Function Name"
  default     = "lambda_handler"
}

variable "function_bucket_id" {
  type        = string
  description = "AWS Storage Bucket ID for Lambda Source Code"
}

variable "raw_bucket_arn" {
  type        = string
  description = "AWS Storage Bucket ARN for Raw Meta Data"
}

variable "raw_bucket_id" {
  type        = string
  description = "AWS Storage Bucket ID for Raw Meta Data"
}

variable "standard_bucket_id" {
  type        = string
  description = "AWS Storage Bucket ID for ELT Parquet Data"
}

variable "policy_prefix" {
  type        = string
  description = "Policy Prefix"
  default     = "DatasimSuperheroLambdaIAM"
}
