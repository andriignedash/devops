locals {
  common_tags = merge(var.tags, {
    Project   = var.project
    ManagedBy = "terraform"
  })
}

module "vpc" {
  source = "./modules/vpc"

  vpc_cidr_block     = var.vpc_cidr_block
  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
  availability_zones = var.availability_zones
  vpc_name           = "${var.project}-vpc"
  tags               = local.common_tags
}

module "ecr" {
  source = "./modules/ecr"

  repository_name = var.ecr_repository_name
  tags            = local.common_tags
}

module "eks" {
  source = "./modules/eks"

  cluster_name        = var.eks_cluster_name
  cluster_version     = var.eks_cluster_version
  subnet_ids          = module.vpc.private_subnet_ids
  node_instance_types = var.eks_node_instance_types
  node_desired_size   = var.eks_node_desired_size
  node_min_size       = var.eks_node_min_size
  node_max_size       = var.eks_node_max_size
  tags                = local.common_tags

  depends_on = [module.vpc]
}

module "rds" {
  count  = var.create_db ? 1 : 0
  source = "./modules/rds"

  name       = var.project
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  use_aurora            = var.use_aurora
  aurora_instance_count = var.aurora_instance_count
  engine                = var.db_engine
  engine_version        = var.db_engine_version
  instance_class        = var.db_instance_class
  db_name               = var.db_name
  username              = var.db_username
  password              = var.db_password
  storage_gb            = var.db_storage_gb
  max_storage_gb        = var.db_max_storage_gb
  multi_az              = var.db_multi_az
  publicly_accessible   = var.db_publicly_accessible
  backup_retention_days = var.db_backup_retention_days
  deletion_protection   = var.db_deletion_protection
  skip_final_snapshot   = var.db_skip_final_snapshot
  apply_immediately     = var.db_apply_immediately
  parameter_overrides   = var.db_parameter_overrides
  tags                  = local.common_tags

  allowed_cidrs              = [var.vpc_cidr_block]
  allowed_security_group_ids = [module.eks.cluster_security_group_id]

  depends_on = [module.vpc, module.eks]
}

module "jenkins" {
  source = "./modules/jenkins"

  chart_version    = var.jenkins_chart_version
  namespace_labels = local.common_tags

  depends_on = [module.eks]
}

module "argo_cd" {
  source = "./modules/argo_cd"

  chart_version    = var.argocd_chart_version
  gitops_repo_url  = var.gitops_repo_url
  namespace_labels = local.common_tags

  depends_on = [module.eks]
}

module "monitoring" {
  source = "./modules/monitoring"

  chart_version    = var.monitoring_chart_version
  namespace_labels = local.common_tags

  depends_on = [module.eks]
}
