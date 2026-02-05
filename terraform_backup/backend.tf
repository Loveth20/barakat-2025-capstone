terraform {
  required_version = ">= 1.6.0"

  backend "s3" {
    bucket         = "bedrock-terraform-state-altsoe0250331"
    key            = "project-bedrock/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "bedrock-terraform-locks"
    encrypt        = true
  }
}

