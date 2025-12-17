resource "aws_instance" "private" {
  count = var.instance_count

  ami                    = data.aws_ami.amazon_linux2.id
  instance_type          = var.instance_type
  subnet_id              = element(aws_subnet.private.*.id, 0)
  vpc_security_group_ids = [aws_security_group.ssm_only.id]

  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  associate_public_ip_address = false

  user_data = <<-EOF
              #!/bin/bash
              set -e

              # Update packages
              yum update -y

              # Install Apache (httpd)
              yum install -y httpd

              # Enable and start Apache
              systemctl enable httpd
              systemctl start httpd

              # Write index page
              echo "Hello from private instance $(hostname -f)" > /var/www/html/index.html

              # Install SSM Agent if missing
              if ! command -v amazon-ssm-agent &> /dev/null; then
                  yum install -y amazon-ssm-agent
              fi

              # Ensure SSM Agent is enabled and running
              systemctl enable amazon-ssm-agent
              systemctl start amazon-ssm-agent
              EOF

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
