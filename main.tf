module "demo_bucket" {
  source = "./modules/s3-bucket"

  bucket_name = var.bucket_name
  environment = var.environment

  tags = {
    Owner = "platform-team"
  }
}

