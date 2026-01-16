###############################################
# NAT + BASTION INSTANCE (PUBLIC SUBNET)
# - One EC2 acting as: Bastion (SSH) + NAT for private subnets
###############################################

resource "aws_eip" "nat_bastion" {
  domain = "vpc"
  tags = {
    Name = "${var.name_prefix}-nat-bastion-eip"
  }
}

resource "aws_instance" "nat_bastion" {
  ami                         = var.ami_id
  instance_type               = var.nat_bastion_instance_type
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [var.nat_sg_id]
  key_name                    = var.key_pair_name
  associate_public_ip_address = true
  source_dest_check           = false

  # 🔑 IAM ROLE FOR FLUENT BIT / FIREHOSE
  iam_instance_profile = "LabInstanceProfile"

  user_data = <<EOF
#!/bin/bash
set -e

apt-get update -y
apt-get install -y python3
EOF

  tags = {
    Name = "${var.name_prefix}-nat-bastion"
    Role = "nat_bastion"
  }
}

resource "aws_eip_association" "nat_bastion" {
  allocation_id = aws_eip.nat_bastion.id
  instance_id   = aws_instance.nat_bastion.id
}

# Route private subnets to the NAT instance for Internet access
resource "aws_route" "private_default_via_nat_instance" {
  route_table_id         = var.private_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_instance.nat_bastion.primary_network_interface_id

  depends_on = [aws_instance.nat_bastion]
}
