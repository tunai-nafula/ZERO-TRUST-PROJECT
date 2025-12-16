# EC2 instance role for SSM can manage the instance
resource "aws_iam_role" "ec2_ssm_role" {
  name = "${var.project}-ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })

  tags = { Name = "${var.project}-ec2-ssm-role" 
  }
}

# Attach AWS managed policy that gives SSM agent the permissions it needs
resource "aws_iam_role_policy_attachment" "attach_ssm_core" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance profile to attach the role to EC2
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project}-instance-profile"
  role = aws_iam_role.ec2_ssm_role.name
}


# Create an admin role 
resource "aws_iam_role" "admin_mfa_role" {
  name = "${var.project}-admin-mfa-role"

  
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.me.account_id}:root" },
      Action    = "sts:AssumeRole"
    }]
  })

  tags = { Name = "${var.project}-admin-mfa-role" 
  }
}

# Require MFA to start/terminate sessions: Zero-Trust identity verification
data "aws_iam_policy_document" "ssm_start_with_mfa_doc" {
  statement {
    sid    = "AllowSSMSessionActionsOnlyWithMFA"
    effect = "Allow"

    actions = [
      "ssm:StartSession",
      "ssm:TerminateSession",
      "ssm:DescribeSessions",
      "ssm:GetConnectionStatus"
    ]

    resources = ["*"]

    condition {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["true"]
    }
  }
}

resource "aws_iam_policy" "ssm_start_mfa_policy" {
  name   = "${var.project}-ssm-start-mfa"
  policy = data.aws_iam_policy_document.ssm_start_with_mfa_doc.json
}

resource "aws_iam_role_policy_attachment" "attach_mfa_policy" {
  role       = aws_iam_role.admin_mfa_role.name
  policy_arn = aws_iam_policy.ssm_start_mfa_policy.arn
}



# ---------------------------------------------------------------
# IAM Policy: SSM Session & Port Forwarding
# ---------------------------------------------------------------
resource "aws_iam_policy" "ssm_port_forwarding" {
  name        = "SSMPortForwardingPolicy"
  description = "Allows SSM sessions and port forwarding for EC2 instances"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "ssm:StartSession",
          "ssm:StartPortForwardingSession",
          "ssm:DescribeInstanceInformation",
          "ssm:TerminateSession" 
        ]
        Resource = "*"
      }
    ]
  })
}

# ---------------------------------------------------------------
# Attach to EC2 IAM Role (used by your Zero Trust EC2)
# ---------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "ssm_port_forwarding_role_attach" {
  role       = aws_iam_role.ec2_ssm_role.name # Replace with your actual EC2 role resource
  policy_arn = aws_iam_policy.ssm_port_forwarding.arn
}

# NEW → Serial Console IAM policy
# --------------------------------------------------------------------
resource "aws_iam_policy" "serial_console_access" {
  name = "${var.project}-serial-console-access"
  description = "Allows starting EC2 Serial Console sessions"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ec2-instance-connect:SendSerialConsoleSSHPublicKey",
          "ec2:StartSerialConsoleSession"
        ],
        Resource = "*"
      }
    ]
  })
}

# Attach Serial Console permissions to the admin MFA role
resource "aws_iam_role_policy_attachment" "attach_serial_console" {
  role       = aws_iam_role.admin_mfa_role.name
  policy_arn = aws_iam_policy.serial_console_access.arn
}
