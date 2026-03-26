output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.nba_cloudfront.domain_name
}

output "cloudfront_arn" {
  value = aws_cloudfront_distribution.nba_cloudfront.arn
}