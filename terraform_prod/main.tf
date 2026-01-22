############################################
# VPC
############################################
module "vpc" {
  source = "./modules/vpc"

  name_prefix         = var.name_prefix
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidr  = var.public_subnet_cidr
  private_subnet_cidr = var.private_subnet_cidr
  availability_zones   = var.availability_zones
}

############################################
# Security Groups
############################################
module "security_groups" {
  source = "./modules/security_groups"

  name_prefix      = var.name_prefix
  vpc_id           = module.vpc.vpc_id
  allowed_ssh_cidr = var.allowed_ssh_cidr
}

############################################
# Bastion Host (public subnet)
############################################
module "bastion" {
  source = "./modules/bastion"

  name_prefix       = var.name_prefix
  ami_id            = data.aws_ami.ubuntu.id
  instance_type     = var.bastion_instance_type
  subnet_id         = module.vpc.public_subnet_id
  security_group_id = module.security_groups.bastion_sg_id
  key_pair_name     = var.key_pair_name
}

############################################
# HAProxy (public subnet)
############################################
module "haproxy" {
  source = "./modules/haproxy"

  name_prefix       = var.name_prefix
  ami_id            = data.aws_ami.ubuntu.id
  instance_type     = var.haproxy_instance_type
  subnet_id         = module.vpc.public_subnet_id
  security_group_id = module.security_groups.haproxy_sg_id
  key_pair_name     = var.key_pair_name
}

############################################
# Microservices (private subnet)
#  - consul
#  - rabbitmq
#  - auth
#  - apps (rest of microservices)
############################################
module "microservices" {
  source = "./modules/microservices"

  name_prefix       = var.name_prefix
  ami_id            = data.aws_ami.ubuntu.id
  instance_type     = var.microservices_instance_type
  subnet_id         = module.vpc.private_subnet_ids[0]
  security_group_id = module.security_groups.microservices_sg_id
  key_pair_name     = var.key_pair_name

  microservices = {
    consul   = {}
    rabbitmq = {}
    auth     = {}
    apps     = {}
  }
}
############################################
# RDS (private subnet)
############################################
module "rds" {
  source = "./modules/rds"

  name_prefix        = var.name_prefix
  private_subnet_ids = module.vpc.private_subnet_ids

  rds_sg_id = module.security_groups.rds_sg_id

  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password

  instance_class = var.rds_instance_class
}

############################################
# Secrets Manager - SSL certificates
############################################
module "ssl_secrets" {
  source = "./modules/secrets_manager"

  name_prefix = var.name_prefix
  secret_name = "pi-infra-microservices-ssl"

  description = "TLS/SSL certificates and keys for internal microservices and HAProxy"

  secret_value = {
    "ca_cert.pem"         = file("${path.module}/ssl/ca_cert.pem")
    "ca_cert.srl"         = file("${path.module}/ssl/ca_cert.srl")
    "ca_key.pem"          = file("${path.module}/ssl/ca_key.pem")

    "client_cert.pem"     = file("${path.module}/ssl/client_cert.pem")
    "client_key.pem"      = file("${path.module}/ssl/client_key.pem")
    "client_req.pem"      = file("${path.module}/ssl/client_req.pem")

    "haproxy_server.pem"  = file("${path.module}/ssl/haproxy_server.pem")

    "server_cert.pem"     = file("${path.module}/ssl/server_cert.pem")
    "server_key.pem"      = file("${path.module}/ssl/server_key.pem")
    "server_req.pem"      = file("${path.module}/ssl/server_req.pem")
  }
}
