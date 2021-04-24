resource "aws_iam_role" "ecs-task-execution-role" {
  name = "ecs-task-execution-role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs-task-execution-role-policy-attachment" {
  role       = aws_iam_role.ecs-task-execution-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_cluster" "ecs-cluster" {
  name               = "ecs-cluster"
  capacity_providers = ["FARGATE"]
}

resource "aws_ecs_task_definition" "dobby" {
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  family                   = "dobby"
  execution_role_arn       = aws_iam_role.ecs-task-execution-role.arn
  cpu = 256
  memory = 512
  container_definitions = jsonencode([
    {
      name      = "dobby"
      image     = "thecasualcoder/dobby"
      essential = true
      portMappings = [
        {
          containerPort = 4444
          hostPort      = 4444
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "dobby" {
  name            = "dobby"
  cluster         = aws_ecs_cluster.ecs-cluster.id
  task_definition = aws_ecs_task_definition.dobby.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = aws_lb_target_group.dobby.arn
    container_name   = "dobby"
    container_port   = 4444
  }

  network_configuration {
    subnets          = [aws_subnet.private.id]
    assign_public_ip = false
    security_groups  = [aws_security_group.ecs-tasks.id]
  }
}