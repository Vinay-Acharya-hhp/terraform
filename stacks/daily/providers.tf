terraform {
  required_version = ">= 1.10"

  backend "s3" {
    bucket       = "epharmacy-tfstate-960233595057-ap-south-1"
    key          = "dev/daily/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = "epharmacy"
      Environment = var.environment
      ManagedBy   = "terraform"
      Stack       = "daily"
    }
  }
}