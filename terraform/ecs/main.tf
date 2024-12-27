  data "aws_ami" "default" {
    filter {
      name   = "name"
      values = ["${var.image_ecs}"]
    }

    most_recent = true
    owners      = ["${var.owner}"]
  }

  # ECS NODE ROLE

  # instâncias EC2 precisam de permissões para interagir com outros serviços AWS.
  data "aws_iam_policy_document" "ecs_node_doc" {
    statement {
      actions = ["sts:AssumeRole"]
      effect  = "Allow"

      principals {
        type        = "Service"
        identifiers = ["ec2.amazonaws.com"]
      }
    }
  }

  # Função IAM
  resource "aws_iam_role" "ecs_node_role" {
    name_prefix        = "ecs-node-role"
    assume_role_policy = data.aws_iam_policy_document.ecs_node_doc.json
  }

  # Política de EC2 como container
  resource "aws_iam_role_policy_attachment" "ecs_node_role_policy" {
    role       = aws_iam_role.ecs_node_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
  }

  # Perfil 
  resource "aws_iam_instance_profile" "ecs_node" {
    name_prefix = "ecs_node_profile"
    path        = "/ecs/instance/"
    role        = aws_iam_role.ecs_node_role.name
  }

  #SG para Node

  # --- ECS Node SG ---

  resource "aws_security_group" "ecs_node_sg" {
    name_prefix = "ecs-node-sg"
    vpc_id      = var.vpc_id

    ingress {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"] # Ou um IP específico para maior segurança
    }

    ingress {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"] # Ou um IP específico para maior segurança
    }

    egress {
      from_port   = 0
      to_port     = 65535
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }


  # Ecs Cluster

  resource "aws_ecs_cluster" "this" {
    name = var.cluster_name
  }

  # Launch Template
  data "aws_ssm_parameter" "ecs_node_ami" {
    name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
  }

  resource "aws_launch_template" "ecs_ec2" {
    name_prefix            = "ecs-ec2-"
    image_id               = data.aws_ssm_parameter.ecs_node_ami.value
    instance_type          = "t2.micro"
    vpc_security_group_ids = [aws_security_group.ecs_node_sg.id]

    key_name = var.key_name

    iam_instance_profile {
      arn = aws_iam_instance_profile.ecs_node.arn
    }

    monitoring {
      enabled = true
    }

    user_data = base64encode(<<-EOF
      #!/bin/bash
      echo ECS_CLUSTER=${var.cluster_name} >> /etc/ecs/ecs.config;
    EOF
    )
  }

  #ASG

  # --- ECS ASG ---

  resource "aws_autoscaling_group" "ecs" {
    name_prefix               = "demo-ecs-asg-"
    vpc_zone_identifier       = var.public_subnet_ids
    min_size                  = 2
    max_size                  = 4
    health_check_grace_period = 0
    health_check_type         = "EC2"
    protect_from_scale_in     = false

    launch_template {
      id      = aws_launch_template.ecs_ec2.id
      version = "$Latest"
    }

    tag {
      key                 = "Name"
      value               = "ecs-cluster"
      propagate_at_launch = true
    }

    tag {
      key                 = "AmazonECSManaged"
      value               = ""
      propagate_at_launch = true
    }
  }

    #ECS Capacity Provider

  resource "aws_ecs_capacity_provider" "this" {
    name = "demo-ecs-ec2"

    auto_scaling_group_provider {
      auto_scaling_group_arn         = aws_autoscaling_group.ecs.arn
      managed_termination_protection = "DISABLED"

      managed_scaling {
        maximum_scaling_step_size = 2
        minimum_scaling_step_size = 1
        status                    = "ENABLED"
        target_capacity           = 100
      }
    }
  }

  resource "aws_ecs_cluster_capacity_providers" "this" {
    cluster_name       = var.cluster_name
    capacity_providers = [aws_ecs_capacity_provider.this.name]

    default_capacity_provider_strategy {
      capacity_provider = aws_ecs_capacity_provider.this.name
      base              = 1
      weight            = 100
    }
  }

  # --- ECS Task Role ---

  data "aws_iam_policy_document" "ecs_task_doc" {
    statement {
      actions = ["sts:AssumeRole"]
      effect  = "Allow"

      principals {
        type        = "Service"
        identifiers = ["ecs-tasks.amazonaws.com"]
      }
    }
  }

  resource "aws_iam_role" "ecs_task_role" {
    name_prefix        = "ecs-task-role"
    assume_role_policy = data.aws_iam_policy_document.ecs_task_doc.json
  }

  resource "aws_iam_role" "ecs_exec_role" {
    name_prefix        = "ecs-exec-role"
    assume_role_policy = data.aws_iam_policy_document.ecs_task_doc.json
  }

  resource "aws_iam_role_policy_attachment" "ecs_exec_role_policy" {
    role       = aws_iam_role.ecs_exec_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  }



  # # ECR

  # # resource "aws_ecr_repository" "app" {
  # #   name = "app"
  # #   image_tag_mutability = "MUTABLE"
  # #   force_delete = true

  # #   image_scanning_configuration {
  # #     scan_on_push = true
  # #   }
  # # }

  # # --- Cloud Watch Logs ---

  resource "aws_cloudwatch_log_group" "ecs" {
    name              = "/ecs/demo"
    retention_in_days = 14
  }

  #ECS TASK DEFINITION

  resource "aws_ecs_task_definition" "app" {
    family             = "app"
    task_role_arn      = aws_iam_role.ecs_task_role.arn
    execution_role_arn = aws_iam_role.ecs_exec_role.arn
    network_mode       = "awsvpc"
    cpu                = 256
    memory             = 256

    container_definitions = jsonencode([{
      name         = "app"
      image        = "${var.container_image}"
      essential    = true
      portMappings = [{ containerPort = 80, hostPort = 80 }]

      environment = [
        { name = "DEV", value = "dev" }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-region"        = "us-east-1"
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
          "awslogs-stream-prefix" = "app"
        }
      }
    }])
  }

  #ECS Service

  resource "aws_security_group" "ecs_task" {
    name_prefix = "ecs-task-sg-"
    description = " Allow all traffic within the VPC"
    vpc_id      = var.vpc_id

    ingress {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"  
      cidr_blocks = [var.cidr_block]
    }

    egress {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  resource "aws_ecs_service" "app" {
    name            = "app"
    cluster         = aws_ecs_cluster.this.id
    task_definition = aws_ecs_task_definition.app.arn
    desired_count   = 2

    network_configuration {
      security_groups = [aws_security_group.ecs_task.id]
      subnets         = var.public_subnet_ids
    }

    capacity_provider_strategy {
      capacity_provider = aws_ecs_capacity_provider.this.name
      base              = 1
      weight            = 100
    }

    ordered_placement_strategy {
      type  = "spread"
      field = "attribute:ecs.availability-zone"
    }

    lifecycle {
      ignore_changes = [desired_count]
    }

    # load_balancer {
    #   target_group_arn = aws_lb_target_group.app.arn
    #   container_name   = "app"
    #   container_port   = 80
    # }

  }

  # # Load Balancer

  # resource "aws_security_group" "http" {
  #   name_prefix = "http-sg-"
  #   description = "Allow all HTTP/HTTPS traffic from public"
  #   vpc_id      = var.vpc_id

  #   dynamic "ingress" {
  #     for_each = [80, 443]
  #     content {
  #       protocol    = "tcp"
  #       from_port   = ingress.value
  #       to_port     = ingress.value
  #       cidr_blocks = ["0.0.0.0/0"]
  #     }
  #   }

  #   egress {
  #     protocol    = "-1"
  #     from_port   = 0
  #     to_port     = 0
  #     cidr_blocks = ["0.0.0.0/0"]
  #   }
  # }

  # resource "aws_lb" "this" {
  #   name               = "demo-alb"
  #   load_balancer_type = "application"
  #   subnets            = var.public_subnet_ids
  #   security_groups    = [aws_security_group.http.id]
  # }

  # resource "aws_lb_target_group" "app" {
  #   name_prefix = "app-"
  #   vpc_id      = var.vpc_id
  #   protocol    = "HTTP"
  #   port        = 80
  #   target_type = "ip"

  #   health_check {
  #     enabled             = true
  #     path                = "/"
  #     port                = 80
  #     matcher             = 200
  #     interval            = 10
  #     timeout             = 5
  #     healthy_threshold   = 2
  #     unhealthy_threshold = 3
  #   }
  # }

  # resource "aws_lb_listener" "http" {
  #   load_balancer_arn = aws_lb.this.id
  #   port              = 80
  #   protocol          = "HTTP"

  #   default_action {
  #     type             = "forward"
  #     target_group_arn = aws_lb_target_group.app.id
  #   }
  # }

