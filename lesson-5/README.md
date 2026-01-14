# Lesson 5: Terraform IaC (AWS)

This project provisions core AWS infrastructure in AWS (us-west-2) using Terraform modules:
- Remote Terraform state backend (S3 + DynamoDB locking)
- VPC networking (3 public + 3 private subnets, IGW, NAT, route tables)
- ECR repository for Docker images

## Project structure

lesson-5/
- main.tf        - root module, connects all modules
- backend.tf     - Terraform backend configuration (S3 + DynamoDB)
- outputs.tf     - root outputs (aggregated from modules)
- modules/
  - s3-backend/  - S3 bucket for tfstate + DynamoDB lock table
  - vpc/         - VPC, subnets, IGW, NAT, routes
  - ecr/         - ECR repository + repository policy

## Prerequisites

- Terraform >= 1.5
- AWS CLI configured (aws configure)
- AWS credentials with permissions for: S3, DynamoDB, VPC/EC2, ECR

Region: us-west-2

## How to run

Initialize:
terraform init

Validate:
terraform fmt -recursive
terraform validate

Plan:
terraform plan

Apply:
terraform apply

Destroy (IMPORTANT to avoid costs):
terraform destroy

## Modules

### s3-backend
Creates:
- S3 bucket with versioning and SSE (AES256) for storing tfstate
- DynamoDB table for state locking (PAY_PER_REQUEST)

### vpc
Creates:
- VPC (10.0.0.0/16)
- 3 public subnets + 3 private subnets across 3 AZs
- Internet Gateway for public subnets
- NAT Gateway (Elastic IP) for private subnets
- Route tables and associations

### ecr
Creates:
- ECR repository with scan-on-push enabled
- Repository policy granting full access to the current AWS account
