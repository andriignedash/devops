resource "aws_db_instance" "this" {
  count = var.use_aurora ? 0 : 1

  identifier = "${var.name}-db"

  engine         = var.engine
  engine_version = local.engine_version
  instance_class = var.instance_class

  allocated_storage     = var.storage_gb
  max_allocated_storage = var.max_storage_gb > 0 ? var.max_storage_gb : null
  storage_type          = var.storage_type
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.username
  password = var.password
  port     = local.port

  multi_az               = var.multi_az
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.this.id]
  parameter_group_name   = aws_db_parameter_group.this[0].name
  publicly_accessible    = var.publicly_accessible

  backup_retention_period = var.backup_retention_days
  backup_window           = var.backup_window
  maintenance_window      = var.maintenance_window

  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.name}-final-snapshot"
  copy_tags_to_snapshot     = true

  apply_immediately = var.apply_immediately

  performance_insights_enabled = var.performance_insights_enabled
  monitoring_interval          = var.monitoring_interval

  tags = merge(local.common_tags, {
    Name = "${var.name}-db"
  })
}
