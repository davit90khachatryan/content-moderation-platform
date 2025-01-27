
resource "aws_iam_role" "lambda_role" {
  name = "lambda-moderation-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_lambda_function" "moderation_function" {
  function_name = "moderation-function"
  role          = aws_iam_role.lambda_role.arn
  handler       = "moderation.handler"
  runtime       = "python3.9"
  filename      = "lambda_function.zip"
}
