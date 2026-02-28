variable "environment" {
  description = "Environment name"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for bastion host"
  type        = string
}

variable "security_group_id" {
  description = "Security group ID for bastion"
  type        = string
}

variable "instance_type" {
  description = "Instance type for bastion"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
