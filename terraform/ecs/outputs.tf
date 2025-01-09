output "alb_url" {
  value = aws_lb.main.dns_name
}

output "ecs_exec_role_arn" {
  value = aws_iam_role.ecs_exec_role.arn
}

output "ecs_task_role_arn" {
  value = aws_iam_role.ecs_task_role.arn
}

output "alb_dns_name" {
  value = aws_lb.main.dns_name
}

output "green_target_arn" {
  value = aws_lb_target_group.green.arn
}

output "blue_target_arn" {
  value = aws_lb_target_group.blue.arn
}
