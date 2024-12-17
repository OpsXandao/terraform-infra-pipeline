
# Variáveis Necessárias
variable "vpc_id" {
  description = "ID da VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "IDs das Subnets públicas"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "IDs das Subnets privadas"
  type        = list(string)
}

variable "cluster_name" {
  description = "Nome do cluster ECS"
  type        = string
}

variable "container_image" {
  description = "Imagem Docker para o container"
  type        = string
}

variable "container_port" {
  description = "Porta exposta pelo container"
  type        = number
}

variable "container_environment" {
  description = "Variáveis de ambiente para o container"
  type        = list(map(string))
  default     = []
}

variable "task_cpu" {
  description = "CPU para a task ECS"
  type        = number
}

variable "task_memory" {
  description = "Memória para a task ECS"
  type        = number
}

variable "desired_count" {
  description = "Número desejado de instâncias do serviço ECS"
  type        = number
}

variable "ec2_ami_id" {
  description = "AMI para as instâncias ECS (otimizada para ECS)"
  type        = string
}

variable "ec2_instance_type" {
  description = "Tipo da instância EC2"
  type        = string
  default     = "t3.micro"
}

variable "ec2_desired_capacity" {
  description = "Capacidade desejada do Auto Scaling Group"
  type        = number
  default     = 2
}

variable "ec2_min_capacity" {
  description = "Capacidade mínima do Auto Scaling Group"
  type        = number
  default     = 1
}

variable "ec2_max_capacity" {
  description = "Capacidade máxima do Auto Scaling Group"
  type        = number
  default     = 5
}
