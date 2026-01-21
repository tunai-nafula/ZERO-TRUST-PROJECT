variable "aws_region" {
  type    = string
  default = "us-east-1"   
}

variable "project" {
  type    = string
  default = "zero-trust-ssm-terraform"
}

variable "instance_count" {
  type    = number
  default = 1
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "private_subnet_cidrs" {
  type = list(string)
  default = ["10.0.1.0/24"]
}

variable "zero_trust_ami_id" {
  description = "Pre-baked AMI with Apache + SSM"
  type        = string
}