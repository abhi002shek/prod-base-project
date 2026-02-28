variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed to SSH to bastion"
  type        = list(string)
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
