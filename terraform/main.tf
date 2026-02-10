terraform {
  backend "s3" {
    bucket         = "bedrock-terraform-state-altsoe0250331"
    key            = "eks/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Keep ONLY the VPC and Subnets here if they aren't in another file
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "bedrock-vpc" }
}

resource "aws_subnet" "subnet_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "subnet_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "main" { vpc_id = aws_vpc.main.id }

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet_a.id
  route_table_id = aws_route_table.main.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.subnet_b.id
  route_table_id = aws_route_table.main.id
}
# --- IAM Role for the Cluster ---
resource "aws_iam_role" "eks_cluster" {
  name = "bedrock-eks-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { 
        Service = [
          "eks.amazonaws.com",
          "lambda.amazonaws.com" # <--- Add this line!
        ] 
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

# --- EKS Node Group ---
#resource "aws_eks_node_group" "main" {
  # Update this line to point to the module output
 # cluster_name    = module.eks.cluster_name 
  
  #node_group_name = "main-node-group"
  #node_role_arn = aws_iam_role.eks_nodes.arn
  #subnet_ids      = [aws_subnet.subnet_a.id, aws_subnet.subnet_b.id]

  #scaling_config {
    #desired_size = 2
    #max_size     = 3
    #min_size     = 1
 # }

  #instance_types = ["t3.medium"]
#}
# --- The EKS Cluster ---
#resource "aws_eks_cluster" "main" {
 # name     = "project-bedrock-cluster" # This MUST match the name in AWS
  #role_arn = aws_iam_role.eks_cluster.arn
  #enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  #vpc_config {
   # subnet_ids = [aws_subnet.subnet_a.id, aws_subnet.subnet_b.id]
  #}

#  lifecycle {
 #   ignore_changes = [
  #    access_config[0].bootstrap_cluster_creator_admin_permissions,
   # ]
  #}
#}
