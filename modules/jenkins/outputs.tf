output "service_name" {
  description = "Jenkins service name"
  value       = "jenkins"
}

output "namespace" {
  description = "Jenkins namespace"
  value       = kubernetes_namespace.jenkins.metadata[0].name
}

output "admin_password" {
  description = "Jenkins admin password (from secret)"
  value       = try(base64decode(data.kubernetes_secret.jenkins_admin.data["jenkins-admin-password"]), null)
  sensitive   = true
}

output "port_forward_command" {
  description = "Command to port-forward Jenkins"
  value       = "kubectl port-forward svc/jenkins 8080:8080 -n jenkins"
}
