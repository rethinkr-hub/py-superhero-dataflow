/* Service Account Auth Module

Create an Azuure Service Principal to manage resouces when MSI isn't an option
List of Resource Provider Operations found here
https://learn.microsoft.com/en-ca/azure/role-based-access-control/resource-provider-operations
*/
terraform{
  required_providers {
    random  = "~> 2.2"
    azuread = {
      source = "hashicorp/azuread"
      version = "~>2.47"
      configuration_aliases = [
        azuread.tokengen,
      ]
    }
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~>3.86"
      configuration_aliases = [
        azurerm.tokengen,
      ]
    }
  }
}

data "azurerm_subscription" "primary" {
  provider = azurerm.tokengen
}

data "azuread_client_config" "current" {
  provider = azuread.tokengen
}

resource "random_uuid" "this" {}

resource "azurerm_role_definition" "this" {
  provider           = azurerm.tokengen

  role_definition_id = random_uuid.this.result
  name               = var.role_name
  scope              = data.azurerm_subscription.primary.id

  permissions {
    actions     = var.roles_list
    not_actions = []
  }

  assignable_scopes = [
    data.azurerm_subscription.primary.id,
  ]
}

resource "azuread_application" "this" {
  provider     = azuread.tokengen
  depends_on   = [ azurerm_role_definition.this ]

  display_name = var.application_display_name
  owners       = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal" "this" {
  provider                     = azuread.tokengen
  depends_on                   = [ azuread_application.this ]

  client_id                    = azuread_application.this.client_id
  app_role_assignment_required = false
  owners                       = [data.azuread_client_config.current.object_id]
}

/* Create Security Group */
resource "azuread_group" "this" {
  provider         = azuread.tokengen
  depends_on       = [ azuread_service_principal.this ]

  display_name     = var.security_group_name
  owners           = [data.azuread_client_config.current.object_id]
  security_enabled = true

  members = [
    data.azuread_client_config.current.object_id,
    azuread_service_principal.this.object_id
  ]
}

resource "azurerm_role_assignment" "this" {
  provider           = azurerm.tokengen
  depends_on         = [ azurerm_role_assignment.this ]

  name               = random_uuid.this.result
  scope              = data.azurerm_subscription.primary.id
  role_definition_id = azurerm_role_definition.this.role_definition_resource_id
  principal_id       = azuread_group.this.id
}

resource "azuread_service_principal_password" "this" {
  provider             = azuread.tokengen
  depends_on           = [ azurerm_role_assignment.this ]

  service_principal_id = azuread_service_principal.this.object_id
  end_date_relative    = var.client_secret_expiration
}