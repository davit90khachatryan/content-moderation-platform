
variable "sqs_queue_url" {
  description = "The URL of the SQS queue"
  type        = string
}

variable "dynamodb_table_name" {
  description = "The name of the DynamoDB table"
  type        = string
}

variable "role_arn" {
  description = "IAM Role ARN for the Lambda function"
  type        = string
}

variable "s3_backend_bucket" {
  description = "S3 bucket for Lambda function code"
  type        = string
}
