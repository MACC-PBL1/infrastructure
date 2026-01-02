output "alb_sg_id" { value = aws_security_group.alb.id }
output "microservices_sg_id" { value = aws_security_group.microservices.id }
output "rds_sg_id" { value = aws_security_group.rds.id }
output "nat_sg_id" { value = aws_security_group.nat_bastion.id }
