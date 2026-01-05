output "bastion_sg_id" {
  value = aws_security_group.bastion_sg.id
}

output "micro_sg_id" {
  value = aws_security_group.micro_sg.id
}
output "DynamoDB_sg_id" {
  value = aws_security_group.DynamoDB_sg.id
}