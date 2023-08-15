/* Superhero Simulator Blob Storage

Creates S3 Blob Storage Containers
*/

terraform{
  required_providers {
    aws = {
      source = "hashicorp/aws"
      configuration_aliases = [
        aws.auth_session,
      ]
    }
  }
}

/* Create S3 Bucket */
resource "aws_s3_bucket" "this" {
  provider      = aws.auth_session
  
  bucket        = var.bucket_name
  force_destroy = true
}