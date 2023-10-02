output "raw_bucket_name" {
  description = "Azure ADLS Gen2 Storage Account Name for Raw Meta Data"
  value       = module.raw_bucket.bucket_name
}

output "standard_bucket_name" {
  description = "Azure ADLS Gen2 Storage Account Name for Standard Meta Data"
  value       = module.standard_bucket.bucket_name
}