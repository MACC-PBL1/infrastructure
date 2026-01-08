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
