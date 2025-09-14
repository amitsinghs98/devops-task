terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }

backend "s3" {
  bucket = "devops-task-tfstate"
  key    = "ecs/terraform.tfstate"
  region = "ap-south-1"
  table  = "terraform-locks"  
  encrypt = true
}

}

provider "aws" {
  region = var.region
}

# ---------------------
# Networking (VPC, Subnets, etc.)
# ---------------------
resource "aws_vpc" "app_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "${var.app_name}-vpc" }
}

resource "aws_internet_gateway" "app_igw" {
  vpc_id = aws_vpc.app_vpc.id
  tags   = { Name = "${var.app_name}-igw" }
}

resource "aws_subnet" "app_subnet_1" {
  vpc_id                  = aws_vpc.app_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${var.region}a"
  tags = { Name = "${var.app_name}-subnet-1" }
}

resource "aws_subnet" "app_subnet_2" {
  vpc_id                  = aws_vpc.app_vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${var.region}b"
  tags = { Name = "${var.app_name}-subnet-2" }
}

resource "aws_route_table" "app_rt" {
  vpc_id = aws_vpc.app_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.app_igw.id
  }
  tags = { Name = "${var.app_name}-rt" }
}

resource "aws_route_table_association" "app_rta_1" {
  subnet_id      = aws_subnet.app_subnet_1.id
  route_table_id = aws_route_table.app_rt.id
}

resource "aws_route_table_association" "app_rta_2" {
  subnet_id      = aws_subnet.app_subnet_2.id
  route_table_id = aws_route_table.app_rt.id
}

resource "aws_security_group" "app_sg" {
  name        = "${var.app_name}-sg"
  description = "Allow HTTP/Express traffic"
  vpc_id      = aws_vpc.app_vpc.id

  ingress {
    description = "Allow HTTP on port 3000"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.app_name}-sg" }
}

# ---------------------
# IAM Role for ECS Task Execution
# ---------------------
data "aws_iam_policy_document" "ecs_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${var.app_name}-ecs-exec-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_attach" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ---------------------
# CloudWatch Log Group
# ---------------------
resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/ecs/${var.app_name}"
  retention_in_days = 7
}

# ---------------------
# ECS Cluster
# ---------------------
resource "aws_ecs_cluster" "app_cluster" {
  name = "${var.app_name}-cluster"
}

# ---------------------
# ECS Task Definition
# ---------------------
resource "aws_ecs_task_definition" "app_task" {
  family                   = var.app_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = templatefile("${path.module}/ecs-taskdef.json.tpl", {
    app_name     = var.app_name,
    ecr_repo_url = var.ecr_repo_url,
    branch       = var.branch,
    region       = var.region,
    log_group    = aws_cloudwatch_log_group.app_logs.name
  })
}

# ---------------------
# ECS Service
# ---------------------
resource "aws_ecs_service" "app_service" {
  name            = "${var.app_name}-service"
  cluster         = aws_ecs_cluster.app_cluster.id
  task_definition = aws_ecs_task_definition.app_task.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [aws_subnet.app_subnet_1.id, aws_subnet.app_subnet_2.id]
    security_groups = [aws_security_group.app_sg.id]
    assign_public_ip = true
  }

  depends_on = [aws_cloudwatch_log_group.app_logs]
}
