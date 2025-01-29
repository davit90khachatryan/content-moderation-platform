resource "aws_sqs_queue" "flagged_content_queue" {
  name = "FlaggedContentQueue"
}

# The queue URL (for code usage)
output "queue_url" {
  value = aws_sqs_queue.flagged_content_queue.id
}

# The queue ARN (for IAM policy usage)
output "queue_arn" {
  value = aws_sqs_queue.flagged_content_queue.arn
}
