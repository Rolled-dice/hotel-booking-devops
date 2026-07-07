output "application_load_balancer_dns_name" {
  description = "Application load balancer DNS name."
  value       = module.hotel_booking_ecs.application_load_balancer_dns_name
}

output "rds_private_endpoint" {
  description = "Private RDS PostgreSQL endpoint."
  value       = module.hotel_booking_rds.database_endpoint
}

output "rds_master_user_secret_arn" {
  description = "AWS Secrets Manager secret ARN for RDS master user."
  value       = module.hotel_booking_rds.database_master_user_secret_arn
}