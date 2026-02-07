output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = module.ecr.repository_url
}

output "db_endpoint" {
  description = "Database endpoint"
  value       = var.create_db ? module.rds[0].endpoint : null
}

output "db_reader_endpoint" {
  description = "Aurora reader endpoint (Aurora only)"
  value       = var.create_db && var.use_aurora ? module.rds[0].reader_endpoint : null
}

output "db_port" {
  description = "Database port"
  value       = var.create_db ? module.rds[0].port : null
}

output "jenkins_namespace" {
  description = "Jenkins namespace"
  value       = module.jenkins.namespace
}

output "jenkins_service_name" {
  description = "Jenkins service name"
  value       = module.jenkins.service_name
}

output "jenkins_port_forward_command" {
  description = "Command to port-forward Jenkins"
  value       = module.jenkins.port_forward_command
}

output "argocd_namespace" {
  description = "Argo CD namespace"
  value       = module.argo_cd.namespace
}

output "argocd_server_service" {
  description = "Argo CD server service name"
  value       = module.argo_cd.argocd_server_service
}

output "argocd_port_forward_command" {
  description = "Command to port-forward Argo CD"
  value       = module.argo_cd.port_forward_command
}

output "grafana_namespace" {
  description = "Grafana (monitoring) namespace"
  value       = module.monitoring.namespace
}

output "grafana_service_name" {
  description = "Grafana service name"
  value       = module.monitoring.grafana_service_name
}

output "grafana_port_forward_command" {
  description = "Command to port-forward Grafana"
  value       = module.monitoring.port_forward_grafana_command
}

output "prometheus_service_name" {
  description = "Prometheus service name"
  value       = module.monitoring.prometheus_service_name
}
