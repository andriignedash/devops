output "bucket_name" {
  description = "Name of the S3 state bucket"
  value       = aws_s3_bucket.state.id
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB lock table"
  value       = aws_dynamodb_table.locks.name
}

output "region" {
  description = "AWS region"
  value       = var.region
}
