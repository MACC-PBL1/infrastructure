aws_region   = "us-east-1"
environment  = "development"
project_name = "pi-infra"
username     = "user"

key_pair_name = "vockey"
allowed_ssh_cidr = "0.0.0.0/0"

nat_bastion_instance_type = "t2.micro"
microservice_instance_type = "t2.micro"

asg_min_size         = 2
asg_desired_capacity = 2
asg_max_size         = 4
cpu_target_utilization = 60

db_name            = "appdb"
db_master_username = "admin"
db_master_password = "admin123"

peer_vpc_cidr = "10.1.0.0/16"
