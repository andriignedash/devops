variable "chart_version" {
  description = "Argo CD Helm chart version"
  type        = string
  default     = "5.51.6"
}

variable "namespace_labels" {
  description = "Labels for the namespace"
  type        = map(string)
  default     = {}
}

variable "gitops_repo_url" {
  description = "Git repo URL for Argo CD applications"
  type        = string
  default     = "https://github.com/REPLACE_ME/REPLACE_ME.git"
}
