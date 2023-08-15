/* Superhero Simulator Security

IAM Group to manage multi-user authorization
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

data "aws_iam_user" "this" {
  user_name = var.contributor_user
}

resource "aws_iam_group" "this" {
  name = var.group_prefix
  path = "/groups/"
}

resource "aws_iam_group_membership" "this" {
  name = "${var.group_prefix}-membership"

  users = [
    data.aws_iam_user.this.user_name,
  ]

  group = aws_iam_group.this.name
}

/* Group-S3 Policy Document

Create a Policy Document to grant s3 access
to group
*/
data "aws_iam_policy_document" "this" {
  provider = aws.auth_session

  statement {
    sid       = "${var.policy_prefix}PolicyDocument1"
    effect    = "Allow"
    actions   = [
      "s3:ListObject",
      "s3:GetObject",
      "s3:PutObject"
    ]

    resources = var.resource_arns
  }
}

resource "aws_iam_group_policy" "this" {
  name  = "${var.group_prefix}-policy"
  group = aws_iam_group.this.name

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = data.aws_iam_policy_document.this.json
}