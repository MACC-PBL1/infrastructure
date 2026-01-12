variable "instances" {
    type = map(object({
        instance_type = string
        subnet_id     = string
        public_ip     = bool
        private_ip    = optional(string)
        user_data     = optional(string)
    }))
}

variable "ami" {
    description = "The AMI ID to use for the EC2 instances"
    type        = string
}

variable "sg_id" {
    description = "The security group ID to associate with the EC2 instances"
    type        = string
}

variable "key_name" {
    description = "The key pair name to use for the EC2 instances"
    type        = string
}