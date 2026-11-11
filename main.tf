module "demo_bucket" {
  source = "./modules/s3-bucket"

  bucket_name = var.bucket_name
  environment = var.environment

  tags = {
    Owner = "platform-team"
  }
}

moved {
  from = aws_s3_bucket.demo
  to   = module.demo_bucket.aws_s3_bucket.this
}