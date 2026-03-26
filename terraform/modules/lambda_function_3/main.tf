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
    sid    = "DynamoDBWritePermissions"
    effect = "Allow"

    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
    ]

    resources = ["arn:aws:dynamodb:us-east-1:944508510388:table/${var.project_name}-*"]
  }
}

resource "aws_iam_policy" "custom_policy_for_DyDB" {
  name        = "${var.project_name}-DyDB_read_write_access"
  description = "Custom policy for DyDB"
  policy      = data.aws_iam_policy_document.dynamodb_permissions.json
}

resource "aws_iam_role_policy_attachment" "custom_DyDB_access" {
  role       = aws_iam_role.lambda_function_role.name
  policy_arn = aws_iam_policy.custom_policy_for_DyDB.arn
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

  #vpc_config {
  #  subnet_ids         = var.subnet_ids
  #  security_group_ids = var.security_group_ids
  #}

  environment {
    variables = {
    
      TABLE_NAME        = var.dynamodb_user_data
      REGION               = var.aws_region
    }
  }

  lifecycle {
    ignore_changes = [
      filename,
      source_code_hash,
      last_modified,
    ]
 }
}
