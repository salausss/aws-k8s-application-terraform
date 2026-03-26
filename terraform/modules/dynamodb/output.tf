output "dynamodb_name" {
  value = aws_dynamodb_table.db.name
}

output "dynamodb_arn" {
  value = aws_dynamodb_table.db.arn
}