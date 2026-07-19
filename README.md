# AWS-Automated-Backup-System
An automated AWS backup system I'm building to learn AWS Backup, IAM, and infrastructure as code. Backs up resources on a schedule, alerts me if something fails, and follows least-privilege security practices.


## The Problem

Companies lose data all the time. Someone deletes the wrong file, a server gets corrupted, ransomware hits, or an employee leaves and something important goes missing with them. If backups aren't automatic, they usually don't happen at all, since manual backups depend on someone remembering to do them.

To fix that, backups need to run on their own, without a person clicking anything. That means giving something other than a human the permission to do it, which is where an IAM role comes in. Instead of using my own login, I set up a role that only AWS Backup can use, so it can create backups automatically on a schedule without me needing to be logged in or even awake.


## Security Setup

Before creating any resources on AWS, I handled the basic security setup.

- Enabled MFA on my root account
- Enabled MFA on my IAM admin user

Wanted it secured before moving forward.


## IAM Setup

Next, I created the IAM role that AWS Backup actually uses to run backups.

- Created IAM Role: `AWSBackupServiceRole`
- Attached AWS managed policy: `AWSBackupServiceRolePolicyForBackup`

I went with the AWS managed policy instead of writing my own policy, since it already covers exactly what AWS Backup needs. It also means the role can only do things related to backups and nothing else, which follows least privilege. In the future I want to improve my skills writing a fully custom policy myself, just to understand IAM permissions at a deeper level.


## Backup Vault

After that, I created the backup vault where the actual backups are going to be stored.

- Created Backup Vault: `primary-backup-vault`
- Encryption: AWS managed key (`aws/backup`)
- Vault Lock: not enabled

I'm leaving Vault Lock off for now. I want to get the basic backup process working first, then turn it on later. It's mainly for compliance and protecting backups from ransomware.


## Created an S3 Bucket

I created an S3 bucket to actually have something to back up.

- Versioning: enabled
- Public access: fully blocked
- Encryption: SSE-S3  (Amazon S3 managed keys)

I left most of the other settings at their defaults since they were already the recommended options.I turned on versioning since it works well with AWS Backup, keeping older copies of files whenever something changes.


## Backup Plan

Next, I created the actual backup plan that runs the schedule.

- Plan name: `S3BackupPlan`
- Rule: `DailyS3Backup`, runs daily at 12:30 AM
- Retention: 30 days
- Point-in-time recovery: enabled
- IAM role: `AWSBackupServiceRole`
- Resource assigned: my S3 bucket specifically, not all buckets in the account

At first the resource assignment defaulted to an auto-generated IAM role instead of the one I built earlier. I caught it, deleted the assignment, and redid it using my own role instead.  I also made sure it was only pointing at my one bucket, instead of accidentally including all buckets in the account.


## Testing the Backup

I ran a manual backup just to see if it actually worked, instead of waiting overnight for the schedule.

It failed the first time with a permissions error. The regular AWS Backup policy wasn't enough for S3 by itself. I had to add one more AWS managed policy, `AWSBackupServiceRolePolicyForS3Backup`, to my IAM role to fix it.

I ran it again after that and it worked. It took a bit since it was the first backup for the bucket, but it finished and created a real recovery point.

