output "vpc_id" {
  value = aws_vpc.main.id
}

output "vpc_cidr" {
  value = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "Map of AZ key to subnet ID, e.g. { 1a = subnet-..., 1b = subnet-... }"
  value       = { for k, s in aws_subnet.public : k => s.id }
}

output "private_subnet_ids" {
  value = { for k, s in aws_subnet.private : k => s.id }
}

output "private_route_table_ids" {
  description = "The daily stack adds the NAT route to these"
  value       = { for k, rt in aws_route_table.private : k => rt.id }
}