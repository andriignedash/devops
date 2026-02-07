output "grafana_service_name" {
  description = "Grafana service name"
  value       = "${helm_release.kube_prometheus_stack.name}-grafana"
}

output "prometheus_service_name" {
  description = "Prometheus server service name"
  value       = "kube-prometheus-stack-prometheus"
}

output "namespace" {
  description = "Monitoring namespace"
  value       = kubernetes_namespace.monitoring.metadata[0].name
}

output "grafana_admin_password" {
  description = "Grafana admin password (from secret)"
  value       = try(base64decode(data.kubernetes_secret.grafana_admin.data["admin-password"]), null)
  sensitive   = true
}

output "port_forward_grafana_command" {
  description = "Command to port-forward Grafana"
  value       = "kubectl port-forward svc/grafana 3000:80 -n monitoring"
}
