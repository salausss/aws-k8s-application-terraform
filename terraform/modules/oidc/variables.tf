variable "project_name" {
  description = "Name of the project"
}

#variable "function_name_arn" {
#  description = "ARN of the function created in nba_function module"
#}

variable "s3_name_arn" {
  description = "S3 name created in s3 module"
}

variable "aws_region" {
  description = "AWS region where lambda is deployed"
}

