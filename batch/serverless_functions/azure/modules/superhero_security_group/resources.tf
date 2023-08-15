/* Security Group

Authorize specific users to the Storage Accounts
*/
terraform{
  required_providers {
    azuread = {
      source = "hashicorp/azuread"
    }
  }
}

data "azuread_client_config" "current" {}

data "azuread_user" "this" {
  user_principal_name = var.contributor_upn
}

/* Create Security Group */
resource "azuread_group" "this" {
  display_name     = var.security_group_name
  owners           = [data.azuread_client_config.current.object_id]
  security_enabled = true

  members = [
    data.azuread_user.this.object_id
  ]
}