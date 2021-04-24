variable "vpc-cidr" {
  default = "10.0.0.0/16"
}

variable "public_subnet-cidr" {
  default = "10.0.1.0/24"
}

variable "private_subnet-cidr" {
  default = "10.0.16.0/24"
}

variable "ecs-service-port" {
  default = 4444
}