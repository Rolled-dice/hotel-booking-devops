output "vpc_id" {
  description = "Hotel booking VPC ID."
  value       = aws_vpc.hotel_booking_vpc.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs for application load balancer."
  value = [
    aws_subnet.hotel_booking_public_subnet_a.id,
    aws_subnet.hotel_booking_public_subnet_b.id
  ]
}

output "private_subnet_ids" {
  description = "Private subnet IDs for ECS and RDS."
  value = [
    aws_subnet.hotel_booking_private_subnet_a.id,
    aws_subnet.hotel_booking_private_subnet_b.id
  ]
}

output "application_load_balancer_security_group_id" {
  description = "Application load balancer security group ID."
  value       = aws_security_group.hotel_booking_application_load_balancer_security_group.id
}

output "ecs_service_security_group_id" {
  description = "ECS service security group ID."
  value       = aws_security_group.hotel_booking_ecs_service_security_group.id
}

output "rds_security_group_id" {
  description = "RDS security group ID."
  value       = aws_security_group.hotel_booking_rds_security_group.id
}