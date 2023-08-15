/* Superhero Simulator Functions

Pipeline trigger to convert Superhero Simulator Meta Data
into Standardized Parquet format
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

/* Function Policy Document

Create a Policy Document to grant Principal access to
the Lamdba Service
*/
data "aws_iam_policy_document" "this" {
  provider = aws.auth_session

  statement {
    sid     = "${var.policy_prefix}PolicyDocument0"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
        identifiers = ["lambda.amazonaws.com"]
        type = "Service"
    }
  }
}

/* Function Role

Create a role to enable user binding to the Function 
Policy Document
*/
resource "aws_iam_role" "this" {
  provider           = aws.auth_session

  name               = "${var.policy_prefix}Role0"
  assume_role_policy = data.aws_iam_policy_document.this.json
}

/* Configure Logging

Create a Logging Group for the Lamdba Function to
stream function execution logs to Cloud Watch.

Without this resource, logs are stored indefinitely
*/
resource "aws_cloudwatch_log_group" "lambda-funtion" {
  provider          = aws.auth_session

  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = 1
}

/* Function-S3-Cloud Watch Policy Document

Create a Policy Document to grant resource access
to the S3 buckets
*/
data "aws_iam_policy_document" "s3-cloud-watch-policy-document" {
  provider = aws.auth_session

  statement {
    sid       = "${var.policy_prefix}S3PolicyDocument1"
    effect    = "Allow"
    actions   = [
      "s3:GetObject",
      "s3:PutObject"
    ]

    resources = var.bucket_arns
  }

  statement {
    sid       = "${var.policy_prefix}CloudWatchPolicyDocument1"
    effect    = "Allow"
    actions   = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
        aws_cloudwatch_log_group.lambda-funtion.arn,
        "${aws_cloudwatch_log_group.lambda-funtion.arn}:*"
    ]
  }
}

/* Function-S3 Role

Create a role to enable user binding to the Function-S3 
Policy Document
*/
resource "aws_iam_role_policy" "this" {
  provider = aws.auth_session
  
  name     = "${var.policy_prefix}RolePolicy0"
  role     = aws_iam_role.this.id
  policy   = data.aws_iam_policy_document.s3-cloud-watch-policy-document.json
}

/*Zip Main Source Code

Zip the latest changes to the Function Source Code
Prior to deployment
*/
data "archive_file" "this" {
  type             = "zip"
  source_file      = "./source/${var.function_source}.py"
  output_file_mode = "0666"
  output_path      = "./source/${var.function_name}.zip"

  //Stops archiving the function during plan
  depends_on = [ aws_iam_role_policy.this ]
}

/* Main Source Code

Upload the Function Source Code to the
Functions Bucket required for Function Deployment
*/
resource "aws_s3_object" "this" {
  provider = aws.auth_session
  
  bucket   = var.function_bucket_id
  key      = "${var.function_name}.zip"
  source   = data.archive_file.this.output_path
}

/* Create AWS Function

Defines the ELT function to convert data in the Raw Bucket to
Parquet Format in the Standard Bucket
*/
resource "aws_lambda_function" "this" {
  provider         = aws.auth_session

  function_name    = var.function_name
  role             = aws_iam_role.this.arn
  handler          = "lambda_function.${var.function_handler}"
  runtime          = "python3.9"
  s3_bucket        = var.function_bucket_id
  s3_key           = aws_s3_object.this.key
  memory_size      = 256
  layers           = var.layer_arns

  environment {
    variables = {
      OUTPUT_BUCKET=var.standard_bucket_id
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda-funtion
  ]
}

/* AWS Function Trigger

Trigger the pipeline execution on every new blob upload on the raw bucket.
No where in the AWS Function resources does it define a target blob storage to
store the ELT data - this is configured in the AWS Function source code
*/
resource "aws_s3_bucket_notification" "this" {
  provider = aws.auth_session

  bucket   = var.raw_bucket_id

  lambda_function {
    lambda_function_arn = aws_lambda_function.this.arn
    events              = ["s3:ObjectCreated:*"]
  }
}

/*Lambda Perminssion Bind

Enable S3 bucket to invoke the Lamnda Function with the
S3 Service Principal
*/
resource "aws_lambda_permission" "this" {
  provider      = aws.auth_session

  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = var.raw_bucket_arn
}