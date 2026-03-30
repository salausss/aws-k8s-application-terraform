# 1. Look up the manual VPC details
data "aws_vpc" "manual" {
  id = var.manual_ec2_vpc_id
}

# 2. Look up all Route Tables in that manual VPC
data "aws_route_tables" "manual_rts" {
  vpc_id = var.manual_ec2_vpc_id
}

# 3. Create the Peering Connection
resource "aws_vpc_peering_connection" "this" {
  vpc_id      = var.eks_vpc_id
  peer_vpc_id = var.manual_ec2_vpc_id
  auto_accept = true

  accepter { allow_remote_vpc_dns_resolution = true }
  requester { allow_remote_vpc_dns_resolution = true }

  tags = { Name = "peer-eks-to-manual" }
}

# 4. Add Routes to EKS Route Tables (pointing to manual VPC)
resource "aws_route" "to_manual" {
  # Switch to count. length() is known even if IDs aren't.
  count                     = length(var.eks_route_table_ids)
  
  route_table_id            = var.eks_route_table_ids[count.index]
  destination_cidr_block    = data.aws_vpc.manual.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id
}

# 5. Add Routes to Manual Route Tables (pointing to EKS VPC)
resource "aws_route" "to_eks" {
  # Since the manual VPC already exists, data source IDs should be fine,
  # but using count here is safer for a clean plan.
  count                     = length(data.aws_route_tables.manual_rts.ids)
  
  route_table_id            = data.aws_route_tables.manual_rts.ids[count.index]
  destination_cidr_block    = var.eks_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id
}