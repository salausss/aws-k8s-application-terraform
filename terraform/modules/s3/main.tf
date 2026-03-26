resource "aws_s3_bucket" "nba_bucket" {
    #for_each = var.bucket_name
    bucket   = var.bucket_name
}

resource "aws_s3_bucket_versioning" "versioning" {
    #for_each    =   var.bucket_name
    bucket      =   aws_s3_bucket.nba_bucket.id
    versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Disabled"
  }
}

resource   "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
    #for_each    =   var.bucket_name
    bucket      =   aws_s3_bucket.nba_bucket.id

    rule {
        bucket_key_enabled  =   true
        apply_server_side_encryption_by_default {
            sse_algorithm   =   "AES256"
        }
    }
}

resource    "aws_s3_bucket_public_access_block" "block_public" {
    #for_each    =   var.bucket_name
    bucket      =   aws_s3_bucket.nba_bucket.id

    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
}

resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.nba_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

