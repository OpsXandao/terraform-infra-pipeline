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


# resource "aws_key_pair" "this" {
#   key_name   = "terraformed-key"
#   public_key = file("/home/elvenworks24/.ssh/id_rsa.pub")

#   tags = {
#     Name = "terraformed-key"
#   }
# }


# VPC Module
module "vpc" {
  source          = "git::https://github.com/OpsXandao/modules-terraform.git//terraform/vpc?ref=main"
  name            = "vpc-standard"
  cidr_block      = "10.0.0.0/16"
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
  azs             = var.azs
  nat_gateway     = var.nat_gateway
}

  module "ecs" {
    source = "./ecs"
    vpc_id = module.vpc.vpc_id
    public_subnet_ids = module.vpc.public_subnet_ids
    cluster_name = "DevCluster"
    container_image = "fabricioveronez/web-color:blue"
    cidr_block = module.vpc.cidr_block
    
    # key_name = aws_key_pair.this.id
  }


# # module "ec2_test" {
#   source             = "./ec2"
#   vpc_id             = module.vpc.vpc_id
#   public_subnet_ids  = module.vpc.public_subnet_ids
#   ami_id             = "ami-0e2c8caa4b6378d8c"
#   instance_type      = "t3.medium"
# }
