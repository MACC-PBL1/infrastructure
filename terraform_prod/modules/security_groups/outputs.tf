output "bastion_sg_id" {
  value = aws_security_group.bastion.id
}

output "haproxy_sg_id" {
  value = aws_security_group.haproxy.id
}

output "microservices_sg_id" {
  value = aws_security_group.microservices.id
}
output "rds_sg_id" {
  description = "Security group ID for RDS"
  value       = aws_security_group.rds.id
}
