# CloudFront's origin-facing IP ranges, maintained by AWS
data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

# ALB: reachable only from CloudFront
resource "aws_security_group" "alb" {
  name        = "${var.name_prefix}-alb-sg"
  description = "ALB, inbound from CloudFront only"
  vpc_id      = aws_vpc.main.id

  tags = { Name = "${var.name_prefix}-alb-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "alb_from_cloudfront" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTP from CloudFront"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  prefix_list_id    = data.aws_ec2_managed_prefix_list.cloudfront.id
}

# Terraform removes the default allow-all egress rule, so the ALB
# needs one to reach the gateway pods and answer health checks.
resource "aws_vpc_security_group_egress_rule" "alb_all" {
  security_group_id = aws_security_group.alb.id
  description       = "ALB to targets"
  ip_protocol       = "-1"
  cidr_ipv4         = var.vpc_cidr
}

# RDS MySQL: no inbound rules yet; the daily stack adds
# "3306 from the EKS cluster SG" once the cluster exists.
resource "aws_security_group" "rds" {
  name        = "${var.name_prefix}-rds-sg"
  description = "MySQL from EKS"
  vpc_id      = aws_vpc.main.id

  tags = { Name = "${var.name_prefix}-rds-sg" }
}

# Redis (Valkey): same pattern, port 6379 added later
resource "aws_security_group" "redis" {
  name        = "${var.name_prefix}-redis-sg"
  description = "Redis from EKS"
  vpc_id      = aws_vpc.main.id

  tags = { Name = "${var.name_prefix}-redis-sg" }
}