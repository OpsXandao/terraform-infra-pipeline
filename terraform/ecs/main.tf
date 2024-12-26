data "aws_ami" "default" {
  filter {
    name   = "name"
    values = ["${var.image_ecs}"]
  }

  most_recent = true
  owners      = ["${var.owner}"]
}

# instâncias EC2 precisam de permissões para interagir com outros serviços AWS.
data "aws_iam_policy_document" "ecs_node_doc" {
  statement {
    actions = ["sts:AssumeRole"]
    effect = "Allow"

    principals {
      type = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# Função IAM
resource "aws_iam_role" "ecs_node_role" {
  name_prefix = "ecs-node-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_node_doc.json
}

# Política de EC2 como container
resource "aws_iam_role_policy_attachment" "ecs_node_role_policy" {
  role = aws_iam_role.ecs_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

# Perfil 
resource "aws_iam_instance_profile" "ecs_node" {
  name_prefix = "ecs_node_profile"
  path = "/ecs/instance"
  role = aws_iam_role.ecs_node_role.name
}

# Ecs Cluster

resource "aws_ecs_cluster" "this" {
  name = var.cluster_name
}