variable "bucket_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "versioning_enabled" {
  type    = bool
  default = true
}

variable "tags" {
  type    = map(string)
  default = {}
}