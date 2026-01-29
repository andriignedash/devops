output "namespace" {
  value       = kubernetes_namespace.jenkins.metadata[0].name
  description = "Jenkins namespace"
}

output "service_name" {
  value       = "jenkins"
  description = "Jenkins service name"
}

output "admin_password_secret" {
  value       = "jenkins"
  description = "Secret name containing Jenkins admin password"
}

output "jenkins_url_internal" {
  value       = "http://jenkins.${kubernetes_namespace.jenkins.metadata[0].name}.svc.cluster.local:8080"
  description = "Internal Jenkins URL"
}

output "port_forward_command" {
  value       = "kubectl port-forward -n ${kubernetes_namespace.jenkins.metadata[0].name} svc/jenkins 8080:8080"
  description = "Command to port-forward Jenkins UI"
}
