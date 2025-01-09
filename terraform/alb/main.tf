# alb/main.tf
resource "aws_security_group" "http" {
  name_prefix = "http-sg-"
  description = "Allow all HTTP/HTTPS traffic from public"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = [80, 443, 5000, 5001]
    content {
      protocol    = "tcp"
      from_port   = ingress.value
      to_port     = ingress.value
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "main" {
  name               = "demo-alb"
  load_balancer_type = "application"
  subnets            = var.public_subnet_ids
  security_groups    = [aws_security_group.http.id]
}

resource "aws_lb_target_group" "blue" {
  name_prefix = "main-"
  vpc_id      = var.vpc_id
  protocol    = "HTTP"
  port        = 5000
  target_type = "instance" 

  health_check {
  enabled             = true
  path                = "/"
  port                = "traffic-port"
  matcher             = "200"
  interval            = 30
  timeout             = 10
  healthy_threshold   = 2
  unhealthy_threshold = 3
}
}

resource "aws_lb_target_group" "green" {
  name_prefix = "green-"
  vpc_id      = var.vpc_id
  protocol    = "HTTP"
  port        = 5000
  target_type = "instance"

 health_check {
  enabled             = true
  path                = "/"
  port                = "traffic-port"
  matcher             = "200"
  interval            = 30
  timeout             = 10
  healthy_threshold   = 2
  unhealthy_threshold = 3
}
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.id
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue.arn
  }

  lifecycle {
    ignore_changes = [default_action]
  }
}

resource "aws_lb_listener" "test" {
  load_balancer_arn = aws_lb.main.id
  port              = 5001 
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.green.arn
  }
}
