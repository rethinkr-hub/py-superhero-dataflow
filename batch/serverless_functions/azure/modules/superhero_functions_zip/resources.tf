/* Azure Function Package

Zip all Azure functions in Source Directory to deploy
as Zip Package

# Zip Deployment guide
https://learn.microsoft.com/en-us/azure/azure-functions/functions-reference-python?tabs=asgi%2Capplication-level&pivots=python-mode-configuration#folder-structure
*/
terraform{
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~>3.86"
      configuration_aliases = [
        azurerm.auth_session,
      ]
    }
  }
}

/* Install Dependency

Install the Python dependency with Pip
*/
resource "null_resource" "this" {
  provisioner "local-exec" {
    command = "pip install --upgrade --target ./source/.python_packages/lib/site-packages -r ./source/requirements.txt"
  }
}
 
/*Zip Source Code

Create a Zip Deploy package for Azure Function App
*/
data "archive_file" "this" {
  type             = "zip"
  source_dir       = "./source"
  output_file_mode = "0666"
  output_path      = "./source/function.zip"
  excludes         = [".venv", "function.zip"]
  depends_on       = [ null_resource.this ]
}

/* Upload the Zip package to Functions Bucket */
resource "azurerm_storage_blob" "this" {
  provider               = azurerm.auth_session

  name                   = "function.zip"
  storage_account_name   = var.function_bucket_name
  storage_container_name = var.function_container_name
  type                   = "Block"
  source                 = "./source/function.zip"
}

/* SAS Token

Create a SAS Token to append to the Blob URL for deployment
in Azure Function App. Deployment in a Private bucket
requires SAS Token to authenticate and download from
within Azure Function
*/
data "azurerm_storage_account_blob_container_sas" "this" {
  provider          = azurerm.auth_session

  connection_string = var.function_bucket_connection
  container_name    = var.function_container_name
  https_only        = true

  start  = timestamp()
  expiry = timeadd(timestamp(), var.function_sas_token_expiry)

  permissions {
    read   = true
    add    = false
    create = false
    write  = false
    delete = false
    list   = true
  }
}