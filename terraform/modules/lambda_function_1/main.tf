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


# Define custom policy for dynamodb access for chat-api-handler function

data "aws_iam_policy_document" "dynamodb_permissions" {
  statement {
    sid    = "DynamoDBPermissions"
    effect = "Allow"

    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:Query",
      "dynamodb:ListTables"
    ]

    resources = ["arn:aws:dynamodb:us-east-1:944508510388:table/${var.project_name}-*"]
  }
}

resource "aws_iam_policy" "custom_policy_for_DyDB" {
  name        = "${var.project_name}-DyDB_access_through_lambda"
  description = "Custom policy for DyDB related"
  policy      = data.aws_iam_policy_document.dynamodb_permissions.json
}

resource "aws_iam_role_policy_attachment" "custom_DyDB_access" {
  role       = aws_iam_role.lambda_function_role.name
  policy_arn = aws_iam_policy.custom_policy_for_DyDB.arn
}

resource "aws_iam_role_policy_attachment" "AmazonAPIGatewayInvokeFullAccess" {
  role       = aws_iam_role.lambda_function_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonAPIGatewayInvokeFullAccess"
}

resource "aws_iam_role_policy_attachment" "AmazonBedrockFullAccess" {
  role       = aws_iam_role.lambda_function_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonBedrockFullAccess"
}

resource "aws_lambda_layer_version" "chatbot_layer" {
  
  filename   = "${path.module}/../../src/layers/chatbot-module-layer.zip"
  layer_name = "chatbot-module-layer"
  #source_code_hash = filebase64sha256("${path.module}/../../../src/layers/chatbot-module-layer.zip")
  compatible_runtimes      = ["python3.12"]
  compatible_architectures = ["x86_64"]
}

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
    aws_lambda_layer_version.chatbot_layer.arn
  ] 
  architectures    = var.architectures

  # vpc_config {
  #  subnet_ids         = var.subnet_ids
  #  security_group_ids = var.security_group_ids
  #}

  environment {
    variables = {
      # We construct the URL format: https://{api_id}.execute-api.{region}.amazonaws.com/{stage}/user
      CHAT_API_URL         = "https://${var.api_gateway_id}.execute-api.${var.aws_region}.amazonaws.com/${var.stage_name}/user"
      USER_PROFILE_API_URL = "https://${var.api_gateway_id}.execute-api.${var.aws_region}.amazonaws.com/${var.stage_name}/user"
      
      DB_TABLE_NAME        = var.dynamodb_name
      MODEL_ID             = var.model_name
      REGION               = var.aws_region
    }
  }

  publish = true

  lifecycle {
    ignore_changes = [
      filename,
      source_code_hash,
      last_modified
    ]
  }
}

resource "aws_lambda_alias" "lambda_alias" {
  name             = var.lambda_alias_name
  description      = "Alias for the ${var.lambda_alias_name} version of the Lambda function"
  function_name    = aws_lambda_function.lambda_function.function_name
  function_version = aws_lambda_function.lambda_function.version 

  lifecycle {
    ignore_changes = [
      function_version,
      routing_config 
    ]
  }
}

resource "aws_lambda_provisioned_concurrency_config" "concurrency_config" {
  function_name                = aws_lambda_function.lambda_function.function_name
  qualifier                    = aws_lambda_alias.lambda_alias.name 
  provisioned_concurrent_executions = var.provisioned_concurrency_count
  depends_on = [aws_lambda_alias.lambda_alias]
}