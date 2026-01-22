############################################
# Global
############################################
aws_region = "us-east-1"

name_prefix = "prod-lab"

############################################
# Networking
############################################
vpc_cidr            = "10.0.0.0/16"
public_subnet_cidr  = "10.0.1.0/24"
private_subnet_cidr = "10.0.2.0/24"

availability_zones = ["us-east-1a", "us-east-1b"]

############################################
# SSH / Access
############################################
key_pair_name     = "labsuser"
allowed_ssh_cidr  = "0.0.0.0/0"
#En prod real IP: "X.X.X.X/32"

############################################
# EC2 Instance Types
############################################
bastion_instance_type       = "t3.medium"
haproxy_instance_type       = "t3.medium"
microservices_instance_type = "t3.medium"

############################################
# RDS
############################################
db_name              = "appdb"
db_username          = "appuser"
db_password          = "StrongPassword123!"
rds_instance_class   = "db.t3.micro"
