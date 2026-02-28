# General
variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

# VPC
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
}

variable "private_frontend_cidrs" {
  description = "CIDR blocks for private frontend subnets"
  type        = list(string)
}

variable "private_backend_cidrs" {
  description = "CIDR blocks for private backend subnets"
  type        = list(string)
}

variable "private_database_cidrs" {
  description = "CIDR blocks for private database subnets"
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway"
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = true
}

# Security
variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed to SSH to bastion"
  type        = list(string)
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
}

# EKS
variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}

variable "endpoint_public_access" {
  description = "Enable public API server endpoint"
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "CIDR blocks allowed to access public endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enabled_log_types" {
  description = "List of control plane logging types"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

variable "frontend_desired_size" {
  description = "Desired number of frontend nodes"
  type        = number
  default     = 2
}

variable "frontend_min_size" {
  description = "Minimum number of frontend nodes"
  type        = number
  default     = 2
}

variable "frontend_max_size" {
  description = "Maximum number of frontend nodes"
  type        = number
  default     = 4
}

variable "backend_desired_size" {
  description = "Desired number of backend nodes"
  type        = number
  default     = 2
}

variable "backend_min_size" {
  description = "Minimum number of backend nodes"
  type        = number
  default     = 2
}

variable "backend_max_size" {
  description = "Maximum number of backend nodes"
  type        = number
  default     = 6
}

variable "frontend_instance_types" {
  description = "Instance types for frontend nodes"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "backend_instance_types" {
  description = "Instance types for backend nodes"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "capacity_type" {
  description = "Capacity type (ON_DEMAND or SPOT)"
  type        = string
  default     = "ON_DEMAND"
}

variable "node_disk_size" {
  description = "Disk size for worker nodes in GB"
  type        = number
  default     = 50
}

# Bastion
variable "bastion_instance_type" {
  description = "Instance type for bastion"
  type        = string
  default     = "t3.micro"
}

# RDS
variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_master_username" {
  description = "Database master username"
  type        = string
}

variable "db_master_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

variable "db_engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "15.5"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.medium"
}

variable "db_allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 100
}

variable "db_max_allocated_storage" {
  description = "Maximum allocated storage"
  type        = number
  default     = 500
}

variable "db_multi_az" {
  description = "Enable Multi-AZ"
  type        = bool
  default     = true
}

variable "db_backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 30
}

variable "db_backup_window" {
  description = "Backup window"
  type        = string
  default     = "03:00-04:00"
}

variable "db_maintenance_window" {
  description = "Maintenance window"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "db_performance_insights_enabled" {
  description = "Enable Performance Insights"
  type        = bool
  default     = true
}

variable "db_deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = true
}

variable "db_skip_final_snapshot" {
  description = "Skip final snapshot"
  type        = bool
  default     = false
}
