variable "name_prefix" { type = string }
variable "vpc_id" { type = string }
variable "vpc_cidr" { type = string }
variable "microservices" {
  description = "Microservices configuration map (ports, paths, etc.)"
  type = any
}
variable "allowed_ssh_cidr" { type = string }
variable "peer_vpc_cidr" {
  type        = string
  description = "CIDR of peer VPC (optional)"
  default     = null
}
