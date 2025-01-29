
variable "sqs_queue_url" {
  description = "The URL of the SQS queue used by the lambda"
  type        = string
}

variable "dynamodb_table_name" {
  description = "The name of the DynamoDB table"
  type        = string
}

variable "s3_backend_bucket" {
  description = "S3 bucket for Lambda function code"
  type        = string
}

variable "dynamodb_arn" {
  type        = string
  description = "ARN of the DynamoDB table used for flagged content"
}

variable "sqs_queue_arn" {
  type        = string
  description = "ARN of the SQS queue for flagged content"
}
