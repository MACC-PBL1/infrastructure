###############################################
# OUTPUTS
###############################################

output "api_gateway_url" {
  description = "Invoke URL for HTTP API (public entrypoint)"
  value       = module.api_gateway.api_url
}

output "nat_bastion_public_ip" {
  description = "Public IP of NAT+Bastion instance"
  value       = module.nat_bastion.public_ip
}

output "alb_dns_name" {
  description = "Internal ALB DNS (reachable only inside VPC)"
  value       = module.alb.alb_dns_name
}

output "aurora_writer_endpoint" {
  description = "Aurora writer endpoint"
  value       = module.rds.writer_endpoint
}

output "aurora_reader_endpoint" {
  description = "Aurora reader endpoint"
  value       = module.rds.reader_endpoint
}
