# terraform.tfvars
# Ajusta estos valores a tu entorno

aws_region   = "us-east-1"
environment  = "development"
username     = "pramos"
project_name = "pi-infra"

# ============ VPC Configuration ============
vpc_cidr              = "10.0.0.0/16"
public_subnet_1_cidr  = "10.0.1.0/24"
private_subnet_1_cidr = "10.0.10.0/24"
private_subnet_2_cidr = "10.0.11.0/24"

# ============ EC2 Instance Types ============
nat_bastion_instance_type  = "t2.micro"
microservice_instance_type = "t2.micro"

# ============ SSH Key ============
key_pair_name = "vockey"

# ============ SSH CIDR ============
allowed_ssh_cidr = ["0.0.0.0/0"] # SOLO para desarrollo; restringe a tu IP en producción

# ============ Database (Aurora) ============
db_name            = "appdb"
db_master_username = "admin"
db_master_password = "ChangeMe123!ChangeMe123!" # CAMBIA ESTO

db_instance_class = "db.t3.medium"

# ============ Tags ============
common_tags = {
  Project     = "pi-infra"
  Environment = "development"
  ManagedBy   = "terraform"
  Team        = "MACC"
  CreatedAt   = "2025-12-29"
}
