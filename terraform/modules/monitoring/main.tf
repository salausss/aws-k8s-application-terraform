# ------------ IAM Role for Grafana ------------ #
resource "aws_iam_role" "grafana_role" {
  name = "${var.cluster_name}-${var.env}-grafana-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "grafana.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "grafana_amp_access" {
  role       = aws_iam_role.grafana_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonPrometheusReadOnlyAccess"
}

# ------------ IAM Role for Prometheus remote write ------------ #
resource "aws_iam_policy" "amp_remote_write" {
  name = "${var.cluster_name}-${var.env}-amp-remote-write"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "aps:RemoteWrite",
        "aps:GetSeries",
        "aps:GetLabels",
        "aps:GetMetricMetadata"
      ]
      Resource = aws_prometheus_workspace.this.arn
    }]
  })
}

resource "aws_iam_role_policy_attachment" "adot_attach" {
  role       = aws_iam_role.adot_role.name
  policy_arn = aws_iam_policy.amp_remote_write.arn
}

# ------------ OIDC details from EKS for ADOT Role ------------ #
data "aws_caller_identity" "current" {}

data "aws_eks_cluster" "primary" {
  name = var.cluster_name
}

data "aws_iam_openid_connect_provider" "eks" {
  url = data.aws_eks_cluster.primary.identity[0].oidc[0].issuer
}

locals {
  oidc_issuer       = replace(data.aws_eks_cluster.primary.identity[0].oidc[0].issuer, "https://", "")
  oidc_provider_arn = data.aws_iam_openid_connect_provider.eks.arn
}

# ------------ ADOT Role for Prometheus remote write ------------ #
resource "aws_iam_role" "adot_role" {
  name = "${var.cluster_name}-${var.env}-adot-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = locals.oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${locals.oidc_issuer}:sub" = "system:serviceaccount:observability:adot-collector"
        }
      }
    }]
  })
}

# ------------ AWS Managed Grafana Workspace & Prometheus Workspace ------------ #
resource "aws_prometheus_workspace" "this" {
  alias = "${var.cluster_name}-${var.env}-amp"
}

resource "aws_grafana_workspace" "this" {
  name                     = "${var.cluster_name}-${var.env}-grafana"
  account_access_type      = "CURRENT_ACCOUNT"
  authentication_providers = ["AWS_SSO"]
  permission_type          = "SERVICE_MANAGED"
  role_arn = aws_iam_role.grafana_role.arn
}

