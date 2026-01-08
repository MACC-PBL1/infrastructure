# =========================
# Global
# =========================
aws_region = "us-east-1"

# Prefijo de nombres (antes: project_name + username + env)
name_prefix = "pi-infra-development-user"

# =========================
# VPC
# =========================
vpc_cidr = "10.0.0.0/16"

# =========================
# Subnets
# =========================
public_subnet_1_cidr  = "10.0.1.0/24"
private_subnet_1_cidr = "10.0.10.0/24"
private_subnet_2_cidr = "10.0.11.0/24"

# =========================
# Availability Zones
# =========================
az1 = "us-east-1a"
az2 = "us-east-1b"
