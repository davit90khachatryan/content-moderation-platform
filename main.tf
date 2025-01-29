terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    # github = {
    #   source  = "integrations/github"
    #   version = "~> 5.0"
    # }
  }

  backend "s3" {
    bucket         = "terraform-content-moderation-bucket"
    key            = "content-moderation/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
  }
}

# Securely pass GitHub Token
# variable "github_token" {
#   description = "The GitHub personal access token for authenticating Terraform with GitHub"
#   type        = string
#   sensitive   = true
# }

provider "aws" {
  region = "us-east-1"
}

# provider "github" {
#   token = var.github_token
#   owner = "davit90khachatryan"  # Ensure this matches your GitHub username
# }
# # GitHub Repository Module
# resource "github_repository" "content_moderation_repo" {
#   name        = "content-moderation-platform"
#   description = "Terraform-managed repository for content moderation"
#   visibility  = "private" # Change to "public" if needed

#   auto_init = true # Initialize with a README
# }

# output "github_repo_url" {
#   value = github_repository.content_moderation_repo.html_url
# }

# Lambda Module
module "lambda" {
  source              = "./modules/lambda"
  sqs_queue_url       = module.sqs.queue_url         # Pass SQS queue URL
  dynamodb_table_name = module.dynamodb.table_name   # Pass DynamoDB table name
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
