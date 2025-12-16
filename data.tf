#fetches account and AMI info used by resources.

data "aws_caller_identity" "me" {}

# Use latest Amazon Linux 2 (contains SSM agent)

data "aws_ami" "amazon_linux2" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

}
