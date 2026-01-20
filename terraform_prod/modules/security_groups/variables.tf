variable "vpc_id" {
  description = "VPC ID where security groups will be created"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed to SSH into bastion"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for naming resources"
  type        = string
}
variable "db_port" {
  description = "Database port (MySQL default 3306)"
  type        = number
  default     = 3306
}
