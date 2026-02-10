# --- VPC CONFIGURATION ---
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "project-bedrock-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = { Project = "Bedrock" }
}

# --- EKS CLUSTER CONFIGURATION ---
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "project-bedrock-cluster"
  cluster_version = "1.31"

  cluster_endpoint_public_access = true
  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"] # Or your specific IP for better security
  
  vpc_id     = "vpc-0a5ca634bd32ef9c7"
  subnet_ids = ["subnet-0dd1a651b7d7fbadd", "subnet-0e3eb7ac5876d9ff2"]

  # Use existing infrastructure
  create_cluster_security_group = true
  #cluster_security_group_id     = "sg-0548b7de599e5e4d7"
  create_iam_role               = false
  iam_role_arn                  = "arn:aws:iam::597088021675:role/bedrock-eks-cluster-role"
  
  bootstrap_self_managed_addons = false
  create_cloudwatch_log_group    = false
  enable_irsa                   = true
}

# --- NODE GROUP CONFIGURATION ---
resource "aws_eks_node_group" "main" {
  cluster_name    = "project-bedrock-cluster"
  node_group_name = "main-node-group"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = ["subnet-0dd1a651b7d7fbadd", "subnet-0e3eb7ac5876d9ff2"]

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  instance_types = ["t3.medium"]
}

# --- IAM ROLE FOR NODES ---
resource "aws_iam_role" "eks_nodes" {
  name = "project-bedrock-node-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "nodes_worker" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "nodes_cni" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "nodes_ecr" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_nodes.name
}
