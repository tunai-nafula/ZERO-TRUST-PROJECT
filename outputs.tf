output "private_instance_ids" {
  value = aws_instance.private.*.id
}

output "private_instance_private_ips" {
  value = aws_instance.private.*.private_ip
}

output "ec2_ssm_role" {
  value = aws_iam_role.ec2_ssm_role.arn
}

output "admin_mfa_role" {
  value = aws_iam_role.admin_mfa_role.arn
}

output "audit_bucket" {
  value = aws_s3_bucket.audit_bucket.bucket
}

output "cloudwatch_log_group" {
  value = aws_cloudwatch_log_group.ssm_sessions.name
}

output "kms_audit_key" {
  value = aws_kms_key.audit.arn
}
