terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "terraform-content-moderation-bucket"
    key            = "content-moderation/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
  }
}

provider "aws" {
  region = "us-east-1"
}

# Lambda Module
module "lambda" {
  source              = "./modules/lambda"
  sqs_queue_url       = module.sqs.queue_url         # Pass SQS queue URL
  dynamodb_table_name = module.dynamodb.table_name   # Pass DynamoDB table name
  s3_backend_bucket   = var.s3_backend_bucket        # Pass S3 bucket name
  role_arn            = aws_iam_role.lambda_role.arn # Pass IAM Role ARN
}

# DynamoDB Module
module "dynamodb" {
  source = "./modules/dynamodb"
}

# SQS Module
module "sqs" {
  source = "./modules/sqs"
}

# API Gateway Module
module "api_gateway" {
  source = "./modules/api_gateway"

  # Pass the Lambda ARN
  lambda_invoke_arn = module.lambda.function_arn
}

# Outputs for API Gateway and Lambda Function
output "api_endpoint" {
  value = module.api_gateway.api_endpoint
}

output "lambda_function_name" {
  value = module.lambda.function_name
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "lambda-moderation-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Data Source for Caller Identity
data "aws_caller_identity" "current" {}

# IAM Policy for Lambda
resource "aws_iam_role_policy" "lambda_policy" {
  name   = "lambda-policy"
  role   = aws_iam_role.lambda_role.id

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
        Resource = "arn:aws:logs:us-east-1:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/*"
      },
      {
        Effect = "Allow",
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "sqs:SendMessage"
        ],
        Resource = "*"
      }
    ]
  })
}
