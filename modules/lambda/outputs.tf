output "function_invoke_arn" {
  value = aws_lambda_function.moderation_function.invoke_arn
}

output "function_name" {
  value = aws_lambda_function.moderation_function.function_name
}
