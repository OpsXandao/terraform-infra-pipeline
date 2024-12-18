variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "cidr_block" {
  description = "Bloco CIDR da VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "enable_dns_support" {
  description = "Habilitar suporte a DNS"
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  description = "Habilitar hostnames DNS"
  type        = bool
  default     = true
}

variable "public_subnets" {
  description = "Blocos CIDR das subnets públicas"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets" {
  description = "Lista de blocos CIDR para subnets privadas"
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "nat_gateway" {
  description = "Indica se um NAT Gateway será criado"
  type        = bool
  default     = true
}

variable "azs" {
  description = "Lista de zonas de disponibilidade"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}


variable "repo_access_token" {
  default = ""
}

