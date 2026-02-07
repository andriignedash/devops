output "argocd_server_service" {
  description = "Argo CD server service name"
  value       = "argo-cd-argocd-server"
}

output "namespace" {
  description = "Argo CD namespace"
  value       = kubernetes_namespace.argocd.metadata[0].name
}

output "initial_admin_password" {
  description = "Argo CD initial admin password (from secret)"
  value       = try(base64decode(data.kubernetes_secret.argocd_admin.data["password"]), null)
  sensitive   = true
}

output "port_forward_command" {
  description = "Command to port-forward Argo CD server"
  value       = "kubectl port-forward svc/argo-cd-argocd-server 8081:443 -n argocd"
}
