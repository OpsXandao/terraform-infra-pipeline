output "ecs_node_role_arn" {
  value = aws_iam_role.ecs_node_role.arn
}

output "ecs_node_profile_arn" {
  value = aws_iam_instance_profile.ecs_node.arn
}

output "ecs_task_role_arn" {
  value = aws_iam_role.ecs_task_role.arn
}

output "ecs_exec_role_arn" {
  value = aws_iam_role.ecs_exec_role.arn
}