variable "resource_name_prefix" {
  description = "Name prefix used for all network resources."
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "public_subnet_a_cidr_block" {
  description = "CIDR block for public subnet A."
  type        = string
}

variable "public_subnet_b_cidr_block" {
  description = "CIDR block for public subnet B."
  type        = string
}

variable "private_subnet_a_cidr_block" {
  description = "CIDR block for private subnet A."
  type        = string
}

variable "private_subnet_b_cidr_block" {
  description = "CIDR block for private subnet B."
  type        = string
}

variable "availability_zone_a" {
  description = "First availability zone."
  type        = string
}

variable "availability_zone_b" {
  description = "Second availability zone."
  type        = string
}

variable "application_port" {
  description = "Application container port."
  type        = number
  default     = 80
}

variable "database_port" {
  description = "PostgreSQL database port."
  type        = number
  default     = 5432
}

variable "enable_nat_gateway" {
  description = "Controls NAT Gateway creation."
  type        = bool
}

variable "common_tags" {
  description = "Common resource tags."
  type        = map(string)
}