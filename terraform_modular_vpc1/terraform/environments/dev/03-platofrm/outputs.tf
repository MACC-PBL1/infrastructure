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
