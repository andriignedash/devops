output "endpoint" {
  description = "Database endpoint (RDS instance endpoint or Aurora cluster endpoint)"
  value       = var.use_aurora ? aws_rds_cluster.this[0].endpoint : aws_db_instance.this[0].endpoint
}

output "reader_endpoint" {
  description = "Aurora cluster reader endpoint (only for Aurora)"
  value       = var.use_aurora ? aws_rds_cluster.this[0].reader_endpoint : null
}

output "port" {
  description = "Database port"
  value       = local.port
}

output "security_group_id" {
  description = "Security group ID for the database"
  value       = aws_security_group.this.id
}

output "subnet_group_name" {
  description = "DB subnet group name"
  value       = aws_db_subnet_group.this.name
}

output "db_identifier" {
  description = "RDS instance identifier (only for non-Aurora)"
  value       = var.use_aurora ? null : aws_db_instance.this[0].identifier
}

output "cluster_id" {
  description = "Aurora cluster identifier (only for Aurora)"
  value       = var.use_aurora ? aws_rds_cluster.this[0].cluster_identifier : null
}

output "db_name" {
  description = "Name of the default database"
  value       = var.db_name
}

output "username" {
  description = "Master username"
  value       = var.username
}

output "engine" {
  description = "Database engine"
  value       = var.use_aurora ? local.aurora_engine : var.engine
}

output "engine_version" {
  description = "Database engine version"
  value       = local.engine_version
}

output "parameter_group_name" {
  description = "Parameter group name"
  value       = var.use_aurora ? aws_rds_cluster_parameter_group.this[0].name : aws_db_parameter_group.this[0].name
}

output "connection_string" {
  description = "Database connection string template"
  value       = var.use_aurora ? "${var.engine}://${var.username}:<password>@${aws_rds_cluster.this[0].endpoint}:${local.port}/${var.db_name}" : "${var.engine}://${var.username}:<password>@${aws_db_instance.this[0].endpoint}/${var.db_name}"
  sensitive   = false
}
