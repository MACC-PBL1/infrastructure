############################################
# Networking
############################################
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_id" {
  description = "Public subnet ID"
  value       = module.vpc.public_subnet_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

############################################
# Bastion
############################################
output "bastion_public_ip" {
  description = "Public IP address of the bastion host"
  value       = module.bastion.bastion_public_ip
}

output "bastion_private_ip" {
  description = "Private IP address of the bastion host"
  value       = module.bastion.bastion_private_ip
}

############################################
# HAProxy
############################################
output "haproxy_public_ip" {
  description = "Public IP address of the HAProxy instance"
  value       = module.haproxy.haproxy_public_ip
}

output "haproxy_private_ip" {
  description = "Private IP address of the HAProxy instance"
  value       = module.haproxy.haproxy_private_ip
}

############################################
# Microservices (private subnet)
############################################
output "microservices_private_ips" {
  description = "Private IPs of microservices instances"
  value       = module.microservices.microservices_private_ips
}

output "microservices_instance_ids" {
  description = "Instance IDs of microservices"
  value       = module.microservices.microservices_instance_ids
}

############################################
# RDS
############################################
output "rds_endpoint" {
  description = "RDS endpoint"
  value       = module.rds.rds_endpoint
}

output "rds_port" {
  description = "RDS port"
  value       = module.rds.rds_port
}

output "rds_db_name" {
  description = "RDS database name"
  value       = module.rds.rds_db_name
}
