variable "project_name" {
    type = string
}

variable "secret_arn" {
  description = "The ARN of the secret from the secrets manager module"
  type        = string
}