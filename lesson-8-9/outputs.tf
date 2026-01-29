output "state_bucket_name" {
  value = module.s3_backend.bucket_name
}

output "lock_table_name" {
  value = module.s3_backend.dynamodb_table_name
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

output "ecr_repository_url" {
  value       = module.ecr.repository_url
  description = "ECR repository URL for pushing Docker images"
}

output "cluster_name" {
  value       = module.eks.cluster_name
  description = "EKS cluster name"
}

output "cluster_endpoint" {
  value       = module.eks.cluster_endpoint
  description = "EKS cluster API endpoint"
}

output "cluster_security_group_id" {
  value       = module.eks.cluster_security_group_id
  description = "Security group ID for EKS cluster"
}

output "jenkins_namespace" {
  value       = module.jenkins.namespace
  description = "Jenkins namespace"
}

output "jenkins_port_forward" {
  value       = module.jenkins.port_forward_command
  description = "Command to port-forward Jenkins UI"
}

output "jenkins_admin_password_command" {
  value       = "kubectl get secret -n ${module.jenkins.namespace} ${module.jenkins.admin_password_secret} -o jsonpath='{.data.jenkins-admin-password}' | base64 -d"
  description = "Command to get Jenkins admin password"
}

output "argocd_namespace" {
  value       = module.argo_cd.namespace
  description = "Argo CD namespace"
}

output "argocd_port_forward" {
  value       = module.argo_cd.port_forward_command
  description = "Command to port-forward Argo CD UI"
}

output "argocd_admin_password_command" {
  value       = "kubectl get secret -n ${module.argo_cd.namespace} ${module.argo_cd.admin_password_secret} -o jsonpath='{.data.password}' | base64 -d"
  description = "Command to get Argo CD admin password"
}
