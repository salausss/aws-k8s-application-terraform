variable "api_name" {
  type        = string
  description = "Name of the WebSocket API"
}

variable "lambda_function_invoke_arn" {
  type        = string
  description = "ARN of the Lambda function to trigger"
}

variable "lambda_function_arn" {
  type        = string
  description = "ARN of the Lambda function to trigger"
}

variable "stage_name" {
  type        = string
}

variable "project_name" {
  type = string
}

# Define the routes we want to create
variable "websocket_routes" {
  type    = list(string)
  default = ["$disconnect", "sendMessage"]
}

#variable "connect_route" {
#  type = string
#  default = ["$connect"]
#}

variable "auth_function_arn" {
  type = string
}

variable "auth_invoke_arn" {
  type = string
}