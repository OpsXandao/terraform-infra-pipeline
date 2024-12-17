output "ecs_cluster_id" {
  description = "ID do cluster ECS"
  value       = aws_ecs_cluster.this.id
}

output "ecs_service_name" {
  description = "Nome do serviço ECS"
  value       = aws_ecs_service.this.name
}

output "load_balancer_dns_name" {
  description = "DNS do Load Balancer"
  value       = aws_lb.this.dns_name
}
