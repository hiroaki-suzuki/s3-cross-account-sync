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
  app_name     = "hs-s3-cross-sync-old"
  new_app_name = "hs-s3-cross-sync-new"
}

# ==================================================
# S3 Bucket
# ==================================================

resource "aws_s3_bucket" "old_bucket" {
  bucket = "${local.app_name}-bucket"
}

resource "aws_s3_bucket_public_access_block" "old_bucket" {
  bucket                  = aws_s3_bucket.old_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "old_bucket" {
  bucket = aws_s3_bucket.old_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ==================================================
# IAM Role
# ==================================================

resource "aws_iam_policy" "s3_sync_role" {
  name        = "${local.app_name}-s3-sync-policy"
  description = "Cross Account S3 Sync Role"

  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Effect : "Allow",
        Action : [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ],
        Resource : [
          aws_s3_bucket.old_bucket.arn,
          "${aws_s3_bucket.old_bucket.arn}/*",
          "arn:aws:s3:::${local.new_app_name}-bucket",
          "arn:aws:s3:::${local.new_app_name}-bucket/*",
        ]
      }
    ]
  })
}

resource "aws_iam_role" "s3_sync_role" {
  name = "${local.app_name}-s3-sync-role"

  assume_role_policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Effect : "Allow",
        Principal : {
          AWS : var.s3_sync_exec_user_arn
        },
        Action : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_sync_role" {
  policy_arn = aws_iam_policy.s3_sync_role.arn
  role       = aws_iam_role.s3_sync_role.name
}
