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
  default = "539247483501.dkr.ecr.ap-south-1.amazonaws.com/logo-server-repo"
  type        = string
}

variable "desired_count" {
  description = "Number of ECS tasks to run"
  type        = number
}
variable "build_number" {
  type = string
  description = "Build number for image tag"
   default     = "latest"  
}