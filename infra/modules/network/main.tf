resource "aws_vpc" "hotel_booking_vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.common_tags, {
    Name = "${var.resource_name_prefix}-vpc"
  })
}

resource "aws_internet_gateway" "hotel_booking_internet_gateway" {
  vpc_id = aws_vpc.hotel_booking_vpc.id

  tags = merge(var.common_tags, {
    Name = "${var.resource_name_prefix}-internet-gateway"
  })
}

resource "aws_subnet" "hotel_booking_public_subnet_a" {
  vpc_id                  = aws_vpc.hotel_booking_vpc.id
  cidr_block              = var.public_subnet_a_cidr_block
  availability_zone       = var.availability_zone_a
  map_public_ip_on_launch = true

  tags = merge(var.common_tags, {
    Name = "${var.resource_name_prefix}-public-subnet-a"
    Tier = "public"
  })
}

resource "aws_subnet" "hotel_booking_public_subnet_b" {
  vpc_id                  = aws_vpc.hotel_booking_vpc.id
  cidr_block              = var.public_subnet_b_cidr_block
  availability_zone       = var.availability_zone_b
  map_public_ip_on_launch = true

  tags = merge(var.common_tags, {
    Name = "${var.resource_name_prefix}-public-subnet-b"
    Tier = "public"
  })
}

resource "aws_subnet" "hotel_booking_private_subnet_a" {
  vpc_id                  = aws_vpc.hotel_booking_vpc.id
  cidr_block              = var.private_subnet_a_cidr_block
  availability_zone       = var.availability_zone_a
  map_public_ip_on_launch = false

  tags = merge(var.common_tags, {
    Name = "${var.resource_name_prefix}-private-subnet-a"
    Tier = "private"
  })
}

resource "aws_subnet" "hotel_booking_private_subnet_b" {
  vpc_id                  = aws_vpc.hotel_booking_vpc.id
  cidr_block              = var.private_subnet_b_cidr_block
  availability_zone       = var.availability_zone_b
  map_public_ip_on_launch = false

  tags = merge(var.common_tags, {
    Name = "${var.resource_name_prefix}-private-subnet-b"
    Tier = "private"
  })
}

resource "aws_route_table" "hotel_booking_public_route_table" {
  vpc_id = aws_vpc.hotel_booking_vpc.id

  tags = merge(var.common_tags, {
    Name = "${var.resource_name_prefix}-public-route-table"
  })
}

resource "aws_route" "hotel_booking_public_internet_route" {
  route_table_id         = aws_route_table.hotel_booking_public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.hotel_booking_internet_gateway.id
}

resource "aws_route_table_association" "hotel_booking_public_subnet_a_route_table_association" {
  subnet_id      = aws_subnet.hotel_booking_public_subnet_a.id
  route_table_id = aws_route_table.hotel_booking_public_route_table.id
}

resource "aws_route_table_association" "hotel_booking_public_subnet_b_route_table_association" {
  subnet_id      = aws_subnet.hotel_booking_public_subnet_b.id
  route_table_id = aws_route_table.hotel_booking_public_route_table.id
}

resource "aws_eip" "hotel_booking_nat_gateway_elastic_ip" {
  count  = var.enable_nat_gateway ? 1 : 0
  domain = "vpc"

  tags = merge(var.common_tags, {
    Name = "${var.resource_name_prefix}-nat-gateway-elastic-ip"
  })
}

resource "aws_nat_gateway" "hotel_booking_nat_gateway" {
  count = var.enable_nat_gateway ? 1 : 0

  allocation_id = aws_eip.hotel_booking_nat_gateway_elastic_ip[0].id
  subnet_id     = aws_subnet.hotel_booking_public_subnet_a.id

  tags = merge(var.common_tags, {
    Name = "${var.resource_name_prefix}-nat-gateway"
  })

  depends_on = [
    aws_internet_gateway.hotel_booking_internet_gateway
  ]
}

resource "aws_route_table" "hotel_booking_private_route_table" {
  vpc_id = aws_vpc.hotel_booking_vpc.id

  tags = merge(var.common_tags, {
    Name = "${var.resource_name_prefix}-private-route-table"
  })
}

resource "aws_route" "hotel_booking_private_nat_gateway_route" {
  count = var.enable_nat_gateway ? 1 : 0

  route_table_id         = aws_route_table.hotel_booking_private_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.hotel_booking_nat_gateway[0].id
}

resource "aws_route_table_association" "hotel_booking_private_subnet_a_route_table_association" {
  subnet_id      = aws_subnet.hotel_booking_private_subnet_a.id
  route_table_id = aws_route_table.hotel_booking_private_route_table.id
}

resource "aws_route_table_association" "hotel_booking_private_subnet_b_route_table_association" {
  subnet_id      = aws_subnet.hotel_booking_private_subnet_b.id
  route_table_id = aws_route_table.hotel_booking_private_route_table.id
}

resource "aws_security_group" "hotel_booking_application_load_balancer_security_group" {
  name        = "${var.resource_name_prefix}-alb-security-group"
  description = "Allow public HTTP traffic to application load balancer"
  vpc_id      = aws_vpc.hotel_booking_vpc.id

  ingress {
    description = "Allow HTTP traffic from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow traffic from load balancer to ECS tasks"
    from_port   = var.application_port
    to_port     = var.application_port
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  tags = merge(var.common_tags, {
    Name = "${var.resource_name_prefix}-alb-security-group"
  })
}

resource "aws_security_group" "hotel_booking_ecs_service_security_group" {
  name        = "${var.resource_name_prefix}-ecs-service-security-group"
  description = "Allow traffic from application load balancer to ECS service"
  vpc_id      = aws_vpc.hotel_booking_vpc.id

  ingress {
    description     = "Allow application traffic from application load balancer"
    from_port       = var.application_port
    to_port         = var.application_port
    protocol        = "tcp"
    security_groups = [aws_security_group.hotel_booking_application_load_balancer_security_group.id]
  }

  egress {
    description = "Allow outbound traffic from ECS tasks"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${var.resource_name_prefix}-ecs-service-security-group"
  })
}

resource "aws_security_group" "hotel_booking_rds_security_group" {
  name        = "${var.resource_name_prefix}-rds-security-group"
  description = "Allow PostgreSQL traffic only from ECS service"
  vpc_id      = aws_vpc.hotel_booking_vpc.id

  ingress {
    description     = "Allow PostgreSQL from ECS service only"
    from_port       = var.database_port
    to_port         = var.database_port
    protocol        = "tcp"
    security_groups = [aws_security_group.hotel_booking_ecs_service_security_group.id]
  }

  egress {
    description = "Allow database response traffic inside VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr_block]
  }

  tags = merge(var.common_tags, {
    Name = "${var.resource_name_prefix}-rds-security-group"
  })
}