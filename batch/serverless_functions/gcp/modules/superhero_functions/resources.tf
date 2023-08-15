/* Superhero Simulator Functions

Pipeline trigger to convert Superhero Simulator Meta Data
into Standardized Paquet format
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

/*Zip Main Source Code

Zip the latest changes to the Function Source Code
Prior to deployment
*/
data "archive_file" "this" {
  type             = "zip"
  output_file_mode = "0666"
  output_path      = "./source/${var.function_name}.zip"

  source {
    content  = file("./source/main.py")
    filename = "main.py"
  }

  source {
    content  = file("./source/requirements.txt")
    filename = "requirements.txt"
  }
}

/* Upload GCP Functions Source

Upload the pipeline source code to trigger on every new
blob upload on the raw bucket
*/
resource "google_storage_bucket_object" "this" {
  provider = google.auth_session

  name     = "${var.function_name}.zip"
  bucket   = var.function_bucket_name
  source   = data.archive_file.this.output_path
}

/* Create GCP Function

Trigger the pipeline execution on every new blob upload on the raw bucket.
No where in the GCP Function resource does it define a target blob storage to
store the ELT data - this is configured in the GCP Function source code
*/
resource "google_cloudfunctions_function" "this" {
  provider    = google.auth_session

  name        = var.function_name
  description = var.function_description
  runtime     = "python310"
  region      = lower(var.raw_bucket_location)

  available_memory_mb          = var.function_memory
  source_archive_bucket        = var.function_bucket_name
  source_archive_object        = google_storage_bucket_object.this.name
  service_account_email        = var.function_service_account_email
  
  timeout                      = 60
  entry_point                  = "run"

  event_trigger {
    event_type = "google.storage.object.finalize"
    resource   = var.raw_bucket_name
  }
  
  environment_variables = {
    GCP_PROJECT_ID = var.project_id
  }
}

/* Bind Member Access

Provide IAM Member access to the Service Account to allow
the Service Account to invoke Cloud Function Trigger when new
blob hits the raw bucket
*/
resource "google_cloudfunctions_function_iam_member" "this" {
  provider       = google.auth_session

  project        = google_cloudfunctions_function.this.project
  region         = google_cloudfunctions_function.this.region
  cloud_function = google_cloudfunctions_function.this.name

  role   = "roles/cloudfunctions.invoker"
  member = var.function_service_account_member
}