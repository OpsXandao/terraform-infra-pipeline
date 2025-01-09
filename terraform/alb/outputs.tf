output "aws_lb_target_group_blue_arn" {
  value = aws_lb_target_group.blue.arn
}

output "aws_lb_target_group_green_arn" {
  value = aws_lb_target_group.green.arn
}


output "alb_dns_name" {
  value = aws_lb.main.dns_name
}

output "alb_url" {
  value = aws_lb.main.dns_name
}


output "http_security_group_id" {
  value = aws_security_group.http.id
}