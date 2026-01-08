variable "name_prefix" {
  description = "Prefix for naming resources"
  type        = string
}

variable "this_vpc_id" {
  description = "VPC ID of the requester"
  type        = string
}

variable "peer_vpc_id" {
  description = "VPC ID of the peer"
  type        = string
}

variable "peer_account_id" {
  description = "AWS account ID of the peer owner"
  type        = string
}

variable "peer_region" {
  description = "AWS region of the peer VPC"
  type        = string
}
