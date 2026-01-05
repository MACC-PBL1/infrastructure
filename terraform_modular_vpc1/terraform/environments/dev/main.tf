###############################################
# DEV environment - root module
###############################################

module "network" {
  source = "../../modules/network"

  name_prefix          = local.name_prefix
  vpc_cidr             = var.vpc_cidr
  public_subnet_1_cidr  = var.public_subnet_1_cidr
  private_subnet_1_cidr = var.private_subnet_1_cidr
  private_subnet_2_cidr = var.private_subnet_2_cidr
  az1                  = local.az1
  az2                  = local.az2
}

module "security_groups" {
  source = "../../modules/security_groups"

  name_prefix      = local.name_prefix
  vpc_id           = module.network.vpc_id
  vpc_cidr         = module.network.vpc_cidr
  microservices    = var.microservices
  allowed_ssh_cidr = var.allowed_ssh_cidr
}

module "nat_bastion" {
  source = "../../modules/nat_bastion"

  name_prefix              = local.name_prefix
  ami_id                   = data.aws_ami.debian_12.id
  nat_bastion_instance_type = var.nat_bastion_instance_type
  key_pair_name            = var.key_pair_name
  public_subnet_id         = module.network.public_subnet_id
  nat_sg_id                = module.security_groups.nat_sg_id
  private_route_table_id   = module.network.private_route_table_id
}

module "alb" {
  source = "../../modules/alb"

  name_prefix         = local.name_prefix
  vpc_id              = module.network.vpc_id
  private_subnet_ids  = module.network.private_subnet_ids
  alb_sg_id           = module.security_groups.alb_sg_id
  microservices       = var.microservices
}

module "microservices" {
  source = "../../modules/microservices"

  name_prefix               = local.name_prefix
  vpc_id                    = module.network.vpc_id
  private_subnet_ids         = module.network.private_subnet_ids
  microservices_sg_id       = module.security_groups.microservices_sg_id
  ami_id                    = data.aws_ami.ubuntu.id
  microservice_instance_type = var.microservice_instance_type
  key_pair_name             = var.key_pair_name
  microservices             = var.microservices
  target_group_arns         = module.alb.target_group_arns

  asg_min_size              = var.asg_min_size
  asg_max_size              = var.asg_max_size
  asg_desired_capacity      = var.asg_desired_capacity
  cpu_target_utilization    = var.cpu_target_utilization
}

module "rds" {
  source = "../../modules/rds"

  name_prefix         = local.name_prefix
  private_subnet_ids  = module.network.private_subnet_ids
  rds_sg_id           = module.security_groups.rds_sg_id
  db_name             = var.db_name
  db_master_username  = var.db_master_username
  db_master_password  = var.db_master_password
  db_instance_class  = var.db_instance_class
}

module "api_gateway" {
  source = "../../modules/api_gateway"

  name_prefix        = local.name_prefix
  private_subnet_ids = module.network.private_subnet_ids
  vpc_link_sg_id     = module.security_groups.alb_sg_id
  alb_listener_arn   = module.alb.listener_arn
  microservices      = var.microservices
}
