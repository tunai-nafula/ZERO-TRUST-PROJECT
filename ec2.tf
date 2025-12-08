resource "aws_instance" "private" {
  count = var.instance_count

  ami                    = data.aws_ami.amazon_linux2.id
  instance_type          = var.instance_type
  subnet_id              = element(aws_subnet.private.*.id, 0)
  vpc_security_group_ids = [aws_security_group.ssm_only.id]

  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  associate_public_ip_address = false

  user_data = <<-EOF
              #!/bin/bash
              # basic example service — accessible only by SSM port forwarding or session shell
              yum update -y
              yum install -y amazon-ssm-agent
              yum install -y httpd
              systemctl enable --now httpd
              echo "Hello from private instance $(hostname -f)" > /var/www/html/index.html

              # ensure SSM agent is running
              systemctl enable amazon-ssm-agent || true
              systemctl start  amazon-ssm-agent  || true
              EOF

  tags = {
    Name      = "${var.project}-private-${count.index}"
    zt-access = "true"   # tag can be used in IAM StartSession conditions
  }
}
