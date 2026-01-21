variable "ami_id" {
  description = "AMI ID for microservices"
  type        = string
}

variable "instance_type" {
  description = "Instance type for microservices"
  type        = string
}

variable "subnet_id" {
  description = "Private subnet ID"
  type        = string
}

variable "security_group_id" {
  description = "Security group ID for microservices"
  type        = string
}

variable "key_pair_name" {
  description = "EC2 key pair name"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for naming resources"
  type        = string
}

variable "microservices" {
  description = "Map of microservices to deploy"
  type        = map(any)
}
