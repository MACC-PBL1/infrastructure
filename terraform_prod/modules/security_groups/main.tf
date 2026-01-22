############################################
# Bastion Security Group
############################################
resource "aws_security_group" "bastion" {
  name        = "${var.name_prefix}-bastion-sg"
  description = "Security group for Bastion host"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from allowed CIDR"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}-bastion-sg"
  }
}

############################################
# HAProxy Security Group
############################################
resource "aws_security_group" "haproxy" {
  name        = "${var.name_prefix}-haproxy-sg"
  description = "Security group for HAProxy"
  vpc_id      = var.vpc_id

  # HTTP público
  ingress {
    description = "HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS público
  ingress {
    description = "HTTPS from Internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Stats / Admin (3001)
  ingress {
    description = "HAProxy stats"
    from_port   = 3001
    to_port     = 3001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH solo desde bastion
  ingress {
    description     = "SSH from Bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}-haproxy-sg"
  }
}

############################################
# Microservices Security Group
############################################
resource "aws_security_group" "microservices" {
  name        = "${var.name_prefix}-microservices-sg"
  description = "Security group for private microservices"
  vpc_id      = var.vpc_id

  # SSH desde Bastion
  ingress {
    description     = "SSH from Bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  # HTTP desde HAProxy
  ingress {
    description     = "HTTP from HAProxy"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.haproxy.id]
  }

  # HTTPS desde HAProxy
  ingress {
    description     = "HTTPS from HAProxy"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.haproxy.id]
  }

  # Puertos 8000–8010 desde HAProxy (microservicios)
  ingress {
    description     = "Microservices from HAProxy"
    from_port       = 8000
    to_port         = 8010
    protocol        = "tcp"
    security_groups = [aws_security_group.haproxy.id]
  }

  # Puertos 8000–8010 entre microservicios
  ingress {
    description = "Microservices internal traffic"
    from_port   = 8000
    to_port     = 8010
    protocol    = "tcp"
    self        = true
  }

  # Consul HTTP API (8500) desde HAProxy
  ingress {
    description     = "Consul HTTP from HAProxy"
    from_port       = 8500
    to_port         = 8500
    protocol        = "tcp"
    security_groups = [aws_security_group.haproxy.id]
  }

  # Consul DNS (8600 UDP) desde HAProxy
  ingress {
    description     = "Consul DNS from HAProxy"
    from_port       = 8600
    to_port         = 8600
    protocol        = "udp"
    security_groups = [aws_security_group.haproxy.id]
  }

  # Consul HTTP interno
  ingress {
    description = "Consul HTTP internal"
    from_port   = 8500
    to_port     = 8500
    protocol    = "tcp"
    self        = true
  }

  # RabbitMQ TLS interno
  ingress {
    description = "RabbitMQ TLS internal"
    from_port   = 5671
    to_port     = 5671
    protocol    = "tcp"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}-microservices-sg"
  }
}

############################################
# RDS Security Group
############################################
resource "aws_security_group" "rds" {
  name        = "${var.name_prefix}-rds-sg"
  description = "Security group for RDS"
  vpc_id      = var.vpc_id

  ingress {
    description     = "DB access from microservices"
    from_port       = var.db_port
    to_port         = var.db_port
    protocol        = "tcp"
    security_groups = [aws_security_group.microservices.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}-rds-sg"
  }
}
