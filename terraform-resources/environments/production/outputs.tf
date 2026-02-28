# VPC Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_frontend_subnet_ids" {
  description = "Private frontend subnet IDs"
  value       = module.vpc.private_frontend_subnet_ids
}

output "private_backend_subnet_ids" {
  description = "Private backend subnet IDs"
  value       = module.vpc.private_backend_subnet_ids
}

output "private_database_subnet_ids" {
  description = "Private database subnet IDs"
  value       = module.vpc.private_database_subnet_ids
}

# EKS Outputs
output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_version" {
  description = "EKS cluster version"
  value       = module.eks.cluster_version
}

output "eks_oidc_provider_arn" {
  description = "OIDC provider ARN for IRSA"
  value       = module.eks.oidc_provider_arn
}

output "configure_kubectl" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.aws_region}"
}

# Bastion Outputs
output "bastion_public_ip" {
  description = "Bastion public IP"
  value       = module.bastion.bastion_public_ip
}

output "bastion_ssh_command" {
  description = "SSH command to connect to bastion"
  value       = "ssh -i ~/.ssh/${var.key_name}.pem ec2-user@${module.bastion.bastion_public_ip}"
}

# RDS Outputs
output "rds_endpoint" {
  description = "RDS endpoint"
  value       = module.rds.db_instance_endpoint
  sensitive   = true
}

output "rds_database_name" {
  description = "RDS database name"
  value       = module.rds.db_name
}

# Secrets Manager Outputs
output "secrets_manager_arn" {
  description = "Secrets Manager ARN"
  value       = module.secrets.secret_arn
}

output "secrets_manager_name" {
  description = "Secrets Manager name"
  value       = module.secrets.secret_name
}
