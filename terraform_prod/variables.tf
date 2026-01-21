############################################
# Global / Provider
############################################
variable "aws_region" {
  description = "AWS region to deploy the infrastructure"
  type        = string
}

############################################
# Naming
############################################
variable "name_prefix" {
  description = "Prefix used for naming all resources"
  type        = string
}

############################################
# Networking
############################################
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet"
  type        = string
}

variable "availability_zones" {
  description = "Availability Zones for private subnets"
  type        = list(string)
}

############################################
# SSH / Access
############################################
variable "key_pair_name" {
  description = "EC2 key pair name for SSH access"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed to SSH into the bastion host"
  type        = string
}

############################################
# EC2 Instance Types
############################################
variable "bastion_instance_type" {
  description = "Instance type for the bastion host"
  type        = string
}

variable "haproxy_instance_type" {
  description = "Instance type for the HAProxy instance"
  type        = string
}

variable "microservices_instance_type" {
  description = "Instance type for microservices"
  type        = string
}

############################################
# RDS
############################################
variable "db_name" {
  description = "Initial database name"
  type        = string
}

variable "db_username" {
  description = "Master database username"
  type        = string
}

variable "db_password" {
  description = "Master database password"
  type        = string
  sensitive   = true
}

variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
}
