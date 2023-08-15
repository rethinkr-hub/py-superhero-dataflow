variable "function_name" {
  type        = string
  description = "Azure Function App Name"
  default     = "datasim-function-app"
}

variable "resource_group_name" {
  type        = string
  description = "Azure Resouce Group Name"
}

variable "resource_group_location" {
  type        = string
  description = "Azure Resouce Group Location"
}

variable "raw_bucket_name" {
  type        = string
  description = "Azure Storage Raw Bucket Name"
}

variable "raw_bucket_key" {
  type        = string
  description = "Azure Storage Raw Bucket Access Key"
}

variable "standard_bucket_name" {
  type        = string
  description = "Azure Storage Standard Bucket Name"
}

variable "standard_bucket_key" {
  type        = string
  description = "Azure Storage Standard Bucket Access Key"
}

variable function_zip_blob_url {
  type        = string
  description = "Azure Function Zip Source File in Blob Storage with SAS token"
}

variable python_version {
  type        = string
  description = "Azure Function Runtime Python Version"
  default     = "3.9"
}

variable "service_plan_name" {
  type        = string
  description = "Azure Service Plan Name"
  default     = "datasim-function-service-plan"
}

variable "service_plan_os_type" {
  type        = string
  description = "Azure Service Plan OS Type"
  default     = "Linux"
}

variable "service_plan_sku_type" {
  type        = string
  description = "Azure Service Plan SKU Type"
  default     = "B1"
}