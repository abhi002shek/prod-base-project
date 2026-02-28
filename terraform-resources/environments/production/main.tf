locals {
  cluster_name = "${var.environment}-${var.project_name}-eks"
  
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

# VPC Module
module "vpc" {
  source = "../../modules/vpc"

  environment              = var.environment
  vpc_cidr                 = var.vpc_cidr
  availability_zones       = var.availability_zones
  public_subnet_cidrs      = var.public_subnet_cidrs
  private_frontend_cidrs   = var.private_frontend_cidrs
  private_backend_cidrs    = var.private_backend_cidrs
  private_database_cidrs   = var.private_database_cidrs
  enable_nat_gateway       = var.enable_nat_gateway
  enable_flow_logs         = var.enable_flow_logs
  cluster_name             = local.cluster_name
  tags                     = local.common_tags
}

# Security Groups Module
module "security_groups" {
  source = "../../modules/security-groups"

  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  cluster_name       = local.cluster_name
  allowed_ssh_cidrs  = var.allowed_ssh_cidrs
  tags               = local.common_tags
}

# EKS Module
module "eks" {
  source = "../../modules/eks"

  cluster_name              = local.cluster_name
  cluster_version           = var.cluster_version
  public_subnet_ids         = module.vpc.public_subnet_ids
  private_subnet_ids        = concat(module.vpc.private_frontend_subnet_ids, module.vpc.private_backend_subnet_ids)
  frontend_subnet_ids       = module.vpc.private_frontend_subnet_ids
  backend_subnet_ids        = module.vpc.private_backend_subnet_ids
  cluster_security_group_id = module.security_groups.eks_cluster_sg_id
  endpoint_public_access    = var.endpoint_public_access
  public_access_cidrs       = var.public_access_cidrs
  enabled_log_types         = var.enabled_log_types
  log_retention_days        = var.log_retention_days
  
  frontend_desired_size     = var.frontend_desired_size
  frontend_min_size         = var.frontend_min_size
  frontend_max_size         = var.frontend_max_size
  frontend_instance_types   = var.frontend_instance_types
  
  backend_desired_size      = var.backend_desired_size
  backend_min_size          = var.backend_min_size
  backend_max_size          = var.backend_max_size
  backend_instance_types    = var.backend_instance_types
  
  capacity_type             = var.capacity_type
  node_disk_size            = var.node_disk_size
  secrets_manager_arns      = [module.secrets.secret_arn]
  
  tags = local.common_tags
}

# Bastion Module
module "bastion" {
  source = "../../modules/bastion"

  environment       = var.environment
  subnet_id         = module.vpc.public_subnet_ids[0]
  security_group_id = module.security_groups.bastion_sg_id
  instance_type     = var.bastion_instance_type
  key_name          = var.key_name
  cluster_name      = local.cluster_name
  aws_region        = var.aws_region
  tags              = local.common_tags
}

# RDS Module
module "rds" {
  source = "../../modules/rds"

  environment                 = var.environment
  db_name                     = var.db_name
  master_username             = var.db_master_username
  master_password             = var.db_master_password
  subnet_ids                  = module.vpc.private_database_subnet_ids
  security_group_id           = module.security_groups.rds_sg_id
  engine_version              = var.db_engine_version
  instance_class              = var.db_instance_class
  allocated_storage           = var.db_allocated_storage
  max_allocated_storage       = var.db_max_allocated_storage
  multi_az                    = var.db_multi_az
  backup_retention_period     = var.db_backup_retention_period
  backup_window               = var.db_backup_window
  maintenance_window          = var.db_maintenance_window
  performance_insights_enabled = var.db_performance_insights_enabled
  deletion_protection         = var.db_deletion_protection
  skip_final_snapshot         = var.db_skip_final_snapshot
  tags                        = local.common_tags
}

# Secrets Manager Module
module "secrets" {
  source = "../../modules/secrets"

  environment             = var.environment
  secret_name             = "db-credentials"
  db_username             = var.db_master_username
  db_password             = var.db_master_password
  db_host                 = module.rds.db_instance_address
  db_port                 = module.rds.db_instance_port
  db_name                 = module.rds.db_name
  recovery_window_in_days = 7
  tags                    = local.common_tags
}
