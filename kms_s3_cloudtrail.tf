# KMS key for encrypting logs (CloudTrail/SSM session artifacts)
resource "aws_kms_key" "audit" {
  description             = "KMS key for ${var.project} audit logs"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  # REQUIRED: CloudTrail must be allowed to use the key
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.me.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow CloudTrail to encrypt logs"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action = [
          "kms:GenerateDataKey*",
          "kms:Encrypt"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:EncryptionContext:aws:cloudtrail:arn" = "arn:aws:cloudtrail:${var.aws_region}:${data.aws_caller_identity.me.account_id}:trail/${var.project}-cloudtrail"
          }
        }
      },
      {
        Sid    = "Allow CloudTrail to decrypt for validation"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action = [
          "kms:Decrypt"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name = "${var.project}-audit-key"
  }
}

# S3 bucket for audit/session logs
resource "aws_s3_bucket" "audit_bucket" {
  bucket = "${var.project}-audit-${data.aws_caller_identity.me.account_id}"

  tags = {
    Name = "${var.project}-audit-bucket"
  }
}

# REQUIRED when ACLs disabled (replaces object_ownership inside bucket block)
resource "aws_s3_bucket_ownership_controls" "audit_bucket_ownership" {
  bucket = aws_s3_bucket.audit_bucket.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# Versioning configuration
resource "aws_s3_bucket_versioning" "audit_bucket_versioning" {
  bucket = aws_s3_bucket.audit_bucket.id

  versioning_configuration {
    status = "Enabled"
  }

  lifecycle {
    prevent_destroy = true
  }
}

# Server-side encryption configuration
resource "aws_s3_bucket_server_side_encryption_configuration" "audit_bucket_encryption" {
  bucket = aws_s3_bucket.audit_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.audit.arn
    }
  }
}

# Bucket Policy for CloudTrail access (FULLY FIXED)
resource "aws_s3_bucket_policy" "audit_bucket_policy" {
  bucket = aws_s3_bucket.audit_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # REQUIRED: ACL check
      {
        Sid       = "AWSCloudTrailAclCheck"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = "arn:aws:s3:::${aws_s3_bucket.audit_bucket.id}"
      },

      # REQUIRED: CloudTrail write with bucket-owner-full-control
      {
        Sid       = "AWSCloudTrailWrite"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "arn:aws:s3:::${aws_s3_bucket.audit_bucket.id}/AWSLogs/${data.aws_caller_identity.me.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },

      # REQUIRED: Allow CloudTrail to write using KMS SSE
      {
        Sid       = "AWSCloudTrailSSEKMSEncrypt"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "arn:aws:s3:::${aws_s3_bucket.audit_bucket.id}/AWSLogs/${data.aws_caller_identity.me.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-server-side-encryption"                = "aws:kms",
            "s3:x-amz-server-side-encryption-aws-kms-key-id" = aws_kms_key.audit.arn
          }
        }
      }
    ]
  })
}

# CloudWatch log group for SSM session logs
resource "aws_cloudwatch_log_group" "ssm_sessions" {
  name              = "/aws/ssm/${var.project}/sessions"
  retention_in_days = 365

  tags = { 
    Name = "${var.project}-ssm-sessions" 
  }
}

# CloudTrail for API-level auditing
resource "aws_cloudtrail" "trail" {
  name                          = "${var.project}-cloudtrail"
  s3_bucket_name                = aws_s3_bucket.audit_bucket.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_logging                = true
  kms_key_id                    = aws_kms_key.audit.arn

  depends_on = [
    aws_s3_bucket_policy.audit_bucket_policy,
    aws_s3_bucket_ownership_controls.audit_bucket_ownership
  ]
}
