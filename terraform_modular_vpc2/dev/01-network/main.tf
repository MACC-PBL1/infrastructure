module "vpc" {
  source = "../../modules/vpc"

  name                 = var.project_name
  cidr_block           = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  azs                  = var.availability_zones
  enable_nat_gateway   = var.enable_nat_gateway
}
