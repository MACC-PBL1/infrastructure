###############################################
# GRAFANA MODULE
###############################################

# Security Group for Grafana
resource "aws_security_group" "grafana" {
  name_prefix = "${var.name_prefix}-grafana-"
  description = "Security group for Grafana instance"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name_prefix}-grafana-sg"
  }
}

# Allow access to Grafana port from VPC (or specific CIDR)
resource "aws_vpc_security_group_ingress_rule" "grafana_http" {
  security_group_id = aws_security_group.grafana.id

  description = "Grafana UI access from VPC"
  from_port   = 3000
  to_port     = 3000
  ip_protocol = "tcp"
  cidr_ipv4   = var.vpc_cidr

  tags = {
    Name = "GRAFANA-HTTP"
  }
}

# SSH from NAT/Bastion
resource "aws_vpc_security_group_ingress_rule" "grafana_ssh" {
  security_group_id            = aws_security_group.grafana.id
  referenced_security_group_id = var.nat_sg_id

  description = "SSH from NAT/Bastion"
  from_port   = 22
  to_port     = 22
  ip_protocol = "tcp"

  tags = {
    Name = "SSH-FROM-BASTION"
  }
}

# Allow all outbound traffic
resource "aws_vpc_security_group_egress_rule" "grafana_egress" {
  security_group_id = aws_security_group.grafana.id

  description = "Allow all outbound"
  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"
}

# Grafana EC2 Instance
resource "aws_instance" "grafana" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.grafana.id]
  key_name               = var.key_pair_name

  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -e
    
    # Update system
    apt-get update -y
    
    # Install dependencies
    apt-get install -y apt-transport-https software-properties-common wget
    
    # Add Grafana GPG key
    mkdir -p /usr/share/keyrings
    wget -q -O /usr/share/keyrings/grafana.key https://apt.grafana.com/gpg.key
    
    # Add Grafana repository
    echo "deb [signed-by=/usr/share/keyrings/grafana.key] https://apt.grafana.com stable main" | tee /etc/apt/sources.list.d/grafana.list
    
    # Update and install Grafana
    apt-get update -y
    apt-get install -y grafana
    
    # Configure Grafana to listen on all interfaces
    sed -i 's/;http_addr =.*/http_addr = 0.0.0.0/' /etc/grafana/grafana.ini
    sed -i 's/;http_port =.*/http_port = 3000/' /etc/grafana/grafana.ini
    
    # Enable and start Grafana
    systemctl daemon-reload
    systemctl enable grafana-server
    systemctl start grafana-server
  EOF
  )

  tags = {
    Name = "${var.name_prefix}-grafana"
    Role = "monitoring"
  }
}