output "access_token" {
  depends_on  = [time_sleep.access-key-propogation]
  description = "Authenticated Session with Service Account Key"
  value       = aws_iam_access_key.this.secret
}

output "access_id" {
  depends_on  = [time_sleep.access-key-propogation]
  description = "Authenticated Session with Service Account ID"
  value       = aws_iam_access_key.this.id
}