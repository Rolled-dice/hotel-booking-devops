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
variable "skip_credentials_validation" {
  type    = bool
  default = false
}

variable "skip_requesting_account_id" {
  type    = bool
  default = false
}

variable "skip_metadata_api_check" {
  type    = bool
  default = false
}

variable "skip_region_validation" {
  type    = bool
  default = false
}

