output "microservices_instance_ids" {
  value = {
    for name, instance in aws_instance.this :
    name => instance.id
  }
}

output "microservices_private_ips" {
  value = {
    for name, instance in aws_instance.this :
    name => instance.private_ip
  }
}
