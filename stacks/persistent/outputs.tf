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

output "alb_sg_id" {
  value = aws_security_group.alb.id
}

output "rds_sg_id" {
  value = aws_security_group.rds.id
}

output "redis_sg_id" {
  value = aws_security_group.redis.id
}

output "ecr_repository_urls" {
  description = "Map of service name to repository URL"
  value       = { for k, r in aws_ecr_repository.svc : k => r.repository_url }
}

output "frontend_bucket" {
  value = module.frontend_bucket.id
}

output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.main.id
}

output "cloudfront_domain" {
  value = aws_cloudfront_distribution.main.domain_name
}

output "github_plan_role_arn" {
  value = aws_iam_role.ci["plan"].arn
}

output "github_apply_role_arn" {
  value = aws_iam_role.ci["apply"].arn
}