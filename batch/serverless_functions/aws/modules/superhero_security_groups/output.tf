output "security_group_arn" {
    description = "AWS Security Group ARN"
    value       = aws_iam_group.this.arn
}