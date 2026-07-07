resource "aws_db_subnet_group" "hotel_booking_rds_subnet_group" {
  name       = "${var.resource_name_prefix}-rds-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = merge(var.common_tags, {
    Name = "${var.resource_name_prefix}-rds-subnet-group"
  })
}

resource "aws_db_instance" "hotel_booking_postgres_rds_instance" {
  identifier = "${var.resource_name_prefix}-postgres-rds"

  engine         = "postgres"
  engine_version = "16.3"
  instance_class = var.database_instance_class

  db_name  = var.database_name
  username = var.database_username

  manage_master_user_password = true

  allocated_storage     = var.allocated_storage_gb
  max_allocated_storage = var.maximum_allocated_storage_gb
  storage_type          = "gp3"
  storage_encrypted     = true

  db_subnet_group_name   = aws_db_subnet_group.hotel_booking_rds_subnet_group.name
  vpc_security_group_ids = [var.rds_security_group_id]
  publicly_accessible    = false

  multi_az                = var.enable_multi_az
  backup_retention_period = var.backup_retention_days
  deletion_protection     = var.enable_deletion_protection
  skip_final_snapshot     = var.skip_final_snapshot

  auto_minor_version_upgrade   = true
  copy_tags_to_snapshot        = true
  performance_insights_enabled = true

  tags = merge(var.common_tags, {
    Name = "${var.resource_name_prefix}-postgres-rds"
  })
}