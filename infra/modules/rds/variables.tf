variable "resource_name_prefix" {
  description = "Name prefix used for RDS resources."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for RDS subnet group."
  type        = list(string)
}

variable "rds_security_group_id" {
  description = "Security group ID attached to RDS."
  type        = string
}

variable "database_name" {
  description = "PostgreSQL database name."
  type        = string
}

variable "database_username" {
  description = "PostgreSQL master username."
  type        = string
}

variable "database_instance_class" {
  description = "RDS instance class."
  type        = string
}

variable "allocated_storage_gb" {
  description = "Initial allocated storage in GB."
  type        = number
}

variable "maximum_allocated_storage_gb" {
  description = "Maximum autoscaled storage in GB."
  type        = number
}

variable "enable_multi_az" {
  description = "Controls Multi-AZ deployment."
  type        = bool
}

variable "enable_deletion_protection" {
  description = "Controls deletion protection."
  type        = bool
}

variable "backup_retention_days" {
  description = "Backup retention period in days."
  type        = number
}

variable "skip_final_snapshot" {
  description = "Controls final snapshot behavior during deletion."
  type        = bool
}

variable "common_tags" {
  description = "Common resource tags."
  type        = map(string)
}