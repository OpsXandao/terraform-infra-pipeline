variable "table_name" {
  description = "O nome da tabela DynamoDB"
  type        = string
}

variable "environment" {
  description = "O ambiente (exemplo: dev, prod)"
  type        = string
  default     = "dev"
}
