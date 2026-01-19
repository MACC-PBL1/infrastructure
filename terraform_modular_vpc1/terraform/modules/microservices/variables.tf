variable "name_prefix" { type = string }
variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "microservices_sg_id" { type = string }
variable "ami_id" { type = string }
variable "microservice_instance_type" { type = string }
variable "key_pair_name" { type = string }
variable "microservices" { type = any }
variable "target_group_arns" { type = map(string) }

variable "asg_min_size" { type = number }
variable "asg_max_size" { type = number }
variable "asg_desired_capacity" { type = number }
variable "cpu_target_utilization" { type = number }
variable "microservices" {
  type = map(object({
    port            = number
    user_data_file  = string
  }))
}