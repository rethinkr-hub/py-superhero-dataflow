variable "resource_group_name" {
  type        = string
  description = "Azure Resouce Group Name"
}

variable "resource_group_location" {
  type        = string
  description = "Azure Resouce Group Location"
}

variable "security_group_id" {
  type        = string
  description = "Security Group to Assign Contributor Role"
}

variable "bucket_name" {
  type        = string
  description = "Azure Storage Account Name"
}

variable "container_name" {
  type        = string
  description = "Azure Storage Account Container Name"
}