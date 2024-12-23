data "aws_ami" "default" {
  filter {
    name   = "name"
    values = ["${var.image_ecs}"]
  }

  most_recent = true
  owners      = ["${var.owner}"]
}


resource "aws_ecs_cluster" "blue_green_cluster" {
  name = var.cluster_name
}

# Security Group
resource "aws_security_group" "ecs_sg" {
  name_prefix = "ecs-sg"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = var.container_port
    to_port     = var.container_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
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

# ECS Task Definition
resource "aws_ecs_task_definition" "blue_green_task" {
  family = "blue-green-task"
  container_definitions = jsonencode([
    {
      name      = var.container_name,
      image     = var.image_name,
      cpu       = 256,
      memory    = 512,
      essential = true,
      portMappings = [
        {
          containerPort = 5000,
          hostPort      = 5000,
          protocol      = "tcp"
        },
      ],
    },
  ])
  requires_compatibilities = ["EC2"]
  network_mode             = "awsvpc"
}

# IAM Role para a instância EC2
resource "aws_iam_role" "ecs_instance_role" {
  name = "ecs-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Effect = "Allow"
        Sid    = ""
      },
    ]
  })
}

# IAM Role Policy Attachment para permitir a ECS acessar os recursos necessários
resource "aws_iam_role_policy_attachment" "ecs_instance_role_policy" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::058264525554:role/ecsTaskExecutionRole"
}

# Criar o IAM Instance Profile para associar a Role à EC2
resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "ecs-instance-profile"
  role = aws_iam_role.ecs_instance_role.name
}

# Launch Configuration para as instâncias EC2
resource "aws_launch_configuration" "ecs_launch_config" {
  name                 = "ecs-launch-config"
  image_id             = data.aws_ami.default.id
  instance_type        = "t3.micro"
  iam_instance_profile = aws_iam_instance_profile.ecs_instance_profile.name
  key_name             = aws_key_pair.this.key_name
  security_groups      = [aws_security_group.ecs_sg.id]

  user_data = base64encode(<<-EOF
              #!/bin/bash
              echo ECS_CLUSTER=${var.cluster_name} >> /etc/ecs/ecs.config
              EOF
  )
}

# Auto Scaling Group para gerenciar instâncias EC2 no ECS
resource "aws_autoscaling_group" "ecs_asg" {
  desired_capacity     = 1
  max_size             = 2
  min_size             = 1
  vpc_zone_identifier  = var.subnets
  launch_configuration = aws_launch_configuration.ecs_launch_config.id
}

# ECS Service
resource "aws_ecs_service" "blue_green_service" {
  name            = "blue-green-service"
  cluster         = aws_ecs_cluster.blue_green_cluster.id
  task_definition = aws_ecs_task_definition.blue_green_task.arn
  desired_count   = var.desired_count
  launch_type     = "EC2"

  network_configuration {
    subnets         = var.subnets
    security_groups = [aws_security_group.ecs_sg.id]
  }
}
