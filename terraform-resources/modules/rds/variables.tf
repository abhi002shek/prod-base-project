variable "environment" {
  description = "Environment name"
  type        = string
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "master_username" {
  description = "Master username"
  type        = string
}

variable "master_password" {
  description = "Master password"
  type        = string
  sensitive   = true
}

variable "subnet_ids" {
  description = "Subnet IDs for DB subnet group"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID for RDS"
  type        = string
}

variable "engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "15.5"
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.medium"
}

variable "allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 100
}

variable "max_allocated_storage" {
  description = "Maximum allocated storage for autoscaling"
  type        = number
  default     = 500
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment"
  type        = bool
  default     = true
}

variable "backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 30
}

variable "backup_window" {
  description = "Backup window"
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "Maintenance window"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "performance_insights_enabled" {
  description = "Enable Performance Insights"
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot on deletion"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
