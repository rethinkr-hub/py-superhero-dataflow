terraform {
  required_providers {
    azuread = {
      source = "hashicorp/azuread"
      version = "~>2.47"
    }
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~>3.86"
    }
  }
}

terraform {
  backend "azurerm" {}
}

provider "azuread" {
  alias = "tokengen"
}

provider "azurerm" {
  alias = "tokengen"
  features {}
}

data "azurerm_subscription" "primary" {
  provider = azurerm.tokengen
}

module "service_account_auth" {
  source = "./modules/service_account_auth"

  roles_list = [
    "Microsoft.Resources/subscriptions/providers/read",
    "Microsoft.Authorization/roleAssignments/*",
    "Microsoft.Resources/subscriptions/resourceGroups/*",
    "Microsoft.Storage/storageAccounts/*",
    "microsoft.web/sites/*",
    "Microsoft.Insights/*",
    "Microsoft.Web/serverfarms/*"
  ]

  providers = {
    azuread.tokengen = azuread.tokengen
    azurerm.tokengen = azurerm.tokengen
  }
}

provider "azurerm" {
  alias = "auth_session"

  client_id       = module.service_account_auth.client_id
  client_secret   = module.service_account_auth.client_secret
  subscription_id = data.azurerm_subscription.primary.subscription_id
  tenant_id       = data.azurerm_subscription.primary.tenant_id
  
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

resource "azurerm_resource_group" "datasim-superhero" {
  provider = azurerm.auth_session
  
  name     = "datasim-superhero-resource-group"
  location = var.azure_region
}

module "raw_bucket" {
  source                   = "./modules/superhero_buckets"
  bucket_name              = "datasimsuperheroraw"
  container_name           = "raw"
  resource_group_name      = azurerm_resource_group.datasim-superhero.name
  resource_group_location  = azurerm_resource_group.datasim-superhero.location
  security_group_id        = module.service_account_auth.security_group_id

  providers = {
    azurerm.auth_session = azurerm.auth_session
  }
}

module "standard_bucket" {
  source                   = "./modules/superhero_buckets"
  bucket_name              = "datasimsuperherostandard"
  container_name           = "standard"
  resource_group_name      = azurerm_resource_group.datasim-superhero.name
  resource_group_location  = azurerm_resource_group.datasim-superhero.location
  security_group_id        = module.service_account_auth.security_group_id

  providers = {
    azurerm.auth_session = azurerm.auth_session
  }
}

module "function_bucket" {
  source                   = "./modules/superhero_buckets"
  bucket_name              = "datasimsuperherofunction"
  container_name           = "function"
  resource_group_name      = azurerm_resource_group.datasim-superhero.name
  resource_group_location  = azurerm_resource_group.datasim-superhero.location
  security_group_id        = module.service_account_auth.security_group_id

  providers = {
    azurerm.auth_session = azurerm.auth_session
  }
}

module "function_zip" {
  source                     = "./modules/superhero_functions_zip"
  function_bucket_name       = module.function_bucket.bucket_name
  function_bucket_connection = module.function_bucket.bucket_connection
  function_container_name    = "function"

  providers = {
    azurerm.auth_session = azurerm.auth_session
  }
}

module "superhero_function" {
  source                  = "./modules/superhero_functions"
  resource_group_name     = azurerm_resource_group.datasim-superhero.name
  resource_group_location = azurerm_resource_group.datasim-superhero.location
  raw_bucket_name         = module.raw_bucket.bucket_name
  raw_bucket_key          = module.raw_bucket.bucket_key
  standard_bucket_name    = module.standard_bucket.bucket_name
  standard_bucket_key     = module.standard_bucket.bucket_key
  function_zip_blob_url   = module.function_zip.function_zip_blob_url

  providers = {
    azurerm.auth_session = azurerm.auth_session
  }
}