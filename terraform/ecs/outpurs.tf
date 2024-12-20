output "ecs_cluster_id" {
  description = "ID do cluster ECS criado"
  value       = aws_ecs_cluster.blue_green_cluster.id
}

output "ecs_service_name" {
  description = "Nome do serviço ECS criado"
  value       = aws_ecs_service.blue_green_service.name
}

output "task_definition_arn" {
  description = "ARN da task definition do ECS"
  value       = aws_ecs_task_definition.blue_green_task.arn
}

variable "cluster_name" {
  type = string
}