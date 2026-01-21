############################################
# Bastion EC2
############################################
resource "aws_eip" "bastion" {
  domain = "vpc"

  tags = {
    Name = "${var.name_prefix}-bastion-eip"
  }
}

resource "aws_instance" "this" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.security_group_id]
  key_name                    = var.key_pair_name
  associate_public_ip_address = true

  tags = {
    Name = "${var.name_prefix}-bastion"
    Role = "bastion"
  }
}

resource "aws_eip_association" "bastion" {
  instance_id   = aws_instance.this.id
  allocation_id = aws_eip.bastion.id
}

