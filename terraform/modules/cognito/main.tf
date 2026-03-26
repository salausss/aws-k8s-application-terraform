resource "aws_cognito_user_pool" "pool" {
  name = "${var.project_name}-user-pool"

  # We remove 'email' here so Cognito defaults to standard 'Username' login.
  # alias_attributes         = ["email"] 
  # auto_verified_attributes = ["email"]

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }

  # Since we don't care about verified emails, we set recovery to admin only.
  account_recovery_setting {
    recovery_mechanism {
      name     = "admin_only"
      priority = 1
    }
  }

  # This allows your import script to ignore the email field entirely.
  schema {
    attribute_data_type = "String"
    name                = "email"
    required            = false # Changed from true
    mutable             = true

    string_attribute_constraints {
      min_length = 0 # Changed from 1 to allow empty values
      max_length = 256
    }
  }
}

resource "aws_cognito_user_pool_client" "client" {
  name                = "${var.project_name}-app-client"
  user_pool_id        = aws_cognito_user_pool.pool.id
  generate_secret     = false 
  explicit_auth_flows = ["ALLOW_USER_PASSWORD_AUTH", "ALLOW_REFRESH_TOKEN_AUTH", "ALLOW_USER_SRP_AUTH","ALLOW_ADMIN_USER_PASSWORD_AUTH"]
  access_token_validity  = 60
  id_token_validity      = 60
  refresh_token_validity = 30

  allowed_oauth_flows                           = [
        "code",
    ]
    allowed_oauth_flows_user_pool_client          = true
    allowed_oauth_scopes                          = [
        "email",
        "openid",
        "profile",
    ]
    auth_session_validity                         = 3
    callback_urls                                 = [
        "http://localhost:5173/",
        "https://${var.cloudfront_domain_name}" ,
    ]
  enable_propagate_additional_user_context_data   = false
  enable_token_revocation                       = true

  logout_urls                                   = [
        "http://localhost:5173/",
        "https://${var.cloudfront_domain_name}" , ]

  default_redirect_uri = "http://localhost:5173/"

  supported_identity_providers                  = [
        "COGNITO",
    ]
  

  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }
}

resource "aws_cognito_user_pool_domain" "main" {
  domain       = "${var.project_name}-app-auth"
  user_pool_id = aws_cognito_user_pool.pool.id
  #cloudfront_distribution_arn = var.cloudfront_distribution_arn
}