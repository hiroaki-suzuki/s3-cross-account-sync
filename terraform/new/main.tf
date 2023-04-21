terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.64.0"
    }
  }
}

provider "aws" {
  region     = "ap-northeast-1"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

locals {
  app_name = "hs-s3-cross-sync-new"
}

# ==================================================
# S3 Bucket
# ==================================================

resource "aws_s3_bucket" "new_bucket" {
  bucket = "${local.app_name}-bucket"
}

resource "aws_s3_bucket_public_access_block" "new_bucket" {
  bucket                  = aws_s3_bucket.new_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "new_bucket" {
  bucket = aws_s3_bucket.new_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "new_bucket" {
  bucket = aws_s3_bucket.new_bucket.id
  policy = data.aws_iam_policy_document.new_bucket.json
}

data "aws_iam_policy_document" "new_bucket" {
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [
        var.old_s3_sync_role_arn,
      ]
    }
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket"
    ]
    resources = [
      aws_s3_bucket.new_bucket.arn,
      "${aws_s3_bucket.new_bucket.arn}/*",
    ]
  }
}