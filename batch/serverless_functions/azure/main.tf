terraform {
  backend "azurerm" {}
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

resource "azurerm_resource_group" "datasim-superhero" {
  name     = "datasim-superhero-resource-group"
  location = "East US"
}

module "superhero_security_group" {
  source                   = "./modules/superhero_security_group"
  contributor_upn   = var.contributor_upn
}

module "raw_bucket" {
  source                   = "./modules/superhero_buckets"
  bucket_name              = "datasimsuperheroraw"
  container_name           = "raw"
  resource_group_name      = azurerm_resource_group.datasim-superhero.name
  resource_group_location  = azurerm_resource_group.datasim-superhero.location
  security_group_id        = module.superhero_security_group.security_group_id
}

module "standard_bucket" {
  source                   = "./modules/superhero_buckets"
  bucket_name              = "datasimsuperherostandard"
  container_name           = "standard"
  resource_group_name      = azurerm_resource_group.datasim-superhero.name
  resource_group_location  = azurerm_resource_group.datasim-superhero.location
  security_group_id        = module.superhero_security_group.security_group_id
}

module "function_bucket" {
  source                   = "./modules/superhero_buckets"
  bucket_name              = "datasimsuperherofunction"
  container_name           = "function"
  resource_group_name      = azurerm_resource_group.datasim-superhero.name
  resource_group_location  = azurerm_resource_group.datasim-superhero.location
  security_group_id        = module.superhero_security_group.security_group_id
}

module "function_zip" {
  source                         = "./modules/superhero_functions_zip"
  function_bucket_name           = module.function_bucket.bucket_name
  function_bucket_connection     = module.function_bucket.bucket_connection
  function_container_name        = "function"
}

module "superhero_function" {
  source                                 = "./modules/superhero_functions"
  resource_group_name                    = azurerm_resource_group.datasim-superhero.name
  resource_group_location                = azurerm_resource_group.datasim-superhero.location
  raw_bucket_name                        = module.raw_bucket.bucket_name
  raw_bucket_key                         = module.raw_bucket.bucket_key
  standard_bucket_name                   = module.standard_bucket.bucket_name
  standard_bucket_key                    = module.standard_bucket.bucket_key
  function_zip_blob_url                  = module.function_zip.function_zip_blob_url
}