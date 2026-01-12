output "az1_public_private_ips" {
  value = module.ec2_az1_public.private_ips
}

output "az1_private_ips" {
  value = module.ec2_az1_private.private_ips
}

output "az2_private_ips" {
  value = module.ec2_az2_private.private_ips
}

output "all_instance_ips" {
  value = {
    az1_public  = module.ec2_az1_public.private_ips
    az1_private = module.ec2_az1_private.private_ips
    az2_private = module.ec2_az2_private.private_ips
  }
}

output "s3_logs_bucket_name" {
  value = module.s3_logs.bucket_name
}

output "firehose_honeypots" {
  value = module.firehose_honeypots.stream_name
}

output "firehose_microservices" {
  value = module.firehose_microservices.stream_name
}

output "dynamodb_table_name" {
  value = module.dynamodb.table_name
}

# ============================================
# CROSS-VPC: Instance IDs para registro en ALB
# ============================================

output "az1_public_instance_ids" {
  description = "Instance IDs of AZ1 public instances"
  value       = module.ec2_az1_public.instance_ids
}

output "az1_private_instance_ids" {
  description = "Instance IDs of AZ1 private instances"
  value       = module.ec2_az1_private.instance_ids
}

output "az2_private_instance_ids" {
  description = "Instance IDs of AZ2 private instances"
  value       = module.ec2_az2_private.instance_ids
}

output "all_instances_info" {
  description = "Complete information about all instances"
  value = {
    az1_public  = module.ec2_az1_public.instances_info
    az1_private = module.ec2_az1_private.instances_info
    az2_private = module.ec2_az2_private.instances_info
  }
}

# Helper: Instancias Auth para registrar en ALB
output "auth_microservice_ids" {
  description = "Instance IDs of Auth-Log-Microservice instances"
  value = {
    for name, info in merge(
      module.ec2_az1_private.instances_info,
      module.ec2_az2_private.instances_info
    ) : name => info.id
    if can(regex("Auth-Log-Microservice", name))
  }
}