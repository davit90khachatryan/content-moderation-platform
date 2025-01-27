resource "aws_dynamodb_table" "flagged_content" {
  name           = "FlaggedContent"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

output "table_name" {
  value = aws_dynamodb_table.flagged_content.name
}
