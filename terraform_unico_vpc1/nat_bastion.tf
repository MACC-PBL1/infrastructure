###############################################
# NAT + BASTION INSTANCE (PUBLIC SUBNET)
# - One EC2 acting as: Bastion (SSH) + NAT for private subnets
###############################################

resource "aws_eip" "nat_bastion" {
  domain = "vpc"
  tags = {
    Name = "${local.name_prefix}-nat-bastion-eip"
  }
}

resource "aws_instance" "nat_bastion" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.nat_bastion_instance_type
  subnet_id                   = aws_subnet.public_az1.id
  vpc_security_group_ids      = [aws_security_group.nat_bastion.id]
  key_name                    = var.key_pair_name
  associate_public_ip_address = true
  source_dest_check           = false

  user_data = <<-EOF
    #!/bin/bash
    set -e

    # Enable IP forwarding
    sysctl -w net.ipv4.ip_forward=1
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf

    # Configure iptables for NAT (MASQUERADE)
    IFACE=$(ip route | awk '/default/ {print $5; exit}')
    iptables -t nat -A POSTROUTING -o $IFACE -j MASQUERADE
    iptables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
    iptables -A FORWARD -j ACCEPT

    # Persist iptables rules (best effort)
    yum install -y iptables-services || true
    service iptables save || true
    systemctl enable iptables || true
  EOF

  tags = {
    Name = "${local.name_prefix}-nat-bastion"
  }
}

resource "aws_eip_association" "nat_bastion" {
  allocation_id = aws_eip.nat_bastion.id
  instance_id   = aws_instance.nat_bastion.id
}

# Route private subnets to the NAT instance for Internet access
resource "aws_route" "private_default_via_nat_instance" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_instance.nat_bastion.primary_network_interface_id

  depends_on = [aws_instance.nat_bastion]
}
