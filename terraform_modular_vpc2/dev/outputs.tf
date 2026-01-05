# ============================================
# Network Outputs
# ============================================
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = module.vpc.private_subnet_ids
}

# ============================================
# EC2 Instances - AZ1 Public
# ============================================
output "az1_public_private_ips" {
  description = "Private IPs of AZ1 public instances"
  value       = module.ec2_az1_public.private_ips
}

# ============================================
# EC2 Instances - AZ1 Private
# ============================================
output "az1_private_ips" {
  description = "Private IPs of AZ1 private instances"
  value       = module.ec2_az1_private.private_ips
}

# ============================================
# EC2 Instances - AZ2 Private
# ============================================
output "az2_private_ips" {
  description = "Private IPs of AZ2 private instances"
  value       = module.ec2_az2_private.private_ips
}

# ============================================
# DynamoDB
# ============================================
output "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  value       = module.dynamodb.table_name
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table"
  value       = module.dynamodb.table_arn
}

# ============================================
# Security Groups
# ============================================
output "security_group_ids" {
  description = "IDs of created security groups"
  value = {
    micro   = module.security.micro_sg_id
    DynamoDB     = module.security.DynamoDB_sg_id
  }
}

# ============================================
# S3
# ============================================
output "s3_logs_bucket_name" {
  description = "Name of the S3 logs bucket"
  value       = module.s3_logs.bucket_name
}

# ============================================
# Kinesis Firehose 
# ============================================

output "firehose_honeypots" {
  description = "Name of the honeypots Firehose stream"
  value       = module.firehose_honeypots.stream_name
}

output "firehose_microservices" {
  description = "Name of the microservices Firehose stream"
  value       = module.firehose_microservices.stream_name
}

# ============================================
# All Instance IPs (Combined)
# ============================================
output "all_instance_ips" {
  description = "All instance private IPs organized by group"
  value = {
    az1_public = module.ec2_az1_public.private_ips
    az1_private = module.ec2_az1_private.private_ips
    az2_private = module.ec2_az2_private.private_ips
  }
}