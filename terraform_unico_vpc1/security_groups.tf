###############################################
# SECURITY GROUPS
###############################################

# ============ NAT + BASTION (PUBLIC) ============
resource "aws_security_group" "nat_bastion" {
  name_prefix = "${local.name_prefix}-nat-bastion-"
  description = "Security group for NAT + Bastion instance in public subnet"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-nat-bastion-sg"
  }
}

# SSH from allowed CIDRs (one rule per CIDR)
resource "aws_vpc_security_group_ingress_rule" "nat_bastion_ssh" {
  for_each          = toset(var.allowed_ssh_cidr)
  security_group_id = aws_security_group.nat_bastion.id

  description = "SSH to NAT/Bastion"
  from_port   = 22
  to_port     = 22
  ip_protocol = "tcp"
  cidr_ipv4   = each.value

  tags = {
    Name = "SSH"
  }
}

# Allow all from VPC (so private instances can use it as NAT)
resource "aws_vpc_security_group_ingress_rule" "nat_from_vpc_all" {
  security_group_id = aws_security_group.nat_bastion.id

  description = "All traffic from VPC"
  ip_protocol = "-1"
  cidr_ipv4   = var.vpc_cidr

    tags = {
    Name = "VPC-ALL"
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
  name_prefix = "${local.name_prefix}-alb-"
  description = "Security group for internal ALB"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-alb-sg"
  }
}

# HTTP from within VPC (VPC Link ENIs live in private subnets)
resource "aws_vpc_security_group_ingress_rule" "alb_http_from_vpc" {
  security_group_id = aws_security_group.alb.id

  description = "HTTP from VPC (API GW VPC Link)"
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
  cidr_ipv4   = var.vpc_cidr

  tags = {
    Name = "HTTP-VPC"
  }
}

# Egress all (to targets)
resource "aws_vpc_security_group_egress_rule" "alb_egress" {
  security_group_id = aws_security_group.alb.id

  description = "Allow all outbound"
  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"
}

# ============ MICROSERVICES (PRIVATE) ============
resource "aws_security_group" "microservices" {
  name_prefix = "${local.name_prefix}-ms-"
  description = "Security group for microservices instances"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-microservices-sg"
  }
}

# SSH only from NAT/Bastion SG (bastion -> private)
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

# App ports from ALB SG
resource "aws_vpc_security_group_ingress_rule" "ms_from_alb_ports" {
  for_each = var.microservices

  security_group_id            = aws_security_group.microservices.id
  referenced_security_group_id = aws_security_group.alb.id

  description = "App port ${each.key} from ALB"
  from_port   = each.value.port
  to_port     = each.value.port
  ip_protocol = "tcp"

  tags = {
    Name = "APP-${each.key}"
  }
}

# Egress all (to RDS + Internet via NAT)
resource "aws_vpc_security_group_egress_rule" "ms_egress" {
  security_group_id = aws_security_group.microservices.id

  description = "Allow all outbound"
  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"
}

# ============ RDS AURORA (PRIVATE) ============
resource "aws_security_group" "rds" {
  name_prefix = "${local.name_prefix}-rds-"
  description = "Security group for Aurora cluster"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-rds-sg"
  }
}

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

resource "aws_vpc_security_group_egress_rule" "rds_egress" {
  security_group_id = aws_security_group.rds.id

  description = "Allow all outbound"
  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"
}
