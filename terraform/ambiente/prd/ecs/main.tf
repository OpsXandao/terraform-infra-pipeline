# --- ECS Cluster ---
resource "aws_ecs_cluster" "main" {
  name = "prd-${var.cluster_name}"
}

# resource "aws_security_group" "ecs_node_sg" {
#   id = var.ecs_node_sg_id
# }

# --- ECS Launch Template ---
data "aws_ssm_parameter" "ecs_node_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

resource "aws_launch_template" "ecs_ec2" {
  name_prefix            = "prd-ecs-ec2-"
  image_id               = data.aws_ssm_parameter.ecs_node_ami.value
  instance_type          = "t2.micro"
  vpc_security_group_ids = [var.ecs_node_sg_id]

  iam_instance_profile { arn = var.ecs_node_profile_arn }
  monitoring { enabled = true }

  user_data = base64encode(<<-EOF
      #!/bin/bash
      echo ECS_CLUSTER=${aws_ecs_cluster.main.name} >> /etc/ecs/ecs.config;
    EOF
  )
}


# --- ECS ASG (prd) ---
resource "aws_autoscaling_group" "ecs" {
  target_group_arns   = [var.aws_lb_target_group_green_arn]
  name                = "prd-ecs-asg"
  vpc_zone_identifier = var.public_subnet_ids
  min_size            = 1
  desired_capacity    = 1
  max_size            = 4

  health_check_grace_period = 0
  health_check_type         = "EC2"
  protect_from_scale_in     = true

  launch_template {
    id      = aws_launch_template.ecs_ec2.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "prd-ecsg-cluster"
    propagate_at_launch = true
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = ""
    propagate_at_launch = true
  }
}

# --- ECS Capacity Provider ---
resource "aws_ecs_capacity_provider" "main" {
  name = "prd-ecs-ec2"

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

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name       = aws_ecs_cluster.main.name
  capacity_providers = [aws_ecs_capacity_provider.main.name]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.main.name
    base              = 1
    weight            = 100
  }
}

# --- Cloud Watch Logs ---
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/prd"
  retention_in_days = 30

  lifecycle {
    ignore_changes = [name]
  }
}


# --- ECS Task Definition ---
resource "aws_ecs_task_definition" "app" {
  family             = "show-colors"
  task_role_arn      = var.ecs_task_role_arn
  execution_role_arn = var.ecs_exec_role_arn
  network_mode       = "bridge"
  cpu                = 256
  memory             = 256

  container_definitions = jsonencode([{
    name      = "app",
    image     = var.container_image,
    essential = true,
    portMappings = [{ containerPort = 5000,
    hostPort = 0 }],

    environment = [
      { name = "EXAMPLE", value = "example" }
    ]

    logConfiguration = {
      logDriver = "awslogs",
      options = {
        "awslogs-region"        = "us-east-1",
        "awslogs-group"         = aws_cloudwatch_log_group.ecs.name,
        "awslogs-stream-prefix" = "app"
      }
    },
  }])
}

# # --- ECS Service ---
# resource "aws_security_group" "ecs_task" {
#   id = var.ecs_task_sg_id
# }

# Service ECS
resource "aws_ecs_service" "app" {
  name            = "color-bg-prd"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  
   load_balancer {
    target_group_arn = var.aws_lb_target_group_blue_arn
    container_name   = "app" 
    container_port   = 5000  
  }



  deployment_controller {
    type = "ECS"
  }

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  lifecycle {
    ignore_changes = [
      task_definition,
      desired_count
    ]
  }
}
