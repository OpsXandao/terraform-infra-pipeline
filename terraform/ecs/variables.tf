variable "region" {
  description = "Região AWS para criar os recursos"
  type        = string
  default     = "us-east-1"
}

variable "image_name" {
  description = "Nome da imagem Docker para a task definition"
  type        = string
  default     = "03021914/blue-green:v1"
}

variable "container_port" {
  description = "Porta do contêiner para expor"
  type        = number
  default     = 5000
}

variable "desired_count" {
  description = "Número desejado de tarefas no ECS Service"
  type        = number
  default     = 1
}

variable "vpc_id" {
  description = "ID do VPC onde o ECS será criado"
  type        = string
}

variable "subnets" {
  description = "Lista de subnets para o ECS Service"
  type        = list(string)
}

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

variable "container_name" {
  type = string
}
