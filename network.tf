# ---------------------------------------------------------------
# VPC — Base network for the environment
# DNS MUST be enabled for Interface Endpoints (SSM, KMS)
# ---------------------------------------------------------------
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project}-vpc"
  }
}

# ---------------------------------------------------------------
# Private subnets (no public IPs, no internet access)
# ---------------------------------------------------------------
resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidrs[count.index]

  availability_zone = var.allowed_azs[
    count.index % length(var.allowed_azs)
  ]

  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project}-private-${count.index}"
  }
}


# ---------------------------------------------------------------
# Security Group — EC2 (SSM-only, zero inbound)
# ---------------------------------------------------------------
resource "aws_security_group" "ssm_only" {
  name        = "${var.project}-sg-ssm-only"
  description = "Zero inbound, HTTPS egress for SSM"
  vpc_id      = aws_vpc.this.id

  # No inbound traffic at all
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = []
    description = "No inbound traffic"
  }

  # Allow HTTPS outbound for SSM agent
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Outbound HTTPS to AWS services"
  }

  tags = {
    Name = "${var.project}-sg-ssm-only"
  }
}

# ---------------------------------------------------------------
# Security Group — VPC Interface Endpoints
# ---------------------------------------------------------------
resource "aws_security_group" "endpoints" {
  name        = "${var.project}-sg-vpc-endpoints"
  description = "Allow HTTPS from private subnets to VPC endpoints"
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.private_subnet_cidrs
    description = "HTTPS from private subnets"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-sg-vpc-endpoints"
  }
}

# ---------------------------------------------------------------
# VPC Interface Endpoints — REQUIRED for SSM (no NAT)
# Private DNS is CRITICAL
# ---------------------------------------------------------------

resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.endpoints.id]
  private_dns_enabled = true

  tags = {
    Name = "${var.project}-vpce-ssm"
  }
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${var.aws_region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.endpoints.id]
  private_dns_enabled = true

  tags = {
    Name = "${var.project}-vpce-ssmmessages"
  }
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${var.aws_region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.endpoints.id]
  private_dns_enabled = true

  tags = {
    Name = "${var.project}-vpce-ec2messages"
  }
}

# ---------------------------------------------------------------
# (Optional but recommended) KMS endpoint
# Required if SSM sessions or logs are encrypted with KMS
# ---------------------------------------------------------------
resource "aws_vpc_endpoint" "kms" {
  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${var.aws_region}.kms"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.endpoints.id]
  private_dns_enabled = true

  tags = {
    Name = "${var.project}-vpce-kms"
  }
}
