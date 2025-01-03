variable "cluster_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "container_image" {
  type = string
}

variable "cidr_block" {
  description = "Bloco CIDR da VPC"
  type        = string
}

# --- Variáveis ---
variable "region" {
  description = "A AWS region"
  type        = string
  default     = "us-east-1"  # região padrão
}

# variable "key_name" {
#   description = "Nome do par de chaves para acesso via SSH às instâncias"
#   type        = string
# }
