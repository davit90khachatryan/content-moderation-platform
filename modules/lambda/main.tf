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
        ],
        Resource = "arn:aws:dynamodb:us-east-1:039612865454:table/FlaggedContent"
      },
      
      # 2) SQS permissions: Allow Lambda to read messages from SQS
      {
          "Effect": "Allow",
          "Action": [
              "sqs:SendMessage",
              "sqs:ReceiveMessage",
              "sqs:DeleteMessage",
              "sqs:GetQueueAttributes"
          ],
          "Resource": "arn:aws:sqs:us-east-1:039612865454:FlaggedContentQueue"
      },
      # Permission for `moderation_review_function` to read messages
      {
        Effect = "Allow",
        Action = [
          "lambda:InvokeFunction"
        ],
        Resource = aws_lambda_function.moderation_review_function.arn
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


# Moderation Review Function (Second Lambda)
resource "aws_lambda_function" "moderation_review_function" {
  function_name = "moderation-review-function"
  runtime       = "python3.9"
  handler       = "lambda_moderation_function.moderation_review.handler"
  role          = aws_iam_role.lambda_role.arn
  filename      = "${path.root}/moderation_review_function.zip"

  environment {
    variables = {
      TABLE_NAME = var.dynamodb_table_name
    }
  }

  timeout     = 10
  memory_size = 128
}

# SQS Event Source Mapping for the Review Function
resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = var.sqs_queue_arn
  function_name    = aws_lambda_function.moderation_review_function.arn
  batch_size       = 10   # Number of messages processed per function execution
  enabled          = true
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
