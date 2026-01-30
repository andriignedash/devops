variable "name" {
  description = "Name prefix for all resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where DB will be created"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the DB subnet group"
  type        = list(string)
}

variable "allowed_cidrs" {
  description = "List of CIDR blocks allowed to connect to the database"
  type        = list(string)
  default     = []
}

variable "allowed_security_group_ids" {
  description = "List of security group IDs allowed to connect to the database"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "use_aurora" {
  description = "Whether to create Aurora cluster instead of single RDS instance"
  type        = bool
  default     = false
}

variable "engine" {
  description = "Database engine: postgres or mysql"
  type        = string
  default     = "postgres"

  validation {
    condition     = contains(["postgres", "mysql"], var.engine)
    error_message = "Engine must be either postgres or mysql."
  }
}

variable "engine_version" {
  description = "Database engine version"
  type        = string
  default     = ""
}

variable "instance_class" {
  description = "Instance class for RDS/Aurora instances"
  type        = string
  default     = "db.t3.micro"
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment for RDS (not applicable to Aurora)"
  type        = bool
  default     = false
}

variable "db_name" {
  description = "Name of the default database to create"
  type        = string
  default     = "appdb"
}

variable "username" {
  description = "Master username for the database"
  type        = string
  default     = "dbadmin"
}

variable "password" {
  description = "Master password for the database"
  type        = string
  sensitive   = true
}

variable "port" {
  description = "Database port (auto-detected based on engine if not specified)"
  type        = number
  default     = null
}

variable "storage_gb" {
  description = "Allocated storage in GB (RDS only)"
  type        = number
  default     = 20
}

variable "max_storage_gb" {
  description = "Maximum storage for autoscaling in GB (RDS only, 0 to disable)"
  type        = number
  default     = 0
}

variable "storage_type" {
  description = "Storage type: gp2, gp3, io1"
  type        = string
  default     = "gp3"
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot when destroying"
  type        = bool
  default     = true
}

variable "publicly_accessible" {
  description = "Whether the database should be publicly accessible"
  type        = bool
  default     = false
}

variable "apply_immediately" {
  description = "Apply changes immediately instead of during maintenance window"
  type        = bool
  default     = false
}

variable "aurora_instance_count" {
  description = "Number of Aurora instances (including writer)"
  type        = number
  default     = 1
}

variable "parameter_group_family" {
  description = "Parameter group family (auto-detected if not specified)"
  type        = string
  default     = ""
}

variable "parameter_overrides" {
  description = "Map of parameter name to value to override defaults"
  type        = map(string)
  default     = {}
}

variable "performance_insights_enabled" {
  description = "Enable Performance Insights"
  type        = bool
  default     = false
}

variable "monitoring_interval" {
  description = "Enhanced monitoring interval in seconds (0 to disable)"
  type        = number
  default     = 0
}

variable "maintenance_window" {
  description = "Preferred maintenance window"
  type        = string
  default     = "sun:03:00-sun:04:00"
}

variable "backup_window" {
  description = "Preferred backup window"
  type        = string
  default     = "02:00-03:00"
}
