output "cluster_name" {
  value       = aws_eks_cluster.this.name
  description = "EKS cluster name"
}

output "cluster_endpoint" {
  value       = aws_eks_cluster.this.endpoint
  description = "EKS cluster API endpoint"
}

output "cluster_ca" {
  value       = aws_eks_cluster.this.certificate_authority[0].data
  description = "EKS cluster certificate authority data"
  sensitive   = true
}

output "cluster_arn" {
  value       = aws_eks_cluster.this.arn
  description = "EKS cluster ARN"
}

output "cluster_security_group_id" {
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
  description = "Security group ID attached to the EKS cluster"
}

output "node_group_id" {
  value       = aws_eks_node_group.this.id
  description = "EKS node group ID"
}

output "node_group_arn" {
  value       = aws_eks_node_group.this.arn
  description = "EKS node group ARN"
}
