variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "env" {
  type = string
}

variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string
}

variable "node_role_arn" {
  description = "IAM role ARN for EKS worker nodes"
  type        = string
}

variable "admin_role_arn" {
  type = string
}

variable "developer_role_arn" {
  type = string
}

variable "admin_group_name" {
  description = "K8s group name for admins"
  type        = string
  default     = "eks:admin-group"
}

variable "developer_group_name" {
  description = "K8s group name for developers"
  type        = string
  default     = "eks:developer-group"
}

variable "developer_namespaces" {
  description = "List of namespaces developers are allowed to access"
  type        = list(string)
  default     = ["app", "db"]
}
