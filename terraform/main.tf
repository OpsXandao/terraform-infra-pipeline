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

module "ecs" {
  source         = "./ecs"
  region         = var.aws_region
  cluster_name   = "colours-cluster"
  image_name     = "03021914/blue-green:v1"
  container_name = "blue-green-app" # Adicione este argumento
  container_port = 5000
  desired_count  = 1
  vpc_id         = module.vpc.vpc_id
  subnets        = module.vpc.public_subnet_ids
}


# module "ec2_test" {
#   source             = "./ec2"
#   vpc_id             = module.vpc.vpc_id
#   public_subnet_ids  = module.vpc.public_subnet_ids
#   ami_id             = "ami-0e2c8caa4b6378d8c"
#   instance_type      = "t3.medium"
# }
