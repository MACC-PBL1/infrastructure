variable "project_name" {}
variable "environment" {}

variable "allowed_ssh_cidr" {
  type = list(string)
}

variable "key_pair_name" {}

variable "ami_id" {}

variable "instance_type_public" {}
variable "instance_type_private" {}

variable "common_tags" {
  type = map(string)
}

variable "firehose_role_arn" {
  description = "IAM Role ARN for Kinesis Firehose"
}

variable "dynamodb_billing_mode" {}
variable "dynamodb_read_capacity" {}
variable "dynamodb_write_capacity" {}

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

variable "peer_vpc_cidr" {
  description = "CIDR of bastion VPC"
  type        = string
}
