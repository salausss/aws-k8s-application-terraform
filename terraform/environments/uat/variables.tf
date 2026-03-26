# General variables
variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "environment" {
    type      = string
}

variable "bucket_name" {
    type = string
}

variable "project_name" {
    type = string
}

## Lambda function

variable "stage_name" {
  description = "API Gateway Stage name"
  type        = string
}

variable "timeout" {
  type    = number
  default = 30
}

variable "ephemeral_storage" {
  type    = number
  default = 512
}

variable "memory_size" {
  type    = number
  default = 128
}

variable "architectures" {
  type    = list(string)
  default = null
}

#variable "secret_arn" {
#  description = "The ARN of the secret from the secrets manager module"
#  type        = string
#}

#variable "api_execution_arn" {
#  description = "ARN that can invoke lambda function"
#  type = list(string)
#}

## Networking variables
variable "vpc_cidr" {
  type = string
}

variable "azs" {
  type = list(string)
}

variable "public_subnet_cidrs" {
  type = list(string)
}

variable "private_subnet_cidrs" {
  type = list(string)
}

## DynamoDB variables

variable "table_name" {
  description = "Name of the DynamoDB table"
  type        = string
}

variable "billing_mode" {
  description = "Controls how you are charged: PROVISIONED or PAY_PER_REQUEST"
  type        = string
  default     = "PAY_PER_REQUEST"
}

variable "hash_key" {
  description = "The attribute to use as the partition key"
  type        = string
}

variable "range_key" {
  description = "The attribute to use as the sort key (optional)"
  type        = string
  default     = null
}

variable "attributes" {
  description = "List of nested attribute definitions"
  type        = list(map(string))
}

variable "ttl_enabled" {
  type    = bool
  default = false
}

variable "ttl_attribute" {
  type    = string
  default = "TimeToLive"
}

variable "pitr_enabled" {
  description = "Enable Point-in-time recovery"
  type        = bool
  default     = false
}

variable "tags" {
  type    = map(string)
  default = {}
}