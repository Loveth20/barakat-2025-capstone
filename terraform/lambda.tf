# 1. Zip the code
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/index.py"
  output_path = "${path.module}/lambda_function_payload.zip"
}

# 2. The Lambda Function
resource "aws_lambda_function" "asset_processor" {
  filename      = data.archive_file.lambda_zip.output_path
  function_name = "bedrock-asset-processor" # This is the "Official" name
  role          = aws_iam_role.eks_cluster.arn # Using your existing cluster role
  handler       = "index.lambda_handler"
  runtime       = "python3.11"

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
}

# 3. Permission for S3 to knock on Lambda's door
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.asset_processor.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::bedrock-assets-altsoe0250331"
}

# 4. The Trigger (Link the Bucket to the Lambda)
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = "bedrock-assets-altsoe0250331"

  lambda_function {
    lambda_function_arn = aws_lambda_function.asset_processor.arn
    events              = ["s3:ObjectCreated:*"]
  }
  depends_on = [aws_lambda_permission.allow_s3]
}
