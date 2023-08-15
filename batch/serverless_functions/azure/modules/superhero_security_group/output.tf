output "security_group_id" {
    description = "Azure AD Superhero Security Group ID"
    value       = azuread_group.this.object_id
}