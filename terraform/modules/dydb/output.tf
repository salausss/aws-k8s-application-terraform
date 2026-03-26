output "table_arn" {
  value = aws_dynamodb_table.betterment_table.arn
}

output "dynamodb_name" {
  value = aws_dynamodb_table.betterment_table.name
}
