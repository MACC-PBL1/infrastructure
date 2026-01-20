output "bastion_instance_id" {
  value = aws_instance.this.id
}

output "bastion_public_ip" {
  value = aws_eip.bastion.public_ip
}

output "bastion_private_ip" {
  value = aws_instance.this.private_ip
}
