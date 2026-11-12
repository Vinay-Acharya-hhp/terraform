# Static public IP for the NAT gateway
resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = { Name = "${var.name_prefix}-nat-eip" }
}

# One NAT gateway in public subnet 1a (single NAT = cheaper dev setup)
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = local.public_subnet_ids["1a"]

  tags = { Name = "${var.name_prefix}-nat-1a" }
}

# Default route for each private subnet -> NAT.
# These live in the daily stack, so they are destroyed together with the NAT
# and never leave a blackhole route behind.
resource "aws_route" "private_nat" {
  for_each = local.private_route_table_ids

  route_table_id         = each.value
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main.id
}