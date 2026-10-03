variable "aws_region" {
  description = "AWS region to deploy resources into."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (e.g. dev, staging, prod). Used for resource naming and tagging."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "project_name" {
  description = "Short project identifier used as a prefix for resource names."
  type        = string
  default     = "meridian"
}

variable "use_localstack" {
  description = "Whether to point the AWS provider at a local LocalStack endpoint instead of real AWS."
  type        = bool
  default     = true
}

variable "localstack_endpoint" {
  description = "Base URL for the LocalStack gateway (used for all services when use_localstack is true)."
  type        = string
  default     = "http://localhost:4566"
}

variable "vpc_cidr_block" {
  description = "CIDR block for the Meridian Labs VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "ecr_image_tag_mutability" {
  description = "Tag mutability setting for the ECR repository (MUTABLE or IMMUTABLE)."
  type        = string
  default     = "MUTABLE"
}

variable "s3_force_destroy" {
  description = "Allow the S3 bucket to be destroyed even if it still contains objects (useful for local testing)."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags applied to all resources."
  type        = map(string)
  default     = {}
}
