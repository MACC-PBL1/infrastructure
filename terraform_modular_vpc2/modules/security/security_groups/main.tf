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