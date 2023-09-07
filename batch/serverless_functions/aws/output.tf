output "raw_bucket_id" {
  description = "AWS Storage Bucket ID for Raw Meta Data"
  value       = module.raw_bucket.bucket_id
}

output "standard_bucket_id" {
  description = "AWS Storage Bucket ID for ELT Parquet Data"
  value       = module.standard_bucket.bucket_id
}

output "aws_cli_profile" {
  description = "AWS CLI Configure --profile name where credentials are stored"
  value       = var.aws_cli_profile
}