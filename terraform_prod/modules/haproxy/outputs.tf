output "haproxy_instance_id" {
  value = aws_instance.this.id
}

output "haproxy_public_ip" {
  value = aws_instance.this.public_ip
}

output "haproxy_private_ip" {
  value = aws_instance.this.private_ip
}
