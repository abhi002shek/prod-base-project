output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_frontend_subnet_ids" {
  description = "Private frontend subnet IDs"
  value       = aws_subnet.private_frontend[*].id
}

output "private_backend_subnet_ids" {
  description = "Private backend subnet IDs"
  value       = aws_subnet.private_backend[*].id
}

output "private_database_subnet_ids" {
  description = "Private database subnet IDs"
  value       = aws_subnet.private_database[*].id
}

output "nat_gateway_ids" {
  description = "NAT Gateway IDs"
  value       = aws_nat_gateway.main[*].id
}
