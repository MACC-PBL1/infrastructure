region  = "us-east-1"
profile = "default"  # Cambia si usas otro perfil AWS CLI

project_name = "popbl-grupo1"
environment  = "dev"

common_tags = {
  Environment = "dev"
  Project     = "POPBL1"
  Group       = "Group1"
  ManagedBy   = "Terraform"
  Course      = "MACC"
}

vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]
availability_zones   = ["us-east-1a", "us-east-1b"]

# True si se necesita instalar cosas de docker, hacer apt update/install
enable_nat_gateway = false

#habria que cambiar a x ips para que sea mas segura
allowed_ssh_cidr = ["0.0.0.0/0"]

# key-09a2953e0e5e18c00
key_pair_name = "popbl-key"

ami_id = "ami-0b6c6ebed2801a5cb"  # Ubuntu 24.04 LTS us-east-1

instance_type_public  = "t3.micro"  # 2 instancias públicas en AZ1
instance_type_private = "t3.micro"  # 8 instancias privadas (4 AZ1 + 4 AZ2)

dynamodb_billing_mode = "PAY_PER_REQUEST"

# Solo si usas PROVISIONED:
dynamodb_read_capacity  = 5
dynamodb_write_capacity = 5

