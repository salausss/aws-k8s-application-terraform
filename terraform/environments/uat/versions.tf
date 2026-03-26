terraform {
  required_version = ">= 1.5.0"
  
  backend "s3" {
    bucket         = "betterment-general-purpose-bucket"
    key            = "uat/terraform.tfstate"
    region         = "us-east-1"
    use_lockfile   = true
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6"
    }
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
        Environment = "uat"
        Project     = "betterment_financial_advisor_genai_chatbot"
        Owner       = "platform-team"
        ManagedBy   = "terraform"
    }
  } 
}