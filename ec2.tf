resource "aws_instance" "private" {
  count = var.instance_count

  ami                    = data.aws_ami.amazon_linux2.id
  instance_type          = var.instance_type
  subnet_id              = element(aws_subnet.private.*.id, 0)
  vpc_security_group_ids = [aws_security_group.ssm_only.id]

  iam_instance_profile         = aws_iam_instance_profile.ec2_profile.name
  associate_public_ip_address  = false

  user_data = <<-EOF
              #!/bin/bash
              # Basic example service — accessible only by SSM port forwarding or session shell

              yum update -y
              #yum install -y amazon-ssm-agent
              yum install -y httpd

              systemctl enable --now httpd
              echo "Hello from private instance $(hostname -f)" > /var/www/html/index.html

              # ensure SSM agent is running
              #systemctl enable amazon-ssm-agent || true
              systemctl start amazon-ssm-agent || true
              EOF

#The EC2 will not launch until the VPC endpoints are created
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
    http_endpoint               = "enabled"
    http_tokens                 = "required"
  }
}

/* Output the type of EC2 to be created and AMI info for debugging purposes
/* output "ami_debug" {
  value = {
    id   = data.aws_ami.amazon_linux2.id
    name = data.aws_ami.amazon_linux2.name
    owner = data.aws_ami.amazon_linux2.owner_id
  }
} */
  

output "private_ec2_id" {
  description = "ID of the first private EC2 instance"
  value       = aws_instance.private[0].id
}