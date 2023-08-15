variable "contributor_user" {
  type        = string
  description = "User Name which is used for CLI Authentication"
}

variable "resource_arns" {
  type        = list(string)
  description = "AWS Resouce ARNs to add to Access Policy"
}

variable "group_prefix" {
  type        = string
  description = "Group Name Prefix"
  default     = "datasim-superhero-group"
}

variable "policy_prefix" {
  type        = string
  description = "Policy Prefix"
  default     = "DatasimSuperheroGroupIAM"
}