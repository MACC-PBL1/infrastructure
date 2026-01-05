variable "region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "profile" {
  description = "AWS CLI profile to use"
  type        = string
  default     = "default"
}


variable "project_name" {
  description = "Project name used as prefix for all resources"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}


variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets - only AZ1 has public subnet"
  type        = list(string)
  validation {
    condition     = length(var.public_subnet_cidrs) == 2
    error_message = "Must provide exactly 2 public subnet CIDRs (one per AZ)."
  }
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (2 AZs)"
  type        = list(string)
  validation {
    condition     = length(var.private_subnet_cidrs) == 2
    error_message = "Must provide exactly 2 private subnet CIDRs (one per AZ)."
  }
}

variable "availability_zones" {
  description = "Availability zones to use"
  type        = list(string)
  validation {
    condition     = length(var.availability_zones) == 2
    error_message = "Must provide exactly 2 availability zones."
  }
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateways for private subnets (required for internet access from private instances)"
  type        = bool
  default     = true
}


variable "allowed_ssh_cidr" {
  description = "CIDR blocks allowed to SSH into bastion"
  type        = list(string)
}

variable "key_pair_name" {
  description = "Name of AWS EC2 key pair for SSH access"
  type        = string
}


variable "ami_id" {
  description = "AMI ID for EC2 instances (Ubuntu 24.04 recommended)"
  type        = string
}

variable "instance_type_public" {
  description = "Instance type for public EC2 instances (AZ1)"
  type        = string
  default     = "t3.micro"
}

variable "instance_type_private" {
  description = "Instance type for private EC2 instances (AZ1 and AZ2)"
  type        = string
  default     = "t3.small"
}

variable "dynamodb_billing_mode" {
  description = "DynamoDB billing mode: PROVISIONED or PAY_PER_REQUEST"
  type        = string
  default     = "PAY_PER_REQUEST"
  validation {
    condition     = contains(["PROVISIONED", "PAY_PER_REQUEST"], var.dynamodb_billing_mode)
    error_message = "Billing mode must be either PROVISIONED or PAY_PER_REQUEST."
  }
}


variable "dynamodb_read_capacity" {
  description = "Read capacity units (only if billing_mode = PROVISIONED)"
  type        = number
  default     = 5
}

variable "dynamodb_write_capacity" {
  description = "Write capacity units (only if billing_mode = PROVISIONED)"
  type        = number
  default     = 5
}