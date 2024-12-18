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
  cluster_name       = "blue-green-clust"
  container_image    = "03021914/blue-green:v1"
  container_port     = 8080
  desired_count      = 2
  
  ec2_ami_id         = "ami-01816d07b1128cd2d"
  task_memory        = 512  
  task_cpu           = 1 
}

# module "s3_bucket" {
#   source      = "./s3"
#   bucket_name = "alexandre-us-east-1-terraform-statefile"
#   environment = "dev"
# }

# module "dynamodb_table" {
#   source     = "./dynamo"   # Caminho para o módulo
#   table_name = "alexandre-us-east-1-terraform-lock"
#   environment = "dev"
# }

# output "dynamodb_table_name" {
#   value = module.dynamodb_table.table_name
# }


