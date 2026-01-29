variable "cluster_name" {
  type        = string
  description = "EKS cluster name"
}

variable "cluster_endpoint" {
  type        = string
  description = "EKS cluster endpoint"
}

variable "cluster_ca" {
  type        = string
  description = "EKS cluster certificate authority data"
  sensitive   = true
}

variable "namespace" {
  type        = string
  default     = "jenkins"
  description = "Kubernetes namespace for Jenkins"
}

variable "chart_version" {
  type        = string
  default     = "5.8.3"
  description = "Jenkins Helm chart version"
}

variable "service_type" {
  type        = string
  default     = "ClusterIP"
  description = "Kubernetes service type (ClusterIP, LoadBalancer, NodePort)"
}

variable "ecr_repository_url" {
  type        = string
  description = "ECR repository URL for pushing images"
}

variable "region" {
  type        = string
  default     = "us-west-2"
  description = "AWS region"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to resources"
}
