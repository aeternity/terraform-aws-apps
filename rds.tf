locals {
  rds_name      = "superhero"
  postgres_tags = merge({ "Name" : local.rds_name }, local.standard_tags)
}

module "superhero-backend-postgres-sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.4.0"

  name        = local.rds_name
  description = "Superhero backend PostgreSQL example security group"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      description = "PostgreSQL access from within VPC"
      cidr_blocks = module.vpc.vpc_cidr_block
    },
  ]
  egress_rules = ["all-all"]
  tags         = local.postgres_tags
}

module "superhero-backend-postgres" {
  source  = "terraform-aws-modules/rds/aws"
  version = "3.4.0"

  identifier = local.rds_name

  engine               = "postgres"
  engine_version       = "12.8"
  family               = "postgres12"
  major_engine_version = "12"
  instance_class       = "db.t2.small"

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_encrypted     = false

  name     = local.rds_name
  username = "postgres"
  #should be handled as secret - working on it
  password = ""
  port     = 5432

  multi_az               = true
  subnet_ids             = module.vpc.private_subnets
  vpc_security_group_ids = [module.superhero-backend-postgres-sg.security_group_id]

  maintenance_window              = "Mon:00:00-Mon:03:00"
  backup_window                   = "03:00-06:00"
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  backup_retention_period = 0
  skip_final_snapshot     = true
  deletion_protection     = false

  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  create_monitoring_role                = true
  monitoring_interval                   = 60
  monitoring_role_name                  = local.rds_name
  monitoring_role_description           = "Superhero Backend postgres for monitoring role"

  parameters = [
    {
      name  = "autovacuum"
      value = 1
    },
    {
      name  = "client_encoding"
      value = "utf8"
    }
  ]

  tags = local.postgres_tags
  db_option_group_tags = {
    "Sensitive" = "low"
  }
  db_parameter_group_tags = {
    "Sensitive" = "low"
  }
  db_subnet_group_tags = {
    "Sensitive" = "high"
  }
}
