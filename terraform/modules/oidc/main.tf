data "aws_caller_identity" "current" {}

data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com"
}

# 2. Create the OIDC Provider
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]
}

resource "aws_iam_role" "github_actions_role" {
  name = "${var.project_name}-github-actions-oidc-role"

  # The Trust Policy: Restricts access to your specific GitHub repo
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:Betterment/ai-quantiphi-agent:*"
          }
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

# 1. Define the Policy
resource "aws_iam_policy" "lambda_deploy" {
  name        = "${var.project_name}-GitHubLambdaDeployPolicy"
  description = "Allows GitHub Actions to deploy code to Lambda"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:UpdateFunctionCode",
          "lambda:UpdateFunctionConfiguration",
          "lambda:GetFunctionConfiguration",
          "lambda:GetFunction"
        ]
        # Restrict this to your specific Lambda ARNs for maximum security
        Resource = "arn:aws:lambda:${var.aws_region}:${data.aws_caller_identity.current.account_id}:function:${var.project_name}-*"

      }
    ]
  })
}

# 2. Attach it to the OIDC Role
resource "aws_iam_role_policy_attachment" "attach_lambda_deploy" {
  role       = aws_iam_role.github_actions_role.name
  policy_arn = aws_iam_policy.lambda_deploy.arn
}

# Adding Role, policies to deploy frontend from GitHub Action Pipeline

resource "aws_iam_role" "frontend_deploy_role" {
  name = "${var.project_name}-frontend-deploy-role"

  # The Trust Policy: Restricts access to your specific GitHub repo
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:Betterment/ai-quantiphi-agent:*"
          }
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "frontend_deploy" {
  name        = "${var.project_name}-GitHubFrontendDeployPolicy"
  description = "Allows GitHub Actions to deploy code to FrontEnd"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        # Restrict this to your specific Lambda ARNs for maximum security
        Resource = var.s3_name_arn
      }
    ]
  })
}

# 2. Attach it to the OIDC Role
resource "aws_iam_role_policy_attachment" "attach_function_deploy" {
  role       = aws_iam_role.frontend_deploy_role.name
  policy_arn = aws_iam_policy.frontend_deploy.arn
}

