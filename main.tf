locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = merge(
    {
      Project     = "Meridian Labs"
      Environment = var.environment
      ManagedBy   = "OpenTofu"
    },
    var.tags
  )
}

# ---------------------------------------------------------------------------
# VPC
# ---------------------------------------------------------------------------

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-vpc"
    }
  )
}

# ---------------------------------------------------------------------------
# ECR repository
#
# ECR is a LocalStack Pro-only service (see README), so this resource is
# skipped when use_localstack = true and created only against real AWS.
# ---------------------------------------------------------------------------

resource "aws_ecr_repository" "app" {
  count = var.use_localstack ? 0 : 1

  name                 = "${local.name_prefix}-app"
  image_tag_mutability = var.ecr_image_tag_mutability

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-ecr"
    }
  )
}

# ---------------------------------------------------------------------------
# S3 bucket
# ---------------------------------------------------------------------------

resource "aws_s3_bucket" "app" {
  bucket        = "${local.name_prefix}-app-bucket"
  force_destroy = var.s3_force_destroy

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-s3"
    }
  )
}

resource "aws_s3_bucket_versioning" "app" {
  bucket = aws_s3_bucket.app.id

  versioning_configuration {
    status = "Enabled"
  }
}

# ---------------------------------------------------------------------------
# DynamoDB table
#
# Included alongside the VPC and S3 bucket as a third, always-on resource
# type so the full configuration can be plan/apply-tested against LocalStack's
# free tier without requiring an ECR-capable (Pro) license.
# ---------------------------------------------------------------------------

resource "aws_dynamodb_table" "app_metadata" {
  name         = "${local.name_prefix}-app-metadata"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-dynamodb"
    }
  )
}
