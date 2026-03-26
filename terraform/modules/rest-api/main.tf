resource "aws_api_gateway_rest_api" "betterment_api" {
  name        = "${var.project_name}-rest-api"
  description = "Gateway for the betterment Lambda function"
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.betterment_api.id
  parent_id   = aws_api_gateway_rest_api.betterment_api.root_resource_id
  path_part   = "user"
}

resource "aws_api_gateway_deployment" "nba_deploy" {
  depends_on  = [
    aws_api_gateway_integration.lambda_integration_get,
    aws_api_gateway_integration.lambda_integration_patch,
    aws_api_gateway_method.history_get,
    aws_api_gateway_method.history_options,
    aws_api_gateway_method.nba_method,
    aws_api_gateway_method.patch,
    aws_api_gateway_method.proxy_options,
    aws_api_gateway_method.root_options,
    aws_api_gateway_integration.history_integration,
    aws_api_gateway_integration.history_options_integration,
    aws_api_gateway_integration.proxy_options_integration,
    aws_api_gateway_integration.root_options_integration   
  ]
  rest_api_id = aws_api_gateway_rest_api.betterment_api.id
  
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.proxy,
      aws_api_gateway_resource.proxy,
      aws_api_gateway_method.history_get,
      aws_api_gateway_method.history_options,
      aws_api_gateway_method.nba_method,
      aws_api_gateway_method.patch,
      aws_api_gateway_method.proxy_options,
      aws_api_gateway_method.root_options,
      aws_api_gateway_integration.history_integration,
      aws_api_gateway_integration.history_options_integration,
      aws_api_gateway_integration.proxy_options_integration,
      aws_api_gateway_integration.root_options_integration

  ]))
  }
   lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "gateway_stage" {
  deployment_id = aws_api_gateway_deployment.nba_deploy.id
  rest_api_id   = aws_api_gateway_rest_api.betterment_api.id
  stage_name    = var.stage_name
}

resource "aws_lambda_permission" "get_user_data_lambda_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.get_user_data_funtion_name
  principal     = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.betterment_api.execution_arn}/*/*"
}

# Defining Cognito Authorizer
resource "aws_api_gateway_authorizer" "cognito_auth" {
  name                   = "${var.project_name}-CognitoAuthorizer"
  rest_api_id            = aws_api_gateway_rest_api.betterment_api.id
  type                   = "COGNITO_USER_POOLS"
  provider_arns          = [var.cognito_user_pool_arn]
  # Tells API Gateway to look for the token in the 'Authorization' header
  identity_source        = "method.request.header.Authorization"
}

# 2. Attach the Authorizer to a specific API Method (e.g., GET /users)
resource "aws_api_gateway_method" "nba_method" {
  rest_api_id   = aws_api_gateway_rest_api.betterment_api.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "GET"
  
  # This is the crucial link:
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito_auth.id
}

resource "aws_api_gateway_integration" "lambda_integration_get" {
  rest_api_id             = aws_api_gateway_rest_api.betterment_api.id
  resource_id             = aws_api_gateway_resource.proxy.id
  http_method             = aws_api_gateway_method.nba_method.http_method
  integration_http_method = "POST" 
  type                    = "AWS_PROXY"
  uri                     = var.get_user_data_lambda_invoke_arn
  content_handling        = "CONVERT_TO_TEXT"
}

resource "aws_api_gateway_method" "patch" {
  rest_api_id   = aws_api_gateway_rest_api.betterment_api.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "PATCH"
  
  # Attach Cognito
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito_auth.id
}

resource "aws_api_gateway_integration" "lambda_integration_patch" {
  rest_api_id             = aws_api_gateway_rest_api.betterment_api.id
  resource_id             = aws_api_gateway_resource.proxy.id
  http_method             = aws_api_gateway_method.patch.http_method
  integration_http_method = "POST" 
  type                    = "AWS_PROXY"
  uri                     = var.get_user_data_lambda_invoke_arn
}

##### for Get user History Lambda

resource "aws_api_gateway_resource" "history" {
  rest_api_id = aws_api_gateway_rest_api.betterment_api.id
  parent_id   = aws_api_gateway_rest_api.betterment_api.root_resource_id
  path_part   = "history"
}

resource "aws_api_gateway_method" "history_get" {
  rest_api_id   = aws_api_gateway_rest_api.betterment_api.id
  resource_id   = aws_api_gateway_resource.history.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito_auth.id
}

resource "aws_api_gateway_integration" "history_integration" {
  rest_api_id             = aws_api_gateway_rest_api.betterment_api.id
  resource_id             = aws_api_gateway_resource.history.id
  http_method             = aws_api_gateway_method.history_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.get_history_lambda_invoke
}

resource "aws_api_gateway_method_response" "history_method_response" {
  rest_api_id = aws_api_gateway_rest_api.betterment_api.id
  resource_id = aws_api_gateway_resource.history.id
  http_method = aws_api_gateway_method.history_get.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_lambda_permission" "get_history_lambda_permission" {
  statement_id  = "AllowExecutionFromAPIGatewayHistory"
  action        = "lambda:InvokeFunction"
  function_name = var.get_history_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.betterment_api.execution_arn}/*/*"
}

