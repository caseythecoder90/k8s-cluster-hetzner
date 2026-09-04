# Q3 (topic: CronJobs)

In Namespace `zeus`, create a CronJob `zeus-backup`:

1. Schedule: **every 5 minutes**
2. Image `busybox:1`, command prints `backup run`
3. `concurrencyPolicy: Forbid` (never run two at once)
4. Keep only **2** successful job records and **1** failed job record
   (`successfulJobsHistoryLimit` / `failedJobsHistoryLimit`)
