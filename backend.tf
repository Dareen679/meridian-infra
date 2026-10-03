terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Local backend for LocalStack development.
  #
  # For a real deployment, replace this with a remote backend (e.g. S3 + DynamoDB
  # lock table) and run `tofu init -migrate-state`. Example:
  #
  # backend "s3" {
  #   bucket         = "meridian-labs-tofu-state"
  #   key            = "meridian-infra/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "meridian-labs-tofu-locks"
  #   encrypt        = true
  # }
  backend "local" {
    path = "state/terraform.tfstate"
  }
}

provider "aws" {
  region                      = var.aws_region
  access_key                  = var.use_localstack ? "test" : null
  secret_key                  = var.use_localstack ? "test" : null
  skip_credentials_validation = var.use_localstack
  skip_metadata_api_check     = var.use_localstack
  skip_requesting_account_id  = var.use_localstack
  s3_use_path_style           = var.use_localstack

  dynamic "endpoints" {
    for_each = var.use_localstack ? [1] : []
    content {
      ec2      = var.localstack_endpoint
      ecr      = var.localstack_endpoint
      s3       = var.localstack_endpoint
      sts      = var.localstack_endpoint
      iam      = var.localstack_endpoint
      dynamodb = var.localstack_endpoint
    }
  }
}
