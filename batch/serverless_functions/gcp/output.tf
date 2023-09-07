output "raw_bucket_name" {
  description = "GCS Bucket Name for Raw Meta Data"
  value       = module.raw_bucket.bucket_name
}

output "project_id" {
  description = "GCP Project ID"
  value       = var.project_id
}