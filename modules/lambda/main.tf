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

# resource "aws_lambda_layer_version" "torch_layer" {
#   filename         = "torch_layer.zip"
#   layer_name       = "torch-layer"
#   compatible_runtimes = ["python3.9"]
# }

# resource "aws_iam_role_policy" "lambda_policy" {
#   name = "lambda-policy"
#   role = aws_iam_role.lambda_role.id

#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect = "Allow",
#         Action = [
#           "logs:CreateLogGroup",
#           "logs:CreateLogStream",
#           "logs:PutLogEvents"
#         ],
#         Resource = "arn:aws:logs:*:*:*"
#       },
#       {
#         Effect = "Allow",
#         Action = [
#           "lambda:InvokeFunction",
#           "lambda:GetLayerVersion" # Add permission to use the Hugging Face layer
#         ],
#         Resource = [
#           "arn:aws:lambda:*:*:function:*",
#           "arn:aws:lambda:us-east-1:336392948345:layer:*" # Grant permission for the Hugging Face layer
#         ]
#       },
#       {
#         Effect = "Allow",
#         Action = [
#           "lambda:InvokeFunction"
#         ],
#         Resource = "arn:aws:lambda:*:*:function:*"
#       }
#     ]
#   })
# }

# Get the current AWS account ID
data "aws_caller_identity" "current" {}


resource "aws_lambda_permission" "apigateway_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.moderation_function.function_name
  principal     = "apigateway.amazonaws.com"

  # Use the dynamically fetched AWS account ID
  source_arn = "arn:aws:execute-api:us-east-1:${data.aws_caller_identity.current.account_id}:*/*/*"
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
  source_code_hash = filebase64sha256("lambda_function.zip")
}

resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/moderation-function"
  retention_in_days = 7

  lifecycle {
    ignore_changes = [name]
  }
}
