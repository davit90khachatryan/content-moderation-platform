output "function_name" {
  value = aws_lambda_function.moderation_function.function_name
}

output "function_invoke_arn" {
  value = aws_lambda_function.moderation_function.invoke_arn
}

output "review_function_name" {
  value = aws_lambda_function.moderation_review_function.function_name
}

output "review_function_invoke_arn" {
  value = aws_lambda_function.moderation_review_function.invoke_arn
}

output "sqs_event_mapping_id" {
  value = aws_lambda_event_source_mapping.sqs_trigger.id
}
