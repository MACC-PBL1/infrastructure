resource "aws_vpc_peering_connection" "this" {
  vpc_id        = var.this_vpc_id
  peer_vpc_id   = var.peer_vpc_id
  peer_owner_id = var.peer_account_id
  peer_region   = var.peer_region
  auto_accept   = false

  tags = {
    Name = "${var.name_prefix}-vpc-peering"
    Side = "requester"
  }
}
