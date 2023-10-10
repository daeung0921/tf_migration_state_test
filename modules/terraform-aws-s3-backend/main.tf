data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "random_string" "rand" {
  count   = var.create ? 1 : 0
  length  = 24
  special = false
  upper   = false
}

locals {
  name           = var.create ? substr(join("-", [var.name, random_string.rand[0].result]), 0, 24) : ""
  principal_arns = var.create ? (var.principal_arns != null ? var.principal_arns : [data.aws_caller_identity.current.arn]) : null
}

# IAM Role
resource "aws_iam_role" "iam_role" {
  count = var.create ? 1 : 0
  name  = "${local.name}-tf-assume-role"

  assume_role_policy = <<-EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Action": "sts:AssumeRole",
          "Principal": {
              "AWS": ${jsonencode(local.principal_arns)}
          },
          "Effect": "Allow"
        }
      ]
    }
  EOF

  tags = {
    ResourceGroup = local.name
  }
}

data "aws_iam_policy_document" "policy_doc" {
  count = var.create ? 1 : 0
  statement {
    actions = [
      "s3:ListBucket",
    ]

    resources = [
      aws_s3_bucket.s3_bucket[0].arn
    ]
  }

  statement {
    actions = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]

    resources = [
      "${aws_s3_bucket.s3_bucket[0].arn}/*",
    ]
  }

  statement {
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem"
    ]
    resources = [aws_dynamodb_table.dynamodb_table[0].arn]
  }

  statement {
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]
    resources = [aws_kms_key.kms_key[0].arn]
  }
}

resource "aws_iam_policy" "iam_policy" {
  count  = var.create ? 1 : 0
  name   = "${local.name}-tf-policy"
  path   = "/"
  policy = data.aws_iam_policy_document.policy_doc[0].json
}

resource "aws_iam_role_policy_attachment" "policy_attach" {
  count      = var.create ? 1 : 0
  role       = aws_iam_role.iam_role[0].name
  policy_arn = aws_iam_policy.iam_policy[0].arn
}

# Resource Group
resource "aws_resourcegroups_group" "resourcegroups_group" {
  count = var.create ? 1 : 0
  name  = "${local.name}-group"

  resource_query {
    query = <<-JSON
{
  "ResourceTypeFilters": [
    "AWS::AllSupported"
  ],
  "TagFilters": [
    {
      "Key": "ResourceGroup",
      "Values": ["${local.name}"]
    }
  ]
}
  JSON
  }
}

# KMS Key
resource "aws_kms_key" "kms_key" {
  count = var.create ? 1 : 0
  tags = {
    ResourceGroup = local.name
  }
}

# Bucket
resource "aws_s3_bucket" "s3_bucket" {
  count         = var.create ? 1 : 0
  bucket        = "${local.name}-state-bucket"
  force_destroy = var.force_destroy_state

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = aws_kms_key.kms_key[0].arn
      }
    }
  }

  tags = {
    ResourceGroup = local.name
  }
}

resource "aws_s3_bucket_public_access_block" "s3_bucket" {
  count  = var.create ? 1 : 0
  bucket = aws_s3_bucket.s3_bucket[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Dynamo DB Table
resource "aws_dynamodb_table" "dynamodb_table" {
  count        = var.create ? 1 : 0
  name         = "${local.name}-state-lock"
  hash_key     = "LockID"
  billing_mode = "PAY_PER_REQUEST"
  attribute {
    name = "LockID"
    type = "S"
  }
  tags = {
    ResourceGroup = local.name
  }
}
