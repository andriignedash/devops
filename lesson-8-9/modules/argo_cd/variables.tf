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
  default     = "argocd"
  description = "Kubernetes namespace for Argo CD"
}

variable "chart_version" {
  type        = string
  default     = "7.7.8"
  description = "Argo CD Helm chart version"
}

variable "gitops_repo_url" {
  type        = string
  description = "GitOps repository URL"
}

variable "gitops_branch" {
  type        = string
  default     = "main"
  description = "GitOps repository branch"
}

variable "app_namespace" {
  type        = string
  default     = "django"
  description = "Namespace for deployed applications"
}

variable "app_chart_path" {
  type        = string
  default     = "charts/django-app"
  description = "Path to application Helm chart in GitOps repo"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to resources"
}
