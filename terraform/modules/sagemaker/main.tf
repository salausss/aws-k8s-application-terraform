# IAM Role for the Notebook
resource "aws_iam_role" "nba_sagemaker_role" {
  name = "${var.project_name}-sagemaker-notebook-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "sagemaker.amazonaws.com" }
    }]
  })
}

# 1. Define the Lambda Invoke Policy
resource "aws_iam_policy" "lambda_invoke_policy" {
  name        = "${var.project_name}-lambda-invoke"
  description = "Allows SageMaker to invoke Lambda functions"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = [
          "lambda:InvokeFunction",      # To run it
          "lambda:InvokeFunctionUrl",
          "lambda:GetFunction",         # To see details
          "lambda:ListFunctions",       # To find it
          "lambda:GetFunctionConfiguration", # To read env vars/configs
          "dynamodb:Query",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem"

        ]
        Effect   = "Allow"
        Resource = "*" # You can restrict this to specific Lambda ARNs for better security
      }
    ]
  })
}

# 2. Attach it to your existing role
resource "aws_iam_role_policy_attachment" "lambda_access" {
  role       = aws_iam_role.nba_sagemaker_role.name
  policy_arn = aws_iam_policy.lambda_invoke_policy.arn
}

# Attach AmazonSageMakerFullAccess (Fine-tune this for production!)
resource "aws_iam_role_policy_attachment" "sagemaker_full_access" {
  role       =  aws_iam_role.nba_sagemaker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
}

resource "aws_iam_role_policy_attachment" "bedrock_access" {
  role       = aws_iam_role.nba_sagemaker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonBedrockFullAccess"
}



# The SageMaker Notebook Instance
resource "aws_sagemaker_notebook_instance" "nba_notebook" {
  name          = var.project_name
  role_arn      = aws_iam_role.nba_sagemaker_role.arn
  instance_type = var.instance_type

  # Optional: Add a lifecycle configuration or Git repository
  lifecycle_config_name = var.lifecycle_config_name
}