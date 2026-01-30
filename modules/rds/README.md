# RDS/Aurora Terraform Module

A reusable Terraform module for creating AWS RDS instances or Aurora clusters with PostgreSQL or MySQL engines.

## Features

- Support for both single RDS instances and Aurora clusters
- PostgreSQL and MySQL engine support
- Automatic parameter group family detection
- Configurable parameter groups with sensible defaults
- Security group with flexible ingress rules
- Encryption at rest enabled by default
- Performance Insights support
- Backup and maintenance window configuration

## Usage Examples

### Example 1: Single RDS Instance (use_aurora = false)

```hcl
module "rds" {
  source = "./modules/rds"

  name       = "myapp"
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  use_aurora = false

  engine         = "postgres"
  engine_version = "15.4"
  instance_class = "db.t3.micro"

  db_name  = "appdb"
  username = "dbadmin"
  password = var.db_password

  storage_gb     = 20
  max_storage_gb = 100

  allowed_cidrs = ["10.0.0.0/16"]

  tags = {
    Environment = "dev"
    Project     = "myapp"
  }
}
```

### Example 2: Aurora Cluster (use_aurora = true)

```hcl
module "aurora" {
  source = "./modules/rds"

  name       = "myapp"
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  use_aurora            = true
  aurora_instance_count = 2

  engine         = "postgres"
  engine_version = "15.4"
  instance_class = "db.r6g.large"

  db_name  = "appdb"
  username = "dbadmin"
  password = var.db_password

  allowed_security_group_ids = [aws_security_group.app.id]

  backup_retention_days = 14
  deletion_protection   = true
  skip_final_snapshot   = false

  tags = {
    Environment = "production"
    Project     = "myapp"
  }
}
```

### Example 3: MySQL RDS Instance

```hcl
module "mysql" {
  source = "./modules/rds"

  name       = "myapp-mysql"
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  use_aurora = false

  engine         = "mysql"
  engine_version = "8.0.35"
  instance_class = "db.t3.small"

  db_name  = "appdb"
  username = "dbadmin"
  password = var.db_password

  multi_az   = true
  storage_gb = 50

  parameter_overrides = {
    "max_connections" = "200"
  }

  tags = {
    Environment = "staging"
  }
}
```

## Configuration Guide

### How to change database type (PostgreSQL / MySQL)

Set the `engine` variable:

```hcl
engine = "postgres"
```

```hcl
engine = "mysql"
```

The port is auto-detected: 5432 for PostgreSQL, 3306 for MySQL.

### How to change engine version

Set the `engine_version` variable:

```hcl
engine         = "postgres"
engine_version = "15.4"
```

```hcl
engine         = "postgres"
engine_version = "14.10"
```

```hcl
engine         = "mysql"
engine_version = "8.0.35"
```

If not specified, defaults are used: PostgreSQL 15.4, MySQL 8.0.35.

### How to change instance class

Set the `instance_class` variable:

```hcl
instance_class = "db.t3.micro"
```

```hcl
instance_class = "db.t3.small"
```

```hcl
instance_class = "db.r6g.large"
```

For Aurora, use Aurora-compatible classes (db.r6g.*, db.t3.medium+).

### How to enable Aurora

Set `use_aurora = true` and optionally configure instance count:

```hcl
use_aurora            = true
aurora_instance_count = 2
```

With Aurora:
- Storage is managed automatically (storage_gb is ignored)
- multi_az is not applicable (Aurora handles this automatically)
- reader_endpoint output becomes available

## Variables

| Variable | Description | Type | Default | Required |
|----------|-------------|------|---------|:--------:|
| name | Name prefix for all resources | string | - | yes |
| vpc_id | VPC ID where DB will be created | string | - | yes |
| subnet_ids | List of subnet IDs for the DB subnet group | list(string) | - | yes |
| password | Master password for the database | string | - | yes |
| allowed_cidrs | List of CIDR blocks allowed to connect | list(string) | [] | no |
| allowed_security_group_ids | List of SG IDs allowed to connect | list(string) | [] | no |
| tags | Tags to apply to all resources | map(string) | {} | no |
| use_aurora | Create Aurora cluster instead of RDS | bool | false | no |
| engine | Database engine: postgres or mysql | string | "postgres" | no |
| engine_version | Database engine version | string | "" (auto) | no |
| instance_class | Instance class for RDS/Aurora | string | "db.t3.micro" | no |
| multi_az | Enable Multi-AZ for RDS | bool | false | no |
| db_name | Name of the default database | string | "appdb" | no |
| username | Master username | string | "dbadmin" | no |
| port | Database port (auto-detected) | number | null | no |
| storage_gb | Allocated storage in GB (RDS only) | number | 20 | no |
| max_storage_gb | Max storage for autoscaling (0=disable) | number | 0 | no |
| storage_type | Storage type: gp2, gp3, io1 | string | "gp3" | no |
| backup_retention_days | Backup retention period | number | 7 | no |
| deletion_protection | Enable deletion protection | bool | false | no |
| skip_final_snapshot | Skip final snapshot on destroy | bool | true | no |
| publicly_accessible | Make database publicly accessible | bool | false | no |
| apply_immediately | Apply changes immediately | bool | false | no |
| aurora_instance_count | Number of Aurora instances | number | 1 | no |
| parameter_group_family | Parameter group family (auto-detected) | string | "" | no |
| parameter_overrides | Parameter overrides map | map(string) | {} | no |
| performance_insights_enabled | Enable Performance Insights | bool | false | no |
| monitoring_interval | Enhanced monitoring interval (0=disable) | number | 0 | no |
| maintenance_window | Preferred maintenance window | string | "sun:03:00-sun:04:00" | no |
| backup_window | Preferred backup window | string | "02:00-03:00" | no |

## Outputs

| Output | Description |
|--------|-------------|
| endpoint | Database endpoint |
| reader_endpoint | Aurora reader endpoint (Aurora only) |
| port | Database port |
| security_group_id | Security group ID |
| subnet_group_name | DB subnet group name |
| db_identifier | RDS instance identifier (RDS only) |
| cluster_id | Aurora cluster identifier (Aurora only) |
| db_name | Default database name |
| username | Master username |
| engine | Database engine |
| engine_version | Engine version |
| parameter_group_name | Parameter group name |
| connection_string | Connection string template |

## Default Parameters

### PostgreSQL
- `log_statement`: all
- `log_min_duration_statement`: 1000ms

### MySQL
- `slow_query_log`: 1
- `long_query_time`: 1s

Override defaults using `parameter_overrides` variable:

```hcl
parameter_overrides = {
  "max_connections" = "200"
  "work_mem"        = "64MB"
}
```

## Notes

- Storage encryption is always enabled
- For Aurora, storage is managed automatically (no storage_gb setting)
- Aurora instance_class must be compatible with Aurora (e.g., db.r6g.*, db.t3.medium+)
- Password is marked as sensitive and will not appear in logs
