resource "aws_s3_bucket" "backup_demo" {
  bucket = "jdrake-backup-demo-bucket"
}

resource "aws_s3_bucket_versioning" "backup_demo_versioning" {
  bucket = aws_s3_bucket.backup_demo.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "backup_demo_block" {
  bucket = aws_s3_bucket.backup_demo.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "backup_demo_encryption" {
  bucket = aws_s3_bucket.backup_demo.id

  rule {
    bucket_key_enabled = true

    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}