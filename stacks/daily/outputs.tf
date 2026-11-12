output "cluster_name" {
  value = module.eks.cluster_name
}

output "alb_controller_role_arn" {
  value = module.alb_controller_irsa.iam_role_arn
}

output "node_security_group_id" {
  description = "RDS and Redis will allow traffic from this group"
  value       = module.eks.node_security_group_id
}

output "rds_endpoint" {
  description = "Bare hostname, no port"
  value       = aws_db_instance.main.address
}

output "db_password" {
  value     = random_password.db.result
  sensitive = true
}

output "redis_endpoint" {
  description = "Bare hostname, no :6379"
  value       = aws_elasticache_replication_group.main.primary_endpoint_address
}