###############################################
# OUTPUTS
###############################################

output "api_gateway_url" {
  description = "Invoke URL for HTTP API (public entrypoint)"
  value       = aws_apigatewayv2_api.http.api_endpoint
}

output "nat_bastion_public_ip" {
  description = "Public IP of NAT+Bastion instance"
  value       = aws_eip.nat_bastion.public_ip
}

output "alb_dns_name" {
  description = "Internal ALB DNS (reachable only inside VPC)"
  value       = aws_lb.internal.dns_name
}

output "aurora_writer_endpoint" {
  description = "Aurora writer endpoint"
  value       = aws_rds_cluster.aurora.endpoint
}

output "aurora_reader_endpoint" {
  description = "Aurora reader endpoint"
  value       = aws_rds_cluster.aurora.reader_endpoint
}
