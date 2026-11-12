data "aws_caller_identity" "current" {}

locals {
  frontend_bucket_name = "${var.name_prefix}-frontend-${data.aws_caller_identity.current.account_id}-${var.region}"
  has_alb              = var.alb_dns_name != ""
}

# Private bucket for the React build (reuses your module)
module "frontend_bucket" {
  source = "../../modules/s3-bucket"

  bucket_name        = local.frontend_bucket_name
  environment        = var.environment
  versioning_enabled = false # build output is reproducible

  tags = { Purpose = "frontend" }
}

# Managed CloudFront policies, looked up by name
data "aws_cloudfront_cache_policy" "optimized" {
  name = "Managed-CachingOptimized"
}

data "aws_cloudfront_cache_policy" "disabled" {
  name = "Managed-CachingDisabled"
}

data "aws_cloudfront_origin_request_policy" "all_viewer_except_host" {
  name = "Managed-AllViewerExceptHostHeader"
}

# OAC: lets CloudFront read the private bucket
resource "aws_cloudfront_origin_access_control" "s3" {
  name                              = "${var.name_prefix}-s3-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# SPA routing: /cart, /orders etc. serve index.html (default behavior only)
resource "aws_cloudfront_function" "spa_rewrite" {
  name    = "${var.name_prefix}-spa-rewrite"
  runtime = "cloudfront-js-2.0"
  publish = true
  code    = <<-EOT
    function handler(event) {
      var request = event.request;
      if (request.uri.indexOf('.') === -1) {
        request.uri = '/index.html';
      }
      return request;
    }
  EOT
}

resource "aws_cloudfront_distribution" "main" {
  enabled             = true
  comment             = "${var.name_prefix} frontend and API"
  default_root_object = "index.html"
  price_class         = "PriceClass_200" # includes India

  # Origin 1: the S3 bucket
  origin {
    domain_name              = "${module.frontend_bucket.id}.s3.${var.region}.amazonaws.com"
    origin_id                = "s3"
    origin_access_control_id = aws_cloudfront_origin_access_control.s3.id
  }

  # Origin 2: the ALB, only when alb_dns_name is set
  dynamic "origin" {
    for_each = local.has_alb ? [1] : []
    content {
      domain_name = var.alb_dns_name
      origin_id   = "alb"

      custom_origin_config {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "http-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    }
  }

  # Default: static site from S3
  default_cache_behavior {
    target_origin_id       = "s3"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    cache_policy_id        = data.aws_cloudfront_cache_policy.optimized.id
    compress               = true

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.spa_rewrite.arn
    }
  }

  # /api/* goes to the ALB (no caching, all methods, no SPA function)
  dynamic "ordered_cache_behavior" {
    for_each = local.has_alb ? [1] : []
    content {
      path_pattern             = "/api/*"
      target_origin_id         = "alb"
      viewer_protocol_policy   = "redirect-to-https"
      allowed_methods          = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
      cached_methods           = ["GET", "HEAD"]
      cache_policy_id          = data.aws_cloudfront_cache_policy.disabled.id
      origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer_except_host.id
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

# Only this distribution may read the bucket
data "aws_iam_policy_document" "frontend_read" {
  statement {
    sid       = "AllowCloudFrontOAC"
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::${module.frontend_bucket.id}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.main.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "frontend" {
  bucket = module.frontend_bucket.id
  policy = data.aws_iam_policy_document.frontend_read.json
}