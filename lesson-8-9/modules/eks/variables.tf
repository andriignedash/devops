variable "cluster_name" {
  type        = string
  description = "Name of the EKS cluster"
}

variable "cluster_version" {
  type        = string
  default     = "1.29"
  description = "Kubernetes version"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where EKS will be deployed"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs for EKS nodes"
}

variable "desired_size" {
  type        = number
  default     = 2
  description = "Desired number of nodes"
}

variable "min_size" {
  type        = number
  default     = 2
  description = "Minimum number of nodes"
}

variable "max_size" {
  type        = number
  default     = 6
  description = "Maximum number of nodes"
}

variable "instance_types" {
  type        = list(string)
  default     = ["t3.medium"]
  description = "Instance types for EKS nodes"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to all resources"
}
