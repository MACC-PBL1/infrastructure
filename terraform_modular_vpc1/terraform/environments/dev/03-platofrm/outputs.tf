output "nat_bastion_public_ip" {
  value = module.nat_bastion.public_ip
}

output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "api_gateway_url" {
  value = module.api_gateway.api_gateway_url
}

output "aurora_writer_endpoint" {
  value = module.rds.writer_endpoint
}

output "aurora_reader_endpoint" {
  value = module.rds.reader_endpoint
}
# =========================
# Logging outputs
# =========================

output "logs_s3_bucket_name" {
  description = "S3 bucket where Zeek logs are stored"
  value       = module.logs_s3.bucket_name
}

output "firehose_zeek_name" {
  description = "Firehose stream name for Zeek logs"
  value       = module.firehose_zeek.firehose_name
}

output "firehose_zeekflowmeter_name" {
  description = "Firehose stream name for ZeekFlowMeter logs"
  value       = module.firehose_zeekflowmeter.firehose_name
}

output "firehose_zeek_arn" {
  value = module.firehose_zeek.firehose_arn
}

output "firehose_zeekflowmeter_arn" {
  value = module.firehose_zeekflowmeter.firehose_arn
}