variable "aws_region" {
  description = "AWS region."
  type        = string
}

variable "project_name" {
  description = "Project name."
  type        = string
}

variable "environment_name" {
  description = "Environment name."
  type        = string
}

variable "common_tags" {
  description = "Common resource tags."
  type        = map(string)
}