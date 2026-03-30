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

provider "kubernetes" {
  host                   = aws_eks_cluster.primary.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.primary.certificate_authority[0].data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.primary.name]
    command     = "aws"
  }
}