# Create the IAM User
resource "aws_iam_user" "dev_viewer" {
  name = "bedrock-dev-view"
  tags = { Project = "Bedrock" }
}

# Attach ReadOnlyAccess (AWS Managed Policy)
resource "aws_iam_user_policy_attachment" "read_only" {
  user       = aws_iam_user.dev_viewer.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# Create Access Keys (Required for Deliverables)
resource "aws_iam_access_key" "dev_viewer" {
  user = aws_iam_user.dev_viewer.name
}

# Output the keys (Keep these safe for your submission!)
output "dev_viewer_access_key" {
  value = aws_iam_access_key.dev_viewer.id
}

output "dev_viewer_secret_key" {
  value     = aws_iam_access_key.dev_viewer.secret
  sensitive = true
}
