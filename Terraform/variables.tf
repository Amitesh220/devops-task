variable "region" {
  type    = string
  default = "ap-south-1"
}

variable "project" {
  type    = string
  default = "devops-task"
}

variable "public_subnets" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "container_port" {
  type    = number
  default = 3000
}

variable "cpu" {
  type    = string
  default = "256"
}

variable "memory" {
  type    = string
  default = "512"
}

variable "desired_count" {
  type    = number
  default = 1
}

variable "dockerhub_image" {
  type    = string
  default = "your-dockerhub-username/devops-task:latest"
}
