output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "nat_gateway_id" {
  value = var.enable_nat_gateway ? aws_nat_gateway.nat[0].id : null
}

output "public_route_table_id" {
  value = aws_route_table.public_rt.id  # Assuming only ONE public RT (no count)
}

output "private_route_table_ids" {
  value = aws_route_table.private_rt[*].id
}

output "vpc_cidr" {
  value = aws_vpc.this.cidr_block
}