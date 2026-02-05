data "aws_eks_cluster_auth" "cluster" {
  name = "project-bedrock-cluster"
}

provider "kubernetes" {
  host                   = aws_eks_cluster.bedrock.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.bedrock.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}
