resource "aws_sqs_queue" "flagged_content_queue" {
  name = "FlaggedContentQueue"
}

output "queue_url" {
  value = aws_sqs_queue.flagged_content_queue.id
}
