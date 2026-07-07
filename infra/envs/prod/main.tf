locals {
  resource_name_prefix = "${var.project_name}-${var.environment_name}"
}

module "hotel_booking_network" {
  source = "../../modules/network"

  resource_name_prefix        = local.resource_name_prefix
  vpc_cidr_block              = "10.20.0.0/16"
  public_subnet_a_cidr_block  = "10.20.1.0/24"
  public_subnet_b_cidr_block  = "10.20.2.0/24"
  private_subnet_a_cidr_block = "10.20.11.0/24"
  private_subnet_b_cidr_block = "10.20.12.0/24"
  availability_zone_a         = "ap-south-1a"
  availability_zone_b         = "ap-south-1b"
  application_port            = 80
  database_port               = 5432
  enable_nat_gateway          = true
  common_tags                 = var.common_tags
}

module "hotel_booking_rds" {
  source = "../../modules/rds"

  resource_name_prefix         = local.resource_name_prefix
  private_subnet_ids           = module.hotel_booking_network.private_subnet_ids
  rds_security_group_id        = module.hotel_booking_network.rds_security_group_id
  database_name                = "hotelbooking"
  database_username            = "hoteladmin"
  database_instance_class      = "db.t4g.small"
  allocated_storage_gb         = 50
  maximum_allocated_storage_gb = 200
  enable_multi_az              = true
  enable_deletion_protection   = true
  backup_retention_days        = 7
  skip_final_snapshot          = false
  common_tags                  = var.common_tags
}

module "hotel_booking_ecs" {
  source = "../../modules/ecs"

  resource_name_prefix                        = local.resource_name_prefix
  vpc_id                                      = module.hotel_booking_network.vpc_id
  public_subnet_ids                           = module.hotel_booking_network.public_subnet_ids
  private_subnet_ids                          = module.hotel_booking_network.private_subnet_ids
  application_load_balancer_security_group_id = module.hotel_booking_network.application_load_balancer_security_group_id
  ecs_service_security_group_id               = module.hotel_booking_network.ecs_service_security_group_id

  container_image    = "nginx:1.27-alpine"
  container_port     = 80
  task_cpu           = 512
  task_memory        = 1024
  desired_task_count = 2
  health_check_path  = "/"

  container_environment_variables = {
    APPLICATION_ENVIRONMENT = var.environment_name
    DATABASE_HOST           = module.hotel_booking_rds.database_endpoint
    DATABASE_NAME           = module.hotel_booking_rds.database_name
    DATABASE_PORT           = tostring(module.hotel_booking_rds.database_port)
    DATABASE_SECRET_MODE    = "aws-managed-rds-secret"
  }

  common_tags = var.common_tags
}