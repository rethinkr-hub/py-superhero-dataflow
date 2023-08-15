variable "project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "bucket_name" {
  type        = string
  description = "GCS Storage Bucket Name"
}

variable "storage_class" {
  type        = string
  description = "GCS Blob Storage Type"
  default     = "standard"
}

variable "storage_location" {
  type        = string
  description = "GCS Blob Storage Region"
  default     = "us-east1"
}