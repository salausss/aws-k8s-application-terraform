resource "aws_iam_role" "auth_role" {
  name = "${var.project_name}-authorizer-role"

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
# This allows your Authorizer to write "Success/Error" logs to CloudWatch
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.auth_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# The Custom Secret Manager Permission 
resource "aws_iam_role_policy" "read_secret" {
  name = "AllowReadAuthSecret"
  role = aws_iam_role.auth_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ 
      Action   = "secretsmanager:GetSecretValue", 
      Effect   = "Allow", 
      #Resource = module.secretmanager.secret_arn
      Resource = var.secret_arn
    }]
  })
}

data "archive_file" "auth_zip" {
  type        = "zip"
  source_file = "${path.module}/../../src/authorizer.py" 
  output_path = "${path.module}/auth_code.zip"          
}

resource "aws_lambda_function" "auth" {
  #filename      = "auth_code.zip"
  filename         = data.archive_file.auth_zip.output_path
  source_code_hash = data.archive_file.auth_zip.output_base64sha256
  function_name = "${var.project_name}-authorizer"
  role          = aws_iam_role.auth_role.arn
  handler       = "authorizer.handler"
  runtime       = "python3.11"
  depends_on    = [data.archive_file.auth_zip]

  environment {
    variables = { SECRET_ARN = var.secret_arn }
  }
}
