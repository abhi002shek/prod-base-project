variable "environment" {
  description = "Environment name"
  type        = string
}

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
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = true
}

variable "cluster_name" {
  description = "EKS cluster name for subnet tagging"
  type        = string
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
