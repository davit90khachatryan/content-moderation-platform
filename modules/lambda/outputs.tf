output "function_arn" {
  value = aws_lambda_function.moderation_function.arn
}

output "function_name" {
  value = aws_lambda_function.moderation_function.function_name
}
