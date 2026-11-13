# Generated password: no special characters, so it is safe in JDBC URLs and shell
resource "random_password" "db" {
  length  = 24
  special = false
}

resource "aws_db_subnet_group" "main" {
  name       = "${var.name_prefix}-db-subnets"
  subnet_ids = values(local.private_subnet_ids)

  tags = { Name = "${var.name_prefix}-db-subnets" }
}

resource "aws_db_instance" "main" {
  identifier = "${var.name_prefix}-db"

  engine         = "mysql"
  engine_version = "8.4"
  instance_class = var.db_instance_class
  availability_zone = var.db_az
  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true

  username = var.db_username
  password = random_password.db.result

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [local.rds_sg_id]
  publicly_accessible    = false
  multi_az               = false

  backup_retention_period = 1
  deletion_protection     = false
  skip_final_snapshot     = true # dev: nightly destroy must not leave a snapshot behind
  apply_immediately       = true
}

# Allow the EKS nodes (where pods run) to reach MySQL.
# Lives here, so it is recreated with the cluster and never goes stale.
resource "aws_vpc_security_group_ingress_rule" "rds_from_eks" {
  security_group_id            = local.rds_sg_id
  description                  = "MySQL from EKS nodes"
  ip_protocol                  = "tcp"
  from_port                    = 3306
  to_port                      = 3306
  referenced_security_group_id = module.eks.node_security_group_id
}