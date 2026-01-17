output "instance_id" {
  description = "Grafana instance ID"
  value       = aws_instance.grafana.id
}

output "private_ip" {
  description = "Grafana private IP address"
  value       = aws_instance.grafana.private_ip
}

output "security_group_id" {
  description = "Grafana security group ID"
  value       = aws_security_group.grafana.id
}