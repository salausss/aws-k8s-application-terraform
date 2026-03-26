resource "aws_eks_cluster" "primary" {
  name    = var.cluster_name
  version = var.cluster_version
  role_arn = var.cluster_role_arn

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["52.36.47.99/32"]
  }

  # CORRECTED: service_ipv4_cidr is now nested inside this block
  kubernetes_network_config {
    service_ipv4_cidr = var.service_ipv4_cidr_block
    #service_ipv4_cidr = data.aws_vpc.existing_vpc.cidr_block
  }

  encryption_config {
    resources = ["secrets"]
    provider {
      key_arn = var.kms_key_arn
    }
  }
}

# Data source to get the OIDC provider's certificate for thumbprint
data "tls_certificate" "eks" {
  url = aws_eks_cluster.primary.identity[0].oidc[0].issuer
}

# Create the IAM OIDC Identity Provider
resource "aws_iam_openid_connect_provider" "this" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.primary.identity[0].oidc[0].issuer

  tags = {
    Name        = "${var.cluster_name}-oidc-provider"
    Environment = "EKS" # Or use a variable for environment
  }
}

# Existing EKS Add-ons (from your example)
resource "aws_eks_addon" "vpc_cni" {
  cluster_name      = aws_eks_cluster.primary.name
  addon_name        = "vpc-cni"
  resolve_conflicts_on_create = "OVERWRITE"

  depends_on = [aws_eks_cluster.primary]  
}

resource "aws_eks_addon" "coredns" {
  cluster_name      = aws_eks_cluster.primary.name
  addon_name        = "coredns"
  resolve_conflicts_on_create = "OVERWRITE"

  depends_on = [
    aws_eks_node_group.application_node,
  ]
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name      = aws_eks_cluster.primary.name
  addon_name        = "kube-proxy"
  resolve_conflicts_on_create = "OVERWRITE"

  depends_on = [
    aws_eks_node_group.application_node,
  ]
}

# ##############################
# # NEW: EBS CSI Driver IRSA Configuration
# ##############################

# 1. Define the Trust Policy for EBS CSI Driver
data "aws_iam_policy_document" "ebs_csi_trust_policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(aws_eks_cluster.primary.identity[0].oidc[0].issuer, "https://", "")}"]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringEquals"
      variable = "${replace(aws_eks_cluster.primary.identity[0].oidc[0].issuer, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(aws_eks_cluster.primary.identity[0].oidc[0].issuer, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

# 2. Create the IAM Role for EBS CSI Driver with the Trust Policy
resource "aws_iam_role" "ebs_csi_driver_role" {
  name               = "${var.cluster_name}-ebs-csi-driver-role" # Use a variable passed into the module
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_trust_policy.json

  tags = {
    "eks.amazonaws.com/cluster-name" = var.cluster_name # Use a variable passed into the module
  }
}

# 3. Attach the Permissions Policy (AWS Managed Policy) to the EBS CSI Role
resource "aws_iam_role_policy_attachment" "ebs_csi_driver_policy_attach" {
  role       = aws_iam_role.ebs_csi_driver_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

# 4. REMOVE THE KUBERNETES SERVICE ACCOUNT RESOURCE FOR EBS CSI DRIVER
#    The aws_eks_addon resource will create this.

# 5. Configure the EKS Addon for EBS CSI Driver to use this Role
resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name             = aws_eks_cluster.primary.name
  addon_name               = "aws-ebs-csi-driver"
  # addon_version          = "v1.48.0-eksbuild.1" # Specify if you need a specific version
  resolve_conflicts_on_create = "OVERWRITE"
  service_account_role_arn = aws_iam_role.ebs_csi_driver_role.arn # Link the role here

  depends_on = [
    aws_iam_role_policy_attachment.ebs_csi_driver_policy_attach,
    aws_eks_node_group.application_node,
    aws_eks_node_group.database_node,
  ]
}

# ##############################
# # NEW: EFS CSI Driver IRSA Configuration (Similar to EBS, needs its own role)
# ##############################

# 1. Define the Trust Policy for EFS CSI Driver
data "aws_iam_policy_document" "efs_csi_trust_policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(aws_eks_cluster.primary.identity[0].oidc[0].issuer, "https://", "")}"]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringEquals"
      variable = "${replace(aws_eks_cluster.primary.identity[0].oidc[0].issuer, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:efs-csi-controller-sa"] # EFS SA name
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(aws_eks_cluster.primary.identity[0].oidc[0].issuer, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

# 2. Create the IAM Role for EFS CSI Driver with the Trust Policy
resource "aws_iam_role" "efs_csi_driver_role" {
  name               = "${var.cluster_name}-efs-csi-driver-role" # Use a variable passed into the module
  assume_role_policy = data.aws_iam_policy_document.efs_csi_trust_policy.json

  tags = {
    "eks.amazonaws.com/cluster-name" = var.cluster_name # Use a variable passed into the module
  }
}

# 3. Attach the Permissions Policy (AWS Managed Policy) to the EFS CSI Role
resource "aws_iam_role_policy_attachment" "efs_csi_driver_policy_attach" {
  role       = aws_iam_role.efs_csi_driver_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy" # EFS permissions policy
}

# 4. REMOVE THE KUBERNETES SERVICE ACCOUNT RESOURCE FOR EFS CSI DRIVER
#    The aws_eks_addon resource will create this.

# 5. Configure the EKS Addon for EFS CSI Driver to use this Role
resource "aws_eks_addon" "efs_csi_driver" {
  cluster_name             = aws_eks_cluster.primary.name # CHANGE HERE
  addon_name               = "aws-efs-csi-driver"
  # addon_version          = "v1.x.x-eksbuild.x" # Specify if you need a specific version
  resolve_conflicts_on_create = "OVERWRITE"
  service_account_role_arn = aws_iam_role.efs_csi_driver_role.arn # Link the role here

  depends_on = [
    aws_iam_role_policy_attachment.efs_csi_driver_policy_attach,
    aws_eks_node_group.application_node,
    aws_eks_node_group.database_node,
  ]
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}


# Application Node Group
resource "aws_eks_node_group" "application_node" {
  cluster_name    = aws_eks_cluster.primary.name
  node_group_name = var.application_node_name
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.subnet_ids
  instance_types  = [var.application_pool_machine_type]
  disk_size       = var.application_pool_disk_size_gb

  scaling_config {
    desired_size = var.application_pool_node_count
    min_size     = var.application_pool_min_node_count
    max_size     = var.application_pool_max_node_count
  }

  update_config {
    max_unavailable = var.application_pool_max_unavailable
  }

  taint {
    key    = "type"
    value  = "application"
    effect = "NO_SCHEDULE"
  }
  labels = {
    "node-type" = "application"
  }
  ami_type = "AL2_x86_64"

  depends_on = [aws_eks_cluster.primary]
}

# Database Node Group
resource "aws_eks_node_group" "database_node" {
  cluster_name    = aws_eks_cluster.primary.name
  node_group_name = var.database_node_name
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.subnet_ids
  instance_types  = [var.database_pool_machine_type]
  disk_size       = var.database_pool_disk_size_gb

  scaling_config {
    desired_size = var.database_pool_node_count
    min_size     = var.database_pool_min_node_count
    max_size     = var.database_pool_max_node_count
  }

  update_config {
    max_unavailable = var.database_pool_max_unavailable
  }

  taint {
    key    = "type"
    value  = "database"
    effect = "NO_SCHEDULE"
  }
  labels = {
    "type" = "database"
  }
  ami_type = "AL2_x86_64"

  depends_on = [aws_eks_cluster.primary]
}