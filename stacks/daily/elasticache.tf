resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.name_prefix}-redis-subnets"
  subnet_ids = values(local.private_subnet_ids)
}

resource "aws_elasticache_replication_group" "main" {
  replication_group_id = "${var.name_prefix}-redis"
  description          = "epharmacy cache (rate limiter and service caching)"

  engine               = "valkey"
  engine_version       = "7.2"
  parameter_group_name = "default.valkey7"
  node_type            = "cache.t4g.micro"
  port                 = 6379

  # Single node, cluster mode disabled
  num_cache_clusters         = 1
  automatic_failover_enabled = false
  multi_az_enabled           = false

  subnet_group_name  = aws_elasticache_subnet_group.main.name
  security_group_ids = [local.redis_sg_id]

  # Your apps have no TLS or password settings
  transit_encryption_enabled = false
  at_rest_encryption_enabled = true

  apply_immediately = true
}

resource "aws_vpc_security_group_ingress_rule" "redis_from_eks" {
  security_group_id            = local.redis_sg_id
  description                  = "Redis from EKS nodes"
  ip_protocol                  = "tcp"
  from_port                    = 6379
  to_port                      = 6379
  referenced_security_group_id = module.eks.node_security_group_id
}