/* Superhero Simulator Functions

Pipeline trigger to convert Superhero Simulator Meta Data
into Standardized Parquet format
*/
terraform{
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
}

/* Service Plan

Configure a Service Plan for Function App Specs
and Performance.

Note: Free Tier is no longer an option
*/
resource "azurerm_service_plan" "this" {
  name                = var.service_plan_name
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  os_type             = var.service_plan_os_type
  sku_name            = var.service_plan_sku_type
}

/* Application Insights

Configure Application Insights to monitor Function
executions and logs. Not configured by default
*/
resource "azurerm_application_insights" "this" {
  name                = "${var.service_plan_name}-app-insights"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  application_type    = "other"
}

/* Azure Function App - Linux

Create the ELT function to convert data in the Raw Bucket to
Parquet Format in the Standard Bucket, and configure with Application Insights
and ENV Variables required by functions. Use a function blob zip
to deploy all functions instead of creating individual functions
with azurerm_function_app_function - too many problems

# Need to compile requirements.txt prior to deploying with Terraform.
# Azure Functions with Linux os_type doesn't support installing requirements.txt
https://stackoverflow.com/questions/62903172/functionapp-not-importing-python-module

# Python also isn't a valid runtime for Windows os_type function apps
https://stackoverflow.com/questions/67750337/python-projects-are-not-supported-on-windows-function-app-deploy-to-a-linux-fun

# App Settings
https://learn.microsoft.com/en-us/azure/azure-functions/functions-app-settings
*/
resource "azurerm_linux_function_app" "this" {
  name                = var.function_name
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  service_plan_id     = azurerm_service_plan.this.id

  storage_account_name       = var.raw_bucket_name
  storage_account_access_key = var.raw_bucket_key

  site_config {
    application_insights_connection_string = azurerm_application_insights.this.connection_string
    application_insights_key               = azurerm_application_insights.this.instrumentation_key

    application_stack {
      python_version = var.python_version
    }
  }

  app_settings        = {
    WEBSITE_RUN_FROM_PACKAGE = var.function_zip_blob_url
    STANDARD_BUCKET_NAME     = var.standard_bucket_name
    STANDARD_BUCKET_KEY      = var.standard_bucket_key
  }
}