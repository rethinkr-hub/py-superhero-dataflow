output "bucket_name" {
  description = "GCS Storage Bucket Name"
  value       = google_storage_bucket.this.name
}