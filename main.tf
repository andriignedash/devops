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
  region = var.aws_region
}

module "vpc" {
  source = "./modules/vpc"

  vpc_cidr_block     = var.vpc_cidr_block
  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
  availability_zones = var.availability_zones
  vpc_name           = "${var.project}-vpc"

  tags = local.common_tags
}

module "rds" {
  count  = var.create_db ? 1 : 0
  source = "./modules/rds"

  name       = var.project
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  use_aurora            = var.use_aurora
  aurora_instance_count = var.aurora_instance_count

  engine         = var.db_engine
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  storage_gb     = var.db_storage_gb
  max_storage_gb = var.db_max_storage_gb

  multi_az            = var.db_multi_az
  publicly_accessible = var.db_publicly_accessible

  backup_retention_days = var.db_backup_retention_days
  deletion_protection   = var.db_deletion_protection
  skip_final_snapshot   = var.db_skip_final_snapshot
  apply_immediately     = var.db_apply_immediately

  allowed_cidrs = [var.vpc_cidr_block]

  parameter_overrides = var.db_parameter_overrides

  tags = local.common_tags

  depends_on = [module.vpc]
}

locals {
  common_tags = merge(var.tags, {
    Project   = var.project
    ManagedBy = "terraform"
  })
}
