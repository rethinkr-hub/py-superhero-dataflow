/* Proxy Provider 

Defines a provider to retrieve access tokens via normal requests with IP Bound Service Account
with seperate aliases to define duties by Service Account. This provider is termed
"accountgen", and its purpose is just for generating minimum priviledged Service Accounts.
*/
terraform{
  required_providers {
    aws = {
      source = "hashicorp/aws"
      configuration_aliases = [
        aws.accountgen,
      ]
    }
  }
}

/* Create bew Service Account */
resource "aws_iam_user" "this" {
  provider = aws.accountgen

  name     = var.new_service_account_name
}

/* Policy Schema example

Define Policy with minimum priviledges (just enough) to deploy 
required infra.

https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-create-and-attach-iam-policy.html
*/
data "aws_iam_policy_document" "this" {
  provider = aws.accountgen

  statement {
    sid       = "${var.policy_prefix}PolicyDoc0"
    effect    = "Allow"
    actions   = var.bootstrap_iam_roles
    resources = ["*"]
  }

  depends_on = [ aws_iam_user.this ]
}

/* Bind Policy

Binds the minimum privilidge policy with the newly 
created Service Account
*/
resource "aws_iam_user_policy" "this" {
  provider = aws.accountgen

  name     = "${var.policy_prefix}UserPolicy"
  user     = aws_iam_user.this.name
  policy   = data.aws_iam_policy_document.this.json
}

/* Generate Service Key 

Generate new authentication tokens for downstream
infra deployment
*/
resource "aws_iam_access_key" "this" {
  provider   = aws.accountgen
  depends_on = [aws_iam_user_policy.this]

  user       = aws_iam_user.this.name
}

resource "time_sleep" "access-key-propogation" {
  depends_on      = [aws_iam_access_key.this]

  create_duration = "60s"
}