resource "aws_instance" "private" {
  count = var.instance_count

  # Use pre-baked Zero Trust AMI (SSM + Apache already installed)
  ami                    = var.zero_trust_ami_id
  instance_type          = var.instance_type
  subnet_id = element(
  aws_subnet.private[*].id,
  count.index % length(aws_subnet.private)
)
  vpc_security_group_ids = [aws_security_group.ssm_only.id]

  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  associate_public_ip_address = false

  # user_data REMOVED
  # Configuration is now baked into the AMI for immutability and faster boot

  # The EC2 will not launch until the VPC endpoints are created
  depends_on = [
    aws_vpc_endpoint.ssm,
    aws_vpc_endpoint.ssmmessages,
    aws_vpc_endpoint.ec2messages
  ]

  tags = {
    Name      = "${var.project}-private-${count.index}"
    zt-access = "true"   # can be used in IAM StartSession policies
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
}

/* Output the type of EC2 to be created and AMI info for debugging purposes
output "ami_debug" {
  value = {
    id    = data.aws_ami.amazon_linux2.id
    name  = data.aws_ami.amazon_linux2.name
    owner = data.aws_ami.amazon_linux2.owner_id
  }
} */

/* Output the private EC2 instance ID */
output "private_ec2_id" {
  description = "ID of the first private EC2 instance"
  value       = aws_instance.private[0].id
}
