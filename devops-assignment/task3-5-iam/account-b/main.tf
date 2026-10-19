terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region              = var.aws_region
  allowed_account_ids = ["111111111111"]
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "account_a_id" {
  type    = string
  default = "000000000000"
}

variable "bucket_name" {
  description = "The single S3 bucket roleC may use (must already exist or be created elsewhere)."
  type        = string
  default     = "account-b-shared-data-bucket"
}

# Apply Account A FIRST: IAM rejects a trust policy whose principal ARN does
# not exist yet ("Invalid principal in policy").
data "aws_iam_policy_document" "roleC_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.account_a_id}:role/roleB"] # the role, not the account
    }
  }
}

resource "aws_iam_role" "roleC" {
  name               = "roleC"
  assume_role_policy = data.aws_iam_policy_document.roleC_trust.json
}

data "aws_iam_policy_document" "roleC_s3" {
  statement {
    sid       = "BucketLevel"
    effect    = "Allow"
    actions   = ["s3:*"]
    resources = ["arn:aws:s3:::${var.bucket_name}"]
  }

  statement {
    sid       = "ObjectLevel"
    effect    = "Allow"
    actions   = ["s3:*"]
    resources = ["arn:aws:s3:::${var.bucket_name}/*"]
  }
}

resource "aws_iam_role_policy" "roleC_s3" {
  name   = "roleC-s3-access"
  role   = aws_iam_role.roleC.id
  policy = data.aws_iam_policy_document.roleC_s3.json
}

output "roleC_arn" {
  value = aws_iam_role.roleC.arn
}
