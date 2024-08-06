variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr_1" {
  description = "CIDR block for the first public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_cidr_2" {
  description = "CIDR block for the second public subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet"
  type        = string
  default     = "10.0.3.0/24"
}

variable "aws_region" {
  description = "AWS region for the resources"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "ECS Cluster name"
  type        = string
  default     = "my-cluster"
}

variable "task_definition_family" {
  description = "Family name for the task definition"
  type        = string
  default     = "my-task-family"
}

variable "service_name" {
  description = "Name of the ECS service"
  type        = string
  default     = "my-service"
}

variable "alb_name" {
  description = "Name of the Application Load Balancer"
  type        = string
  default     = "my-alb"
}

variable "target_group_name" {
  description = "Name of the target group"
  type        = string
  default     = "my-target-group"
}
