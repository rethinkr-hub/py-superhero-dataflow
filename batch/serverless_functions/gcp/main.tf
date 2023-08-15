/* Root Module

Deploy GCP Infra for Superhero Simulator Dataflow
*/

terraform {
  backend "gcs" {}
}


/* Proxy Google Provider

Create blank Google Provider to pass into Service Account Auth module
*/
provider "google" {
  alias = "tokengen"
}

/* Create and Authenticate Service Account Session

The Service Account Auth Module will authenticate with GCP using
the Impersonate Service Account Mode to request Access Tokens, and
create new short-live Service Accounts to Deploy/Destroy our
Superhero Simulator Dataflow
*/
module "service_account_auth" {
  source                            = "./modules/service_account_auth"
  project_id                        = var.project_id
  impersonate_service_account_email = var.impersonate_service_account_email
  impersonate_user_email            = var.impersonate_user_email
  new_service_account_name          = "datasim-superhero-dataflow"
  new_service_account_description   = "Service Account to manage Superhero Dataflow GCP Resources"
  bootstrap_project_iam_roles       = [
    "roles/storage.admin",
    "roles/cloudfunctions.admin",
    "roles/iam.serviceAccountUser"
  ]

  providers = {
    google.tokengen = google.tokengen
  }
}

/* Authenticated Session

Create an authenticated GCP session with newly created
Service Account which is bootstrapped with Project IAM Roles
to deploy the required infra for Superhero Simulator Dataflow
*/
provider "google" {
  alias        = "auth_session"
  access_token = module.service_account_auth.access_token
  project      = var.project_id
}

/* Create Superhero Simulator Dataflow Buckets

Define and Deploy the GCS Buckets necessary to complete the pipeline
for the Superherof Simulator Dataflow
*/

/* Create GCS Bucket for Raw Data */
module "raw_bucket" {
  source          = "./modules/superhero_buckets"
  project_id      = var.project_id
  bucket_name     = "datasim-superhero-dataflow-raw"

  providers = {
    google.auth_session = google.auth_session
  }
}

/* Creater GCS Bucket for Functions Source Code*/
module "function_bucket" {
  source          = "./modules/superhero_buckets"
  project_id      = var.project_id
  bucket_name     = "datasim-superhero-dataflow-function-source"

  providers = {
    google.auth_session = google.auth_session
  }
}

/* Create GCS Bucket for Standardized Parquet Data */
module "standard_bucket" {
  source          = "./modules/superhero_buckets"
  project_id      = var.project_id
  bucket_name     = "datasim-superhero-dataflow-standard"

  providers = {
    google.auth_session = google.auth_session
  }
}

/* Create and Configure Superhero Simulator Dataflow GCP Function

Establish a pipeline which will trigger based on new Superhero Simulator
Meta Data entering into the raw bucket, and automatically executing ELT
procedure to convert the data to Parquet format
*/
module "superhero_functions" {
  source                          = "./modules/superhero_functions"
  project_id                      = var.project_id
  function_name                   = "datasim-superhero-raw-elt-function"
  function_memory                 = 256
  function_bucket_name            = module.function_bucket.bucket_name
  raw_bucket_name                 = module.raw_bucket.bucket_name
  function_service_account_member = module.service_account_auth.service_account_member
  function_service_account_email  = module.service_account_auth.service_account_email

  providers = {
    google.auth_session = google.auth_session
  }
}