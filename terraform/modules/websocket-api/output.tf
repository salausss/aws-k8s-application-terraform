output "websocket_api" {
  value = aws_apigatewayv2_api.websocket_api.id
}

output "apigatewayv2_source_arn" {
  value = aws_apigatewayv2_api.websocket_api.execution_arn
}