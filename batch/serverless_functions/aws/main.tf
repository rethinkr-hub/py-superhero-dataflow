/* Root Module

Deploy AWS Infra for Superhero Simulator Dataflow
*/
terraform {
  backend "s3" {}
}

/* Proxy AWS Provider

Create AWS Provider to pass into Service Account Auth module. This Provider utilizes
the credentials of another Service Account which is IP Bound to the development machine
to reduce the risk of comprimization.
*/
provider "aws" {
  alias = "accountgen"
}

/* Create and Authenticate Service Account Session

The Service Account Auth Module will authenticate with AWS using
the IP Bound Service Account to request Access Tokens, and
create new short-live Service Accounts to Deploy/Destroy our
Superhero Simulator Dataflow
*/
module "service_account_auth" {
  source                      = "./modules/service_account_auth"
  new_service_account_name    = var.new_service_account_name
  // AWS role issues trying to deploy Lambda function with anything less than full access!
  bootstrap_iam_roles         = ["*"]
  /*bootstrap_iam_roles         = [
    "s3:*",
    "s3-object-lambda:*",
    "lambda:*",
    "iam:DeleteRole",
    "iam:ListInstanceProfilesForRole",
    "iam:ListAttachedRolePolicies",
    "iam:ListRolePolicies",
    "iam:GetRole",
    "iam:CreateRole",
    "iam:GetRolePolicy",
    "iam:PutRolePolicy",
    "iam:DeleteRolePolicy",
  ]*/

  providers = {
    aws.accountgen = aws.accountgen
  }
}

/* Authenticated Session

Create an authenticated AWS session with newly created
Service Account which is bootstrapped with IAM Roles
to deploy the required infra for Superhero Simulator Dataflow
*/
provider "aws" {
  alias       = "auth_session"
  region      = var.aws_region
  access_key  = module.service_account_auth.access_id
  secret_key  = module.service_account_auth.access_token
}

/* Create Superhero Simulator Dataflow Buckets

Creates S3 Blob Storage Containers to store the Dataflow 
Meta Data & Pipeline Source Code, and create a landing container
for the standarized parquet data
*/

/* AWS Storage Bucket for Superhero Meta Raw Data & Functions Trigger Container */
module "raw_bucket" {
  source      = "./modules/superhero_buckets"
  bucket_name = "datasim-superhero-dataflow-raw"
  providers   = {
    aws.auth_session = aws.auth_session
  }
}

/* AWS Storage Bucket for Superhero Standardized Parquet Data */
module "standard_bucket" {
  source      = "./modules/superhero_buckets"
  bucket_name = "datasim-superhero-dataflow-standard"
  providers   = {
    aws.auth_session = aws.auth_session
  }
}

/* AWS Storage Bucket for Lambda Source Code */
module "function_bucket" {
  source      = "./modules/superhero_buckets"
  bucket_name = "datasim-superhero-dataflow-function-source"
  providers   = {
    aws.auth_session = aws.auth_session
  }
}

/* Security Group

Create a Policy to connect Data Simulator Resources
*/
module "superhero_security_groups" {
  source           = "./modules/superhero_security_groups"
  contributor_user = var.contributor_user
  resource_arns    = [
    module.raw_bucket.bucket_arn,
    "${module.raw_bucket.bucket_arn}/*",
    module.standard_bucket.bucket_arn,
    "${module.standard_bucket.bucket_arn}/*",
    module.function_bucket.bucket_arn,
    "${module.function_bucket.bucket_arn}/*",
  ]
  
  providers = {
    aws.auth_session = aws.auth_session
  }
}

/* PyArrow Layer Source Code

Upload the PyArrow Layer Source Code to the
Functions Bucket required for Function Deployment
*/
module "superhero_functions_pyarrow_layer" {
  source          = "./modules/superhero_functions_layers"
  bucket_id       = module.function_bucket.bucket_id
  package_name    = "pyarrow"
  package_version = "10.0.1"

  providers = {
    aws.auth_session = aws.auth_session
  }
}

/* Numpy Layer Source Code

Upload the Numpy Layer Source Code to the
Functions Bucket required for Function Deployment
*/
module "superhero_functions_numpy_layer" {
  source          = "./modules/superhero_functions_layers"
  bucket_id       = module.function_bucket.bucket_id
  package_name    = "numpy"
  package_version = "1.23.5"

  providers = {
    aws.auth_session = aws.auth_session
  }
}

/* Create and Configure Superhero Simulator Dataflow AWS Function

Establish a pipeline which will trigger based on new Superhero Simulator
Meta Data entering into the raw bucket, and automatically executing ELT
procedure to convert the data to Parquet format
*/
module "superhero_functions" {
  source = "./modules/superhero_functions"
  bucket_arns = [
    module.raw_bucket.bucket_arn,
    "${module.raw_bucket.bucket_arn}/*",
    module.standard_bucket.bucket_arn,
    "${module.standard_bucket.bucket_arn}/*",
    module.function_bucket.bucket_arn,
    "${module.function_bucket.bucket_arn}/*",
  ]

  layer_arns = [
    module.superhero_functions_pyarrow_layer.layer_arn,
    module.superhero_functions_numpy_layer.layer_arn
  ]

  function_bucket_id  = module.function_bucket.bucket_id
  raw_bucket_arn      = module.raw_bucket.bucket_arn
  raw_bucket_id       = module.raw_bucket.bucket_id
  standard_bucket_id  = module.standard_bucket.bucket_id

  providers = {
    aws.auth_session = aws.auth_session
  }
}