variable "chart_version" {
  description = "kube-prometheus-stack Helm chart version"
  type        = string
  default     = "55.5.0"
}

variable "namespace_labels" {
  description = "Labels for the namespace"
  type        = map(string)
  default     = {}
}
