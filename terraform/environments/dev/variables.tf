# General variables
variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "environment" {
    type      = string
}

variable "project_name" {
    type = string
}

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

# AWS user Authentication 
variable "user_arn" {
  type = string
}

variable "username" {
  type = string
}