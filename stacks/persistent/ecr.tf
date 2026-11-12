locals {
  services = [
    "eureka",
    "api-gateway",
    "user",
    "medicine",
    "cart",
    "order",
    "payment",
  ]
}

resource "aws_ecr_repository" "svc" {
  for_each = toset(local.services)

  name                 = "${var.name_prefix}/${each.key}"
  image_tag_mutability = "MUTABLE" # your charts use :latest
  force_delete         = true      # dev only: lets destroy remove repos that still hold images

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }
}

# Keep storage cost down: retain only the 10 most recent images per repo
resource "aws_ecr_lifecycle_policy" "svc" {
  for_each   = aws_ecr_repository.svc
  repository = each.value.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = { type = "expire" }
    }]
  })
}