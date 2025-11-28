variable "aws_region" {
  type    = string
  default = "us-east-1"    # change to your preferred region
}

variable "project" {
  type    = string
  default = "zt-ssm-terraform"
}

variable "instance_count" {
  type    = number
  default = 1
}

variable "instance_type" {
  type    = string
  default = "t3.small"
}

variable "vpc_cidr" {
  type    = string
  default = "10.10.0.0/16"
}

variable "private_subnet_cidrs" {
  type = list(string)
  default = ["10.10.1.0/24"]
}
