variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for EKS control plane"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "All private subnet IDs"
  type        = list(string)
}

variable "frontend_subnet_ids" {
  description = "Frontend subnet IDs for worker nodes"
  type        = list(string)
}

variable "backend_subnet_ids" {
  description = "Backend subnet IDs for worker nodes"
  type        = list(string)
}

variable "cluster_security_group_id" {
  description = "Security group ID for EKS cluster"
  type        = string
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
  description = "List of control plane logging types to enable"
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

variable "secrets_manager_arns" {
  description = "ARNs of Secrets Manager secrets to grant access"
  type        = list(string)
  default     = ["*"]
}

variable "vpc_cni_version" {
  description = "VPC CNI addon version"
  type        = string
  default     = "v1.21.1-eksbuild.3"
}

variable "coredns_version" {
  description = "CoreDNS addon version"
  type        = string
  default     = "v1.11.4-eksbuild.28"
}

variable "kube_proxy_version" {
  description = "Kube-proxy addon version"
  type        = string
  default     = "v1.32.11-eksbuild.5"
}

variable "ebs_csi_version" {
  description = "EBS CSI driver addon version"
  type        = string
  default     = "v1.56.0-eksbuild.1"
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
