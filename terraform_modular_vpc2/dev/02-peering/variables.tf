variable "project_name" {}

variable "peer_vpc_peering_id" {
  description = "Peering ID created by the requester"
}

variable "peer_vpc_cidr" {
  description = "CIDR of the requester VPC"
}

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
