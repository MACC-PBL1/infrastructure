variable "project_name" {}

variable "peer_vpc_peering_id" {
  description = "Peering ID created by the requester"
}

variable "peer_vpc_cidr" {
  description = "CIDR of the requester VPC"
}
