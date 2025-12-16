# Policy: DENY ssm:StartSession unless session logging to S3 and CloudWatch is enabled

# Users must start sessions with the CLI flags:
#   --cloud-watch-output-enabled  (or equivalent)
#   --s3-output-enabled
#

resource "aws_iam_policy" "ssm_logging_enforced" {
  name = "${var.project}-ssm-logging-enforced"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "DenyStartSessionIfLoggingNotEnabled",
        Effect = "Deny",
        Action = "ssm:StartSession",
        Resource = "*",
        Condition = {
          # Deny if CloudWatch logging flag is not true
          Bool = {
            "ssm:SessionCloudWatchLogsEnabled" = "false"
          },
          # Deny if S3 logging flag is not true
          Bool = {
            "ssm:SessionS3LogEnabled" = "false"
          }
        }
      }
    ]
  })
}

# Attach this deny policy to your human/admin role so they cannot start session
# unless logging is requested in the StartSession request.
resource "aws_iam_role_policy_attachment" "attach_logging_enforced" {
  role       = aws_iam_role.admin_mfa_role.name
  policy_arn = aws_iam_policy.ssm_logging_enforced.arn
}

