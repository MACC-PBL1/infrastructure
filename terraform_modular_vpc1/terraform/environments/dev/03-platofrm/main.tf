###############################################
# DEV - 03 PLATFORM (after network + peering)
###############################################

terraform {
  required_version = ">= 1.5.0"
}

provider "aws" {
  region = var.aws_region
}

# =========================
# Remote states (network + peering)
# =========================
data "terraform_remote_state" "network" {
  backend = "local"
  config = {
    path = "../01-network/terraform.tfstate"
  }
}

# Optional: only to force dependency / visibility of peering outputs.
# (Not strictly required if 03-platform doesn't need peering id directly.)
#data "terraform_remote_state" "peering" {
#  backend = "local"
#  config = {
#    path = "../02-peering/terraform.tfstate"
#  }
#}

# =========================
# AMIs
# =========================
# Debian 12 for NAT+Bastion
data "aws_ami" "debian_12" {
  most_recent = true
  owners      = ["136693071363"] # Debian official

  filter {
    name   = "name"
    values = ["debian-12-amd64-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

# Ubuntu 22.04 for microservices
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical official

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# =========================
# Locals
# =========================
locals {
  name_prefix = "${var.project_name}-${var.environment}-${var.username}"
}

# =========================
# Security Groups
# =========================
module "security_groups" {
  source = "../../../modules/security_groups"

  name_prefix      = local.name_prefix
  vpc_id           = data.terraform_remote_state.network.outputs.vpc_id
  vpc_cidr         = data.terraform_remote_state.network.outputs.vpc_cidr
  peer_vpc_cidr    = var.peer_vpc_cidr   # 👈 AÑADIR
  microservices    = var.microservices
  allowed_ssh_cidr = var.allowed_ssh_cidr
}


# =========================
# NAT + Bastion
# =========================
module "nat_bastion" {
  source = "../../../modules/nat_bastion"

  name_prefix               = local.name_prefix
  ami_id                    = data.aws_ami.debian_12.id
  nat_bastion_instance_type = var.nat_bastion_instance_type
  key_pair_name             = var.key_pair_name

  public_subnet_id       = data.terraform_remote_state.network.outputs.public_subnet_id
  nat_sg_id              = module.security_groups.nat_sg_id
  private_route_table_id = data.terraform_remote_state.network.outputs.private_route_table_id
}

# =========================
# ALB (internal)
# =========================
module "alb" {
  source = "../../../modules/alb"

  name_prefix        = local.name_prefix
  vpc_id             = data.terraform_remote_state.network.outputs.vpc_id
  private_subnet_ids = data.terraform_remote_state.network.outputs.private_subnet_ids
  alb_sg_id          = module.security_groups.alb_sg_id
  microservices      = var.microservices
  auth_instance_ips = var.auth_instance_ips
  logs_instance_ips = var.logs_instance_ips
}

# =========================
# Microservices (ASGs)
# =========================
module "microservices" {
  source = "../../../modules/microservices"

  name_prefix                = local.name_prefix
  vpc_id                     = data.terraform_remote_state.network.outputs.vpc_id
  private_subnet_ids         = data.terraform_remote_state.network.outputs.private_subnet_ids
  microservices_sg_id        = module.security_groups.microservices_sg_id

  ami_id                     = data.aws_ami.ubuntu.id
  microservice_instance_type = var.microservice_instance_type
  key_pair_name              = var.key_pair_name

  microservices              = var.microservices
  target_group_arns          = module.alb.target_group_arns

  asg_min_size               = var.asg_min_size
  asg_max_size               = var.asg_max_size
  asg_desired_capacity       = var.asg_desired_capacity
  cpu_target_utilization     = var.cpu_target_utilization
}

# =========================
# RDS (Aurora)
# =========================
module "rds" {
  source = "../../../modules/rds"

  name_prefix        = local.name_prefix
  private_subnet_ids = data.terraform_remote_state.network.outputs.private_subnet_ids
  rds_sg_id          = module.security_groups.rds_sg_id

  db_name            = var.db_name
  db_master_username = var.db_master_username
  db_instance_class  = var.db_instance_class
}

# =========================
# API Gateway -> VPC Link -> ALB
# =========================
module "api_gateway" {
  source = "../../../modules/api_gateway"

  name_prefix        = local.name_prefix
  private_subnet_ids = data.terraform_remote_state.network.outputs.private_subnet_ids
  vpc_link_sg_id     = module.security_groups.alb_sg_id

  alb_listener_arn   = module.alb.listener_arn
  microservices      = var.microservices
}

# =========================
# Logging - S3 + Firehose
# =========================

module "logs_s3" {
  source = "../../../modules/s3"

  bucket_name = "${local.name_prefix}-zeek-logs-2"

  tags = {
    Project     = var.project_name
    Environment = var.environment
    Owner       = var.username
  }
}

# module "firehose_zeek" {
#   source = "../../../modules/firehose"
#
#   firehose_name  = "${local.name_prefix}-zeek-firehose"
#
#   s3_bucket_name = module.logs_s3.bucket_name
#   s3_bucket_arn  = module.logs_s3.bucket_arn
#
#   iam_role_arn = var.lab_role_arn
#   prefix       = "zeek"
#
#   tags = {
#     Project     = var.project_name
#     Environment = var.environment
#     Owner       = var.username
#     LogSource   = "zeek"
#   }
# }

# module "firehose_zeekflowmeter" {
#   source = "../../../modules/firehose"
#
#   firehose_name  = "${local.name_prefix}-zeekflowmeter-firehose"
#
#   s3_bucket_name = module.logs_s3.bucket_name
#   s3_bucket_arn  = module.logs_s3.bucket_arn
#
#   iam_role_arn = var.lab_role_arn
#   prefix       = "zeekflowmeter"
#
#   tags = {
#     Project     = var.project_name
#     Environment = var.environment
#     Owner       = var.username
#     LogSource   = "zeekflowmeter"
#   }
# }