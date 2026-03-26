variable "project_name" {
  type = string
}

variable "cognito_user_pool_arn" {
  description = "ARN used in apigateway for authorization"
}

variable "get_user_data_lambda_invoke_arn" {
  type = string
}

variable "stage_name" {
  type = string
}

variable "get_history_lambda_invoke" {
  type = string
}

variable "get_history_function_name" {
  type = string
}

variable "get_user_data_funtion_name" {
  type = string
}