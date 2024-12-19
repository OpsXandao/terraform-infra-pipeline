# Chave SSH
resource "aws_key_pair" "this" {
  key_name   = "terraformed-key"
  public_key = file("/home/elvenworks24/.ssh/id_rsa.pub")

  tags = {
    Name = "terraformed-key"
  }
}

# Security Group para a instância EC2
resource "aws_security_group" "this" {
  name        = "ec2-test-sg"
  description = "Allow HTTP, SSH, and Docker access"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2-test-sg"
  }
}

# Instância EC2
resource "aws_instance" "wordpress_server" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = element(var.public_subnet_ids, 0)
  associate_public_ip_address = true
  key_name                    = aws_key_pair.this.key_name
  vpc_security_group_ids      = [aws_security_group.this.id]

  user_data = file("${path.module}/../scripts/docker_install.sh")

  tags = {
    Name = "ec2-test-server"
  }
}
