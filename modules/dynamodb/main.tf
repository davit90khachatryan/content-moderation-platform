resource "aws_dynamodb_table" "flagged_content" {
  name           = "FlaggedContent"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "comment_id"

  attribute {
    name = "comment_id"
    type = "S"
  }
}

output "table_name" {
  value = aws_dynamodb_table.flagged_content.name
}

output "table_arn" {
  value = aws_dynamodb_table.flagged_content.arn
}
