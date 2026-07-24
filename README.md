An automated AWS backup system I'm building to learn AWS Backup, IAM, and infrastructure as code. Backs up resources on a schedule, alerts me if something fails, and follows least-privilege security practices.

I'm building this project twice. First by clicking through the AWS Console by hand, then again using Terraform, so I can actually learn how infrastructure as code works instead of just reading about it.

# Part 1: Building This by Hand

I'm doing this project two ways. First, clicking through the AWS Console manually to learn how everything works. Then, I'll rebuild it using Terraform to learn Infrastructure as Code.


## The Problem

Companies lose data all the time. Someone deletes the wrong file, a server gets corrupted, ransomware hits, or an employee leaves and something important goes missing with them. If backups aren't automatic, they usually don't happen at all, since manual backups depend on someone remembering to do them.

To fix that, backups need to run on their own, without a person clicking anything. That means giving something other than a human the permission to do it, which is where an IAM role comes in. Instead of using my own login, I set up a role that only AWS Backup can use, so it can create backups automatically on a schedule without me needing to be logged in or even awake.


I will be doing this first manually clicking through and then trying terraform for my first to try to learn and understand it


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

At first the resource assignment defaulted to an auto-generated IAM role instead of the one I built earlier. I caught it, deleted the assignment,  and redid it using my own role instead.  I also made sure it was only pointing at my one bucket, instead of accidentally including all buckets in the account.


## Testing the Backup

I ran a manual backup just to see if it actually worked, instead of waiting overnight for the schedule.

It failed the first time with a permissions error. The regular AWS Backup policy wasn't enough for S3 by itself.  I had to add one more AWS managed policy, `AWSBackupServiceRolePolicyForS3Backup`, to my IAM role to fix it.

I ran it again after that and it worked. It took a bit since it was the first backup for the bucket, but it finished and created a real recovery point.


## First Automated Backup

The next morning, I checked the Jobs page and saw a new backup that I didn't trigger myself.  It ran automatically overnight at 12:30 AM based on the schedule in my backup plan, and it completed successfully.

This confirmed the automation actually works end to end, not just when I run it manually.


## SNS Notifications

I set up SNS so I could get notified about backups instead of checking the console every time.

- Created a topic called `backup-notifications` (Standard type)
- Subscribed my email to it
- Had to confirm the subscription through an email AWS sent me, which actually went to my spam folder at first

I kept the topic locked down so only I can publish to it or subscribe to it, nobody else.


## EventBridge Rule

The last thing I needed was a way to connect backup job events to my SNS topic, so I could actually get notified instead of checking the console every time.

- Made a rule called `BackupJobStateChange`
- It watches for AWS Backup job status changes
- Sends those events to my SNS topic, `backup-notifications`
- Let AWS create the IAM role for it automatically, since it only needed access to one thing.

Now the whole thing works together. A backup runs, its status changes, EventBridge catches that, and SNS sends me an email.


## Confirmed Notifications Work

I ran another backup to test the SNS setup. It worked, I got three emails, one for each stage       (running, created, completed). The last one showed it finished successfully.

This proved the whole thing works on its own. A backup runs, its status changes, EventBridge catches it, and SNS emails me. No manual checking needed.

One thing I noticed is the emails are just raw JSON, not something easy to read. I want to look into using a small Lambda function later to clean that up.


## CloudWatch Dashboard

I set up a small CloudWatch dashboard to check on backup activity.

- Created a dashboard called `BackupSystemDashboard`
- Added two widgets:  completed jobs and created jobs
- Wanted to track failed jobs too, but that metric doesn't show up until a backup actually fails. I'll add it later if that happens.


## Cleanup

Delete order if I shut this down:

1.  EventBridge rule
2.  SNS topic
3.  CloudWatch dashboard
4.  Backup plan
5.  Recovery points, then the vault (can't delete a vault with backups inside)
6.  S3 bucket
7.  IAM role

Most of the cost risk is the vault holding backups long-term. Everything else here is free or basically free.

Keeping it running for now since it's part of my portfolio.


## Cost Estimate

This project doesn't cost much at this size.

- S3 storage: only a few cents per month
- AWS Backup: charged based on how much data is backed up and how many backup jobs run
- Amazon SNS and Amazon EventBridge: covered by the AWS Free Tier
- CloudWatch dashboard: small cost after the Free Tier

If I backed up more data or kept backups for a longer time, the monthly cost would go up. For me right now, everything falls under the Free Tier, so this project has cost me nothing.


---


# Part 2: Rebuilding This in Terraform

Everything above this point was built by clicking through the AWS Console by hand. It all worked, and I tested and confirmed it end to end.

Below this point, I'm rebuilding the same system using Terraform, so it's actually written in code instead of just existing because I clicked through it once. This also gives me a chance to learn Infrastructure as Code by applying it to something I already understand.

---


## Terraform Setup

Started setting up Terraform.

- Installed Terraform with Homebrew
- Already had the AWS CLI installed
- Made a new access key for my IAM user just for this
- Ran `aws configure` and confirmed the CLI is using my IAM user

First Terraform file was just a provider block, telling Terraform to use AWS and my region. Ran `terraform init` and it worked.
## Terraform: IAM Role

This was my first time using Terraform, so I started with something I'd already built by hand, the IAM role, to learn how Terraform actually works.

- Wrote `iam.tf` with the role and both policy attachments
- Since the role already existed, I used `terraform import` to bring it under Terraform's management instead of creating a duplicate
- Ran into an error importing the S3 policy attachment. Turned out the actual policy ARN didn't have `/service-role/` in the path like the other one did. Checked it directly with the AWS CLI and found the real ARN, then fixed my code.
- Ran `terraform apply` and it synced everything. The only real change was updating the role's description to match what's in my code now.

This was a good first resource to learn on. Importing existing infrastructure and debugging a real mismatch taught me more than if everything had just worked on the first try.


## Terraform: S3 Bucket

Rebuilt the S3 bucket in Terraform, versioning, public access block, and encryption included.

- Wrote `s3.tf` for all four pieces
- Imported them since they already existed
- Found one mismatch, the bucket had `bucket_key_enabled = true` that wasn't in my code. Added it and it matched.
- Ran `terraform plan` again and got "No changes," meaning my code now matches what's actually in AWS


## Terraform: Backup Plan

This one was harder than the others. First time really seeing how much detail Terraform needs to match reality.

- Wrote `backup.tf` for the plan and the resource assignment
- Had to import both. The assignment needed the plan ID and its own ID combined together
- My first schedule was wrong. I assumed AWS stored the time in UTC, but it actually uses my own timezone. Had to check the real values with the AWS CLI and fix it
- Tried adding the S3 backup options (ACLs and tags) in code, but Terraform doesn't support that for S3 yet, only EC2. Had to leave it out and tell Terraform to ignore that difference instead
- Also had a syntax error from an unclosed block after editing
- Finally got "No changes" after fixing everything, meaning my code actually matches what's really in AWS now
