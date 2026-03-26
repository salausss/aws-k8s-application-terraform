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
#variable "secret_arn" {
#  description = "The ARN of the secret from the secrets manager module"
#  type        = string
#}


variable "dynamodb_user_data" {
  type = string
}