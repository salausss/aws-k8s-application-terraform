output "execution_arn" { value = aws_api_gateway_rest_api.betterment_api.execution_arn }

output "base_url" { value = aws_api_gateway_stage.gateway_stage.invoke_url }

output "rest_api_id" {
  value = aws_api_gateway_rest_api.betterment_api.id
}

output "cognito_auth_id" {
  value = aws_api_gateway_authorizer.cognito_auth.id
}

output "parent_id" {
  value = aws_api_gateway_rest_api.betterment_api.root_resource_id
}