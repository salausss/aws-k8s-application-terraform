data "aws_region" "current" { }

# The WebSocket API Container
resource "aws_apigatewayv2_api" "websocket_api" {
  name                       = "${var.project_name}-${var.api_name}"
  protocol_type              = "WEBSOCKET"
  route_selection_expression = "$request.body.action"
}

# The Integration (The bridge to Lambda)
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id                    = aws_apigatewayv2_api.websocket_api.id
  integration_type          = "AWS_PROXY"
  #integration_uri          = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${var.lambda_function_invoke_arn}/invocations"
  integration_uri           = var.lambda_function_invoke_arn
  content_handling_strategy = "CONVERT_TO_TEXT"
  passthrough_behavior      = "WHEN_NO_MATCH"
  #integration_method       = "POST"

}

# The Default Route (Catches everything not defined)
resource "aws_apigatewayv2_route" "default_route" {
  api_id    = aws_apigatewayv2_api.websocket_api.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# Permission for API Gateway to call Lambda
resource "aws_lambda_permission" "apigw_lambda" {
  for_each      = toset(var.websocket_routes)

  statement_id  = "AllowExecutionFromAPIGateway-${replace(each.key, "$", "")}"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.websocket_api.execution_arn}/*/${each.key}"
}

# Permission for API Gateway to call Lambda (connect)
resource "aws_lambda_permission" "apigw_lambda_connect" {
  statement_id  = "AllowExecutionFromAPIGateway-connect"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.websocket_api.execution_arn}/*/$connect"
}

resource "aws_lambda_permission" "apigw_lambda_authorizer" {
  statement_id  = "AllowExecutionFromAPIGateway-Authorizer"
  action        = "lambda:InvokeFunction"
  function_name = var.auth_function_arn 
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.websocket_api.execution_arn}/authorizers/${aws_apigatewayv2_authorizer.websocket_authorizer.id}"
}

# Dynamic Routes (Disconnect, SendMessage)
resource "aws_apigatewayv2_route" "routes" {
  for_each  = toset(var.websocket_routes)
  
  api_id    = aws_apigatewayv2_api.websocket_api.id
  route_key = each.key
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# Dynamic Routes (Connect)
resource "aws_apigatewayv2_route" "routes_connect" {  
  api_id    = aws_apigatewayv2_api.websocket_api.id
  route_key = "$connect"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.websocket_authorizer.id
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_deployment" "deployment" {
  api_id      = aws_apigatewayv2_api.websocket_api.id
  description = "Terraform deployment"

  # CRITICAL: This forces a new deployment whenever routes or integrations change
   triggers = {
    redeployment = sha1(join(",", [
      jsonencode(aws_apigatewayv2_integration.lambda_integration),
      jsonencode(aws_apigatewayv2_route.default_route),
      jsonencode(aws_apigatewayv2_route.routes), 
      jsonencode(aws_apigatewayv2_route.routes_connect),
      jsonencode(var.websocket_routes),
      jsonencode(aws_apigatewayv2_authorizer.websocket_authorizer),

    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_apigatewayv2_route.default_route,
    aws_apigatewayv2_route.routes,
    aws_apigatewayv2_integration.lambda_integration,
    aws_apigatewayv2_route.routes_connect
  ]
}

resource "aws_apigatewayv2_stage" "stage" {
  api_id        = aws_apigatewayv2_api.websocket_api.id
  name          = var.stage_name
  deployment_id = aws_apigatewayv2_deployment.deployment.id 
  auto_deploy = false
}

resource "aws_apigatewayv2_authorizer" "websocket_authorizer" {
  api_id           = aws_apigatewayv2_api.websocket_api.id
  authorizer_type  = "REQUEST"
  authorizer_uri   = var.auth_invoke_arn
  # Matches "Identity sources: token (Query string)" in your screenshot
  identity_sources = ["route.request.querystring.token"] 
  name             = "CognitoWebSocketAuthorizerUAT"
}