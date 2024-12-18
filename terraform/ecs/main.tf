# IAM Role para ECS Task
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.cluster_name}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "ecs.amazonaws.com"
        }
      },
    ]
  })
}

# Política para o ECS Task Role (ajustado para remover S3 e DynamoDB)
resource "aws_iam_policy" "ecs_task_policy" {
  name        = "${var.cluster_name}-ecs-task-policy"
  description = "Policy for ECS Task Role"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]  # Mantido apenas permissões de logs
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

# Associando a política ao Role
resource "aws_iam_role_policy_attachment" "ecs_task_role_policy_attachment" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_task_policy.arn
}

# Cluster ECS
resource "aws_ecs_cluster" "this" {
  name = var.cluster_name
}

# Launch Template para instâncias EC2
resource "aws_launch_template" "ecs" {
  name          = "${var.cluster_name}-launch-template"
  image_id      = var.ec2_ami_id # AMI ECS-optimized
  instance_type = var.ec2_instance_type

  user_data = base64encode(<<-EOT
    #!/bin/bash
    echo ECS_CLUSTER=${aws_ecs_cluster.this.name} >> /etc/ecs/ecs.config
  EOT
  )

  network_interfaces {
    security_groups            = [aws_security_group.ecs_service.id]
    associate_public_ip_address = true
  }
}

# Auto Scaling Group para ECS
resource "aws_autoscaling_group" "ecs" {
  desired_capacity     = var.ec2_desired_capacity
  max_size             = var.ec2_max_capacity
  min_size             = var.ec2_min_capacity

  launch_template {
    id      = aws_launch_template.ecs.id
    version = "$Latest"
  }

  vpc_zone_identifier = var.private_subnet_ids
}

# Security Group para o ECS Service
resource "aws_security_group" "ecs_service" {
  name        = "${var.cluster_name}-sg"
  description = "Security group for ECS service"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = var.container_port
    to_port     = var.container_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Load Balancer para ECS
resource "aws_lb" "this" {
  name               = "${var.cluster_name}-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ecs_service.id]
  subnets            = var.public_subnet_ids
}

# Target Group (alterado para "ip", compatível com o modo awsvpc)
resource "aws_lb_target_group" "this" {
  name        = "${var.cluster_name}-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"  # Alterado para "ip", compatível com o modo awsvpc
}

# Listener para Load Balancer
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

# Task Definition para EC2 (modo awsvpc agora)
resource "aws_ecs_task_definition" "this" {
  family                   = "${var.cluster_name}-task"
  network_mode             = "awsvpc"  # Agora utilizando o modo awsvpc
  requires_compatibilities = ["EC2"]    # Suporte para EC2
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  task_role_arn            = aws_iam_role.ecs_task_role.arn  # Referenciando o role criado

  container_definitions = jsonencode([{
    name  = "my-container"
    image = var.container_image
    portMappings = [{
      containerPort = var.container_port
      protocol      = "tcp"
    }]
    environment = var.container_environment
  }])
}

# Serviço ECS com deploy blue/green
resource "aws_ecs_service" "this" {
  cluster        = aws_ecs_cluster.this.id
  name           = "${var.cluster_name}-service"
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = "my-container"
    container_port   = var.container_port
  }

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs_service.id]
    assign_public_ip = false
  }

  enable_execute_command = true
}
