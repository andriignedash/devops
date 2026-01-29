output "namespace" {
  value       = kubernetes_namespace.argocd.metadata[0].name
  description = "Argo CD namespace"
}

output "server_service_name" {
  value       = "argocd-server"
  description = "Argo CD server service name"
}

output "admin_password_secret" {
  value       = "argocd-initial-admin-secret"
  description = "Secret name containing Argo CD admin password"
}

output "argocd_url_internal" {
  value       = "http://argocd-server.${kubernetes_namespace.argocd.metadata[0].name}.svc.cluster.local"
  description = "Internal Argo CD URL"
}

output "port_forward_command" {
  value       = "kubectl port-forward -n ${kubernetes_namespace.argocd.metadata[0].name} svc/argocd-server 8081:80"
  description = "Command to port-forward Argo CD UI"
}
