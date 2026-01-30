locals {
  is_postgres = var.engine == "postgres"
  is_mysql    = var.engine == "mysql"

  default_port = local.is_postgres ? 5432 : 3306
  port         = coalesce(var.port, local.default_port)

  default_engine_versions = {
    postgres = "15.4"
    mysql    = "8.0.35"
  }
  engine_version = var.engine_version != "" ? var.engine_version : local.default_engine_versions[var.engine]

  aurora_engines = {
    postgres = "aurora-postgresql"
    mysql    = "aurora-mysql"
  }
  aurora_engine = local.aurora_engines[var.engine]

  parameter_group_families = {
    postgres = {
      "15" = "postgres15"
      "14" = "postgres14"
      "13" = "postgres13"
    }
    mysql = {
      "8.0" = "mysql8.0"
      "5.7" = "mysql5.7"
    }
  }

  aurora_parameter_group_families = {
    postgres = {
      "15" = "aurora-postgresql15"
      "14" = "aurora-postgresql14"
      "13" = "aurora-postgresql13"
    }
    mysql = {
      "8.0" = "aurora-mysql8.0"
      "5.7" = "aurora-mysql5.7"
    }
  }

  engine_major_version = regex("^\\d+\\.?\\d*", local.engine_version)

  auto_parameter_family = var.use_aurora ? (
    lookup(local.aurora_parameter_group_families[var.engine], local.engine_major_version, "")
    ) : (
    lookup(local.parameter_group_families[var.engine], local.engine_major_version, "")
  )

  parameter_group_family = var.parameter_group_family != "" ? var.parameter_group_family : local.auto_parameter_family

  base_postgres_params = {
    "log_statement"              = "all"
    "log_min_duration_statement" = "1000"
  }

  base_mysql_params = {
    "slow_query_log"  = "1"
    "long_query_time" = "1"
  }

  base_params = local.is_postgres ? local.base_postgres_params : local.base_mysql_params

  merged_params = merge(local.base_params, var.parameter_overrides)

  common_tags = merge(var.tags, {
    ManagedBy = "terraform"
    Module    = "rds"
  })
}
