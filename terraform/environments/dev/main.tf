
module "vpc" {
  source                = "../../modules/networking"
  project_name          = var.project_name
  env                   = var.environment
  vpc_cidr              = "10.1.0.0/16"
  azs                   = ["ap-south-1a", "ap-south-1b"]
  public_subnet_cidrs   = ["10.1.1.0/24", "10.1.2.0/24"]
  private_subnet_cidrs  = ["10.1.11.0/24", "10.1.12.0/24"]
}

module "kms" {
  source                = "../../modules/kms"
  name                  = var.project_name
  alias                 = "kms_alias"
  environment           = var.environment
  description           = "kms_description"
}

module "eks" {
  source                  = "../../modules/eks"
  cluster_name            = var.project_name
  cluster_version         = 1.35
  subnet_ids              = module.vpc.private_subnet_ids
  kms_key_arn             = module.kms.key_arn
  cluster_node_name       = "cluster_node_pip"
  application_node_name   = "application"
  database_node_name      = "database"
  user_arn                = var.user_arn
  username                = var.username
}
