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
  bucket_name = "andrii-gnedash-lesson-7-tfstate-001"
  table_name  = "terraform-locks-lesson-7"


  tags = {
    Project = "lesson-7"
  }
}

# VPC
module "vpc" {
  source = "./modules/vpc"

  vpc_cidr_block     = "10.0.0.0/16"
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets    = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
  vpc_name           = "lesson-7-vpc"

  tags = {
    Project = "lesson-7"
  }
}

# ECR
module "ecr" {
  source       = "./modules/ecr"
  ecr_name     = "lesson-7-ecr"
  scan_on_push = true

  tags = {
    Project = "lesson-7"
  }
}

# EKS Cluster
module "eks" {
  source = "./modules/eks"

  cluster_name       = "lesson-7-eks"
  cluster_version    = "1.29"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  desired_size   = 2
  min_size       = 2
  max_size       = 6
  instance_types = ["t3.medium"]

  tags = {
    Project = "lesson-7"
  }

  depends_on = [module.vpc]
}
