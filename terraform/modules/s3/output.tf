output "bucket_id" { 
    value = aws_s3_bucket.nba_bucket.id 
    }
output "bucket_arn" {
     value = aws_s3_bucket.nba_bucket.arn 
    }
output "bucket_regional_domain_name" {
     value = aws_s3_bucket.nba_bucket.bucket_regional_domain_name 
    }

output "website_endpoint" {
  value = aws_s3_bucket_website_configuration.website.website_endpoint
}
