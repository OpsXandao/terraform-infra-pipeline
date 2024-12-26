variable "image_ecs" {
  description = "The AMI from which to launch the instance."
  type        = string
  default     = "amzn2-ami-ecs-hvm-2.0.202*-x86_64-ebs*"
}

variable "owner" {
  description = "Owner ami"
  type        = any
  default     = "amazon"
}

variable "cluster_name" {
  type = string
}