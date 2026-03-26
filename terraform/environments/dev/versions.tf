terraform {
  required_version = ">= 1.5.0"
  
  backend "s3" {
    bucket         = "salah-training-period"
    key            = "dev/terraform.tfstate"
    region         = "ap-south-1"
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
        Environment = "dev"
        Project     = "PIP-project"
        Owner       = "platform-team"
        ManagedBy   = "terraform"
    }
  } 
}