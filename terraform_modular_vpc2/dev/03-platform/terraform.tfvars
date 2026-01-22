project_name = "popbl-grupo1"
environment  = "dev"

common_tags = {
  Environment = "dev"
  Project     = "POPBL1"
  Group       = "Group1"
  ManagedBy   = "Terraform"
  Course      = "MACC"
}

allowed_ssh_cidr = ["0.0.0.0/0"]

key_pair_name = "labsuser"

ami_id = "ami-0b6c6ebed2801a5cb"

instance_type_public  = "t3.micro"
instance_type_private = "t3.micro"

firehose_role_arn = "arn:aws:iam::975049933544:role/LabRole"

dynamodb_billing_mode = "PAY_PER_REQUEST"
dynamodb_read_capacity  = 5
dynamodb_write_capacity = 5
peer_vpc_cidr = "10.0.0.0/16"
