# Read the persistent stack's outputs straight from its state file
data "terraform_remote_state" "persistent" {
  backend = "s3"

  config = {
    bucket = var.state_bucket
    key    = "dev/persistent/terraform.tfstate"
    region = var.region
  }
}

locals {
  p = data.terraform_remote_state.persistent.outputs

  vpc_id                  = local.p.vpc_id
  vpc_cidr                = local.p.vpc_cidr
  public_subnet_ids       = local.p.public_subnet_ids
  private_subnet_ids      = local.p.private_subnet_ids
  private_route_table_ids = local.p.private_route_table_ids
  alb_sg_id               = local.p.alb_sg_id
  rds_sg_id               = local.p.rds_sg_id
  redis_sg_id             = local.p.redis_sg_id
}