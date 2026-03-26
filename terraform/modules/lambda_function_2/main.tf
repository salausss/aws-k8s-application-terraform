resource "aws_iam_role" "lambda_function_role" {
  
  name = "${var.project_name}-${var.function_name}-role"
  # The Trust Policy: Tells AWS that Lambda is allowed to use this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Basic Logging Permissions
# Attachment for Basic Execution (CloudWatch Logs)
resource "aws_iam_role_policy_attachment" "lambda_logs_access" {
  role       = aws_iam_role.lambda_function_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Attachment for VPC Access (Network Interfaces)
resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  role       = aws_iam_role.lambda_function_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

#resource "aws_iam_role_policy_attachment" "AmazonAPIGatewayInvokeFullAccess" {
#  role       = aws_iam_role.lambda_function_role.name
#  policy_arn = "arn:aws:iam::aws:policy/AmazonAPIGatewayInvokeFullAccess"
#}

# Data Zip for Lambda function
data "archive_file" "betterment_lambda_function_zip" {
  type        = "zip"
  source_file = "${path.module}/../../src/function_code/recommend.py" 
  output_path = "${path.module}/nba_function.zip"
}

resource "aws_lambda_function" "lambda_function" {
  filename          = data.archive_file.betterment_lambda_function_zip.output_path
  source_code_hash  = data.archive_file.betterment_lambda_function_zip.output_base64sha256
  function_name     = "${var.project_name}-${var.function_name}"
  role              = aws_iam_role.lambda_function_role.arn
  handler           = var.handler
  runtime           = var.runtime
  timeout           = var.timeout
  memory_size       = var.memory_size
  depends_on        = [data.archive_file.betterment_lambda_function_zip]

  layers           = [
    "arn:aws:lambda:us-east-1:770693421928:layer:Klayers-p312-arm64-requests:21",
    "arn:aws:lambda:us-east-1:944508510388:layer:auth-layer:2"
  ] 
  architectures    = var.architectures

  # vpc_config {
  #  subnet_ids         = var.subnet_ids
  #  security_group_ids = var.security_group_ids
  #}

  #environment {
  #  variables = {
  #    # We construct the URL format: https://{api_id}.execute-api.{region}.amazonaws.com/{stage}/user
  #    CHAT_API_URL         = "https://${var.api_gateway_id}.execute-api.${var.aws_region}.amazonaws.com/${var.stage_name}/user"
  #    USER_PROFILE_API_URL = "https://${var.api_gateway_id}.execute-api.${var.aws_region}.amazonaws.com/${var.stage_name}/user"
  #    
  #    DB_TABLE_NAME        = var.dynamodb_name
  #    MODEL_ID             = var.model_name
  #    REGION               = var.aws_region
  #  }
  #}

  lifecycle {
    ignore_changes = [
      filename,
      source_code_hash,
      last_modified,
    ]

 }
}

resource "aws_apigatewayv2_authorizer" "cognito_auth" {
  api_id           = var.api_gateway_id
  
  name             = "CognitoWebSocketAuthorizer"
  authorizer_type  = "REQUEST"
  authorizer_uri   = aws_lambda_function.lambda_function.invoke_arn
  identity_sources = ["route.request.querystring.token"]
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.apigatewayv2_source_arn}/authorizers/${aws_apigatewayv2_authorizer.cognito_auth.id}"
}