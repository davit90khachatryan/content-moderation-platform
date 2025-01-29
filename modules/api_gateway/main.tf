# Define the Lambda Invoke ARN as a variable
variable "lambda_invoke_arn" {
  description = "The ARN of the Lambda function to integrate with"
}

# Define the API Gateway
resource "aws_apigatewayv2_api" "content_moderation_api" {
  name          = "ContentModerationAPI"
  protocol_type = "HTTP"
}

# Define the integration with Lambda
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id                 = aws_apigatewayv2_api.content_moderation_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.lambda_invoke_arn
  payload_format_version = "2.0"
}

# Define the route for POST /moderate
resource "aws_apigatewayv2_route" "moderate_route" {
  api_id    = aws_apigatewayv2_api.content_moderation_api.id
  route_key = "POST /moderate"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"

  depends_on = [
    aws_apigatewayv2_integration.lambda_integration
  ]
}

# Define the CloudWatch Log Group for API Gateway logs
resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  name              = "/aws/apigateway/content_moderation_api_logs"
  retention_in_days = 7
}

# Define the deployment resource
resource "aws_apigatewayv2_deployment" "api_deployment" {
  api_id = aws_apigatewayv2_api.content_moderation_api.id

  depends_on = [
    aws_apigatewayv2_route.moderate_route
  ]

  lifecycle {
    create_before_destroy = true
  }
}

# Define the stage resource
resource "aws_apigatewayv2_stage" "default_stage" {
  api_id        = aws_apigatewayv2_api.content_moderation_api.id
  name          = "default"
  auto_deploy   = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_logs.arn
    format          = jsonencode({
      requestId       = "$context.requestId",
      ip              = "$context.identity.sourceIp",
      caller          = "$context.identity.caller",
      user            = "$context.identity.user",
      requestTime     = "$context.requestTime",
      httpMethod      = "$context.httpMethod",
      resourcePath    = "$context.resourcePath",
      status          = "$context.status",
      responseLength  = "$context.responseLength"
    })
  }
}

# Output the API Gateway endpoint
output "api_endpoint" {
  value = aws_apigatewayv2_stage.default_stage.invoke_url
}
