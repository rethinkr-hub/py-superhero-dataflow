variable "project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "function_name" {
  type        = string
  description = "GCP Function Pipeline Name"
}

variable "function_description" {
  type        = string
  description = "GCP Function Pipeline Description"
  default     = "JSON to Parquet transformation for raw/ objects"
}

variable "function_memory" {
  type        = number
  description = "GCP Function memory size"
}

variable "function_bucket_name" {
    type        = string
    description = "GCS Function Source Bucket Name"
}

variable "raw_bucket_name" {
    type        = string
    description = "GCS Raw Data Bucket Name"
}

variable "raw_bucket_location" {
    type        = string
    description = "GCS Raw Data Bucket Location"
    default     = "us-east1"
}

variable "function_service_account_email" {
    type        = string
    description = "GCP Service Account Email (pre-strapped with required Project IAM Role Bindings)"
}

variable "function_service_account_member" {
    type        = string
    description = "GCP Service Account Member Details (pre-strapped with required Project IAM Role Bindings)"
}