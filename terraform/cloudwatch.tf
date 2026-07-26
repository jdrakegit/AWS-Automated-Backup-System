resource "aws_cloudwatch_dashboard" "backup_system_dashboard" {
  dashboard_name = "BackupSystemDashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 6
        height = 3
        properties = {
          metrics   = [
            ["AWS/Backup", "NumberOfBackupJobsCompleted"]
          ]
          view      = "singleValue"
          region    = "us-east-2"
          title     = "NumberOfBackupJobsCompleted"
          sparkline = true
        }
      },
      {
        type   = "metric"
        x      = 6
        y      = 0
        width  = 6
        height = 3
        properties = {
          metrics   = [
            ["AWS/Backup", "NumberOfBackupJobsCreated"]
          ]
          view      = "singleValue"
          region    = "us-east-2"
          title     = "NumberOfBackupJobsCreated"
          sparkline = true
        }
      }
    ]
  })
}
