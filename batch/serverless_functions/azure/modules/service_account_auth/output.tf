output "client_id" {
  description = "Azure Service Principal Client ID"
  value       = azuread_application.this.client_id
}

output "client_secret_key" {
  sensitive = true
  description = "Azure Service Principal Secret ID"
  value       = azuread_service_principal_password.this.key_id
}

output "client_secret" {
  sensitive = true
  description = "Azure Service Principal Secret"
  value       = azuread_service_principal_password.this.value
}

output "security_group_id" {
    description = "Azure AD Superhero Security Group ID"
    value       = azuread_group.this.object_id
}