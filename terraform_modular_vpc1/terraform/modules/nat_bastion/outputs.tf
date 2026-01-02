output "public_ip" { value = aws_eip.nat_bastion.public_ip }
output "instance_id" { value = aws_instance.nat_bastion.id }
