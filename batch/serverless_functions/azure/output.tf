output "raw_bucket_name" {
  description = "Azure ADLS Gen2 Storage Account Name for Raw Meta Data"
  value       = module.raw_bucket.bucket_name
}