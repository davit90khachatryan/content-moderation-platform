# IAM Role for the Lambda
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

resource "aws_iam_role_policy" "lambda_policy" {
  name = "lambda-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:*"
      },

      # 1) DynamoDB permissions
      {
        Effect = "Allow",
        Action = [
          "dynamodb:PutItem",
          "dynamodb:UpdateItem"
          # "dynamodb:GetItem" if needed, etc.
        ],
        Resource = "arn:aws:dynamodb:us-east-1:039612865454:table/FlaggedContent"
      },

      # 2) SQS permissions
      {
        Effect = "Allow",
        Action = [
          "sqs:SendMessage"
        ],
        Resource = var.sqs_queue_arn
      }
    ]
  })
}

# Get AWS Account ID
data "aws_caller_identity" "current" {}


# NLTK Layer
resource "aws_lambda_layer_version" "nltk_layer" {
  layer_name          = "my-nltk-layer"
  filename            = "${path.root}/nltk_layer/nltk_layer.zip"
  compatible_runtimes = ["python3.9"]
  source_code_hash    = filebase64sha256("${path.root}/nltk_layer/nltk_layer.zip")
}

resource "aws_lambda_function" "moderation_function" {
  function_name = "moderation-function"
  runtime       = "python3.9"
  handler = "lambda_function.moderation.handler"
  role          = aws_iam_role.lambda_role.arn
  filename      = "${path.root}/lambda_function.zip"

  environment {
    variables = {
      TABLE_NAME    = var.dynamodb_table_name
      SQS_QUEUE_URL = var.sqs_queue_url
    }
  }
  layers = [
    aws_lambda_layer_version.nltk_layer.arn
  ]

  timeout     = 10
  memory_size = 512
}


# Allow API Gateway to Invoke the Lambda
resource "aws_lambda_permission" "apigateway_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.moderation_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:us-east-1:${data.aws_caller_identity.current.account_id}:*/*/*"
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/moderation-function"
  retention_in_days = 7

  lifecycle {
    ignore_changes = [name]
  }
}
