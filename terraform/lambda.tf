# 1. Archive the python code into a ZIP file
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/index.py"
  output_path = "${path.module}/lambda_function_payload.zip"
}

# 2. Create the Lambda Function
resource "aws_lambda_function" "asset_processor" {
  filename      = data.archive_file.lambda_zip.output_path
  function_name = "bedrock-asset-processor"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.lambda_handler"
  runtime       = "python3.11"

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  tags = {
    Project = "Bedrock"
  }
}

# 3. Create the S3 Bucket Notification (Requirement 4.5)
resource "aws_s3_bucket_notification" "bucket_notification" {
  # Change this to use the resource reference
  bucket = aws_s3_bucket.assets.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.asset_processor.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_s3]
}
#4. Give S3 permission to trigger the Lambda
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.asset_processor.function_name
  principal     = "s3.amazonaws.com"
  
  # Using the ARN string directly to avoid "undeclared resource" errors
  source_arn    = "arn:aws:s3:::bedrock-assets-altsoe0250331"
}
