#instances will not be reachable via the network (no SSH/22), agent reaches AWS via HTTPS


# VPC
resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr
  tags = { Name = "${var.project}-vpc" }
}

# Private subnets (no public IPs)
resource "aws_subnet" "private" {
  count                   = length(var.private_subnet_cidrs)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.private_subnet_cidrs[count.index]
  map_public_ip_on_launch = false
  tags = { Name = "${var.project}-private-${count.index}" }
}

# Security group: NO inbound at all. Only allow outbound 443 for SSM Agent.
resource "aws_security_group" "ssm_only" {
  name        = "${var.project}-ssm-only"
  description = "Zero inbound SSM only access"
  vpc_id      = aws_vpc.this.id

  ingress {
     from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = []
    description = "No inbound ports"
  }

  egress {
    description = "Allow SSM agent outbound (HTTPS)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project}-sg-ssm" }
}
