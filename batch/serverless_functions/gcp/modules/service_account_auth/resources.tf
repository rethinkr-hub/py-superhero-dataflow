/*
Original work from Garret Wong

https://medium.com/google-cloud/a-hitchhikers-guide-to-gcp-service-account-impersonation-in-terraform-af98853ebd37
*/

/* Proxy Provider 

Defines a blank provider to retrieve access tokens via Service Account Impersonation
with seperate aliases to define duties by Service Account. This provider is termed
"tokengen", and its purpose to just for requesting access keys via Servie Impersonation.
*/
terraform{
  required_providers {
    google = {
      source = "hashicorp/google"
      configuration_aliases = [
        google.tokengen,
      ]
    }
  }
}

data "google_client_config" "default" {
  provider = google.tokengen
}

/* Retreieve Access Token

Requst access token to Service Account with rolesets to create
new Service Accounts
*/
data "google_service_account_access_token" "creator-sa" {
  provider               = google.tokengen
  
  target_service_account = var.impersonate_service_account_email
  lifetime               = "600s"
  scopes                 = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
}

/* Google Service Account Creator Provider

Defines a provider provisioned to create new Service Accounts based on
*/
provider "google" {
  alias        = "creator"
  access_token = data.google_service_account_access_token.creator-sa.access_token
  project      = var.project_id
}

/* Blank Service Account Creation

Creates a fresh Service Account with no priviledges for later Project IAM role binding
*/
resource "google_service_account" "new-service-account" {
  provider     = google.creator

  account_id   = var.new_service_account_name
  display_name = var.new_service_account_description
  project      = var.project_id
}

/* Bind Token Creator IAM Policy

Bind the Service IAM Policy for token generator to the new Service Account
with the impersonator user email as the Principal
*/
resource "google_service_account_iam_binding" "token-creator-iam" {
  provider = google.creator
  
  service_account_id = google_service_account.new-service-account.name
  role               = "roles/iam.serviceAccountTokenCreator"
  members            = ["user:${var.impersonate_user_email}"]
}

/* Bind Project IAM Roles to Service Account */
resource "google_project_iam_member" "bind-roles" {
  for_each = toset(var.bootstrap_project_iam_roles)
  provider = google.creator

  project = var.project_id
  role    = each.value
  member  = google_service_account.new-service-account.member
}

/* IAM Policy Propogation Wait

No current mechanism to wait until Service IAM/Project IAM roles
have been finished binding to Service Accounts and Principals. We
wait for a minute to allow time for propogation to happen otherwise
we're hit with 403 unauthorized errors
*/
resource "time_sleep" "iam-propogation" {
  depends_on      = [google_project_iam_member.bind-roles]

  create_duration = "60s"
}

/* Retreieve Access Token

Requst access token to *New* Service Account with Project IAM priviledges
to deploy project infra
*/
data "google_service_account_access_token" "new-sa" {
  provider               = google.tokengen
  depends_on             = [time_sleep.iam-propogation]

  target_service_account = google_service_account.new-service-account.email
  scopes                 = [
    "https://www.googleapis.com/auth/cloud-platform",
  ]
}
