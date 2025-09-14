variable "app_name" {
  description = "Application name"
  type        = string
}

variable "branch" {
  description = "Git branch name (used for tagging images)"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "ecr_repo_url" {
  description = "ECR repository URL for ExpressJS app"
  type        = string
}

variable "desired_count" {
  description = "Number of ECS tasks to run"
  type        = number
  default     = 1
}
