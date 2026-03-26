variable "project_name" {
  description = "Name of the application"
  type = string
}

#variable "cloudfront_distribution_arn" {
#  type = string
#}

variable "cloudfront_domain_name" {
  description = "The domain name of the CloudFront distribution (e.g., d1234.cloudfront.net)"
  type        = string
}

