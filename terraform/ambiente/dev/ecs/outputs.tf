output "ecs_task_definition_arn" {
  value = aws_ecs_task_definition.app.arn
}

output "ecs_task_definition_family" {
  value = aws_ecs_task_definition.app.family
}

output "ecs_task_definition_revision" {
  value = aws_ecs_task_definition.app.revision
}

output "ecs_task_definition_container_definitions" {
  value = aws_ecs_task_definition.app.container_definitions
}

output "ecs_service_name" {
  value = aws_ecs_service.app.name
}

output "ecs_node_sg_id" {
  value = aws_security_group.ecs_node_sg.id
}

output "ecs_task_sg_id" {
  value = aws_security_group.ecs_task.id
}
