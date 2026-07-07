output "database_endpoint" {
  description = "Private RDS PostgreSQL endpoint."
  value       = aws_db_instance.hotel_booking_postgres_rds_instance.endpoint
}

output "database_port" {
  description = "Private RDS PostgreSQL port."
  value       = aws_db_instance.hotel_booking_postgres_rds_instance.port
}

output "database_name" {
  description = "PostgreSQL database name."
  value       = aws_db_instance.hotel_booking_postgres_rds_instance.db_name
}

output "database_master_user_secret_arn" {
  description = "AWS Secrets Manager secret ARN for RDS master user."
  value       = aws_db_instance.hotel_booking_postgres_rds_instance.master_user_secret[0].secret_arn
}