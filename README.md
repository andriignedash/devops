# Terraform RDS/Aurora Module Homework

This repository contains a reusable Terraform module for AWS RDS and Aurora databases.

## Structure

```
.
├── main.tf                  # Root module configuration
├── variables.tf             # Root variables
├── outputs.tf               # Root outputs
├── backend.tf               # Terraform backend configuration
├── terraform.tfvars.example # Example variables file
└── modules/
    ├── vpc/                 # VPC module
    └── rds/                 # RDS/Aurora module
```

## Backend Configuration

This project uses **local backend** by default to avoid accidental costs during homework evaluation. For production use, switch to S3 + DynamoDB backend:

```hcl
terraform {
  backend "s3" {
    bucket         = "your-tfstate-bucket"
    key            = "rds-module/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
```

## Quick Start

1. Initialize Terraform:

```bash
terraform init
```

2. Copy and configure variables:

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
```

3. Plan without creating DB (default):

```bash
terraform plan
```

4. Plan with DB creation:

```bash
terraform plan -var="create_db=true" -var="db_password=YourSecurePassword123!"
```

5. Apply:

```bash
terraform apply
```

## Module Features

### RDS Module (modules/rds)

- Supports both single RDS instances and Aurora clusters
- PostgreSQL and MySQL engines
- Automatic parameter group family detection
- Configurable security groups
- Encryption enabled by default
- Performance Insights support

See [modules/rds/README.md](modules/rds/README.md) for detailed documentation.

## Variables

| Variable | Description | Default |
|----------|-------------|---------|
| aws_region | AWS region | us-west-2 |
| project | Project name for resource naming | db-module-hw |
| create_db | Whether to create database | false |
| use_aurora | Use Aurora instead of RDS | false |
| db_engine | Database engine (postgres/mysql) | postgres |
| db_password | Database password (required if create_db=true) | "" |

See `variables.tf` for complete list.

## Outputs

When `create_db=true`:

- `db_endpoint` - Database endpoint
- `db_reader_endpoint` - Aurora reader endpoint (Aurora only)
- `db_port` - Database port
- `db_security_group_id` - Security group ID
- `db_connection_string` - Connection string template

## Examples

### Create PostgreSQL RDS instance

```bash
terraform apply \
  -var="create_db=true" \
  -var="db_password=SecurePass123!" \
  -var="db_engine=postgres"
```

### Create Aurora PostgreSQL cluster

```bash
terraform apply \
  -var="create_db=true" \
  -var="use_aurora=true" \
  -var="aurora_instance_count=2" \
  -var="db_instance_class=db.r6g.large" \
  -var="db_password=SecurePass123!"
```

### Create MySQL RDS instance

```bash
terraform apply \
  -var="create_db=true" \
  -var="db_engine=mysql" \
  -var="db_password=SecurePass123!"
```

## Cleanup

```bash
terraform destroy
```
