data "terraform_remote_state" "network" {
  backend = "local"
  config = {
    path = "../01-network/terraform.tfstate"
  }
}

resource "aws_vpc_peering_connection_accepter" "from_peer" {
  vpc_peering_connection_id = var.peer_vpc_peering_id
  auto_accept               = true

  tags = {
    Name = "${var.project_name}-peering-accepter"
  }
}

resource "aws_route" "to_peer_private" {
  for_each = toset(
    data.terraform_remote_state.network.outputs.private_route_table_ids
  )

  route_table_id            = each.value
  destination_cidr_block    = var.peer_vpc_cidr
  vpc_peering_connection_id = var.peer_vpc_peering_id
}

resource "aws_route" "to_peer_public" {
  route_table_id            = data.terraform_remote_state.network.outputs.public_route_table_id
  destination_cidr_block    = var.peer_vpc_cidr
  vpc_peering_connection_id = var.peer_vpc_peering_id
}