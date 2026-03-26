resource "random_password" "api_key" {
  length  = 32
  special = false
}

resource "aws_secretsmanager_secret" "api_key" {
  name        = "${var.project_name}-auth-key"
  description = "API Key for authorizing incoming requests"
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_secretsmanager_secret_version" "key_value" {
  secret_id     = aws_secretsmanager_secret.api_key.id
  secret_string = jsonencode({ api_key = random_password.api_key.result })
  #secret_string = jsonencode({
  #  api_key = var.initial_api_key_value
  #})
}