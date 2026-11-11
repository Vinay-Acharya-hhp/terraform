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