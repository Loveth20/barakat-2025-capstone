# --- VPC CONFIGURATION ---
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
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

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  
  cluster_endpoint_public_access = true

  # Requirement 4.4: Control Plane Logging
  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  eks_managed_node_groups = {
    default = {
      # Using t3.micro and size 1 to stay within my current 1 vCPU limit
      instance_types = ["t3.micro"]
      capacity_type  = "ON_DEMAND"
      
      min_size     = 1
      max_size     = 3
      desired_size = 1 
    }
  }

  tags = { Project = "Bedrock" }
}

# --- SECTION 4.3: IAM DEVELOPER USER ---
resource "aws_iam_user" "dev_viewer" {
  name = "bedrock-dev-view"
  tags = { Project = "Bedrock" }
}

resource "aws_iam_user_policy_attachment" "dev_read_only" {
  user       = aws_iam_user.dev_viewer.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_access_key" "dev_viewer" {
  user = aws_iam_user.dev_viewer.name
}

# --- SECTION 4.5: S3 BUCKET FOR ASSETS ---
resource "aws_s3_bucket" "assets" {
  # !!! WITH ACTUAL ID !!!
  bucket = "bedrock-assets-ALT/SOE/025/0331"
tags = { Project = "Bedrock" }
}
