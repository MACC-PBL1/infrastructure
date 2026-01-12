variable "name_prefix" { type = string }
variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "alb_sg_id" { type = string }
variable "microservices" { type = any }
variable "auth_instance_ids" {
  description = "Instance IDs of auth EC2s in peer VPC"
  type        = list(string)
}
variable "logs_instance_ids" {
  description = "Instance IDs of logs EC2s in peer VPC"
  type        = list(string)
}
