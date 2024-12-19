variable "vpc_id" {
  description = "ID da VPC onde a instância será criada"
  type        = string
}

variable "public_subnet_ids" {
  description = "Lista de subnets públicas para associar à instância EC2"
  type        = list(string)
}

variable "ami_id" {
  description = "ID da AMI para instância EC2"
  type        = string
}

variable "instance_type" {
  description = "Tipo da instância EC2"
  type        = string
}
