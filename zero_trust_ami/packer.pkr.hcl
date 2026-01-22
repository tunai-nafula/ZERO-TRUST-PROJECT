packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = ">= 1.2.0"
    }
  }
}

variable "aws_region" {
  default = "us-east-1"
}

# Base Amazon Linux 2 image with SSM and Zero Trust services baked
source "amazon-ebs" "zero_trust" {
  region        = var.aws_region
  instance_type = "t3.micro"
  ssh_username  = "ec2-user"

  ami_name = "zero-trust-ami-{{timestamp}}"

  source_ami_filter {
    filters = {
      name                = "amzn2-ami-hvm-*-x86_64-gp2"
      virtualization-type = "hvm"
      root-device-type    = "ebs"
    }
    owners      = ["amazon"]
    most_recent = true
  }
}

# Build block — provisioning
build {
  sources = ["source.amazon-ebs.zero_trust"]

  provisioner "shell" {
    inline = [
      "set -euxo pipefail",

      # Base system update
      "sudo yum update -y",

      # Install required services
      # - amazon-ssm-agent : REQUIRED
      # - chrony           : REQUIRED for TLS and SSM registration
      # - httpd            : Demo service only
      "sudo yum install -y amazon-ssm-agent chrony httpd",

      # Enable and start chrony for accurate time (critical for SSM TLS)
      "sudo systemctl enable chronyd",
      "sudo systemctl start chronyd",

      # Enable SSM agent to start on boot
      # Do NOT leave it running at bake time
      "sudo systemctl enable amazon-ssm-agent",

      # OPTIONAL: temporary start to validate it exists
      "sudo systemctl start amazon-ssm-agent",
      "systemctl is-active amazon-ssm-agent",

      # Stop SSM agent and remove baked-in registration - prevents AMI from being pre-registered
      "sudo systemctl stop amazon-ssm-agent",
      "sudo rm -rf /var/lib/amazon/ssm/*",

      # Optional demo service
      "sudo systemctl enable httpd",
      "sudo systemctl start httpd",
      "echo 'Hello from Zero Trust AMI' | sudo tee /var/www/html/index.html",

      # Sanity checks and debug
      "amazon-ssm-agent --version",
      "date"
    ]
  }
}

