terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_ca)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_ca)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

# S3 + DynamoDB (backend resources)
module "s3_backend" {
  source      = "./modules/s3-backend"
  bucket_name = "andrii-gnedash-lesson-8-9-tfstate-001"
  table_name  = "terraform-locks-lesson-8-9"

  tags = {
    Project = "lesson-8-9"
  }
}

# VPC
module "vpc" {
  source = "./modules/vpc"

  vpc_cidr_block     = "10.0.0.0/16"
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets    = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
  vpc_name           = "lesson-8-9-vpc"

  tags = {
    Project = "lesson-8-9"
  }
}

# ECR
module "ecr" {
  source       = "./modules/ecr"
  ecr_name     = "lesson-8-9-ecr"
  scan_on_push = true

  tags = {
    Project = "lesson-8-9"
  }
}

# EKS Cluster
module "eks" {
  source = "./modules/eks"

  cluster_name       = "lesson-8-9-eks"
  cluster_version    = "1.29"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  desired_size   = 2
  min_size       = 2
  max_size       = 6
  instance_types = ["t3.medium"]

  tags = {
    Project = "lesson-8-9"
  }

  depends_on = [module.vpc]
}

# Jenkins
module "jenkins" {
  source = "./modules/jenkins"

  cluster_name       = module.eks.cluster_name
  cluster_endpoint   = module.eks.cluster_endpoint
  cluster_ca         = module.eks.cluster_ca
  ecr_repository_url = module.ecr.repository_url
  region             = "us-west-2"

  namespace    = "jenkins"
  service_type = "ClusterIP"

  tags = {
    Project = "lesson-8-9"
  }

  depends_on = [module.eks]
}

# Argo CD
module "argo_cd" {
  source = "./modules/argo_cd"

  cluster_name     = module.eks.cluster_name
  cluster_endpoint = module.eks.cluster_endpoint
  cluster_ca       = module.eks.cluster_ca

  namespace = "argocd"

  gitops_repo_url = "https://github.com/YOUR_USERNAME/YOUR_GITOPS_REPO.git"
  gitops_branch   = "main"
  app_namespace   = "django"
  app_chart_path  = "charts/django-app"

  tags = {
    Project = "lesson-8-9"
  }

  depends_on = [module.eks]
}
