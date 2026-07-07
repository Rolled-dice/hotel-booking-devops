variable "resource_name_prefix" {
  description = "Name prefix used for ECS resources."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where ECS resources are deployed."
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for application load balancer."
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for ECS tasks."
  type        = list(string)
}

variable "application_load_balancer_security_group_id" {
  description = "Security group ID for application load balancer."
  type        = string
}

variable "ecs_service_security_group_id" {
  description = "Security group ID for ECS service."
  type        = string
}

variable "container_image" {
  description = "Container image used by ECS task."
  type        = string
}

variable "container_port" {
  description = "Container port."
  type        = number
}

variable "task_cpu" {
  description = "Fargate task CPU."
  type        = number
}

variable "task_memory" {
  description = "Fargate task memory."
  type        = number
}

variable "desired_task_count" {
  description = "Desired ECS task count."
  type        = number
}

variable "health_check_path" {
  description = "Application health check path."
  type        = string
}

variable "container_environment_variables" {
  description = "Environment variables for ECS container."
  type        = map(string)
}

variable "common_tags" {
  description = "Common resource tags."
  type        = map(string)
}