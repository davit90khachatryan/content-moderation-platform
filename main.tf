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
  sqs_queue_arn = module.sqs.queue_arn
  sqs_queue_url       = module.sqs.queue_url         # Pass SQS queue URL
  dynamodb_table_name = module.dynamodb.table_name   # Pass DynamoDB table name
  # Pass the output from the dynamodb module to the lambda module
  dynamodb_arn  = module.dynamodb.table_arn
  s3_backend_bucket   = var.s3_backend_bucket        # Pass S3 bucket name
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
  source           = "./modules/api_gateway"
  lambda_invoke_arn = module.lambda.function_invoke_arn
}

# Outputs for API Gateway and Lambda Function
output "api_endpoint" {
  value = module.api_gateway.api_endpoint
}

output "lambda_function_name" {
  value = module.lambda.function_name
}

# Data Source for Caller Identity
data "aws_caller_identity" "current" {}
