resource "aws_backup_vault" "primary_backup_vault" {
  name = "primary-backup-vault"
}

resource "aws_backup_plan" "s3_backup_plan" {
  name = "S3BackupPlan"

  rule {
    rule_name                    = "DailyS3Backup"
    target_vault_name            = aws_backup_vault.primary_backup_vault.name
    schedule                     = "cron(30 0 ? * * *)"
    schedule_expression_timezone = "America/New_York"
    start_window                 = 480
    completion_window            = 10080
    enable_continuous_backup     = true

    lifecycle {
      delete_after = 30
    }
  }

  lifecycle {
    ignore_changes = [advanced_backup_setting]
  }
}

resource "aws_backup_selection" "s3_backup_selection" {
  name         = "S3BucketAssignment"
  plan_id      = aws_backup_plan.s3_backup_plan.id
  iam_role_arn = aws_iam_role.backup_role.arn

  resources = [
    aws_s3_bucket.backup_demo.arn
  ]
}