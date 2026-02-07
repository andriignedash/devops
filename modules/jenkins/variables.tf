variable "chart_version" {
  description = "Jenkins Helm chart version"
  type        = string
  default     = "4.6.1"
}

variable "namespace_labels" {
  description = "Labels for the namespace"
  type        = map(string)
  default     = {}
}
