provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "eks_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
}

# Fetch available availability zones in the current AWS region
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "eks_subnets" {
  count = 2
  vpc_id = aws_vpc.eks_vpc.id
  cidr_block = "10.0.${count.index}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]
}

resource "aws_eks_cluster" "my_eks" {
  name     = "my-eks-cluster"
  role_arn = var.eks_role_arn
  vpc_config {
    subnet_ids = aws_subnet.eks_subnets[*].id
  }
}

resource "aws_eks_node_group" "my_node_group" {
  cluster_name    = aws_eks_cluster.my_eks.name
  node_group_name = "my-node-group"
  node_role_arn   = var.node_role_arn
  subnet_ids      = aws_subnet.eks_subnets[*].id

  scaling_config {
    desired_size = 2
    max_size     = 4
    min_size     = 1
  }
}