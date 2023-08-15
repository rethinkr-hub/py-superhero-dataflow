/* Superhero Simulator Blob Storage

Creates GCS Blob Storage Containers to store the Dataflow 
Meta Data & Pipeline Source Code, and create a landing container
for the standarized parquet data
*/

terraform{
  required_providers {
    google = {
      source = "hashicorp/google"
      configuration_aliases = [
        google.auth_session,
      ]
    }
  }
}

/* Create GCS Bucket */
resource "google_storage_bucket" "this" {
  provider                    = google.auth_session

  project                     = var.project_id
  name                        = var.bucket_name
  storage_class               = var.storage_class
  location                    = var.storage_location
  uniform_bucket_level_access = true
  force_destroy               = true
}