###############################################
# SECURITY GROUPS
###############################################

# ============ NAT + BASTION (PUBLIC) ============
resource "aws_security_group" "nat_bastion" {
  name_prefix = "${var.name_prefix}-nat-bastion-"
  description = "Security group for NAT + Bastion instance in public subnet"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name_prefix}-nat-bastion-sg"
  }
}

# SSH from allowed CIDRs
resource "aws_vpc_security_group_ingress_rule" "nat_bastion_ssh" {
  security_group_id = aws_security_group.nat_bastion.id
  cidr_ipv4         = var.allowed_ssh_cidr
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"

  tags = {
    Name = "SSH"
  }
}

# Allow all from own VPC (NAT usage)
resource "aws_vpc_security_group_ingress_rule" "nat_from_vpc_all" {
  security_group_id = aws_security_group.nat_bastion.id

  description = "All traffic from VPC"
  ip_protocol = "-1"
  cidr_ipv4   = var.vpc_cidr

  tags = {
    Name = "VPC-ALL"
  }
}

# >>> PEERING <<< Allow all from peer VPC (optional)
resource "aws_vpc_security_group_ingress_rule" "nat_from_peer_vpc_all" {
  count = var.peer_vpc_cidr == null ? 0 : 1

  security_group_id = aws_security_group.nat_bastion.id

  description = "All traffic from peer VPC"
  ip_protocol = "-1"
  cidr_ipv4   = var.peer_vpc_cidr

  tags = {
    Name = "PEER-VPC-ALL"
  }
}

# Egress all
resource "aws_vpc_security_group_egress_rule" "nat_bastion_egress" {
  security_group_id = aws_security_group.nat_bastion.id

  description = "Allow all outbound traffic"
  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"
}

# ============ ALB (PRIVATE) ============
resource "aws_security_group" "alb" {
  name_prefix = "${var.name_prefix}-alb-"
  description = "Security group for internal ALB"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name_prefix}-alb-sg"
  }
}

# HTTP from own VPC (API Gateway VPC Link)
resource "aws_vpc_security_group_ingress_rule" "alb_http_from_vpc" {
  security_group_id = aws_security_group.alb.id

  description = "HTTP from VPC"
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
  cidr_ipv4   = var.vpc_cidr

  tags = {
    Name = "HTTP-VPC"
  }
}

# Egress all
resource "aws_vpc_security_group_egress_rule" "alb_egress" {
  security_group_id = aws_security_group.alb.id

  description = "Allow all outbound"
  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"
}

# ============ MICROSERVICES (PRIVATE) ============
# ============ MICROSERVICES (PRIVATE) ============
resource "aws_security_group" "microservices" {
  name_prefix = "${var.name_prefix}-ms-"
  description = "Security group for microservices instances"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name_prefix}-microservices-sg"
  }
}

# SSH only from NAT/Bastion
resource "aws_vpc_security_group_ingress_rule" "ms_ssh_from_bastion" {
  security_group_id            = aws_security_group.microservices.id
  referenced_security_group_id = aws_security_group.nat_bastion.id

  description = "SSH from NAT/Bastion"
  from_port   = 22
  to_port     = 22
  ip_protocol = "tcp"

  tags = {
    Name = "SSH-FROM-BASTION"
  }
}

# HTTPS from ALB (HAProxy)
resource "aws_vpc_security_group_ingress_rule" "ms_from_alb_https" {
  security_group_id            = aws_security_group.microservices.id
  referenced_security_group_id = aws_security_group.alb.id

  description = "HTTPS from ALB to microservices (HAProxy)"
  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"

  tags = {
    Name = "HTTPS-FROM-ALB"
  }
}

# >>> PEERING <<< Allow all traffic from peer VPC
resource "aws_vpc_security_group_ingress_rule" "ms_from_peer_vpc" {
  count = var.peer_vpc_cidr == null ? 0 : 1

  security_group_id = aws_security_group.microservices.id

  description = "All traffic from peer VPC"
  ip_protocol = "-1"
  cidr_ipv4   = var.peer_vpc_cidr

  tags = {
    Name = "PEER-VPC-ALL"
  }
}

# Egress all
resource "aws_vpc_security_group_egress_rule" "ms_egress" {
  security_group_id = aws_security_group.microservices.id

  description = "Allow all outbound"
  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"
}

# ============ RDS AURORA (PRIVATE) ============
resource "aws_security_group" "rds" {
  name_prefix = "${var.name_prefix}-rds-"
  description = "Security group for Aurora cluster"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name_prefix}-rds-sg"
  }
}

# MySQL only from microservices
resource "aws_vpc_security_group_ingress_rule" "rds_from_ms" {
  security_group_id            = aws_security_group.rds.id
  referenced_security_group_id = aws_security_group.microservices.id

  description = "MySQL from microservices"
  from_port   = 3306
  to_port     = 3306
  ip_protocol = "tcp"

  tags = {
    Name = "MYSQL-FROM-MS"
  }
}

# Egress all
resource "aws_vpc_security_group_egress_rule" "rds_egress" {
  security_group_id = aws_security_group.rds.id

  description = "Allow all outbound"
  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"
}

# ============ LAMBDA -> RDS ============
resource "aws_vpc_security_group_ingress_rule" "rds_from_lambda" {
  security_group_id = aws_security_group.rds.id

  description = "MySQL from Lambda functions"
  from_port   = 3306
  to_port     = 3306
  ip_protocol = "tcp"
  cidr_ipv4   = var.vpc_cidr

  tags = {
    Name = "MYSQL-FROM-LAMBDA"
  }
}