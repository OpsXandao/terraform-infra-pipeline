resource "aws_dynamodb_table" "this" {
  name           = var.table_name
  billing_mode   = "PAY_PER_REQUEST"  # Você pode mudar para "PROVISIONED" se precisar de controle sobre a capacidade
  hash_key       = "LockID"
  attribute {
    name = "LockID"
    type = "S"  # Tipo da chave, pode ser 'S' (String), 'N' (Number), 'B' (Binary)
  }

  tags = {
    Name        = var.table_name
    Environment = var.environment
  }
}
