output "private_ips" {
  value = { for k, v in aws_instance.services : k => v.private_ip }
}