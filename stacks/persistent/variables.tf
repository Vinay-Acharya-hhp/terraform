variable "region" {
  type    = string
  default = "ap-south-1"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "name_prefix" {
  type        = string
  description = "Prefix for every resource name, so new resources never collide with the manual ones"
  default     = "epharmacy-tf"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "alb_dns_name" {
  type        = string
  description = "DNS name of the ALB. Empty until the daily stack has created it."
  default     = ""
}

variable "github_repo" {
  type    = string
  default = "Vinay-Acharya-hhp/terraform"
}

variable "state_bucket" {
  type    = string
  default = "epharmacy-tfstate-960233595057-ap-south-1"
}