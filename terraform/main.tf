terraform {
  # Section 4.1: Remote State Management
  backend "s3" {
    bucket         = "jasonmwome-terraform-state-2026"
    key            = "eks/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    use_lockfile   = true  # This removes the warning
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

#resource "aws_vpc"
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name    = "bedrock-vpc"
    Project = "barakat-2025-capstone"
  }
}
# --- Section 4.4: CloudWatch Observability Add-on ---
resource "aws_subnet" "subnet_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name    = "bedrock-subnet-a"
    Project = "barakat-2025-capstone"
  }
}

resource "aws_subnet" "subnet_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name    = "bedrock-subnet-b"
    Project = "barakat-2025-capstone"
  }
}
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = { Project = "barakat-2025-capstone" }
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = { Project = "barakat-2025-capstone" }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet_a.id
  route_table_id = aws_route_table.main.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.subnet_b.id
  route_table_id = aws_route_table.main.id
}

# --- IAM for EKS ---
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
          "eks-fargate-pods.amazonaws.com",
          "lambda.amazonaws.com"
        ]
      }
    }]
  })
  tags = { Project = "barakat-2025-capstone" }
}
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

# --- EKS Cluster ---
resource "aws_eks_cluster" "main" {
  name     = "project-bedrock-cluster"
  version  = "1.31"
  role_arn = aws_iam_role.eks_cluster.arn

  # Section 4.4: Control Plane Logging
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  vpc_config {
    subnet_ids = [aws_subnet.subnet_a.id, aws_subnet.subnet_b.id]
  }

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  tags = { Project = "barakat-2025-capstone" }
}

# --- Section 4.3: Developer Access ---
resource "aws_iam_user" "dev" {
  name = "bedrock-dev-view"
  tags = { Project = "barakat-2025-capstone" }
}

resource "aws_iam_user_policy_attachment" "read_only" {
  user       = aws_iam_user.dev.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "fargate_pod_execution" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.eks_cluster.name
}
resource "aws_iam_role_policy_attachment" "cloudwatch_policy" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.eks_cluster.name
}
resource "aws_iam_access_key" "dev" {
  user = aws_iam_user.dev.name
}

# --- EKS RBAC Access (Access Entries) ---
resource "aws_eks_access_entry" "dev_user" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = aws_iam_user.dev.arn
  type          = "STANDARD"
}

# This tells Terraform to go find the official ARN from AWS directly
resource "aws_eks_access_policy_association" "dev_view_policy" {
  cluster_name  = aws_eks_cluster.main.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
  principal_arn = aws_iam_user.dev.arn

  access_scope {
    type = "cluster"
  }
}
#Outputs ---
output "cluster_endpoint" { value = aws_eks_cluster.main.endpoint }
output "cluster_name" { value = aws_eks_cluster.main.name }
output "region" { value = "us-east-1" }
output "vpc_id" { value = aws_vpc.main.id }
output "assets_bucket_name" { value = "bedrock-assets-jasonmwome-2026-final" }
output "dev_access_key" { value = aws_iam_access_key.dev.id }

output "dev_secret_key" {
  value     = aws_iam_access_key.dev.secret
  sensitive = true
}
