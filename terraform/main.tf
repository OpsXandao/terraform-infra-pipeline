terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.5.0"
}

provider "aws" {
  region = var.aws_region
}


# VPC Module
module "vpc" {
  source          = "git::https://github.com/OpsXandao/modules-terraform.git//terraform/vpc?ref=main"
  name            = "vpc-standard"
  cidr_block      = var.cidr_block
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
  azs             = var.azs
  nat_gateway     = var.nat_gateway
}

# module "ecs" {
#   source             = "./ecs"
#   vpc_id             = module.vpc.vpc_id
#   public_subnet_ids  = module.vpc.public_subnet_ids
#   private_subnet_ids = module.vpc.private_subnet_ids
#   cluster_name       = "blue-green-cluster"
#   container_image    = "03021914/blue-green:v2.1"
#   container_port     = 5000
#   desired_count      = 1
  
#   ec2_ami_id         = "ami-01816d07b1128cd2d"
#   task_memory        = 2048  # A memória agora é compatível com 1 vCPU (1024)
#   task_cpu           = 1024  # 1 vCPU
# }

module "ec2_test" {
  source             = "./ec2"
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  ami_id             = "ami-0e2c8caa4b6378d8c"
  instance_type      = "t3.medium"
}
