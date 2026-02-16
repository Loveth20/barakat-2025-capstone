terraform {
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

# --- VPC CONFIGURATION ---
# This creates the network, fixes the "blackhole" route issue by using IGW,
# and ensures subnets automatically assign public IPs.
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "bedrock-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]

  # --- CRITICAL FIXES ---
  enable_nat_gateway     = false # Connects directly to Internet Gateway
  single_nat_gateway     = false
  map_public_ip_on_launch = true # Fixes Ec2SubnetInvalidConfiguration error
}

# --- EKS CLUSTER & NODE GROUP CONFIGURATION ---
# This creates the cluster, manages the IAM roles, and sets up the worker nodes.
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "bedrock-eks-cluster"
  cluster_version = "1.31"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnets

  # THIS LINE IS ALL YOU NEED
  enable_cluster_creator_admin_permissions = true

  # Remove the "admin" entry from here to stop the conflict
  access_entries = {} 

  cluster_endpoint_public_access = true

  eks_managed_node_groups = {
    main = {
      instance_types = ["t3.medium"]
      min_size       = 1
      max_size       = 3
      desired_size   = 2
    }
  }
}

