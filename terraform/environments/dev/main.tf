
module "vpc" {
  source                = "../../modules/networking"
  project_name          = var.project_name
  env                   = var.environment
  vpc_cidr            = "10.1.0.0/16"
  azs                 = ["us-east-1a", "us-east-1b"]
  public_subnet_cidrs  = ["10.1.1.0/24", "10.1.2.0/24"]
  private_subnet_cidrs = ["10.1.11.0/24", "10.1.12.0/24"]
}

