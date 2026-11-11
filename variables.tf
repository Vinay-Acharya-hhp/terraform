variable "region" {
  type    = string
  default = "ap-south-1"
}

variable "environment" {
  type        = string
  description = "dev, staging, or prod"
}

variable "bucket_name" {
  type = string
}