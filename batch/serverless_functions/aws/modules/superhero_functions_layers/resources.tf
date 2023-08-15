/* Superhero Simulator Functions Layers

Function Layers for storing extra libraries required by
the Lambda Function
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

/* Install Dependency

Install the Python dependency with Pip
*/
resource "null_resource" "this" {
  provisioner "local-exec" {
    command = "pip install --no-deps --upgrade --target ./source/${var.package_name}/python ${var.package_name}==${var.package_version}"
  }
}

/*Zip Main Source Code

Zip the Python package for upload to AWS Storage Bucket.
https://docs.aws.amazon.com/lambda/latest/dg/python-package.html
https://docs.aws.amazon.com/lambda/latest/dg/packaging-layers.html
*/
data "archive_file" "this" {
  type             = "zip"
  source_dir       = "./source/${var.package_name}"
  output_file_mode = "0666"
  output_path      = "./source/${var.package_name}.zip"

  depends_on = [ null_resource.this ]
}

resource "aws_s3_object" "this" {
  provider = aws.auth_session

  bucket  = var.bucket_id
  key     = "layer_${var.package_name}.zip"
  source  = data.archive_file.this.output_path
}

resource "aws_lambda_layer_version" "this" {
  provider            = aws.auth_session

  layer_name          = "layer_${var.package_name}"
  s3_bucket           = var.bucket_id
  s3_key              = aws_s3_object.this.key
  compatible_runtimes = ["python3.9"]
}