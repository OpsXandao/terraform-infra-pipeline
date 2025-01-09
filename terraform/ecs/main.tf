# --- ECS Cluster ---
resource "aws_ecs_cluster" "main" {
  name =  var.cluster_name
}

# --- ECS Node Role ---
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

resource "aws_iam_role" "ecs_node_role" {
  name        = "demo-ecs-node-role" 
  assume_role_policy = data.aws_iam_policy_document.ecs_node_doc.json
}

resource "aws_iam_role_policy_attachment" "ecs_node_role_policy" {
  role       = aws_iam_role.ecs_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_node" {
  name = "demo-ecs-node-profile"
  path        = "/ecs/instance/"
  role        = aws_iam_role.ecs_node_role.name
}

resource "aws_security_group" "ecs_node_sg" {
  name = "demo-ecs-node-sg-"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 32768
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.http.id]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- ECS Launch Template ---
data "aws_ssm_parameter" "ecs_node_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

resource "aws_launch_template" "ecs_ec2" {
  name            = "demo-ecs-ec2-"
  image_id               = data.aws_ssm_parameter.ecs_node_ami.value
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.ecs_node_sg.id]

  iam_instance_profile { arn = aws_iam_instance_profile.ecs_node.arn }
  monitoring { enabled = true }

  user_data = base64encode(<<-EOF
      #!/bin/bash
      echo ECS_CLUSTER=${aws_ecs_cluster.main.name} >> /etc/ecs/ecs.config;
    EOF
  )
}

# --- ECS ASG ---
resource "aws_autoscaling_group" "ecs" {
  name         = "demo-ecs-asg-"
  vpc_zone_identifier = var.public_subnet_ids
  min_size           = 1
  desired_capacity   = 2
  max_size           = 8

  health_check_grace_period = 0
  health_check_type         = "EC2"
  protect_from_scale_in     = true

  target_group_arns = [
    aws_lb_target_group.blue.arn,
    aws_lb_target_group.green.arn
  ]

  launch_template {
    id      = aws_launch_template.ecs_ec2.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "demo-ecsg-cluster"
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
  name = "demo-ecs-ecc"

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

# --- ECS Task Role ---
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
  name               = "demo-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_doc.json
}

# Separate policy for the task role
resource "aws_iam_role_policy" "ecs_task_policy" {
  name = "ecs-task-base-policy"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# Make sure the execution role has proper permissions
resource "aws_iam_role" "ecs_exec_role" {
  name               = "demo-ecs-exec-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_doc.json
}

resource "aws_iam_role_policy_attachment" "ecs_exec_role_policy" {
  role       = aws_iam_role.ecs_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# --- CloudWatch Log Group ---
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/demo"
  retention_in_days = 30

  tags = {
    Environment = "dev"
    Application = "demo"
  }
}

resource "aws_ecs_task_definition" "app" {
  family             = "demo-teste"
  task_role_arn      = aws_iam_role.ecs_task_role.arn
  execution_role_arn = aws_iam_role.ecs_exec_role.arn
  network_mode       = "bridge"  # Changed from awsvpc to bridge
  cpu                = 256
  memory             = 256

  container_definitions = jsonencode([{
    name         = "app",
    image        = var.container_image,
    essential    = true,
    portMappings = [{ 
      containerPort = 5000,
      hostPort      = 0  # Dynamic port mapping
    }],
 

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

# --- ECS Service ---
resource "aws_security_group" "ecs_task" {
  name = "ecs-task-sg" 
  description = "Allow all traffic within the VPC"
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

# SERVICE ECS
resource "aws_ecs_service" "app" {
  name            = "app"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 2

  deployment_controller {
    type = "ECS"
  }

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  load_balancer {
    target_group_arn = aws_lb_target_group.blue.arn
    container_name   = "app"
    container_port   = 5000
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.green.arn
    container_name   = "app"
    container_port   = 5000
  }

  lifecycle {
    ignore_changes = [
      task_definition,
      load_balancer,
      desired_count
    ]
  }
}


# --- ALB ---
resource "aws_security_group" "http" {
  name = "http-sg"
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
  name = "main"
  vpc_id      = var.vpc_id
  protocol    = "HTTP"
  port        = 5000
  target_type = "instance" 

  health_check {
    enabled             = true
    path                = "/"
    port                = "traffic-port"
    matcher             = 200
    interval            = 10
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_target_group" "green" {
  name = "green"
  vpc_id      = var.vpc_id
  protocol    = "HTTP"
  port        = 5000
  target_type = "instance"

  health_check {
    enabled             = true
    path                = "/"
    port                = "traffic-port"
    matcher             = 200
    interval            = 10
    timeout             = 5
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
  port              = 5001  # Test port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.green.arn
  }
}
# --- GitHub Actions IAM Policy ---
resource "aws_iam_policy" "github_actions_ecs_policy" {
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecs:DescribeServices",
          "ecs:UpdateService",
          "ecs:RegisterTaskDefinition",
          "ecs:DescribeTaskDefinition",
          "iam:PassRole",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:ModifyListener",
          "elasticloadbalancing:DescribeListeners"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach Policy para o GitHub Actions Role
resource "aws_iam_role_policy_attachment" "github_actions_ecs_policy_attachment" {
  role       = "github-actions-OpsXandao-pipeline"
  policy_arn = aws_iam_policy.github_actions_ecs_policy.arn
}