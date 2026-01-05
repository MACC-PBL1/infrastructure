variable "name" {
    description = "The name prefix for resources"
    type        = string
}

variable "vpc_id" {
    description = "The ID of the VPC where security resources will be created"
    type        = string
}

variable "allowed_ssh_cidr" {
    description = "List of CIDR blocks allowed to access via SSH"
    type        = list(string)
}
