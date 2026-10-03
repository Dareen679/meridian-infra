output "vpc_id" {
  description = "ID of the Meridian Labs VPC."
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the Meridian Labs VPC."
  value       = aws_vpc.main.cidr_block
}

output "ecr_repository_name" {
  description = "Name of the ECR repository. Null when use_localstack = true, since ECR is skipped against LocalStack's free tier."
  value       = try(aws_ecr_repository.app[0].name, null)
}

output "ecr_repository_url" {
  description = "Repository URL for the ECR repository (useful for docker push/pull). Null when use_localstack = true."
  value       = try(aws_ecr_repository.app[0].repository_url, null)
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket."
  value       = aws_s3_bucket.app.bucket
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket."
  value       = aws_s3_bucket.app.arn
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table."
  value       = aws_dynamodb_table.app_metadata.name
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table."
  value       = aws_dynamodb_table.app_metadata.arn
}
