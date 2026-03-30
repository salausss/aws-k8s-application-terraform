variable "eks_vpc_id" {
  description = "ID of the Terraform-managed EKS VPC"
  type        = string
}

variable "eks_vpc_cidr" {
  description = "CIDR of the EKS VPC"
  type        = string
}

variable "eks_route_table_ids" {
  description = "List of Route Table IDs in the EKS VPC to update"
  type        = list(string)
}

variable "manual_ec2_vpc_id" {
  description = "ID of the manually created EC2 VPC"
  type        = string
}

variable "eks_security_group_id" {
  type = string
}