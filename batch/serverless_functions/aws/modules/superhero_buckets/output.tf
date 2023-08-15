output "bucket_arn" {
  description = "AWS Storage Bucket ARN"
  value       = aws_s3_bucket.this.arn
}

output "bucket_id" {
  description = "AWS Storage Bucket ID"
  value       = aws_s3_bucket.this.id
}