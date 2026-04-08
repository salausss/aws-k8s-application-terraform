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
  policy_arn = "arn:aws:iam::aws:policy/AmazonPrometheusQueryAccess"
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

# ------------ ADOT Role & Policy for Prometheus remote write ------------ #
resource "aws_iam_role" "adot_role" {
  name = "${var.cluster_name}-${var.env}-adot-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = local.oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_issuer}:sub" = "system:serviceaccount:observability:adot-collector"
        }
      }
    }]
  })
}

resource "aws_iam_policy" "adot_amp" {
  name = "${var.cluster_name}-adot-amp-policy"

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
  policy_arn = aws_iam_policy.adot_amp.arn
}

# ------------ AWS Managed Grafana Workspace & Prometheus Workspace ------------ #
resource "aws_prometheus_workspace" "this" {
  alias = "${var.cluster_name}-${var.env}-amp"
}

provider "aws" {
  alias  = "grafana"
  region = "us-east-1" # AMG
}

resource "aws_grafana_workspace" "this" {
  provider = aws.grafana 
  name                     = "${var.cluster_name}-${var.env}-grafana"
  account_access_type      = "CURRENT_ACCOUNT"
  authentication_providers = ["AWS_SSO"]
  permission_type          = "SERVICE_MANAGED"
  role_arn = aws_iam_role.grafana_role.arn
  region = "us-east-1" # Grafana is only available in us-east-1, but can query AMP in other regions
}

# ------------ ADOT Collector Helm Chart for Prometheus Remote Write ------------ #
resource "helm_release" "adot" {
  name       = "adot-collector"
  repository = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart      = "opentelemetry-collector"
  namespace  = "observability"

  create_namespace = true

  values = [
    yamlencode({
      mode = "daemonset"

      image = {
        repository = "public.ecr.aws/aws-observability/aws-otel-collector"
        tag        = "latest" 
      } 

      serviceAccount = {
        create = true
        name   = "adot-collector"
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.adot_role.arn
        }
      }

      config = {
        extensions = {
          sigv4auth = {
            region = var.region
          }
        health_check = {} 
        }
        
        receivers = {
          prometheus = {
            config = {
              scrape_configs = [
                {
                  job_name = "kubernetes-nodes"
                  kubernetes_sd_configs = [{ role = "node" }]
                },
                {
                  job_name = "kubernetes-pods"
                  kubernetes_sd_configs = [{ role = "pod" }]
                }
              ]
            }
          }
        }

        exporters = {
          prometheusremotewrite = {
            endpoint = "${aws_prometheus_workspace.this.prometheus_endpoint}/api/v1/remote_write"

            auth = {
              authenticator = "sigv4auth"
            }
          }
        }

        service = {
          extensions = ["sigv4auth", "health_check"] 

          pipelines = {
            metrics = {
              receivers  = ["prometheus"]
              exporters  = ["prometheusremotewrite"]
            }
          }
        }
      }
    })
  ]

  depends_on = [
    aws_iam_role_policy_attachment.adot_attach
  ]
}