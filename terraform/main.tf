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
  region = "us-east-1"
}

# VPC Module
module "vpc" {
  source          = "git::https://github.com/OpsXandao/modules-terraform.git//terraform/vpc?ref=main"
  name            = "vpc-standard"
  cidr_block      = "10.0.0.0/16"
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]
  azs             = ["us-east-1a", "us-east-1b"]
  nat_gateway     = true
}

module "ecs-dev" {
  source                        = "./ambiente/dev/ecs"
  vpc_id                        = module.vpc.vpc_id
  public_subnet_ids             = module.vpc.public_subnet_ids
  cluster_name                  = "demo"
  container_image               = "03021914/blue-green:v1"
  cidr_block                    = module.vpc.cidr_block
  http_security_group           = module.alb.http_security_group_id
  ecs_task_role_arn             = module.iam.ecs_task_role_arn
  ecs_exec_role_arn             = module.iam.ecs_exec_role_arn
  ecs_node_role_arn             = module.iam.ecs_node_role_arn
  ecs_node_profile_arn          = module.iam.ecs_node_profile_arn
  aws_lb_target_group_blue_arn  = module.alb.aws_lb_target_group_blue_arn
  aws_lb_target_group_green_arn = module.alb.aws_lb_target_group_green_arn
}

module "ecs-prd" {
  source                        = "./ambiente/prd/ecs"
  vpc_id                        = module.vpc.vpc_id
  public_subnet_ids             = module.vpc.public_subnet_ids
  cluster_name                  = "demo"
  container_image               = "03021914/blue-green:v1"
  cidr_block                    = module.vpc.cidr_block
  http_security_group           = module.alb.http_security_group_id
  ecs_task_role_arn             = module.iam.ecs_task_role_arn
  ecs_exec_role_arn             = module.iam.ecs_exec_role_arn
  ecs_node_role_arn             = module.iam.ecs_node_role_arn
  ecs_node_profile_arn          = module.iam.ecs_node_profile_arn
  aws_lb_target_group_blue_arn  = module.alb.aws_lb_target_group_blue_arn
  aws_lb_target_group_green_arn = module.alb.aws_lb_target_group_green_arn
  ecs_task_sg_id                = module.ecs-dev.ecs_task_sg_id
  ecs_node_sg_id                = module.ecs-dev.ecs_node_sg_id
}
module "alb" {
  source            = "./alb"
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
}

module "iam" {
  source = "./iam"
}