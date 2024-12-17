output "table_name" {
  description = "O nome da tabela DynamoDB"
  value       = aws_dynamodb_table.this.name
}

output "table_arn" {
  description = "O ARN da tabela DynamoDB"
  value       = aws_dynamodb_table.this.arn
}
