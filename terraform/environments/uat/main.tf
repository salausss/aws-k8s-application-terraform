module  "s3" {
  source    = "../../modules/s3"
  #project_name  = var.project_name
  bucket_name = var.bucket_name
  enable_versioning = true   
  environment =  var.environment
  #cloudfront_distribution_arn = module.cloudfront.cloudfront_arn
}

module "cloudfront" {
  source = "../../modules/cloudfront"
  project_name = var.project_name
  #s3_website_endpoint = module.s3.website_endpoint
  s3_regional_name = module.s3.bucket_regional_domain_name
  depends_on = [ module.s3 ]
}

module "vpc" {
  source = "../../modules/networking"
  project_name  = var.project_name
  #name                 = "dev"
  vpc_cidr            = "10.1.0.0/16"
  azs                 = ["us-east-1a", "us-east-1b"]
  public_subnet_cidrs  = ["10.1.1.0/24", "10.1.2.0/24"]
  private_subnet_cidrs = ["10.1.11.0/24", "10.1.12.0/24"]
}

#module "dynamodb" {
#  source = "../../modules/dynamodb"
#
#  table_name   = var.table_name
#  billing_mode = var.billing_mode
#  hash_key     = var.hash_key
#  range_key    = var.range_key
#  attributes   = var.attributes
#  #pitr_enabled = false
#  project_name = var.project_name
#}

module "sagemaker_notebook" {
  source        = "../../modules/sagemaker"
  project_name  = var.project_name
  instance_type = "ml.t3.medium"
}

#module "oidc" {
#  source = "../../modules/oidc"
#  project_name = var.project_name
#  s3_name_arn = module.s3.bucket_arn
#  aws_region = var.aws_region
#}

module "Cognito" {
  source                  = "../../modules/cognito"
  project_name            = var.project_name
  cloudfront_domain_name  = module.cloudfront.cloudfront_domain_name
}

module "websocket_api" {
  source                    = "../../modules/websocket-api"
  project_name              = var.project_name
  api_name                  = "websocket_api"
  #cognito_user_pool_arn     = module.Cognito.cognito_user_pool_arn
  stage_name                = var.stage_name
  lambda_function_invoke_arn       = module.chat-api-handler.function_name_invoke_arn
  lambda_function_arn       =   module.chat-api-handler.function_name_arn
  auth_function_arn          =   module.jwt-authorizer.function_name_arn
  auth_invoke_arn       =    module.jwt-authorizer.function_name_invoke_arn
}

module "chat-api-handler" {
  source               = "../../modules/lambda_function_1"
  project_name         = var.project_name
  function_name        = "chat-api-handler"
  handler              = "lambda_function.lambda_handler"
  ephemeral_storage    = 512
  memory_size          = 1024
  timeout              = 360
  runtime              = "python3.12"
  #architectures        = var.architectures
  #subnet_ids           = module.vpc.private_subnet_ids
  #security_group_ids   = [module.vpc.private_security_group_id]
  depends_on           = [ module.vpc ]
  api_gateway_id       = module.rest-api.rest_api_id   
  aws_region           = var.aws_region
  stage_name           = var.stage_name
  dynamodb_name        = module.user_conversation_history.dynamodb_name
  model_name           = "us.anthropic.claude-sonnet-4-5-20250929-v1:0"
}

module "jwt-authorizer" {
  source               = "../../modules/lambda_function_2"
  project_name         = var.project_name
  function_name        = "jwt-authorizer"
  handler              = "lambda_function.lambda_handler"
  ephemeral_storage    = 512
  memory_size          = 128
  timeout              = 3
  runtime              = "python3.14"
  #architectures        = var.architectures
  #subnet_ids           = module.vpc.private_subnet_ids
  #security_group_ids   = [module.vpc.private_security_group_id]
  depends_on           = [ module.vpc ]
  api_gateway_id       = module.websocket_api.websocket_api
  aws_region           = var.aws_region
  stage_name           = var.stage_name
  apigatewayv2_source_arn = module.websocket_api.apigatewayv2_source_arn
}

module "get-user-data" {
  source               = "../../modules/lambda_function_3"
  project_name         = var.project_name
  function_name        = "get-user-data"
  handler              = "lambda_function.lambda_handler"
  ephemeral_storage    = 512
  memory_size          = 128
  timeout              = 3
  runtime              = "python3.14"
  #architectures        = var.architectures
  #subnet_ids           = module.vpc.private_subnet_ids
  #security_group_ids   = [module.vpc.private_security_group_id]
  depends_on           = [ module.vpc ]
  api_gateway_id       = module.rest-api.rest_api_id
  aws_region           = var.aws_region
  stage_name           = var.stage_name
  dynamodb_user_data   = module.user_data.dynamodb_name
}

module "get-chat-history" {
  source               = "../../modules/lambda_function_4"
  project_name         = var.project_name
  function_name        = "get-chat-history"
  handler              = "lambda_function.lambda_handler"
  ephemeral_storage    = 512
  memory_size          = 128
  timeout              = 3
  runtime              = "python3.14"
  #subnet_ids           = module.vpc.private_subnet_ids
  #security_group_ids   = [module.vpc.private_security_group_id]
  depends_on           = [ module.vpc ]
  api_gateway_id       = module.rest-api.rest_api_id
  aws_region           = var.aws_region
  stage_name           = var.stage_name
  dynamodb_get_chat_history = module.user_conversation_history.dynamodb_name
}

module "rest-api" {
  source                              = "../../modules/rest-api"
  project_name                        = var.project_name
  get_user_data_funtion_name          = module.get-user-data.function_name
  get_user_data_lambda_invoke_arn     = module.get-user-data.function_name_invoke_arn
  cognito_user_pool_arn               = module.Cognito.cognito_user_pool_arn
  stage_name                          = var.stage_name
  get_history_function_name           = module.get-chat-history.function_name
  get_history_lambda_invoke           = module.get-chat-history.function_name_invoke_arn
}

module "user_conversation_history" {
  source                  = "../../modules/dydb"
  project_name            = var.project_name
  table_name              = "UserConversationHistory"
  hash_key                = "user_id"
  range_key               = "session_id"
  pitr_enabled            = true 
  attributes              = [
    { name = "user_id", type = "S" },
    { name = "session_id", type = "S" },
    { name = "actual_session_id", type = "S" },
    { name = "timestamp", type = "S" }          
  ]
  global_secondary_indexes = [
    {
      name               = "SessionIndex"
      hash_key           = "actual_session_id"
      range_key          = "timestamp"
      projection_type = "INCLUDE" 
      non_key_attributes = ["turn_id", "user_message", "ai_response"] 
    }
  ]
}

module "user_data" {
  source                 = "../../modules/dydb"
  project_name           = var.project_name
  table_name             = "user-data"
  hash_key               = "user_id"
  pitr_enabled           = false
  attributes             = [
    { name = "user_id", type = "S" }
  ]
}

resource "aws_s3_bucket_policy" "allow_cloudfront_oac" {
  bucket = module.s3.bucket_id

  depends_on = [
    module.s3
  ]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipal"
        Effect    = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action    = "s3:GetObject"
        Resource  = "${module.s3.bucket_arn}/*"
        Condition = {
          StringEquals = {
            # This uses the variable we defined above
            "AWS:SourceArn" = module.cloudfront.cloudfront_arn
          }
        }
      }
    ]
  })
}