################################################################################
# CORS CONFIGURATION
################################################################################

# --- CORS for Resource: /user (aws_api_gateway_resource.proxy) ---

resource "aws_api_gateway_method" "proxy_options" {
  rest_api_id   = aws_api_gateway_rest_api.betterment_api.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "proxy_options_integration" {
  rest_api_id = aws_api_gateway_rest_api.betterment_api.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "proxy_options_response" {
  rest_api_id = aws_api_gateway_rest_api.betterment_api.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy_options.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "proxy_options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.betterment_api.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy_options.http_method
  status_code = aws_api_gateway_method_response.proxy_options_response.status_code

  depends_on = [aws_api_gateway_integration.proxy_options_integration]

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,PATCH'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# --- CORS for Resource: /history (aws_api_gateway_resource.history) ---


resource "aws_api_gateway_method" "history_options" {
  rest_api_id   = aws_api_gateway_rest_api.betterment_api.id
  resource_id   = aws_api_gateway_resource.history.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "history_options_integration" {
  rest_api_id = aws_api_gateway_rest_api.betterment_api.id
  resource_id = aws_api_gateway_resource.history.id
  http_method = aws_api_gateway_method.history_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "history_options_response" {
  rest_api_id = aws_api_gateway_rest_api.betterment_api.id
  resource_id = aws_api_gateway_resource.history.id
  http_method = aws_api_gateway_method.history_options.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "history_options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.betterment_api.id
  resource_id = aws_api_gateway_resource.history.id
  http_method = aws_api_gateway_method.history_options.http_method
  status_code = aws_api_gateway_method_response.history_options_response.status_code

  depends_on = [aws_api_gateway_integration.history_options_integration]

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# --- Gateway Responses (Default 4XX and 5XX CORS) ---

resource "aws_api_gateway_gateway_response" "response_4xx" {
  rest_api_id   = aws_api_gateway_rest_api.betterment_api.id
  response_type = "DEFAULT_4XX"

  response_parameters = {
    "gatewayresponse.header.Access-Control-Allow-Origin"  = "'*'"
    "gatewayresponse.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
  }
}

resource "aws_api_gateway_gateway_response" "response_5xx" {
  rest_api_id   = aws_api_gateway_rest_api.betterment_api.id
  response_type = "DEFAULT_5XX"

  response_parameters = {
    "gatewayresponse.header.Access-Control-Allow-Origin"  = "'*'"
    "gatewayresponse.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
  }
}

# --- CORS for Root Resource: / (aws_api_gateway_rest_api.betterment_api.root_resource_id) ---

resource "aws_api_gateway_method" "root_options" {
  rest_api_id   = aws_api_gateway_rest_api.betterment_api.id
  resource_id   = aws_api_gateway_rest_api.betterment_api.root_resource_id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "root_options_integration" {
  rest_api_id = aws_api_gateway_rest_api.betterment_api.id
  resource_id = aws_api_gateway_rest_api.betterment_api.root_resource_id
  http_method = aws_api_gateway_method.root_options.http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "root_options_response" {
  rest_api_id = aws_api_gateway_rest_api.betterment_api.id
  resource_id = aws_api_gateway_rest_api.betterment_api.root_resource_id
  http_method = aws_api_gateway_method.root_options.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "root_options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.betterment_api.id
  resource_id = aws_api_gateway_rest_api.betterment_api.root_resource_id
  http_method = aws_api_gateway_method.root_options.http_method
  status_code = aws_api_gateway_method_response.root_options_response.status_code

  depends_on = [aws_api_gateway_integration.root_options_integration]

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,PATCH'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}