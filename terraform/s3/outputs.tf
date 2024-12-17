variable "bucket_name" {
  description = "O nome do bucket S3"
  type        = string
}

variable "environment" {
  description = "O ambiente"
  type        = string
  default     = "dev"
}
