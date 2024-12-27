variable "image_ecs" {
  description = "The AMI from which to launch the instance."
  type        = string
  default     = "amzn2-ami-ecs-hvm-2.0.202*-x86_64-ebs*"
}

variable "owner" {
  description = "Owner ami"
  type        = any
  default     = "amazon"
}

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

variable "key_name" {
  description = "Nome do par de chaves para acesso via SSH às instâncias"
  type        = string
}
