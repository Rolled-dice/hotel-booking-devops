output "ecs_cluster_name" {
  description = "ECS cluster name."
  value       = aws_ecs_cluster.hotel_booking_ecs_cluster.name
}

output "ecs_service_name" {
  description = "ECS service name."
  value       = aws_ecs_service.hotel_booking_ecs_service.name
}

output "application_load_balancer_dns_name" {
  description = "Application load balancer DNS name."
  value       = aws_lb.hotel_booking_application_load_balancer.dns_name
}