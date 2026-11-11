terraform {
  required_version = ">= 1.10"
#terraform init -backend-config=envs/dev.backend.hcl -migrate-state
#terraform state list
#terraform plan -var-file=envs/dev.tfvars    # should say: No changes
  backend "s3" {
    bucket       = "epharmacy-tfstate-960233595057-ap-south-1"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true
    # key is supplied per environment at init time
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}