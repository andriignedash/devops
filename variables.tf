variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "eu-central-1"
}

variable "aws_profile" {
  description = "AWS CLI profile for provider and backend"
  type        = string
  default     = "final"
}

variable "project" {
  description = "Project name used for resource naming"
  type        = string
  default     = "final-project"
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "List of public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnets" {
  description = "List of private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
}

variable "ecr_repository_name" {
  description = "ECR repository name"
  type        = string
  default     = "django-app"
}

variable "eks_cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "final-project-eks"
}

variable "eks_cluster_version" {
  description = "EKS Kubernetes version"
  type        = string
  default     = "1.28"
}

variable "eks_node_instance_types" {
  description = "EKS node group instance types"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "eks_node_desired_size" {
  description = "EKS node group desired size"
  type        = number
  default     = 2
}

variable "eks_node_min_size" {
  description = "EKS node group minimum size"
  type        = number
  default     = 1
}

variable "eks_node_max_size" {
  description = "EKS node group maximum size"
  type        = number
  default     = 4
}

variable "jenkins_chart_version" {
  description = "Jenkins Helm chart version"
  type        = string
  default     = "4.6.1"
}

variable "argocd_chart_version" {
  description = "Argo CD Helm chart version"
  type        = string
  default     = "5.51.6"
}

variable "monitoring_chart_version" {
  description = "kube-prometheus-stack Helm chart version"
  type        = string
  default     = "55.5.0"
}

variable "gitops_repo_url" {
  description = "Git repo URL for Argo CD (charts/django-app)"
  type        = string
  default     = "https://github.com/REPLACE_ME/REPLACE_ME.git"
}

variable "create_db" {
  description = "Whether to create the database resources"
  type        = bool
  default     = false
}

variable "use_aurora" {
  description = "Whether to create Aurora cluster instead of RDS instance"
  type        = bool
  default     = false
}

variable "aurora_instance_count" {
  description = "Number of Aurora instances (including writer)"
  type        = number
  default     = 1
}

variable "db_engine" {
  description = "Database engine: postgres or mysql"
  type        = string
  default     = "postgres"
}

variable "db_engine_version" {
  description = "Database engine version"
  type        = string
  default     = ""
}

variable "db_instance_class" {
  description = "Instance class for the database"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Name of the default database"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Master username for the database"
  type        = string
  default     = "dbadmin"
}

variable "db_password" {
  description = "Master password for the database (required when create_db=true)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "db_storage_gb" {
  description = "Allocated storage in GB (RDS only)"
  type        = number
  default     = 20
}

variable "db_max_storage_gb" {
  description = "Maximum storage for autoscaling (0 to disable)"
  type        = number
  default     = 0
}

variable "db_multi_az" {
  description = "Enable Multi-AZ deployment"
  type        = bool
  default     = false
}

variable "db_publicly_accessible" {
  description = "Make database publicly accessible"
  type        = bool
  default     = false
}

variable "db_backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
}

variable "db_deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = false
}

variable "db_skip_final_snapshot" {
  description = "Skip final snapshot when destroying"
  type        = bool
  default     = true
}

variable "db_apply_immediately" {
  description = "Apply changes immediately"
  type        = bool
  default     = false
}

variable "db_parameter_overrides" {
  description = "Map of parameter overrides for the database"
  type        = map(string)
  default     = {}
}
