data "terraform_remote_state" "network" {
  backend = "local"

  config = {
    path = "../01-network/terraform.tfstate"
  }
}

module "vpc_peering" {
  source = "../../../modules/vpc_peering"

  name_prefix     = var.name_prefix
  this_vpc_id     = data.terraform_remote_state.network.outputs.vpc_id
  peer_vpc_id     = var.peer_vpc_id
  peer_account_id = var.peer_account_id
  peer_region     = var.peer_region
}

resource "aws_route" "to_peer" {
  route_table_id            = data.terraform_remote_state.network.outputs.private_route_table_id
  destination_cidr_block    = var.peer_vpc_cidr
  vpc_peering_connection_id = module.vpc_peering.peering_id
}
