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
  source             = "./ecs"
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids
  cluster_name       = "blue-green-cluster"
  container_image    = "03021914/blue-green:v1"
  container_port     = 8080
  desired_count      = 2
}
