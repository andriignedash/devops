resource "aws_db_subnet_group" "this" {
  name        = "${var.name}-db-subnet-group"
  description = "Subnet group for ${var.name} database"
  subnet_ids  = var.subnet_ids

  tags = merge(local.common_tags, {
    Name = "${var.name}-db-subnet-group"
  })
}

resource "aws_security_group" "this" {
  name        = "${var.name}-db-sg"
  description = "Security group for ${var.name} database"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, {
    Name = "${var.name}-db-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "ingress_cidr" {
  count = length(var.allowed_cidrs) > 0 ? 1 : 0

  type              = "ingress"
  from_port         = local.port
  to_port           = local.port
  protocol          = "tcp"
  cidr_blocks       = var.allowed_cidrs
  security_group_id = aws_security_group.this.id
  description       = "Allow DB access from specified CIDRs"
}

resource "aws_security_group_rule" "ingress_sg" {
  count = length(var.allowed_security_group_ids)

  type                     = "ingress"
  from_port                = local.port
  to_port                  = local.port
  protocol                 = "tcp"
  source_security_group_id = var.allowed_security_group_ids[count.index]
  security_group_id        = aws_security_group.this.id
  description              = "Allow DB access from security group"
}

resource "aws_security_group_rule" "egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.this.id
  description       = "Allow all outbound traffic"
}

resource "aws_db_parameter_group" "this" {
  count = var.use_aurora ? 0 : 1

  name        = "${var.name}-db-params"
  family      = local.parameter_group_family
  description = "Parameter group for ${var.name} RDS instance"

  dynamic "parameter" {
    for_each = local.merged_params
    content {
      name         = parameter.key
      value        = parameter.value
      apply_method = "pending-reboot"
    }
  }

  tags = merge(local.common_tags, {
    Name = "${var.name}-db-params"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_rds_cluster_parameter_group" "this" {
  count = var.use_aurora ? 1 : 0

  name        = "${var.name}-cluster-params"
  family      = local.parameter_group_family
  description = "Cluster parameter group for ${var.name} Aurora cluster"

  dynamic "parameter" {
    for_each = local.merged_params
    content {
      name         = parameter.key
      value        = parameter.value
      apply_method = "pending-reboot"
    }
  }

  tags = merge(local.common_tags, {
    Name = "${var.name}-cluster-params"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_parameter_group" "aurora_instance" {
  count = var.use_aurora ? 1 : 0

  name        = "${var.name}-aurora-instance-params"
  family      = local.parameter_group_family
  description = "Instance parameter group for ${var.name} Aurora instances"

  tags = merge(local.common_tags, {
    Name = "${var.name}-aurora-instance-params"
  })

  lifecycle {
    create_before_destroy = true
  }
}
