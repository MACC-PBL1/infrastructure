############################################
# Microservices EC2 instances
############################################
resource "aws_instance" "this" {
  for_each = var.microservices

  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.security_group_id]
  key_name                    = var.key_pair_name
  associate_public_ip_address = false

  tags = {
    Name = "${var.name_prefix}-${each.key}"
    Role = "microservice"
    Service = each.key
  }
}
