output "raw_bucket_name" {
  description = "Azure ADLS Gen2 Storage Account Name for Raw Meta Data"
  value       = module.raw_bucket.bucket_name
}

output "standard_bucket_name" {
  description = "Azure ADLS Gen2 Storage Account Name for Standard Meta Data"
  value       = module.standard_bucket.bucket_name
}

output "client_id" {
  sensitive   = true
  description = "Azure Service Principal Client ID"
  value       = module.service_account_auth.client_id
}

output "client_secret_key" {
  sensitive   = true
  description = "Azure Service Principal Secret ID"
  value       = module.service_account_auth.client_secret_key
}

output "client_secret" {
  sensitive   = true
  description = "Azure Service Principal Secret"
  value       = module.service_account_auth.client_secret
}

output "tenant_id" {
  sensitive   = true
  description = "Azure Tenant ID"
  value       = data.azurerm_subscription.primary.tenant_id
}