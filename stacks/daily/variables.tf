variable "region" {
  type    = string
  default = "ap-south-1"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "name_prefix" {
  type    = string
  default = "epharmacy-tf"
}

variable "state_bucket" {
  type    = string
  default = "epharmacy-tfstate-960233595057-ap-south-1"
}

variable "cluster_name" {
  type    = string
  default = "epharmacy-tf"
}

variable "cluster_version" {
  type    = string
  default = "1.35"
}

variable "node_instance_type" {
  type        = string
  description = "t3.medium was rejected by your Free Plan, so m7i-flex.large"
  default     = "m7i-flex.large"
}

variable "node_count" {
  type    = number
  default = 2
}

variable "db_instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "db_username" {
  type    = string
  default = "admin"
}