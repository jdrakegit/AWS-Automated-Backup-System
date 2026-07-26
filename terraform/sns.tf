resource "aws_sns_topic" "backup_notifications" {
  name = "backup-notifications"
}

resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn                       = aws_sns_topic.backup_notifications.arn
  protocol                        = "email"
  endpoint                        = "jidrake111@gmail.com"
  confirmation_timeout_in_minutes = 1
  endpoint_auto_confirms          = false
}