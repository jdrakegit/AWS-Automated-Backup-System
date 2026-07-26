resource "aws_cloudwatch_event_rule" "backup_job_state_change" {
  name        = "BackupJobStateChange"
  description = "Sends AWS Backup job status updates to SNS"

  event_pattern = jsonencode({
    source      = ["aws.backup"]
    detail-type = ["Backup Job State Change"]
  })
}

resource "aws_cloudwatch_event_target" "sns_target" {
  rule      = aws_cloudwatch_event_rule.backup_job_state_change.name
  target_id = "Idedb9a53f-b92d-4e9d-a79a-434c985c8e5e"
  arn       = aws_sns_topic.backup_notifications.arn
  role_arn  = "arn:aws:iam::183088435390:role/service-role/Amazon_EventBridge_Invoke_Sns_1851665710"
}
