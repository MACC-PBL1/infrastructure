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

peer_vpc_cidr = "10.1.0.0/16"

auth_instance_ips = [
  "10.1.11.61",
  "10.1.12.246"
]

logs_instance_ips = [
  "10.1.11.61",
  "10.1.12.246"
]
lab_role_arn = "arn:aws:iam::512411987939:role/LabRole"
#lab_role_arn = "arn:aws:iam::975049933544:role/LabRole"

microservices = {
  order-warehouse = {
    paths = [
      "/order/*",
      "/warehouse/*"
    ]
    user_data_file = "order_warehouse.sh"
  }

  payment-delivery = {
    paths = [
      "/payment/*",
      "/delivery/*"
    ]
    user_data_file = "payment_delivery.sh"
  }

  machines = {
    paths = [
      "/machines/*"
    ]
    user_data_file = "machines.sh"
  }
}

