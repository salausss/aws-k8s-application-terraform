# --------------------------------------------------
# GENERAL
# --------------------------------------------------
environment = "uat"
aws_region = "us-east-1"
project_name = "betterment-uat"

## S3 variable
bucket_name  = "betterment-uat-chat-recommendation"

# VPC
vpc_cidr            = "10.0.0.0/16"
azs                 = ["us-east-1a", "us-east-1b"]
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]

## DynamoDB Variables
table_name   = "user-data"
billing_mode = "PAY_PER_REQUEST"
hash_key     = "UserId"
range_key    = "OrderId"

attributes = [
  { name = "UserId", type = "S" },
  { name = "OrderId", type = "S" }
]

## Lambda_variables
stage_name  = "uat"
