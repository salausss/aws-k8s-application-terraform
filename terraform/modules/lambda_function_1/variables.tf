variable "project_name" {
    type = string
}

variable "aws_region" {
  type = string
}

variable "api_gateway_id" {
  type = string
}

variable "stage_name" {
  description = "API Gateway Stage name"
  type        = string
  default     = "dev"
}

variable "dynamodb_name" {
  type = string
}

variable "model_name" {
  type = string
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
  default = ["x86_64"]
}

variable "runtime" {
  type = string
}

variable "handler" {
  type = string
}

variable "function_name" {
  type = string
}

variable "lambda_alias_name" {
  description = "The name for the Lambda function alias."
  type        = string
  default     = "latest" 
}

variable "provisioned_concurrency_count" {
  description = "The amount of provisioned concurrency for the Lambda alias."
  type        = number
  default     = 2 
}