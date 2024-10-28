provider "aws" {
  region = "us-east-1"
}

# Create VPC
resource "aws_vpc" "eks_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "eks-vpc"
  }
}

# Fetch available availability zones in the current AWS region
data "aws_availability_zones" "available" {
  state = "available"
}

# Create Subnets
resource "aws_subnet" "eks_subnets" {
  count                   = 2
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = "10.0.${count.index}.0/24"
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = "eks-subnet-${count.index}"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "eks_igw" {
  vpc_id = aws_vpc.eks_vpc.id
  tags = {
    Name = "eks-igw"
  }
}

# Create Route Table
resource "aws_route_table" "eks_route_table" {
  vpc_id = aws_vpc.eks_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eks_igw.id
  }
  tags = {
    Name = "eks-route-table"
  }
}

# Associate Route Table with Subnets
resource "aws_route_table_association" "eks_route_table_assoc" {
  count          = 2
  subnet_id      = aws_subnet.eks_subnets[count.index].id
  route_table_id = aws_route_table.eks_route_table.id
}

# Create Security Group for EKS Control Plane
resource "aws_security_group" "eks_control_plane_sg" {
  vpc_id = aws_vpc.eks_vpc.id
  description = "EKS Control Plane Security Group"
  tags = {
    Name = "eks-control-plane-sg"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create Security Group for Node Group
resource "aws_security_group" "eks_node_sg" {
  vpc_id = aws_vpc.eks_vpc.id
  description = "EKS Node Group Security Group"
  tags = {
    Name = "eks-node-sg"
  }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EKS Cluster
resource "aws_eks_cluster" "my_eks" {
  name     = "my-eks-cluster"
  role_arn = var.eks_role_arn

  vpc_config {
    subnet_ids         = aws_subnet.eks_subnets[*].id
    security_group_ids = [aws_security_group.eks_control_plane_sg.id]
  }

  tags = {
    Name = "my-eks-cluster"
  }
}

# Node Group
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

  instance_types = ["t3.medium"]

  remote_access {
    ec2_ssh_key = "windows-demo"
    source_security_group_ids = [aws_security_group.eks_node_sg.id]
  }

  tags = {
    Name = "my-node-group"
  }
}
