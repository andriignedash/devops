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

output "db_security_group_id" {
  description = "Database security group ID"
  value       = var.create_db ? module.rds[0].security_group_id : null
}

output "db_subnet_group_name" {
  description = "Database subnet group name"
  value       = var.create_db ? module.rds[0].subnet_group_name : null
}

output "db_identifier" {
  description = "Database identifier (RDS instance or Aurora cluster)"
  value       = var.create_db ? (var.use_aurora ? module.rds[0].cluster_id : module.rds[0].db_identifier) : null
}

output "db_connection_string" {
  description = "Database connection string template"
  value       = var.create_db ? module.rds[0].connection_string : null
  sensitive   = false
}
