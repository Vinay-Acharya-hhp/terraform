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