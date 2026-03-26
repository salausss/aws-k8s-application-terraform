resource "aws_cloudfront_origin_access_control" "betterment_oac" {
  name                              = "${var.project_name}-oac" 
  description                       = "Ui origin access control for s3"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "nba_cloudfront" {
  comment   = "Ui origin access control for s3"
  origin {
    #domain_name = var.s3_website_endpoint
    domain_name = var.s3_regional_name
    origin_id   = "s3-website-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.betterment_oac.id
    connection_attempts      = 3
    connection_timeout       = 10
  }

  enabled             = true
  is_ipv6_enabled     = false
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "s3-website-origin"

    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
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
