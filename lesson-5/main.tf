terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

# S3 + DynamoDB (backend resources)
module "s3_backend" {
  source      = "./modules/s3-backend"
  bucket_name = "andrii-gnedash-lesson-5-tfstate-001"
  table_name  = "terraform-locks"

  tags = {
    Project = "lesson-5"
  }
}

# VPC
module "vpc" {
  source = "./modules/vpc"

  vpc_cidr_block     = "10.0.0.0/16"
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets    = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
  vpc_name           = "lesson-5-vpc"

  tags = {
    Project = "lesson-5"
  }
}

# ECR
module "ecr" {
  source       = "./modules/ecr"
  ecr_name     = "lesson-5-ecr"
  scan_on_push = true

  tags = {
    Project = "lesson-5"
  }
}
