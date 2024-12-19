output "instance_id" {
  description = "ID da instância EC2"
  value       = aws_instance.wordpress_server.id
}

output "public_ip" {
  description = "IP público da instância EC2"
  value       = aws_instance.wordpress_server.public_ip
}

output "security_group_id" {
  description = "ID do Security Group da instância EC2"
  value       = aws_security_group.this.id
}
