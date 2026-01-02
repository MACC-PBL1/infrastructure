variable "name_prefix" { type = string }
variable "vpc_id" { type = string }
variable "vpc_cidr" { type = string }
variable "microservices" {
  description = "Microservices configuration map (ports, paths, etc.)"
  type = any
}
variable "allowed_ssh_cidr" { type = string }
