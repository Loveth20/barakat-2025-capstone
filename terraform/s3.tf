# Create the S3 Bucket for Assets
resource "aws_s3_bucket" "assets" {
  bucket = "bedrock-assets-altsoe0250331"

  # Recommended: Allow bucket to be destroyed even if it has files (good for Capstone)
  force_destroy = true

  tags = {
    Name    = "Bedrock Assets"
    Project = "Capstone"
  }
}

# Optional but recommended: Block public access
resource "aws_s3_bucket_public_access_block" "assets_block" {
  bucket = aws_s3_bucket.assets.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
