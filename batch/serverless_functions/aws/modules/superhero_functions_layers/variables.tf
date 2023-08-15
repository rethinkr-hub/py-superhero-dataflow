variable "bucket_id" {
  type        = string
  description = "AWS Storage Bucket ID for Lambda Source Code"
}

variable "package_name" {
  type       = string
  description = "Python Dependency Package Required for Lambda Function"
}

variable "package_version" {
  type       = string
  description = "Python Dependency Package Version"
}