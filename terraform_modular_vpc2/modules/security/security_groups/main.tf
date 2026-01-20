data "aws_vpc" "selected" {
    id = var.vpc_id
}

resource "aws_security_group" "bastion_sg" {
    name   = "${var.name}-bastion-sg"
    description = "Security group for SSH access"
    vpc_id      = data.aws_vpc.selected.id

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = var.allowed_ssh_cidr
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "${var.name}-bastion-sg"
    }
}

resource "aws_security_group" "DynamoDB_sg" {
    name   = "${var.name}-DynamoDB-sg"
    description = "Security group for DynamoDB access"
    vpc_id      = data.aws_vpc.selected.id

    ingress {
        from_port   = 3306
        to_port     = 3306
        protocol    = "tcp"
        security_groups = [aws_security_group.micro_sg.id]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "${var.name}-DynamoDB-sg"
    }
}

resource "aws_security_group" "micro_sg" {
    name = "${var.name}-micro-sg"
    description = "Security group for microservices"
    vpc_id = data.aws_vpc.selected.id

    # SSH desde internet (para honeypots públicos)
    ingress {
        description = "SSH from internet"
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        #cidr_blocks = var.allowed_ssh_cidr
    }

    ingress {
        description = "SSH admin port 2222 Cowrie Honeypot"
        from_port   = 2222
        to_port     = 2222
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]  # Cambiar a tu IP si quieres más seguridad
    }

    ingress {
        description = "SSH from bastion VPC (via peering)"
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = [var.peer_vpc_cidr]
    }

    ingress {
        description = "All traffic from peer VPC"
        from_port   = 0
        to_port     = 65535
        protocol    = "tcp"
        cidr_blocks = [var.peer_vpc_cidr]
    }

    ingress {
        description = "ICMP from peer VPC (peering)"
        from_port   = -1
        to_port     = -1
        protocol    = "icmp"
        cidr_blocks = [var.peer_vpc_cidr]
    }

    ingress {
        description = "VPC internal (all TCP)"
        from_port   = 0
        to_port     = 65535
        protocol    = "tcp"
        cidr_blocks = [data.aws_vpc.selected.cidr_block]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "${var.name}-micro-sg"
    }
}

# ============================================
# CROSS-VPC: Permitir tráfico desde VPC1 ALB
# ============================================

resource "aws_vpc_security_group_ingress_rule" "micro_from_vpc1_alb_8080" {
  security_group_id = aws_security_group.micro_sg.id

  description = "Allow traffic from VPC1 ALB - Port 8080"
  from_port   = 8080
  to_port     = 8080
  ip_protocol = "tcp"
  cidr_ipv4   = "10.0.0.0/16"  # CIDR de VPC1

  tags = {
    Name = "FROM-VPC1-ALB-8080"
  }
}

resource "aws_vpc_security_group_ingress_rule" "dionaea_mongodb" {
  security_group_id = aws_security_group.micro_sg.id

  description = "MongoDB for Dionaea honeypot"
  from_port   = 27017
  to_port     = 27017
  ip_protocol = "tcp"
  cidr_ipv4   = "0.0.0.0/0"  # Abierto a Internet (es un honeypot)

  tags = {
    Name = "DIONAEA-MONGODB"
  }
}