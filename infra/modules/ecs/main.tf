data "aws_region" "current_aws_region" {}

resource "aws_cloudwatch_log_group" "hotel_booking_ecs_log_group" {
  name              = "/ecs/${var.resource_name_prefix}"
  retention_in_days = 30

  tags = merge(var.common_tags, {
    Name = "${var.resource_name_prefix}-ecs-log-group"
  })
}

resource "aws_ecs_cluster" "hotel_booking_ecs_cluster" {
  name = "${var.resource_name_prefix}-ecs-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = merge(var.common_tags, {
    Name = "${var.resource_name_prefix}-ecs-cluster"
  })
}

resource "aws_lb" "hotel_booking_application_load_balancer" {
  name               = "${var.resource_name_prefix}-alb"
  load_balancer_type = "application"
  internal           = false
  subnets            = var.public_subnet_ids
  security_groups    = [var.application_load_balancer_security_group_id]

  tags = merge(var.common_tags, {
    Name = "${var.resource_name_prefix}-application-load-balancer"
  })
}

resource "aws_lb_target_group" "hotel_booking_ecs_target_group" {
  name        = "${var.resource_name_prefix}-ecs-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    path                = var.health_check_path
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200-399"
  }

  tags = merge(var.common_tags, {
    Name = "${var.resource_name_prefix}-ecs-target-group"
  })
}

resource "aws_lb_listener" "hotel_booking_http_listener" {
  load_balancer_arn = aws_lb.hotel_booking_application_load_balancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.hotel_booking_ecs_target_group.arn
  }
}

data "aws_iam_policy_document" "hotel_booking_ecs_task_assume_role_policy_document" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "hotel_booking_ecs_task_execution_role" {
  name               = "${var.resource_name_prefix}-ecs-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.hotel_booking_ecs_task_assume_role_policy_document.json

  tags = merge(var.common_tags, {
    Name = "${var.resource_name_prefix}-ecs-task-execution-role"
  })
}

resource "aws_iam_role_policy_attachment" "hotel_booking_ecs_task_execution_policy_attachment" {
  role       = aws_iam_role.hotel_booking_ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_task_definition" "hotel_booking_ecs_task_definition" {
  family                   = "${var.resource_name_prefix}-ecs-task-definition"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = tostring(var.task_cpu)
  memory                   = tostring(var.task_memory)
  execution_role_arn       = aws_iam_role.hotel_booking_ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "hotel-booking-application"
      image     = var.container_image
      essential = true

      portMappings = [
        {
          containerPort = var.container_port
          protocol      = "tcp"
        }
      ]

      environment = [
        for environment_variable_name, environment_variable_value in var.container_environment_variables : {
          name  = environment_variable_name
          value = environment_variable_value
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.hotel_booking_ecs_log_group.name
          awslogs-region        = data.aws_region.current_aws_region.name
          awslogs-stream-prefix = "hotel-booking"
        }
      }
    }
  ])

  tags = merge(var.common_tags, {
    Name = "${var.resource_name_prefix}-ecs-task-definition"
  })
}

resource "aws_ecs_service" "hotel_booking_ecs_service" {
  name            = "${var.resource_name_prefix}-ecs-service"
  cluster         = aws_ecs_cluster.hotel_booking_ecs_cluster.id
  task_definition = aws_ecs_task_definition.hotel_booking_ecs_task_definition.arn
  desired_count   = var.desired_task_count
  launch_type     = "FARGATE"

  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_service_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.hotel_booking_ecs_target_group.arn
    container_name   = "hotel-booking-application"
    container_port   = var.container_port
  }

  depends_on = [
    aws_lb_listener.hotel_booking_http_listener
  ]

  tags = merge(var.common_tags, {
    Name = "${var.resource_name_prefix}-ecs-service"
  })
}