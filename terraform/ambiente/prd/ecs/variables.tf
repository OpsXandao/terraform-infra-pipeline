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

variable "region" {
  description = "A AWS region"
  type        = string
  default     = "us-east-1"  # região padrão
}

variable "http_security_group" {
  description = "O security group do ALB"
  type        = string
}

variable "ecs_task_role_arn" {
  description = "The ARN of the ECS task role"
  type        = string
}

variable "ecs_exec_role_arn" {
  description = "The ARN of the ECS execution role"
  type        = string
}

variable "ecs_node_role_arn" {
  description = "The ARN of the ECS node role"
  type        = string
}

variable "ecs_node_profile_arn" {
  description = "The ARN of the ECS node instance profile"
  type        = string
}

variable "aws_lb_target_group_blue_arn" {
  description = "ARN do target group blue"
  type        = string
}

variable "aws_lb_target_group_green_arn" {
  description = "ARN do target group green"
  type        = string
}

variable "ecs_task_sg_id" {
  description = "ID do Security Group da task ECS"
  type        = string
}

variable "ecs_node_sg_id" {
  description = "ID do Security Group do node ECS"
  type        = string
}


# variable "key_name" {
#   description = "Nome do par de chaves para acesso via SSH às instâncias"
#   type        = string
# }
