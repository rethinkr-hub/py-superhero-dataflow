/* Superhero Simulator Blob Storage

Creates ADLS GenV2 Blob Storage Accounts
*/

terraform{
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
}

/* Create Storage Account */
resource "azurerm_storage_account" "this" {
  name                     = var.bucket_name
  resource_group_name      = var.resource_group_name
  location                 = var.resource_group_location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

/* Assign Security Group

Provie the Data Contributor Role to the
Security Group with access to this Storage Account
*/
resource "azurerm_role_assignment" "this" {
  scope                = azurerm_storage_account.this.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.security_group_id
}

/* Create Container in the Storage Account */
resource "azurerm_storage_container" "this" {
  name                  = var.container_name
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = "private"
}